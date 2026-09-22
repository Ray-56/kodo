import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kodo_app/main.dart' as app;
import 'package:kodo_app/app.dart';
import 'package:kodo_app/features/projects/screens.dart';
import 'package:kodo_app/core/sync/worker.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('M1 real device UI create → quick 10 → committed', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    final identity = container.read(syncProvider)!.identity;
    expect(identity.problem, isNull);
    expect(identity.identity, isNotNull);
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    if (find.text('今日 10 个').evaluate().isNotEmpty) {
      expect(find.text('今日 10 个'), findsOneWidget);
      if (const bool.fromEnvironment('QA_SYNC_AFTER_RESTART')) {
        final worker = container.read(syncProvider)!;
        final repo = container.read(repositoryProvider);
        final queued = await repo.rows(
          'SELECT body_json FROM outbox WHERE seq=2',
        );
        await worker.setEnabled(true);
        await worker.wake();
        expect(await repo.pending(), 0);
        expect(worker.status, '云端副本已更新');
        const url = String.fromEnvironment('API_BASE_URL');
        final id = worker.identity.identity!;
        if (queued.isNotEmpty) {
          final replay = await HttpMirrorApi(
            url,
          ).send(id, queued.single['body_json'] as String);
          expect(replay.body?['status'], 'duplicate');
        }
        final snapshot =
            (await Dio().get<Object?>(
                  '$url/v1/snapshot',
                  options: Options(
                    headers: {'Authorization': 'Bearer ${id.bearer}'},
                  ),
                )).data
                as Map;
        expect((snapshot['entries'] as List).length, 1);
        expect((snapshot['entries'] as List).single['amount'], 10);
        debugPrint('KODO_RESTART_SYNC_PASSED');
      }
      await binding.takeScreenshot('m1-same-install-restart');
      debugPrint('KODO_RESTART_PASSED');
      return;
    }
    expect(find.text('从一次行动开始'), findsOneWidget);
    await binding.takeScreenshot('m1-empty');
    await tester.tap(find.byKey(const Key('create-project')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('project-name')), '俯卧撑');
    await tester.enterText(find.byKey(const Key('project-unit')), '个');
    await tester.enterText(find.byKey(const Key('project-quick')), '10');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('m1-create');
    await tester.ensureVisible(find.byKey(const Key('save-project')));
    await tester.tap(find.byKey(const Key('save-project')));
    await tester.pumpAndSettle();
    expect(find.text('俯卧撑'), findsOneWidget);
    await tester.tap(find.text('+10'));
    await tester.pumpAndSettle();
    expect(find.text('今日 10 个'), findsOneWidget);
    expect(find.text('项目详情'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('m1-home-ten');
  });
}
