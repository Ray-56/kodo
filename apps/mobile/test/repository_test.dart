import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo_app/core/storage/database.dart';
import 'package:kodo_app/core/storage/models.dart';
import 'package:kodo_app/core/storage/repository.dart';

void main() {
  late KodoDatabase db;
  late KodoRepository r;
  late FixedClock clock;
  setUp(() async {
    db = KodoDatabase(NativeDatabase.memory());
    clock = FixedClock(DateTime.parse('2026-09-11T10:00:00Z'));
    r = KodoRepository(db, clock: clock);
    await r.initialize('00000000-0000-4000-8000-000000009999');
  });
  tearDown(() async => db.close());
  Future<String> project({String unit = '个'}) =>
      r.putProject(name: '俯卧撑', unit: unit, icon: 'dumbbell', quick: 10);
  test(
    'P01/P02 first launch empty; create, commit and reopen file retains 10',
    () async {
      expect(await r.rows('SELECT * FROM projects'), isEmpty);
      final dir = await Directory.systemTemp.createTemp('kodo-test-');
      final f = File('${dir.path}/test.sqlite');
      var disk = KodoDatabase.file(f);
      var repo = KodoRepository(disk, clock: clock);
      await repo.initialize('disk-id');
      final p = await repo.putProject(
        name: '俯卧撑',
        unit: '个',
        icon: 'dumbbell',
        quick: 10,
      );
      await repo.addEntry(p, 10);
      await disk.close();
      disk = KodoDatabase.file(f);
      repo = KodoRepository(disk, clock: clock);
      expect((await repo.project(p))!.today, 10);
      expect(await repo.pending(), 2);
      expect((await repo.meta())!['last_enqueued_seq'], 2);
      await disk.close();
      await dir.delete(recursive: true);
    },
  );
  test('P03/P04 text Unicode scalar validation and controls', () async {
    for (final n in ['', '  ', 'a' * 41, 'x\ny', 'x\u0085y']) {
      expect(() => validText(n, 40, '名称'), throwsA(isA<DomainError>()));
    }
    expect(validText('  中文😀  ', 40, '名称'), '中文😀');
    expect(validText('个', 8, '单位'), '个');
    expect(validText('😀' * 8, 8, '单位'), '😀' * 8);
    expect(() => validText('个' * 9, 8, '单位'), throwsA(isA<DomainError>()));
  });
  test('P05 repeated names are independent UUIDs', () async {
    final a = await project();
    final b = await project();
    expect(a, isNot(b));
    await r.addEntry(a, 10);
    expect((await r.project(b))!.total, 0);
  });
  test('P08 strict integer boundaries', () async {
    final p = await project();
    for (final v in [0, -1, 1.5, 1000000, '10', true]) {
      await expectLater(r.addEntry(p, v), throwsA(isA<DomainError>()));
    }
    await r.addEntry(p, 999999);
    expect((await r.project(p))!.total, 999999);
    for (final v in ['1.0', '1e0', '-1', ' 1']) {
      expect(() => parseAmount(v), throwsA(isA<DomainError>()));
    }
  });
  test(
    'P09 100 accepted commands create 100 distinct entries and FIFO bodies',
    () async {
      final p = await project();
      await Future.wait(List.generate(100, (_) => r.addEntry(p, 10)));
      expect((await r.project(p))!.total, 1000);
      final entries = await r.history(p, limit: 200);
      expect(entries.length, 100);
      expect(entries.map((e) => e['id']).toSet().length, 100);
      expect(await r.pending(), 101);
      final outbox = await r.rows('SELECT * FROM outbox ORDER BY seq');
      expect(
        outbox.map((e) => e['seq']).toList(),
        List.generate(101, (i) => i + 1),
      );
    },
  );
  test('P10 domain, outbox and seq rollback together on failure', () async {
    final p = await project();
    r.beforeEnqueue = () async => throw StateError('injected disk error');
    await expectLater(r.addEntry(p, 10), throwsStateError);
    expect((await r.project(p))!.total, 0);
    expect(await r.pending(), 1);
    expect((await r.meta())!['last_enqueued_seq'], 1);
    r.beforeEnqueue = null;
    await r.addEntry(p, 10);
    expect((await r.meta())!['last_enqueued_seq'], 2);
  });
  test(
    'P12/P13/P14/P15 void exact ID, repeated void and unit locks after all voided',
    () async {
      final p = await project();
      final a = await r.addEntry(p, 20);
      final b = await r.addEntry(p, 10);
      final c = await r.addEntry(p, 12);
      await r.voidEntry(b);
      expect((await r.project(p))!.total, 32);
      expect((await r.history(p)).length, 2);
      final seq = (await r.meta())!['last_enqueued_seq'];
      await r.voidEntry(b);
      expect((await r.meta())!['last_enqueued_seq'], seq);
      await r.voidEntry(a);
      await r.voidEntry(c);
      await expectLater(
        r.putProject(id: p, name: '俯卧撑', unit: '次', icon: 'check', quick: 1),
        throwsA(isA<DomainError>()),
      );
    },
  );
  test(
    'P16/P17/P18 unit edits without history, archive blocks additions but allows void',
    () async {
      final p = await project();
      await r.putProject(
        id: p,
        name: '俯卧撑',
        unit: '次',
        icon: 'check',
        quick: 1,
      );
      final e = await r.addEntry(p, 20);
      await r.archive((await r.project(p))!, true);
      await expectLater(r.addEntry(p, 1), throwsA(isA<DomainError>()));
      await r.voidEntry(e);
      expect((await r.project(p))!.total, 0);
      await r.archive((await r.project(p))!, false);
      await r.addEntry(p, 5);
      expect((await r.project(p))!.total, 5);
    },
  );
  test(
    'P19/P20 supplied golden data matches all totals and 7/30-day zero fill',
    () async {
      final demo =
          jsonDecode(File('../../examples/demo_export.json').readAsStringSync())
              as Json;
      for (final raw in demo['projects'] as List) {
        final p = raw as Json;
        await db
            .customStatement('INSERT INTO projects VALUES(?,?,?,?,?,?,?,?)', [
              p['id'],
              p['name'],
              p['unit'],
              p['icon_key'],
              p['quick_amount'],
              p['archived'] == true ? 1 : 0,
              p['created_at_utc_ms'],
              p['updated_at_utc_ms'],
            ]);
      }
      for (final raw in demo['entries'] as List) {
        final e = raw as Json;
        await db.customStatement('INSERT INTO entries VALUES(?,?,?,?,?,?,?)', [
          e['id'],
          e['project_id'],
          e['amount'],
          e['occurred_at_utc_ms'],
          e['utc_offset_minutes'],
          e['local_date'],
          e['voided_at_utc_ms'],
        ]);
      }
      final expected =
          jsonDecode(
                File('../../examples/demo_expected.json').readAsStringSync(),
              )
              as Json;
      for (final id in (expected['project_totals'] as Json).keys) {
        final p = (await r.project(id))!;
        expect(p.total, expected['project_totals'][id]);
        expect(p.today, expected['project_today_totals'][id]);
      }
      final stats = await r.stats(7);
      expect(stats.values, expected['last_7_entry_counts']);
      expect(stats.eventCount, 13);
      expect(stats.values.last, 6);
      expect(stats.projectCount, 4);
      expect(
        (await r.stats(
          7,
          projectId: '00000000-0000-4000-8000-000000000001',
        )).values,
        expected['pushup_last_7_amounts'],
      );
      expect((await r.stats(30)).dates.length, 30);
    },
  );
  test('P20 all-zero chart has seven calendar days', () async {
    final s = await r.stats(7);
    expect(s.values, List.filled(7, 0));
    expect(s.activeDays, 0);
  });
  test('P21/P22 midnight and travel preserve captured dates', () async {
    final p = await project();
    clock.value = DateTime.parse('2026-09-11T15:59:00Z');
    final e = await r.addEntry(p, 10);
    clock.value = DateTime.parse('2026-09-11T16:01:00Z');
    expect((await r.project(p))!.today, 0);
    expect((await r.history(p)).single['local_date'], '2026-09-11');
    clock.offset = -420;
    expect(r.today, '2026-09-11');
    expect((await r.project(p))!.today, 10);
    expect((await r.history(p)).single['id'], e);
  });
  test('P23 DST captured offsets stay attached to original records', () async {
    final p = await project();
    clock.value = DateTime.parse('2026-11-01T08:30:00Z');
    clock.offset = -420;
    await r.addEntry(p, 1);
    clock.value = DateTime.parse('2026-11-01T09:30:00Z');
    clock.offset = -480;
    await r.addEntry(p, 1);
    final list = await r.history(p);
    expect(list.map((e) => e['local_date']).toSet(), {'2026-11-01'});
    expect(list.map((e) => e['utc_offset_minutes']).toSet(), {-420, -480});
  });
  test('P24 same-millisecond cursor 50+5 has no gap or duplicate', () async {
    final p = await project();
    for (var i = 0; i < 55; i++) {
      await r.addEntry(p, 1);
    }
    final a = await r.history(p);
    final b = await r.history(p, after: a.last);
    expect(a.length, 50);
    expect(b.length, 5);
    expect([...a, ...b].map((e) => e['id']).toSet().length, 55);
  });
  test(
    'P25 export includes void markers and excludes credentials/outbox',
    () async {
      final p = await project();
      final e = await r.addEntry(p, 10);
      await r.voidEntry(e);
      final export = await r.export();
      expect(export.keys.toSet(), {
        'schema_version',
        'exported_at_utc_ms',
        'source',
        'projects',
        'entries',
      });
      expect((export['entries'] as List).single['voided_at_utc_ms'], isNotNull);
      expect((export['projects'] as List).single['archived'], false);
      await File(
        '../../qa/evidence/local-export.json',
      ).writeAsString(jsonEncode(export));
    },
  );
}
