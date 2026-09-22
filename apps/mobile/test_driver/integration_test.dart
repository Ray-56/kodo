import 'dart:io';
import 'dart:convert';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final folder = Platform.environment['KODO_EVIDENCE'] ?? '../../qa/evidence';
    await Directory(folder).create(recursive: true);
    await File('$folder/$name.png').writeAsBytes(bytes);
    return true;
  },
  responseDataCallback: (data) async {
    final folder = Platform.environment['KODO_EVIDENCE'] ?? '../../qa/evidence';
    await Directory(folder).create(recursive: true);
    if (data != null) {
      await File('$folder/integration-metrics.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          for (final entry in data.entries)
            if (entry.key != 'screenshots') entry.key: entry.value,
        }),
      );
    }
    final android = Platform.environment['KODO_RESTART_ANDROID'];
    if (android != null) {
      final result = await Process.run('python3', [
        '../../scripts/probe_android_restart.py',
        android,
        folder,
        Platform.environment['KODO_RESTART_MODE'] ?? 'local',
      ]);
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode != 0) {
        throw StateError('Android restart probe failed');
      }
    }
    final device = Platform.environment['KODO_RESTART_IOS'];
    if (device != null) {
      final result = await Process.run('python3', [
        '../../scripts/probe_ios_restart.py',
        device,
      ]);
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode != 0) {
        throw StateError('Same-install restart probe failed');
      }
    }
  },
);
