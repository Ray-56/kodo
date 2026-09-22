import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:kodo_app/core/storage/database.dart';
import 'package:kodo_app/core/storage/repository.dart';

void main() {
  test(
    'v1 file upgrades to v2 without changing entries, identity, seq or immutable outbox',
    () async {
      final dir = await Directory.systemTemp.createTemp('kodo-migration-');
      final file = File('${dir.path}/db.sqlite');
      final old = sqlite.sqlite3.open(file.path);
      old.execute(
        await File('test/fixtures/local_schema_v1.sql').readAsString(),
      );
      old.execute('PRAGMA user_version=1');
      old.execute(
        "INSERT INTO app_meta(id,installation_id,last_enqueued_seq,sync_enabled) VALUES(1,'existing-installation',2,1)",
      );
      old.execute(
        "INSERT INTO projects VALUES('project','阅读','页','book',10,0,1,1)",
      );
      old.execute(
        "INSERT INTO entries VALUES('entry','project',10,1,480,'1970-01-01',NULL)",
      );
      for (var seq = 1; seq <= 2; seq++) {
        old.execute('INSERT INTO outbox(seq,op_id,body_json) VALUES(?,?,?)', [
          seq,
          'op-$seq',
          '{"immutable":"original $seq"}',
        ]);
      }
      old.close();
      final db = KodoDatabase.file(file);
      final repo = KodoRepository(db);
      final meta = (await repo.meta())!;
      expect(meta['installation_id'], 'existing-installation');
      expect(meta['last_enqueued_seq'], 2);
      expect(meta['last_acked_seq'], 0);
      expect(meta['sync_enabled'], 1);
      expect(meta.containsKey('last_sync_error_status'), true);
      expect(meta['last_sync_error_status'], isNull);
      expect(
        (await repo.rows('PRAGMA user_version')).single['user_version'],
        2,
      );
      expect((await repo.project('project'))!.total, 10);
      expect(
        (await repo.rows(
          'SELECT body_json FROM outbox ORDER BY seq',
        )).map((r) => r['body_json']),
        ['{"immutable":"original 1"}', '{"immutable":"original 2"}'],
      );
      await db.close();
      await dir.delete(recursive: true);
    },
  );
}
