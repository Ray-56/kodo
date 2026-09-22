import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kodo_app/main.dart' as app;
import 'package:kodo_app/app.dart';
import 'package:kodo_app/core/sync/worker.dart';
import 'package:kodo_app/features/projects/screens.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('M5 full native UI and real Rust mirror', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    final repo = container.read(repositoryProvider),
        worker = container.read(syncProvider)!;
    // Use a fresh disposable test installation, never erase pre-existing data.
    expect(await repo.rows('SELECT id FROM projects'), isEmpty);
    await tester.pumpAndSettle();
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    final platform = Platform.isIOS ? 'ios' : 'android';
    await binding.takeScreenshot('m5-$platform-empty');
    await tester.tap(find.byKey(const Key('create-project')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('project-name')), '俯卧撑');
    await tester.enterText(find.byKey(const Key('project-unit')), '个');
    await tester.enterText(find.byKey(const Key('project-quick')), '10');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-project')));
    await tester.tap(find.byKey(const Key('save-project')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+10'));
    await tester.pumpAndSettle();
    expect(find.text('今日 10 个'), findsOneWidget);
    final p =
        (await repo.rows('SELECT id FROM projects')).single['id'] as String;
    await tester.tap(find.text('俯卧撑'));
    await tester.pumpAndSettle();
    for (final n in ['1', '5', '20']) {
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, n));
      await tester.tap(find.widgetWithText(OutlinedButton, n));
      await tester.pumpAndSettle();
      expect((await repo.project(p))!.total, 10);
    }
    await tester.enterText(find.byKey(const Key('entry-amount')), '12');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('record-entry')));
    await tester.tap(find.byKey(const Key('record-entry')));
    await tester.pumpAndSettle();
    expect((await repo.project(p))!.total, 22);
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect((await repo.project(p))!.total, 10);
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, '20'));
    await tester.tap(find.widgetWithText(OutlinedButton, '20'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('entry-amount')))
          .controller!
          .text,
      '20',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('record-entry')));
    await tester.tap(find.byKey(const Key('record-entry')));
    await tester.pumpAndSettle();
    expect((await repo.project(p))!.total, 30);
    expect(worker.enabled, false);
    await tester.drag(find.byType(ListView).last, const Offset(0, 1000));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('m2-$platform-detail-30');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('m2-$platform-home-30');
    await tester.tap(find.text('统计').last);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('m2-$platform-stats');
    await tester.tap(find.text('项目').last);
    await tester.pumpAndSettle();
    final immutable =
        (await repo.rows(
              'SELECT body_json FROM outbox WHERE seq=2',
            )).single['body_json']
            as String;
    await tester.tap(find.byTooltip('设置与更多'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('m4-$platform-consent');
    await tester.tap(find.text('同意并开启'));
    await tester.pumpAndSettle();
    await worker.wake();
    await tester.pumpAndSettle();
    expect(worker.status, '云端副本已更新');
    expect(await repo.pending(), 0);
    final url = const String.fromEnvironment('API_BASE_URL');
    final id = worker.identity.identity!;
    final duplicate = await HttpMirrorApi(url).send(id, immutable);
    expect(duplicate.body?['status'], 'duplicate');
    final snapshot =
        (await Dio().get<Object?>(
              '$url/v1/snapshot',
              options: Options(
                headers: {'Authorization': 'Bearer ${id.bearer}'},
              ),
            )).data
            as Map;
    expect(
      (snapshot['entries'] as List)
          .where((e) => e['voided_at_utc_ms'] == null)
          .fold<int>(0, (n, e) => n + (e['amount'] as int)),
      30,
    );
    await binding.takeScreenshot('m4-$platform-synced');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('俯卧撑'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('项目操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('归档项目'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect((await repo.project(p))!.archived, true);
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, '恢复项目'));
    await tester.tap(find.widgetWithText(OutlinedButton, '恢复项目'));
    await tester.pumpAndSettle();
    expect((await repo.project(p))!.archived, false);
    await worker.wake();
    expect(jsonEncode(await repo.export()).contains('voided_at_utc_ms'), true);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('设置与更多'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('删除全部数据'));
    await tester.tap(find.text('删除全部数据'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '删除全部数据'));
    await tester.pumpAndSettle();
    expect(await repo.rows('SELECT * FROM projects'), isEmpty);
    expect(await repo.pending(), 0);
    await binding.takeScreenshot('m4-$platform-deleted');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('从一次行动开始'), findsOneWidget);
  });
}
