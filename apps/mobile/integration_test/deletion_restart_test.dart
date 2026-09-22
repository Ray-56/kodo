import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kodo_app/main.dart' as app;
import 'package:kodo_app/app.dart';
import 'package:kodo_app/core/storage/database.dart';
import 'package:kodo_app/core/storage/identity.dart';
import 'package:kodo_app/core/storage/repository.dart';
import 'package:kodo_app/core/sync/worker.dart';
import 'package:kodo_app/features/projects/screens.dart';

// Hold an actual successful HTTP response before the local deletion checkpoint.
// The host kills the process here; startup must retry the persisted intent.
class HoldDeletedResponse implements MirrorApi {
  HoldDeletedResponse(this.real, this.marker);
  final MirrorApi real;
  final File marker;
  final committed = Completer<void>();
  @override
  Future<ApiResponse> register(Identity id) => real.register(id);
  @override
  Future<ApiResponse> send(Identity id, String body) => real.send(id, body);
  @override
  Future<ApiResponse> delete(Identity id) async {
    final response = await real.delete(id);
    expect(response.status, 204);
    await marker.writeAsString('remote_committed', flush: true);
    committed.complete();
    return Completer<ApiResponse>().future;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Physical force-stop between remote deletion and local checkpoint',
    (tester) async {
      final dir = await getApplicationSupportDirectory();
      final marker = File('${dir.path}/qa-deletion-committed');
      if (await marker.exists()) {
        final old = Identity.decode(
          (await PlatformSecretStore().read('identity'))!,
        );
        await app.main();
        await tester.pumpAndSettle();
        final c = ProviderScope.containerOf(
          tester.element(find.byType(HomeScreen)),
        );
        final repo = c.read(repositoryProvider);
        expect(await repo.rows('SELECT id FROM projects'), isEmpty);
        expect(await repo.pending(), 0);
        expect((await repo.meta())!['deletion_pending'], 0);
        expect(await PlatformSecretStore().read('deletion'), isNull);
        final identity = c.read(syncProvider)!.identity;
        expect(identity.problem, isNull);
        expect(identity.identity!.id, isNot(old.id));
        final api = HttpMirrorApi(const String.fromEnvironment('API_BASE_URL'));
        expect((await api.register(old)).status, 410);
        expect(find.text('从一次行动开始'), findsOneWidget);
        await tester.pump();
        debugPrint('KODO_DELETE_RECOVERED');
        return;
      }
      final repo = KodoRepository(
        KodoDatabase.file(File('${dir.path}/kodo.sqlite')),
      );
      final identity = IdentityManager(repo, PlatformSecretStore());
      await identity.open();
      expect(identity.problem, isNull);
      expect(await repo.rows('SELECT id FROM projects'), isEmpty);
      final api = HoldDeletedResponse(
        HttpMirrorApi(const String.fromEnvironment('API_BASE_URL')),
        marker,
      );
      final worker = SyncWorker(repo, identity, api);
      final deletion = DeletionController(worker);
      await worker.load();
      runApp(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            syncProvider.overrideWithValue(worker),
            deletionProvider.overrideWithValue(deletion),
          ],
          child: const KodoApp(),
        ),
      );
      final p = await repo.putProject(
        name: '删除中断测试',
        unit: '次',
        icon: 'check',
        quick: 10,
      );
      await repo.addEntry(p, 10);
      await worker.setEnabled(true);
      await worker.wake();
      expect(await repo.pending(), 0);
      unawaited(deletion.begin());
      await api.committed.future;
      expect((await repo.project(p))!.total, 10);
      expect(
        jsonDecode((await PlatformSecretStore().read('deletion'))!)['stage'],
        'sending',
      );
      await tester.pumpAndSettle();
      if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('deletion-before-force-stop');
      binding.reportData = {
        'remote_delete_committed': true,
        'local_stage_before_force_stop': 'sending',
        'local_amount_before_force_stop': 10,
      };
    },
  );
}
