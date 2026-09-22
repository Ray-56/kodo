import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'database.dart';
import 'models.dart';

class KodoRepository {
  KodoRepository(this.db, {Clock? clock, String Function()? newId})
    : clock = clock ?? SystemClock(),
      newId = newId ?? const Uuid().v4;
  final KodoDatabase db;
  final Clock clock;
  final String Function() newId;
  Future<void> Function()?
  beforeEnqueue; // Failure injection at the transaction boundary.
  void Function()? onCommit;
  String get today =>
      capturedDate(clock.now().millisecondsSinceEpoch, clock.offsetMinutes());
  Future<List<Json>> rows(String sql, [List<Object> args = const []]) async =>
      (await db
              .customSelect(
                sql,
                variables: args.map((a) => Variable(a)).toList(),
              )
              .get())
          .map((r) => r.data)
          .toList();
  Future<void> initialize(String installationId) async {
    await db.customStatement(
      'INSERT OR IGNORE INTO app_meta(id,installation_id) VALUES(1,?)',
      [installationId],
    );
  }

  Future<Json?> meta() async {
    final result = await rows('SELECT * FROM app_meta WHERE id=1');
    return result.isEmpty ? null : result.single;
  }

  Future<void> setMeta(String field, Object value) async {
    if (!{
      'sync_enabled',
      'registration_attempted',
      'deletion_pending',
    }.contains(field)) {
      throw ArgumentError(field);
    }
    await db.customUpdate(
      'UPDATE app_meta SET $field=? WHERE id=1',
      variables: [Variable(value)],
      updates: {db.appMeta},
    );
  }

  Future<void> _writable() async {
    if ((await meta())?['deletion_pending'] != 0) {
      throw const DomainError('删除正在进行，暂时不能记录');
    }
  }

  Future<void> _enqueue(String kind, String id, Json payload) async {
    await beforeEnqueue?.call();
    final m = (await meta())!;
    final seq = (m['last_enqueued_seq'] as int) + 1;
    if (seq > 9007199254740991) throw const DomainError('操作序号已达上限');
    final op = newId();
    final body = jsonEncode({
      'op_id': op,
      'seq': seq,
      'kind': kind,
      'entity_id': id,
      'payload': payload,
    });
    await db.customStatement(
      'INSERT INTO outbox(seq,op_id,body_json) VALUES(?,?,?)',
      [seq, op, body],
    );
    await db.customStatement(
      'UPDATE app_meta SET last_enqueued_seq=? WHERE id=1',
      [seq],
    );
  }

  Future<T> _write<T>(Future<T> Function() action) async {
    final result = await db.transaction(() async {
      await _writable();
      return action();
    });
    db.notifyUpdates({
      TableUpdate.onTable(db.projects),
      TableUpdate.onTable(db.entries),
      TableUpdate.onTable(db.outbox),
      TableUpdate.onTable(db.appMeta),
    });
    onCommit?.call();
    return result;
  }

  Future<String> putProject({
    String? id,
    required String name,
    required String unit,
    required String icon,
    required int quick,
    bool archived = false,
  }) => _write(() async {
    name = validText(name, 40, '名称');
    unit = validText(unit, 8, '单位');
    validAmount(quick, 9999);
    if (!icons.contains(icon)) throw const DomainError('请选择有效图标');
    final time = clock.now().millisecondsSinceEpoch;
    validTime(time);
    final old = id == null ? null : await project(id);
    if (id != null && old == null) throw const DomainError('项目不存在');
    if (old == null && archived) throw const DomainError('新项目不能归档');
    if (old != null && old.unit != unit && old.unitLocked) {
      throw const DomainError('已有记录，单位不可更改；请新建项目');
    }
    final projectId = id ?? newId();
    final created = old?.data['created_at_utc_ms'] ?? time;
    await db.customStatement(
      '''INSERT INTO projects(id,name,unit,icon_key,quick_amount,archived,created_at_utc_ms,updated_at_utc_ms)
      VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,unit=excluded.unit,
      icon_key=excluded.icon_key,quick_amount=excluded.quick_amount,archived=excluded.archived,updated_at_utc_ms=excluded.updated_at_utc_ms''',
      [projectId, name, unit, icon, quick, archived ? 1 : 0, created, time],
    );
    await _enqueue('project.put', projectId, {
      'name': name,
      'unit': unit,
      'icon_key': icon,
      'quick_amount': quick,
      'archived': archived,
      'created_at_utc_ms': created,
      'updated_at_utc_ms': time,
    });
    return projectId;
  });
  Future<void> archive(ProjectView p, bool value) async => putProject(
    id: p.id,
    name: p.name,
    unit: p.unit,
    icon: p.icon,
    quick: p.quick,
    archived: value,
  );
  Future<String> addEntry(String projectId, Object amount) => _write(() async {
    final value = validAmount(amount);
    final p = await project(projectId);
    if (p == null || p.archived) throw const DomainError('归档项目不能记录；请先恢复项目');
    final timestamp = clock.now().millisecondsSinceEpoch;
    validTime(timestamp);
    final offset = clock.offsetMinutes();
    if (offset < -840 || offset > 840) throw const DomainError('无效时区');
    final date = capturedDate(timestamp, offset);
    final id = newId();
    await db.customStatement(
      'INSERT INTO entries(id,project_id,amount,occurred_at_utc_ms,utc_offset_minutes,local_date) VALUES(?,?,?,?,?,?)',
      [id, projectId, value, timestamp, offset, date],
    );
    await _enqueue('entry.add', id, {
      'project_id': projectId,
      'amount': value,
      'occurred_at_utc_ms': timestamp,
      'utc_offset_minutes': offset,
      'local_date': date,
    });
    return id;
  });
  Future<void> voidEntry(String id) => _write(() async {
    final entry = await rows('SELECT * FROM entries WHERE id=?', [id]);
    if (entry.isEmpty) throw const DomainError('记录不存在');
    if (entry.single['voided_at_utc_ms'] != null) return;
    final time = clock.now().millisecondsSinceEpoch;
    validTime(time);
    await db.customStatement(
      'UPDATE entries SET voided_at_utc_ms=? WHERE id=?',
      [time, id],
    );
    await _enqueue('entry.void', id, {'voided_at_utc_ms': time});
  });
  String get _projectsSql =>
      '''SELECT p.*,COALESCE(SUM(CASE WHEN e.voided_at_utc_ms IS NULL THEN e.amount ELSE 0 END),0) AS total,
    COALESCE(SUM(CASE WHEN e.voided_at_utc_ms IS NULL AND e.local_date=? THEN e.amount ELSE 0 END),0) AS today,
    COUNT(e.id) AS history_count FROM projects p LEFT JOIN entries e ON p.id=e.project_id''';
  Stream<List<ProjectView>> watchProjects({bool? archived}) => db
      .customSelect(
        '$_projectsSql ${archived == null ? "" : "WHERE p.archived=?"} GROUP BY p.id ORDER BY p.created_at_utc_ms DESC,p.id DESC',
        variables: [
          Variable(today),
          if (archived != null) Variable(archived ? 1 : 0),
        ],
        readsFrom: {db.projects, db.entries},
      )
      .watch()
      .map((r) => r.map((r) => ProjectView(r.data)).toList());
  Future<ProjectView?> project(String id) async {
    final result = await rows('$_projectsSql WHERE p.id=? GROUP BY p.id', [
      today,
      id,
    ]);
    return result.isEmpty ? null : ProjectView(result.single);
  }

  Future<List<Json>> history(String id, {int limit = 50, Json? after}) => rows(
    '''SELECT * FROM entries WHERE project_id=? AND voided_at_utc_ms IS NULL
    ${after == null ? '' : 'AND (occurred_at_utc_ms < ? OR (occurred_at_utc_ms = ? AND id < ?))'}
    ORDER BY occurred_at_utc_ms DESC,id DESC LIMIT ?''',
    [
      id,
      if (after != null) ...[
        after['occurred_at_utc_ms'] as int,
        after['occurred_at_utc_ms'] as int,
        after['id'] as String,
      ],
      limit,
    ],
  );
  Future<StatsData> stats(int days, {String? projectId}) async {
    if (days != 7 && days != 30) throw ArgumentError('days');
    // UTC calendar arithmetic avoids DST's 23/25-hour days.
    final day = DateTime.parse('${today}T00:00:00Z');
    final dates = List.generate(
      days,
      (i) => dateKey(day.subtract(Duration(days: days - 1 - i))),
    );
    final data = await rows(
      '''SELECT local_date,COUNT(*) AS events,SUM(amount) AS amount FROM entries
      WHERE voided_at_utc_ms IS NULL AND local_date BETWEEN ? AND ? ${projectId == null ? '' : 'AND project_id=?'} GROUP BY local_date''',
      [dates.first, dates.last, ?projectId],
    );
    final count = await rows(
      '''SELECT COUNT(DISTINCT project_id) AS n FROM entries WHERE voided_at_utc_ms IS NULL
      AND local_date BETWEEN ? AND ? ${projectId == null ? '' : 'AND project_id=?'}''',
      [dates.first, dates.last, ?projectId],
    );
    final byDate = {for (final r in data) r['local_date']: r};
    return StatsData(
      dates,
      dates
          .map(
            (d) =>
                (byDate[d]?[projectId == null ? 'events' : 'amount'] as int?) ??
                0,
          )
          .toList(),
      data.fold(0, (n, r) => n + (r['events'] as int)),
      count.single['n'] as int,
      data.length,
    );
  }

  Future<Json> export() => db.transaction(
    () async => {
      'schema_version': 1,
      'exported_at_utc_ms': clock.now().millisecondsSinceEpoch,
      'source': 'local',
      'projects': (await rows(
        'SELECT * FROM projects ORDER BY id',
      )).map((r) => ProjectView(r).toJson()).toList(),
      'entries': await rows('SELECT * FROM entries ORDER BY id'),
    },
  );
  Future<Json?> head() async {
    final r = await rows('SELECT * FROM outbox ORDER BY seq LIMIT 1');
    return r.isEmpty ? null : r.single;
  }

  Future<int> pending() async =>
      (await rows('SELECT COUNT(*) AS n FROM outbox')).single['n'] as int;
  Future<void> acknowledge(Json ack) => db.transaction(() async {
    final h = await head();
    final m = (await meta())!;
    if (ack['seq'] is! int ||
        ack.length != 4 ||
        h == null ||
        ack['op_id'] != h['op_id'] ||
        ack['seq'] != h['seq'] ||
        h['seq'] != (m['last_acked_seq'] as int) + 1 ||
        !['applied', 'duplicate'].contains(ack['status']) ||
        ack['accepted_at_utc_ms'] is! int) {
      throw const DomainError('同步回执不匹配');
    }
    validTime(ack['accepted_at_utc_ms'] as int);
    await db.customStatement('DELETE FROM outbox WHERE seq=? AND op_id=?', [
      h['seq'],
      h['op_id'],
    ]);
    await db.customStatement(
      'UPDATE app_meta SET last_acked_seq=?,last_sync_error_status=NULL WHERE id=1',
      [h['seq']],
    );
  });
  Future<void> clearLocal() async {
    await db.transaction(() async {
      for (final table in ['outbox', 'entries', 'projects', 'app_meta']) {
        await db.customStatement('DELETE FROM $table');
      }
    });
    db.notifyUpdates({
      TableUpdate.onTable(db.projects),
      TableUpdate.onTable(db.entries),
      TableUpdate.onTable(db.appMeta),
    });
  }

  void refreshDate() => db.notifyUpdates({TableUpdate.onTable(db.entries)});
}
