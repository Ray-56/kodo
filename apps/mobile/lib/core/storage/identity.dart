import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'repository.dart';

abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class PlatformSecretStore implements SecretStore {
  final _storage = const FlutterSecureStorage(
    // Plugin defaults may erase credentials after a KeyStore error. Preserve
    // them for recovery/deletion and let IdentityManager suspend synchronization.
    aOptions: AndroidOptions(resetOnError: false),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> remove(String key) => _storage.delete(key: key);
}

class Identity {
  Identity(this.id, this.secret);
  final String id, secret;
  static Identity generate() {
    final random = Random.secure();
    return Identity(
      const Uuid().v4(),
      base64UrlEncode(
        List.generate(32, (_) => random.nextInt(256)),
      ).replaceAll('=', ''),
    );
  }

  factory Identity.decode(String source) {
    final j = jsonDecode(source) as Json;
    final id = j['installation_id'] as String, secret = j['secret'] as String;
    if (!Uuid.isValidUUID(fromString: id) ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(secret) ||
        base64Url.decode(base64Url.normalize(secret)).length != 32) {
      throw const DomainError('凭据损坏');
    }
    return Identity(id, secret);
  }
  Json toJson() => {'installation_id': id, 'secret': secret};
  String get bearer => '$id.$secret';
}

class IdentityManager {
  IdentityManager(this.repo, this.store);
  final KodoRepository repo;
  final SecretStore store;
  Identity? identity;
  String? problem;
  bool orphaned = false;
  Future<void> open() async {
    identity = null;
    problem = null;
    orphaned = false;
    final meta = await repo.meta();
    try {
      final raw = await store.read('identity');
      if (meta == null && raw != null) {
        orphaned = true;
        problem = '本机数据库已丢失，旧副本无法自动恢复。可清理旧副本后开始新记录。';
        await repo.initialize(const Uuid().v4());
        return;
      }
      if (meta == null) {
        final fresh = Identity.generate();
        await store.write('identity', jsonEncode(fresh.toJson()));
        await repo.initialize(fresh.id);
        identity = fresh;
      } else {
        if (raw == null) throw const DomainError('安全凭据丢失，已暂停同步。数据保留在本机，可导出。');
        final saved = Identity.decode(raw);
        if (saved.id != meta['installation_id']) {
          orphaned = true;
          throw const DomainError('数据库与凭据不匹配，已暂停同步。数据保留，可导出或清理旧副本。');
        }
        identity = saved;
      }
    } catch (e) {
      problem = e is DomainError ? e.message : '安全存储不可用，已暂停同步；本机仍可记录和导出。';
      if (meta == null && await repo.meta() == null) {
        await repo.initialize(const Uuid().v4());
      }
    }
  }
}
