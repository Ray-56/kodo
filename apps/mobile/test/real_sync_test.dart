import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo_app/core/storage/database.dart';
import 'package:kodo_app/core/storage/identity.dart';
import 'package:kodo_app/core/storage/repository.dart';
import 'package:kodo_app/core/sync/worker.dart';
import 'sync_test.dart' show MemorySecrets;

class LossyApi implements MirrorApi {
  LossyApi(this.inner);
  final MirrorApi inner;
  bool dropOperation = false, dropRegistration = false, dropDeletion = false;
  @override
  Future<ApiResponse> register(Identity i) async {
    final r = await inner.register(i);
    if (dropRegistration) {
      dropRegistration = false;
      throw TimeoutException('registration response lost');
    }
    return r;
  }

  @override
  Future<ApiResponse> send(Identity i, String body) async {
    final r = await inner.send(i, body);
    if (dropOperation) {
      dropOperation = false;
      throw TimeoutException('operation response lost after server commit');
    }
    return r;
  }

  @override
  Future<ApiResponse> delete(Identity i) async {
    final r = await inner.delete(i);
    if (dropDeletion) {
      dropDeletion = false;
      throw TimeoutException('DELETE response lost');
    }
    return r;
  }
}

void main() {
  final url = Platform.environment['KODO_TEST_API_URL'];
  test(
    'M4 real Rust: offline 10+12−12+20, lost responses, reopen, mirror 30, archive, export, deletion restart',
    () async {
      final dir = await Directory.systemTemp.createTemp('kodo-real-');
      final file = File('${dir.path}/db.sqlite');
      var db = KodoDatabase.file(file);
      var repo = KodoRepository(db);
      final store = MemorySecrets();
      var identity = IdentityManager(repo, store);
      await identity.open();
      final transport = LossyApi(HttpMirrorApi(url!));
      var worker = SyncWorker(repo, identity, transport, jitter: () => 0);
      await worker.load();
      final p = await repo.putProject(
        name: '俯卧撑',
        unit: '个',
        icon: 'dumbbell',
        quick: 10,
      );
      await repo.addEntry(p, 10);
      final e = await repo.addEntry(p, 12);
      await repo.voidEntry(e);
      await repo.addEntry(p, 20);
      expect((await repo.project(p))!.total, 30);
      expect(await repo.pending(), 5);
      transport.dropRegistration = true;
      await worker.setEnabled(true);
      expect(await repo.pending(), 5);
      transport.dropOperation = true;
      await worker.wake(manual: true);
      expect(await repo.pending(), 5);
      worker.dispose();
      await db.close();
      db = KodoDatabase.file(file);
      repo = KodoRepository(db);
      identity = IdentityManager(repo, store);
      await identity.open();
      worker = SyncWorker(repo, identity, transport, jitter: () => 0);
      await worker.load();
      expect((await repo.project(p))!.total, 30);
      await worker.wake(manual: true);
      expect(await repo.pending(), 0);
      final dio = Dio();
      Future<Map<String, dynamic>> snapshot() async =>
          Map<String, dynamic>.from(
            (await dio.get<Object?>(
                  '$url/v1/snapshot',
                  options: Options(
                    headers: {
                      'Authorization': 'Bearer ${identity.identity!.bearer}',
                    },
                  ),
                )).data
                as Map,
          );
      var snap = await snapshot();
      expect(snap['last_seq'], 5);
      expect(
        (snap['entries'] as List)
            .where((e) => e['voided_at_utc_ms'] == null)
            .fold<int>(0, (n, e) => n + (e['amount'] as int)),
        30,
      );
      // Server commits, then local ACK transaction fails. Restart must retry the exact body.
      await repo.archive((await repo.project(p))!, true);
      await db.customStatement(
        "CREATE TRIGGER fail_ack BEFORE DELETE ON outbox BEGIN SELECT RAISE(ABORT,'crash_before_ack'); END;",
      );
      await worker.wake(manual: true);
      expect(await repo.pending(), 1);
      await db.customStatement('DROP TRIGGER fail_ack');
      worker.dispose();
      await db.close();
      db = KodoDatabase.file(file);
      repo = KodoRepository(db);
      identity = IdentityManager(repo, store);
      await identity.open();
      worker = SyncWorker(repo, identity, transport, jitter: () => 0);
      await worker.load();
      await worker.wake(manual: true);
      expect(await repo.pending(), 0);
      await repo.archive((await repo.project(p))!, false);
      await worker.wake();
      snap = await snapshot();
      expect(snap['last_seq'], 7);
      expect(snap['projects'][0]['archived'], false);
      final exported = await repo.export();
      expect((exported['entries'] as List).length, 3);
      transport.dropDeletion = true;
      var deletion = DeletionController(worker);
      await deletion.begin();
      expect(store.values['identity'], isNotNull);
      expect(store.values['deletion'], isNotNull);
      deletion.dispose();
      worker.dispose();
      await db.close();
      db = KodoDatabase.file(file);
      repo = KodoRepository(db);
      identity = IdentityManager(repo, store);
      await identity.open();
      worker = SyncWorker(repo, identity, transport);
      await worker.load();
      deletion = DeletionController(worker);
      await deletion.recover();
      expect(await repo.rows('SELECT * FROM projects'), isEmpty);
      expect(await repo.pending(), 0);
      expect(store.values['deletion'], isNull);
      deletion.dispose();
      worker.dispose();
      await db.close();
      await dir.delete(recursive: true);
    },
    skip: url == null
        ? 'Set KODO_TEST_API_URL to a running Rust service'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
