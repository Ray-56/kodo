#!/usr/bin/env python3
"""Exercise the REAL Kodo Rust API after implementation. Python 3.10+, stdlib only.

Creates two temporary namespaces, checks replay/isolation/deletion, then removes them.
No credentials or activity payloads are printed. This is not a mock server.
"""
from __future__ import annotations
import argparse
import base64
import copy
import datetime as dt
import json
import secrets
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from dataclasses import dataclass
from typing import Any

@dataclass(frozen=True)
class Installation:
    id: str
    secret: str

    @classmethod
    def create(cls) -> 'Installation':
        return cls(str(uuid.uuid4()), base64.urlsafe_b64encode(secrets.token_bytes(32)).decode().rstrip('='))

    @property
    def bearer(self) -> str:
        return f'{self.id}.{self.secret}'

class Smoke:
    def __init__(self, base_url: str, timeout: float):
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.results: list[dict[str, Any]] = []

    def request(self, method: str, path: str, body: Any = None,
                identity: Installation | None = None) -> tuple[int, Any]:
        headers = {'Accept': 'application/json'}
        data = None
        if body is not None:
            data = json.dumps(body, ensure_ascii=False, separators=(',', ':')).encode()
            headers['Content-Type'] = 'application/json'
        if identity is not None:
            headers['Authorization'] = 'Bearer ' + identity.bearer
        req = urllib.request.Request(self.base_url + path, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as response:
                status, raw = response.status, response.read()
        except urllib.error.HTTPError as error:
            status, raw = error.code, error.read()
        except (urllib.error.URLError, TimeoutError) as error:
            raise RuntimeError(f'Cannot reach API at {self.base_url}; start the implemented Rust service first.') from error
        if not raw:
            return status, None
        try:
            return status, json.loads(raw)
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise AssertionError(f'{method} {path}: expected JSON response, got non-JSON (HTTP {status})') from error

    def expect(self, name: str, expected: int, method: str, path: str,
               body: Any = None, identity: Installation | None = None) -> Any:
        status, result = self.request(method, path, body, identity)
        if status != expected:
            # Error bodies may contain user content on a buggy implementation; do not echo them.
            raise AssertionError(f'{name}: expected HTTP {expected}, got {status}')
        self.results.append({'test': name, 'status': 'passed', 'http_status': status})
        return result

def operation(seq: int, kind: str, entity_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    return {'op_id': str(uuid.uuid4()), 'seq': seq, 'kind': kind, 'entity_id': entity_id, 'payload': payload}

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base-url', default='http://127.0.0.1:8080')
    parser.add_argument('--timeout', type=float, default=15.0)
    parser.add_argument('--allow-insecure', action='store_true', help='Permit HTTP to a non-loopback development host.')
    parser.add_argument('--report', help='Optional JSON report path. Contains no secrets.')
    args = parser.parse_args()
    parsed = urllib.parse.urlparse(args.base_url)
    if parsed.scheme not in ('http', 'https') or not parsed.hostname or parsed.username or parsed.password:
        parser.error('base URL must be http(s) without embedded credentials')
    if parsed.scheme == 'http' and parsed.hostname not in ('127.0.0.1', 'localhost', '::1') and not args.allow_insecure:
        parser.error('Use HTTPS or explicitly allow an insecure DEVELOPMENT host with --allow-insecure')
    if args.timeout <= 0:
        parser.error('timeout must be positive')
    if not __debug__:
        parser.error('Do not run acceptance tests with python -O')
    if parsed.query or parsed.fragment:
        parser.error('base URL must not contain a query or fragment')
    client = Smoke(args.base_url, args.timeout)
    a, b = Installation.create(), Installation.create()
    created: list[Installation] = []
    started = time.monotonic()
    error_text: str | None = None
    try:
        client.expect('health ready', 200, 'GET', '/health/ready')
        client.expect('unauthorized snapshot', 401, 'GET', '/v1/snapshot')
        for identity in (a, b):
            # Track before request so a lost registration response still leads to cleanup.
            created.append(identity)
            result = client.expect('register temporary namespace', 201, 'POST', '/v1/installations',
                                   {'installation_id': identity.id, 'secret': identity.secret})
            assert result['installation_id'] == identity.id
        result = client.expect('registration retry', 200, 'POST', '/v1/installations',
                               {'installation_id': a.id, 'secret': a.secret})
        assert result['status'] == 'existing'
        client.expect('registration credential mismatch', 401, 'POST', '/v1/installations',
                      {'installation_id': a.id, 'secret': b.secret})
        now = int(time.time() * 1000)
        project_id = str(uuid.uuid4())
        project = {'name': 'smoke 俯卧撑', 'unit': '个', 'icon_key': 'dumbbell', 'quick_amount': 10,
                   'archived': False, 'created_at_utc_ms': now, 'updated_at_utc_ms': now}
        put = operation(1, 'project.put', project_id, project)
        result = client.expect('create project', 200, 'POST', '/v1/operations', put, a)
        assert result['seq'] == 1 and result['status'] == 'applied'
        date = dt.datetime.fromtimestamp(now / 1000, dt.timezone(dt.timedelta(hours=8))).date().isoformat()
        def entry_body(amount: int) -> dict[str, Any]:
            return {'project_id': project_id, 'amount': amount, 'occurred_at_utc_ms': now,
                    'utc_offset_minutes': 480, 'local_date': date}
        first = operation(2, 'entry.add', str(uuid.uuid4()), entry_body(20))
        second = operation(3, 'entry.add', str(uuid.uuid4()), entry_body(10))
        client.expect('add 20', 200, 'POST', '/v1/operations', first, a)
        client.expect('add 10', 200, 'POST', '/v1/operations', second, a)
        replay = client.expect('replay entry', 200, 'POST', '/v1/operations', first, a)
        assert replay['status'] == 'duplicate'
        changed = copy.deepcopy(first)
        changed['payload']['amount'] = 21
        bad = client.expect('same identity changed body', 409, 'POST', '/v1/operations', changed, a)
        assert bad['error']['code'] == 'operation_mismatch'
        gap = operation(5, 'entry.void', second['entity_id'], {'voided_at_utc_ms': now + 1})
        bad = client.expect('sequence gap', 409, 'POST', '/v1/operations', gap, a)
        assert bad['error']['expected_seq'] == 4
        void = operation(4, 'entry.void', second['entity_id'], {'voided_at_utc_ms': now + 1})
        client.expect('void exact entry', 200, 'POST', '/v1/operations', void, a)
        again = operation(5, 'entry.void', second['entity_id'], {'voided_at_utc_ms': now + 2})
        client.expect('repeated void no extra effect', 200, 'POST', '/v1/operations', again, a)
        archived = {**project, 'archived': True, 'updated_at_utc_ms': now + 3}
        client.expect('archive project', 200, 'POST', '/v1/operations', operation(6, 'project.put', project_id, archived), a)
        replay = client.expect('replay before archived-state validation', 200, 'POST', '/v1/operations', first, a)
        assert replay['status'] == 'duplicate'
        client.expect('no new entry on archived project', 422, 'POST', '/v1/operations',
                      operation(7, 'entry.add', str(uuid.uuid4()), entry_body(1)), a)
        client.expect('cross namespace project reference', 422, 'POST', '/v1/operations',
                      operation(1, 'entry.add', str(uuid.uuid4()), entry_body(1)), b)
        b_snapshot = client.expect('empty isolated namespace', 200, 'GET', '/v1/snapshot', identity=b)
        assert b_snapshot['projects'] == [] and b_snapshot['entries'] == [] and b_snapshot['last_seq'] == 0
        client.expect('restore project after rejected seq', 200, 'POST', '/v1/operations',
                      operation(7, 'project.put', project_id, {**project, 'updated_at_utc_ms': now + 4}), a)
        client.expect('locked unit', 422, 'POST', '/v1/operations',
                      operation(8, 'project.put', project_id, {**project, 'unit': '次', 'updated_at_utc_ms': now + 5}), a)
        invalid_date = {**entry_body(1), 'local_date': '1970-01-01'}
        client.expect('date consistency', 422, 'POST', '/v1/operations',
                      operation(8, 'entry.add', str(uuid.uuid4()), invalid_date), a)
        snapshot = client.expect('consistent server snapshot', 200, 'GET', '/v1/snapshot', identity=a)
        valid = [e for e in snapshot['entries'] if e['voided_at_utc_ms'] is None]
        assert snapshot['last_seq'] == 7 and len(valid) == 1 and sum(e['amount'] for e in valid) == 20
        assert len(snapshot['entries']) == 2 and len(snapshot['projects']) == 1
        client.expect('delete all server data', 204, 'DELETE', '/v1/installations/current', identity=a)
        client.expect('repeat deletion', 204, 'DELETE', '/v1/installations/current', identity=a)
        client.expect('late operation cannot revive data', 410, 'POST', '/v1/operations', first, a)
        client.expect('revoked snapshot rejected', 410, 'GET', '/v1/snapshot', identity=a)
        client.expect('revoked registration rejected', 410, 'POST', '/v1/installations',
                      {'installation_id': a.id, 'secret': a.secret})
    except (AssertionError, RuntimeError, KeyError, TypeError) as error:
        error_text = str(error) or type(error).__name__
    finally:
        cleanup_failed = False
        for identity in created:
            try:
                status, _ = client.request('DELETE', '/v1/installations/current', identity=identity)
                if status != 204:
                    cleanup_failed = True
            except Exception:
                cleanup_failed = True
        if cleanup_failed:
            print('WARNING: cleanup could not be confirmed. These are temporary test namespaces.', file=sys.stderr)
    if cleanup_failed and error_text is None:
        error_text = 'Temporary test data cleanup was not confirmed'
    report = {'scope': 'real API smoke test', 'base_url': args.base_url,
              'passed': error_text is None, 'elapsed_seconds': round(time.monotonic() - started, 3),
              'checks': client.results, 'error': error_text, 'cleanup_confirmed': not cleanup_failed}
    if args.report:
        from pathlib import Path
        path = Path(args.report)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    if error_text:
        print(f'FAILED: {error_text}', file=sys.stderr)
        return 1
    print(f'PASSED: {len(client.results)} real API checks; no duplicate counts; temporary data removed.')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
