import 'dart:io';
import 'dart:async';
import 'core/sync/worker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'core/storage/database.dart';
import 'core/storage/identity.dart';
import 'core/storage/repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  );
  try {
    final dir = await getApplicationSupportDirectory();
    final repo = KodoRepository(
      KodoDatabase.file(File('${dir.path}/kodo.sqlite')),
    );
    final identity = IdentityManager(repo, PlatformSecretStore());
    await identity.open();
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://localhost:8080',
    );
    final worker = SyncWorker(repo, identity, HttpMirrorApi(url));
    final deletion = DeletionController(worker);
    await deletion.recover();
    await worker.load();
    repo.onCommit = () {
      deletion.clearMessage();
      unawaited(worker.wake());
    };
    unawaited(worker.wake());
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
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Kodo')),
          body: const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '无法打开本机数据库。原文件已保留，请勿卸载应用。请重试启动或联系开发者导出应用支持目录中的 kodo.sqlite、-wal 和 -shm 文件。',
            ),
          ),
        ),
      ),
    );
  }
}
