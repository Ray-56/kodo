#!/usr/bin/env python3
"""Validate handoff files, sample schemas, SQLite invariants and fixture arithmetic.

This does NOT compile Flutter/Rust or certify the not-yet-implemented service.
Run: python3 -m pip install -r scripts/requirements-validation.txt
     python3 scripts/validate_handoff.py
"""
from __future__ import annotations
import copy
import datetime as dt
import hashlib
import json
from pathlib import Path
import sqlite3
import sys
import xml.etree.ElementTree as ET

try:
    import jsonschema
except ImportError:
    raise SystemExit('Install scripts/requirements-validation.txt before running this validator.')

ROOT = Path(__file__).resolve().parents[1]
RESULTS: list[str] = []

def load(path: str):
    return json.loads((ROOT / path).read_text(encoding='utf-8'))

def check(name: str, condition: bool):
    if not condition:
        raise AssertionError(name)
    RESULTS.append(name)

def reject(conn: sqlite3.Connection, sql: str, args=()):
    try:
        conn.execute(sql, args)
    except sqlite3.IntegrityError:
        return
    raise AssertionError('Expected SQLite constraint rejection')

def main() -> int:
    api = load('contracts/openapi.json')
    check('OpenAPI version and operation paths', api['openapi'] == '3.1.0' and len(api['paths']) == 6)
    def walk(value):
        if isinstance(value, dict):
            if '$ref' in value:
                pointer = value['$ref']
                if pointer.startswith('#/'):
                    target = api
                    for key in pointer[2:].split('/'):
                        target = target[key.replace('~1', '/').replace('~0', '~')]
            for item in value.values():
                walk(item)
        elif isinstance(value, list):
            for item in value:
                walk(item)
    walk(api)
    RESULTS.append('Every local OpenAPI schema reference resolves')
    operation_schema = load('contracts/operation.schema.json')
    export_schema = load('contracts/local_export.schema.json')
    for schema in (operation_schema, export_schema):
        jsonschema.Draft202012Validator.check_schema(schema)
    fixture = load('examples/demo_export.json')
    expected = load('examples/demo_expected.json')
    jsonschema.validate(fixture, export_schema, format_checker=jsonschema.FormatChecker())
    sequence = load('examples/operations_sequence.json')
    for op in sequence['operations']:
        jsonschema.validate(op, operation_schema, format_checker=jsonschema.FormatChecker())
    RESULTS.append('All operation and export fixtures conform to JSON Schema')
    validator = jsonschema.Draft202012Validator(operation_schema)
    for invalid_amount in (0, -1, 1.5, 1000000, '10', True):
        op = copy.deepcopy(sequence['operations'][1])
        op['payload']['amount'] = invalid_amount
        check(f'Schema rejects invalid amount {invalid_amount!r}', not validator.is_valid(op))
    bad = copy.deepcopy(sequence['operations'][1])
    bad['installation_id'] = 'not-permitted'
    check('Unknown envelope fields rejected', not validator.is_valid(bad))
    for entry in fixture['entries']:
        computed = dt.datetime.fromtimestamp((entry['occurred_at_utc_ms'] + entry['utc_offset_minutes'] * 60000) / 1000,
                                            dt.timezone.utc).date().isoformat()
        check('Timestamp/date consistency: ' + entry['id'][-4:], computed == entry['local_date'])
    conn = sqlite3.connect(':memory:')
    conn.executescript((ROOT / 'contracts/local_schema.sql').read_text())
    for p in fixture['projects']:
        conn.execute('INSERT INTO projects VALUES (?,?,?,?,?,?,?,?)', tuple(p[k] for k in
                    ('id','name','unit','icon_key','quick_amount','archived','created_at_utc_ms','updated_at_utc_ms')))
    for e in fixture['entries']:
        conn.execute('INSERT INTO entries VALUES (?,?,?,?,?,?,?)', tuple(e[k] for k in
                    ('id','project_id','amount','occurred_at_utc_ms','utc_offset_minutes','local_date','voided_at_utc_ms')))
    for project_id, total in expected['project_totals'].items():
        result = conn.execute('SELECT COALESCE(SUM(amount),0) FROM entries WHERE project_id=? AND voided_at_utc_ms IS NULL', (project_id,)).fetchone()[0]
        check('Per-project total: ' + project_id[-4:], result == total)
    for project_id, total in expected['project_today_totals'].items():
        result = conn.execute('SELECT COALESCE(SUM(amount),0) FROM entries WHERE project_id=? AND local_date=? AND voided_at_utc_ms IS NULL', (project_id,expected['today'])).fetchone()[0]
        check('Per-project today: ' + project_id[-4:], result == total)
    rows = dict(conn.execute('SELECT local_date,COUNT(*) FROM entries WHERE voided_at_utc_ms IS NULL GROUP BY local_date'))
    check('Today counts logging events, not amounts', rows[expected['today']] == expected['today_entry_count'])
    check('Seven calendar dates zero-filled', [rows.get(d,0) for d in expected['last_7_dates']] == expected['last_7_entry_counts'])
    check('Seven-day overall event count', sum(rows.get(d,0) for d in expected['last_7_dates']) == expected['last_7_total_entry_count'])
    check('Export contains tombstone for undo history', any(e['voided_at_utc_ms'] is not None for e in fixture['entries']))
    # Local transaction proof: an exception after both local writes rolls both back, including sequence.
    conn.execute("INSERT INTO app_meta(id,installation_id) VALUES(1,'local-test')")
    conn.commit()
    try:
        with conn:
            conn.execute('UPDATE app_meta SET last_enqueued_seq=1 WHERE id=1')
            conn.execute('INSERT INTO entries VALUES(?,?,?,?,?,?,?)',
                         ('rollback-sentinel', fixture['projects'][0]['id'], 1, 0, 0, '1970-01-01', None))
            conn.execute("INSERT INTO outbox(seq,op_id,body_json) VALUES(1,'o','{}')")
            raise RuntimeError('fault injection')
    except RuntimeError:
        pass
    check('Local transaction rollback leaves no sequence hole', conn.execute('SELECT last_enqueued_seq FROM app_meta').fetchone()[0] == 0)
    check('Local transaction rollback leaves no new Entry', conn.execute("SELECT COUNT(*) FROM entries WHERE id='rollback-sentinel'").fetchone()[0] == 0)
    check('Local transaction rollback leaves no outbox', conn.execute('SELECT COUNT(*) FROM outbox').fetchone()[0] == 0)
    # Server schema defense-in-depth checks. This is not an Axum/SQLx integration test.
    server = sqlite3.connect(':memory:')
    server.executescript((ROOT / 'contracts/server_schema.sql').read_text())
    for ident in ('a','b'):
        server.execute('INSERT INTO installations(id,secret_hash,created_at_utc_ms) VALUES(?,?,0)',(ident,hashlib.sha256(ident.encode()).digest()))
    def insert_project(ident, pid):
        server.execute('INSERT INTO projects VALUES(?,?,?,?,?,?,?,?,?)',(ident,pid,'俯卧撑','个','dumbbell',10,0,0,0))
    insert_project('a','p')
    server.execute('INSERT INTO entries VALUES(?,?,?,?,?,?,?,?)',('a','e','p',20,0,0,'1970-01-01',None))
    reject(server,'INSERT INTO entries VALUES(?,?,?,?,?,?,?,?)',('b','e','p',10,0,0,'1970-01-01',None))
    RESULTS.append('Composite foreign key prevents cross-installation project reference')
    reject(server,'UPDATE projects SET unit=? WHERE installation_id=? AND id=?',('次','a','p'))
    RESULTS.append('Unit cannot change after first entry')
    reject(server,"UPDATE entries SET amount=30 WHERE installation_id='a' AND id='e'")
    RESULTS.append('Entry amount is immutable')
    server.execute("UPDATE entries SET voided_at_utc_ms=1 WHERE installation_id='a' AND id='e'")
    reject(server,"UPDATE entries SET voided_at_utc_ms=NULL WHERE installation_id='a' AND id='e'")
    RESULTS.append('Void cannot be silently reversed')
    reject(server,'UPDATE projects SET unit=? WHERE installation_id=? AND id=?',('次','a','p'))
    RESULTS.append('Unit stays locked when every entry has been voided')
    insert_project('b','p')
    check('Same project ID may exist in separate namespaces',server.execute("SELECT COUNT(*) FROM projects WHERE id='p'").fetchone()[0] == 2)
    h=hashlib.sha256(b'payload').digest()
    server.execute('INSERT INTO operation_receipts VALUES(?,?,?,?,?)',('a',1,'op',h,0))
    reject(server,'INSERT INTO operation_receipts VALUES(?,?,?,?,?)',('a',1,'new-op',h,0))
    reject(server,'INSERT INTO operation_receipts VALUES(?,?,?,?,?)',('a',2,'op',h,0))
    RESULTS.append('Server receipt enforces uniqueness of both seq and op_id')
    for amount in (0,-1,1.5,1000000):
        reject(server,'INSERT INTO entries VALUES(?,?,?,?,?,?,?,?)',('a','bad'+str(amount),'p',amount,0,0,'1970-01-01',None))
    RESULTS.append('SQL rejects invalid amount boundaries and fractional value')
    # Resource checks.
    svg_files=list((ROOT/'design/assets').rglob('*.svg'))
    for path in svg_files:
        element=ET.parse(path).getroot()
        check('SVG parse: '+path.name,element.tag.endswith('svg'))
        text=path.read_text()
        check('Self-contained SVG: '+path.name,'<script' not in text and '<image' not in text and '@font-face' not in text)
    check('22 independent UI icons',len(list((ROOT/'design/assets/icons').glob('*.svg')))==22)
    # Generated dependencies are not redistributed source assets.
    generated = {'.git', '.venv', 'build', 'target', '.dart_tool', '.gradle', 'Pods', '.symlinks', 'ephemeral'}
    source_fonts = [p for p in ROOT.rglob('*')
                    if p.suffix.lower() in ('.ttf', '.otf', '.ttc', '.woff', '.woff2')
                    and not generated.intersection(p.relative_to(ROOT).parts)]
    check('No font files redistributed', not source_fonts)
    check('All checked foreground/background pairs pass 4.5:1',all(x['ratio']>=4.5 for x in load('design/contrast_checks.json')))
    # Lexical Python compile: not network or Flutter/Rust execution.
    compile((ROOT/'scripts/smoke_api.py').read_text(), 'smoke_api.py', 'exec')
    RESULTS.append('Real-API smoke script parses as Python')
    manifest_path=ROOT/'design/asset_manifest.json'
    if manifest_path.exists():
        for item in load('design/asset_manifest.json')['files']:
            path=ROOT/item['path']
            check('Asset hash: '+path.name,hashlib.sha256(path.read_bytes()).hexdigest()==item['sha256'])
    report={'scope':'handoff files and SQLite/fixture validation only','passed':True,'checks':RESULTS,
            'not_run':['Flutter/Dart compilation','Rust compilation','Real API smoke','iOS/Android simulator tests','Physical device tests']}
    (ROOT/'qa/validation_results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'PASS: {len(RESULTS)} handoff checks. No Flutter/Rust runtime claim.')
    return 0

if __name__=='__main__':
    try:
        raise SystemExit(main())
    except (AssertionError,jsonschema.ValidationError,jsonschema.SchemaError,sqlite3.Error,KeyError,ValueError) as error:
        print('VALIDATION FAILED: '+str(error),file=sys.stderr)
        raise SystemExit(1)
