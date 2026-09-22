import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo_app/app.dart';
import 'package:kodo_app/core/storage/database.dart';
import 'package:kodo_app/core/storage/repository.dart';
import 'package:kodo_app/core/storage/models.dart';
import 'package:kodo_app/features/projects/screens.dart';
import 'package:kodo_app/core/storage/identity.dart';
import 'package:kodo_app/core/sync/worker.dart';
import 'sync_test.dart' show MemorySecrets, FakeApi;

final captureKey = GlobalKey();
Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['KODO_TEST_FONT'] == null) return;
  final boundary =
      captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '../../qa/evidence/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final font = Platform.environment['KODO_TEST_FONT'];
    if (font != null) {
      final loader = FontLoader('Roboto')
        ..addFont(
          Future.value(ByteData.sublistView(await File(font).readAsBytes())),
        );
      await loader.load();
    }
  });

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  for (final size in [const Size(390, 844), const Size(360, 800)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'native layouts ${size.width}x${size.height} at ${scale * 100}% text',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = KodoDatabase(NativeDatabase.memory());
          final r = KodoRepository(db);
          await r.initialize('test-only');
          final id = await r.putProject(
            name: '俯卧撑',
            unit: '个',
            icon: 'dumbbell',
            quick: 10,
          );
          await r.addEntry(id, 999999);
          final container = ProviderContainer(
            overrides: [repositoryProvider.overrideWithValue(r)],
          );
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: RepaintBoundary(key: captureKey, child: const KodoApp()),
            ),
          );
          // Override platform scaling, which MaterialApp's View-derived MediaQuery reads.
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 10),
          );
          expect(tester.takeException(), isNull);
          await capture(
            tester,
            'm5-layout-home-${size.width.toInt()}-${(scale * 100).toInt()}',
          );
          await tester.tap(find.text('俯卧撑'));
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 10),
          );
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.byKey(const Key('record-entry')),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 10),
          );
          final button = tester.getSize(find.byKey(const Key('record-entry')));
          expect(button.height, greaterThanOrEqualTo(48));
          expect(button.width, greaterThanOrEqualTo(48));
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 10),
          );
          await tester.tap(find.text('统计').last);
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 10),
          );
          expect(tester.takeException(), isNull);
          await capture(
            tester,
            'm5-layout-stats-${size.width.toInt()}-${(scale * 100).toInt()}',
          );
          await tester.tap(find.byTooltip('设置与更多'));
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 10),
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 10),
          );
          await tester.tap(find.text('项目').last);
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 10),
          );
          await tester.tap(find.byKey(const Key('create-project')));
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 10),
          );
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          addTearDown(tester.view.resetViewInsets);
          await tester.enterText(find.byKey(const Key('project-name')), '阅读');
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 10),
          );
          await tester.scrollUntilVisible(
            find.byKey(const Key('save-project')),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.getBottomRight(find.byKey(const Key('save-project'))).dy,
            lessThanOrEqualTo(size.height - 280 + 1),
          );
          await tester.pumpWidget(const SizedBox());
          container.dispose();
          await tester.pump();
          final closing = db.close();
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 1));
          }
          await closing;
        },
      );
    }
  }
  testWidgets(
    'P06 quick hit target records without detail navigation; P07 draft only',
    (tester) async {
      final db = KodoDatabase(NativeDatabase.memory());
      final r = KodoRepository(db);
      await r.initialize('widget');
      final p = await r.putProject(
        name: '俯卧撑',
        unit: '个',
        icon: 'dumbbell',
        quick: 10,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(r)],
          child: const KodoApp(),
        ),
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      await tester.tap(find.byKey(Key('quick-$p')));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      expect(find.byType(DetailScreen), findsNothing);
      expect((await r.project(p))!.total, 10);
      await tester.tap(find.text('俯卧撑'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );
      for (final value in ['1', '5', '20']) {
        await tester.ensureVisible(find.widgetWithText(OutlinedButton, value));
        await tester.tap(find.widgetWithText(OutlinedButton, value));
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 10),
        );
      }
      expect((await r.project(p))!.total, 10);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      final closing = db.close();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      await closing;
    },
  );
  testWidgets('P21 visible today refreshes across midnight', (tester) async {
    final db = KodoDatabase(NativeDatabase.memory());
    final clock = FixedClock(DateTime.parse('2026-09-11T15:59:00Z'));
    final r = KodoRepository(db, clock: clock);
    await r.initialize('clock');
    final p = await r.putProject(
      name: '俯卧撑',
      unit: '个',
      icon: 'check',
      quick: 10,
    );
    await r.addEntry(p, 10);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(r)],
        child: const KodoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('今日 10 个'), findsOneWidget);
    clock.value = DateTime.parse('2026-09-11T16:01:00Z');
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();
    expect(find.text('今日 0 个'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    final closing = db.close();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    await closing;
  });
  testWidgets(
    'selected statistics survives delete-all and returns to global events',
    (tester) async {
      final db = KodoDatabase(NativeDatabase.memory());
      final repo = KodoRepository(db);
      final identity = IdentityManager(repo, MemorySecrets());
      await identity.open();
      final worker = SyncWorker(repo, identity, FakeApi());
      final deletion = DeletionController(worker);
      final p = await repo.putProject(
        name: '阅读',
        unit: '页',
        icon: 'book',
        quick: 10,
      );
      await repo.addEntry(p, 10);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            syncProvider.overrideWithValue(worker),
            deletionProvider.overrideWithValue(deletion),
          ],
          child: const KodoApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('统计').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('阅读').last);
      await tester.pumpAndSettle();
      expect(find.text('10 页'), findsWidgets);
      await tester.tap(find.byTooltip('设置与更多'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('删除全部数据'));
      await tester.tap(find.text('删除全部数据'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('继续'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '删除全部数据'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('0 次记录'), findsOneWidget);
      final next = await repo.putProject(
        name: '运动',
        unit: '个',
        icon: 'check',
        quick: 1,
      );
      await repo.addEntry(next, 5);
      await tester.pumpAndSettle();
      expect(find.text('1 次记录'), findsOneWidget);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .initialValue,
        '',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      worker.dispose();
      deletion.dispose();
      final closing = db.close();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      await closing;
    },
  );
}
