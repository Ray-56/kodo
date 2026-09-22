import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo_app/core/storage/database.dart';
import 'package:kodo_app/core/storage/identity.dart';
import 'package:kodo_app/core/storage/repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Android KeyStore errors must not request credential reset or mutate local data',
    () async {
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            final args = call.arguments as Map;
            expect((args['options'] as Map)['resetOnError'], 'false');
            throw PlatformException(code: 'KeyStoreUnavailable');
          });
      final repo = KodoRepository(KodoDatabase(NativeDatabase.memory()));
      await repo.initialize('11111111-1111-4111-8111-111111111111');
      final p = await repo.putProject(
        name: '保留本机',
        unit: '次',
        icon: 'check',
        quick: 1,
      );
      await repo.addEntry(p, 10);
      final before = await repo.meta();
      final identity = IdentityManager(repo, PlatformSecretStore());
      await identity.open();
      expect(identity.identity, isNull);
      expect(identity.problem, contains('安全存储不可用'));
      expect(calls, ['read']);
      expect(await repo.meta(), before);
      expect((await repo.project(p))!.total, 10);
      expect(await repo.pending(), 2);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await repo.db.close();
    },
  );
}
