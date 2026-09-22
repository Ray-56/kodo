import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kodo_app/main.dart' as app;
import 'package:kodo_app/app.dart';
import 'package:kodo_app/core/storage/models.dart';
import 'package:kodo_app/core/storage/repository.dart';
import 'package:kodo_app/features/projects/screens.dart';
import 'package:uuid/uuid.dart';

// Test target only: the normal application never seeds these records.
Future<void> seed(KodoRepository repo) async {
  final time = repo.clock.now().millisecondsSinceEpoch;
  final offset = repo.clock.offsetMinutes();
  var seq = 0;
  await repo.db.transaction(() async {
    await repo.db.batch((batch) {
      void enqueue(String kind, String id, Json payload) {
        final op = const Uuid().v4();
        batch.customStatement(
          'INSERT INTO outbox(seq,op_id,body_json) VALUES(?,?,?)',
          [
            ++seq,
            op,
            jsonEncode({
              'op_id': op,
              'seq': seq,
              'kind': kind,
              'entity_id': id,
              'payload': payload,
            }),
          ],
        );
      }

      for (var p = 0; p < 100; p++) {
        final id = const Uuid().v4();
        final name = '性能项目 ${p + 1}';
        batch.customStatement(
          'INSERT INTO projects(id,name,unit,icon_key,quick_amount,archived,created_at_utc_ms,updated_at_utc_ms) VALUES(?,?,?,?,?,0,?,?)',
          [id, name, '次', 'check', 10, time + p, time + p],
        );
        enqueue('project.put', id, {
          'name': name,
          'unit': '次',
          'icon_key': 'check',
          'quick_amount': 10,
          'archived': false,
          'created_at_utc_ms': time + p,
          'updated_at_utc_ms': time + p,
        });
        for (var e = 0; e < 100; e++) {
          final entry = const Uuid().v4();
          final timestamp = time - e * 60000;
          final date = capturedDate(timestamp, offset);
          batch.customStatement(
            'INSERT INTO entries(id,project_id,amount,occurred_at_utc_ms,utc_offset_minutes,local_date) VALUES(?,?,10,?,?,?)',
            [entry, id, timestamp, offset, date],
          );
          enqueue('entry.add', entry, {
            'project_id': id,
            'amount': 10,
            'occurred_at_utc_ms': timestamp,
            'utc_offset_minutes': offset,
            'local_date': date,
          });
        }
      }
      batch.customStatement(
        'UPDATE app_meta SET last_enqueued_seq=? WHERE id=1',
        [seq],
      );
    });
  });
}

void main() {
  final startup = Stopwatch()..start();
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Physical profile: 100 taps, 100 projects/10k entries, scrolling', (
    tester,
  ) async {
    expect(
      kProfileMode,
      true,
      reason: 'Performance results require profile mode',
    );
    await app.main();
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    final repo = container.read(repositoryProvider);
    final projects = await repo.rows('SELECT id FROM projects');
    if (projects.isNotEmpty) {
      expect(projects.length, 100);
      expect(
        (await repo.rows('SELECT COUNT(*) AS n FROM entries')).single['n'],
        10000,
      );
      expect(find.text('性能项目 100'), findsOneWidget);
      await tester.pump();
      // Emitted after a frame with the persisted list, not the loading screen.
      debugPrint(
        'KODO_PERF_READY ${jsonEncode({'projects': 100, 'entries': 10000, 'dart_start_to_verified_ui_ms': startup.elapsedMicroseconds / 1000})}',
      );
      return;
    }
    final p = await repo.putProject(
      name: '性能点击',
      unit: '次',
      icon: 'check',
      quick: 10,
    );
    await tester.pumpAndSettle();
    final milliseconds = <double>[];
    for (var i = 1; i <= 100; i++) {
      final clock = Stopwatch()..start();
      await tester.tap(find.byKey(Key('quick-$p')));
      // Poll a real frame, without pumpAndSettle's fixed 100ms sampling interval.
      while (true) {
        await tester.pump(const Duration(milliseconds: 1));
        final text = tester.widget<Text>(find.byKey(Key('today-$p'))).data;
        final button = tester.widget<FilledButton>(find.byKey(Key('quick-$p')));
        if (text == '今日 ${number(i * 10)} 次' && button.onPressed != null) break;
        if (clock.elapsedMilliseconds > 5000) {
          fail('Committed counter did not become visible');
        }
      }
      milliseconds.add(clock.elapsedMicroseconds / 1000);
    }
    expect((await repo.project(p))!.total, 1000);
    expect(await repo.pending(), 101);
    final sorted = [...milliseconds]..sort();
    binding.reportData = {
      'mode': 'profile',
      'tap_to_committed_counter_frame_ms': {
        'samples': milliseconds,
        'p50': sorted[49],
        'p95': sorted[94],
        'max': sorted.last,
      },
      'accepted_entries': 100,
    };
    // Only this fresh QA fixture is reset. No user data is involved.
    await container.read(deletionProvider)!.begin();
    await seed(repo);
    container.invalidate(projectsProvider);
    await tester.pumpAndSettle();
    expect(
      (await repo.rows('SELECT COUNT(*) AS n FROM entries')).single['n'],
      10000,
    );
    await binding.watchPerformance(() async {
      for (var i = 0; i < 12; i++) {
        await tester.fling(
          find.byType(ListView).first,
          const Offset(0, -1200),
          2400,
        );
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 12; i++) {
        await tester.fling(
          find.byType(ListView).first,
          const Offset(0, 1200),
          2400,
        );
        await tester.pumpAndSettle();
      }
    }, reportKey: 'scroll_100_projects_10000_entries');
    binding.reportData!['scale'] = {
      'projects': 100,
      'entries': 10000,
      'pending': await repo.pending(),
    };
    // Capture only after timings; surface conversion changes rendering.
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('profile-100-projects');
    expect(sorted[94], lessThanOrEqualTo(150), reason: 'M5 tap feedback p95');
  });
}
