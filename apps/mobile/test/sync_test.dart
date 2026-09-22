import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo_app/core/storage/database.dart';
import 'package:kodo_app/core/storage/identity.dart';
import 'package:kodo_app/core/storage/models.dart';
import 'package:kodo_app/core/storage/repository.dart';
import 'package:kodo_app/core/sync/worker.dart';

class MemorySecrets implements SecretStore {
  final values = <String, String>{};
  bool failRead = false;
  String? failWrite;
  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('secure unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (key == failWrite) throw StateError('secure write failed');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

class FakeApi implements MirrorApi {
  final sent = <Json>[];
  int active = 0, maxActive = 0, registrations = 0, deletes = 0;
  int status = 200;
  Duration? retryAfter;
  bool loseResponse = false, deleteOffline = false;
  Completer<void>? gate;
  @override
  Future<ApiResponse> register(Identity i) async {
    registrations++;
    return ApiResponse(201, {'installation_id': i.id, 'status': 'created'});
  }

  @override
  Future<ApiResponse> send(Identity i, String body) async {
    active++;
    if (active > maxActive) maxActive = active;
    try {
      await gate?.future;
      final op = jsonDecode(body) as Json;
      sent.add(op);
      if (loseResponse) throw TimeoutException('lost');
      return ApiResponse(
        status,
        status == 200
            ? {
                'op_id': op['op_id'],
                'seq': op['seq'],
                'status': 'applied',
                'accepted_at_utc_ms': 1,
              }
            : {
                'error': {'code': 'injected_error'},
              },
        retryAfter: retryAfter,
      );
    } finally {
      active--;
    }
  }

  @override
  Future<ApiResponse> delete(Identity i) async {
    deletes++;
    if (deleteOffline) throw TimeoutException('offline');
    return ApiResponse(204, null);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases =
      true; // Tests intentionally use distinct connections/files.
  late KodoDatabase db;
  late KodoRepository r;
  late MemorySecrets store;
  late IdentityManager id;
  late FakeApi api;
  late SyncWorker w;
  setUp(() async {
    db = KodoDatabase(NativeDatabase.memory());
    r = KodoRepository(db);
    store = MemorySecrets();
    id = IdentityManager(r, store);
    await id.open();
    api = FakeApi();
    w = SyncWorker(r, id, api, jitter: () => 0);
    await w.load();
  });
  tearDown(() async {
    w.dispose();
    await db.close();
  });
  Future<String> project() =>
      r.putProject(name: '俯卧撑', unit: '个', icon: 'dumbbell', quick: 10);
  test(
    'S10/S11/S15 consent gates registration, FIFO offline create add void archive',
    () async {
      final p = await project();
      final e = await r.addEntry(p, 10);
      await r.voidEntry(e);
      await r.archive((await r.project(p))!, true);
      await w.wake();
      expect(api.registrations, 0);
      expect(api.sent, isEmpty);
      await w.setEnabled(true);
      expect(api.sent.map((e) => e['kind']), [
        'project.put',
        'entry.add',
        'entry.void',
        'project.put',
      ]);
      expect(api.sent.map((e) => e['seq']), [1, 2, 3, 4]);
      expect(await r.pending(), 0);
      expect(w.status, '云端副本已更新');
      await w.setEnabled(false);
      await r.archive((await r.project(p))!, false);
      await w.wake();
      expect(api.sent.length, 4);
      await w.setEnabled(true);
      expect(api.sent.length, 5);
      expect(api.registrations, 1);
    },
  );
  test('S13 permanent 422 blocks head and never skips seq', () async {
    final p = await project();
    await r.addEntry(p, 10);
    api.status = 422;
    await w.setEnabled(true);
    await w.wake();
    expect(api.sent.length, 1);
    expect(w.blocked, true);
    expect(await r.pending(), 2);
    expect((await r.head())!['seq'], 1);
    expect((await r.project(p))!.total, 10);
  });
  test('S14 merged wakeups keep one sender/in-flight', () async {
    final p = await project();
    for (var i = 0; i < 20; i++) {
      await r.addEntry(p, 10);
    }
    api.gate = Completer();
    final start = w.setEnabled(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final wakes = List.generate(20, (_) => w.wake());
    api.gate!.complete();
    await start;
    await Future.wait(wakes);
    expect(api.maxActive, 1);
    expect(api.sent.length, 21);
    expect(await r.pending(), 0);
  });
  test('S08/S19 timeout retains original op and persistent backoff', () async {
    await project();
    api.loseResponse = true;
    final body = (await r.head())!['body_json'];
    await w.setEnabled(true);
    expect(await r.pending(), 1);
    expect((await r.head())!['body_json'], body);
    expect((await r.head())!['attempts'], 1);
    expect((await r.head())!['next_attempt_at_utc_ms'], isA<int>());
    api.loseResponse = false;
    await w.wake(manual: true);
    expect(api.sent[0], api.sent[1]);
    expect(await r.pending(), 0);
  });
  test('S09 local ACK transaction failure rolls back queue/acked seq', () async {
    await project();
    await db.customStatement(
      "CREATE TRIGGER fail_ack BEFORE DELETE ON outbox BEGIN SELECT RAISE(ABORT,'test'); END;",
    );
    await w.setEnabled(true);
    expect(await r.pending(), 1);
    expect((await r.meta())!['last_acked_seq'], 0);
    await db.customStatement('DROP TRIGGER fail_ack');
    await w.wake(manual: true);
    expect(await r.pending(), 0);
    expect(api.sent[0], api.sent[1]);
  });
  test('ACK wrong id cannot drop queue', () async {
    await project();
    await expectLater(
      r.acknowledge({
        'seq': 1,
        'op_id': 'wrong',
        'status': 'applied',
        'accepted_at_utc_ms': 1,
      }),
      throwsA(isA<DomainError>()),
    );
    expect(await r.pending(), 1);
  });
  test(
    'S17 deletion lost response retains identity; startup retries and clears',
    () async {
      await project();
      await w.setEnabled(true);
      final old = id.identity!.id;
      api.deleteOffline = true;
      final d = DeletionController(w);
      await d.begin();
      expect((await r.meta())!['deletion_pending'], 1);
      expect(store.values['identity'], isNotNull);
      expect(jsonDecode(store.values['deletion']!)['stage'], 'sending');
      await expectLater(project(), throwsA(isA<DomainError>()));
      api.deleteOffline = false;
      await d.recover();
      expect(await r.rows('SELECT * FROM projects'), isEmpty);
      expect(store.values.containsKey('deletion'), false);
      expect(id.identity!.id, isNot(old));
      expect(w.enabled, false);
      d.dispose();
    },
  );
  test(
    'S17 remote_deleted crash marker completes cleanup without new DELETE',
    () async {
      await project();
      await store.write('deletion', jsonEncode({'stage': 'remote_deleted'}));
      final d = DeletionController(w);
      await d.recover();
      expect(await r.rows('SELECT * FROM projects'), isEmpty);
      expect(api.deletes, 0);
      expect(store.values.containsKey('deletion'), false);
      d.dispose();
    },
  );
  test('S17 security-store failure preserves all data before delete', () async {
    await project();
    await w.setEnabled(true);
    store.failWrite = 'deletion';
    final d = DeletionController(w);
    await d.begin();
    expect(api.deletes, 0);
    expect(await r.rows('SELECT * FROM projects'), hasLength(1));
    expect(store.values['identity'], isNotNull);
    store.failWrite = null;
    await d.resume();
    expect(await r.rows('SELECT * FROM projects'), isEmpty);
    d.dispose();
  });
  test(
    'S22 missing/mismatched secret never silently creates or uploads identity',
    () async {
      await project();
      store.values.remove('identity');
      await id.open();
      expect(id.identity, isNull);
      expect(await r.rows('SELECT * FROM projects'), hasLength(1));
      await expectLater(w.setEnabled(true), throwsA(isA<DomainError>()));
      expect(api.registrations, 0);
      store.values['identity'] = jsonEncode(Identity.generate().toJson());
      await id.open();
      expect(id.identity, isNull);
      expect(id.orphaned, true);
      expect(await r.pending(), 1);
    },
  );
  test('S22 leftover keychain with absent database is cleanup-only', () async {
    final old = store.values['identity'];
    await r.clearLocal();
    await id.open();
    expect(id.orphaned, true);
    expect(id.identity, isNull);
    expect(store.values['identity'], old);
    expect(
      (await r.meta())!['installation_id'],
      isNot(Identity.decode(old!).id),
    );
    await expectLater(w.setEnabled(true), throwsA(isA<DomainError>()));
  });
  test(
    'security storage unavailable still permits purely local writes',
    () async {
      await r.clearLocal();
      store.failRead = true;
      await id.open();
      await project();
      expect(await r.pending(), 1);
      expect(id.identity, isNull);
      expect(api.registrations, 0);
    },
  );
  test('S16 delete waits for in-flight operation then revokes', () async {
    await project();
    api.gate = Completer();
    final sync = w.setEnabled(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final d = DeletionController(w);
    final deleting = d.begin();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(api.deletes, 0);
    api.gate!.complete();
    await sync;
    await deleting;
    expect(api.deletes, 1);
    expect(await r.pending(), 0);
    d.dispose();
  });
  test('file queue recovers after process-equivalent reopen', () async {
    final dir = await Directory.systemTemp.createTemp('kodo-sync-');
    final file = File('${dir.path}/db.sqlite');
    var disk = KodoDatabase.file(file);
    var repo = KodoRepository(disk);
    final secrets = MemorySecrets();
    var ident = IdentityManager(repo, secrets);
    await ident.open();
    await repo.putProject(name: '俯卧撑', unit: '个', icon: 'check', quick: 10);
    final body = (await repo.head())!['body_json'];
    await disk.close();
    disk = KodoDatabase.file(file);
    repo = KodoRepository(disk);
    ident = IdentityManager(repo, secrets);
    await ident.open();
    final worker = SyncWorker(repo, ident, api);
    await worker.load();
    await worker.setEnabled(true);
    expect(jsonEncode(api.sent.single), body);
    expect(await repo.pending(), 0);
    worker.dispose();
    await disk.close();
    await dir.delete(recursive: true);
  });
  test('S19 Retry-After and foreground/consent pause preserve queue', () async {
    await project();
    api.status = 429;
    api.retryAfter = const Duration(seconds: 120);
    final before = r.clock.now().millisecondsSinceEpoch;
    await w.setEnabled(true);
    final h = (await r.head())!;
    expect(
      h['next_attempt_at_utc_ms'] as int,
      greaterThanOrEqualTo(before + 120000),
    );
    expect(w.blocked, false);
    w.setForeground(false);
    await w.wake(manual: true);
    expect(api.sent.length, 1);
    await w.setEnabled(false);
    expect(await r.pending(), 1);
  });
  for (final status in [401, 410, 409, 422]) {
    test(
      'permanent $status remains blocked after file reopen until explicit retry',
      () async {
        final dir = await Directory.systemTemp.createTemp('kodo-block-');
        final file = File('${dir.path}/db.sqlite');
        var disk = KodoDatabase.file(file);
        final clock = FixedClock(DateTime.utc(2026, 9, 21));
        var repo = KodoRepository(disk, clock: clock);
        final secrets = MemorySecrets();
        var identity = IdentityManager(repo, secrets);
        await identity.open();
        await repo.putProject(name: '保持队首', unit: '次', icon: 'check', quick: 1);
        final original = (await repo.head())!['body_json'];
        final transport = FakeApi()..status = status;
        var worker = SyncWorker(repo, identity, transport);
        await worker.load();
        await worker.setEnabled(true);
        expect(worker.blocked, true);
        expect(transport.sent.length, 1);
        worker.dispose();
        await disk.close();
        clock.value = clock.value.add(const Duration(days: 1));
        disk = KodoDatabase.file(file);
        repo = KodoRepository(disk, clock: clock);
        identity = IdentityManager(repo, secrets);
        await identity.open();
        worker = SyncWorker(repo, identity, transport);
        await worker.load();
        expect(worker.blocked, true);
        expect(worker.status, '同步需要处理');
        await worker.wake();
        expect(transport.registrations, 1);
        expect(transport.sent.length, 1);
        expect((await repo.head())!['body_json'], original);
        transport.status = 200;
        await worker.wake(manual: true);
        expect(await repo.pending(), 0);
        expect((await repo.meta())!['last_sync_error_status'], isNull);
        worker.dispose();
        await disk.close();
        await dir.delete(recursive: true);
      },
    );
  }
}
