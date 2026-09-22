import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
part 'database.g.dart';

@DriftDatabase(include: {'schema.drift'})
class KodoDatabase extends _$KodoDatabase {
  KodoDatabase(super.e);
  factory KodoDatabase.file(File file) =>
      KodoDatabase(NativeDatabase.createInBackground(file, setup: _setup));
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement(
          'ALTER TABLE app_meta ADD COLUMN last_sync_error_status INTEGER',
        );
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys=ON');
      await customStatement('PRAGMA busy_timeout=5000');
      await customStatement('PRAGMA synchronous=FULL');
    },
  );
}

void _setup(dynamic db) {
  db.execute('PRAGMA journal_mode=WAL');
  db.execute('PRAGMA synchronous=FULL');
  db.execute('PRAGMA foreign_keys=ON');
  db.execute('PRAGMA busy_timeout=5000');
}
