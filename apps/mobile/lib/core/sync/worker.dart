import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/identity.dart';
import '../storage/models.dart';
import '../storage/repository.dart';

class ApiResponse {
  ApiResponse(this.status, this.body, {this.retryAfter});
  final int status;
  final Json? body;
  final Duration? retryAfter;
}

abstract interface class MirrorApi {
  Future<ApiResponse> register(Identity identity);
  Future<ApiResponse> send(Identity identity, String immutableBody);
  Future<ApiResponse> delete(Identity identity);
}

class HttpMirrorApi implements MirrorApi {
  HttpMirrorApi(
    this.baseUrl, {
    Dio? dio,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
               validateStatus: (_) => true,
             ),
           ) {
    final uri = Uri.parse(baseUrl);
    if (!['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (kReleaseMode && uri.scheme != 'https')) {
      throw const DomainError('服务地址无效；Release 必须使用 HTTPS');
    }
  }
  final String baseUrl;
  final Duration requestTimeout;
  final Dio _dio;
  Future<ApiResponse> _request(
    String method,
    String path,
    Identity id, {
    Object? data,
    bool auth = true,
  }) async {
    final cancellation = CancelToken();
    final deadline = Timer(requestTimeout, () {
      cancellation.cancel('request_deadline');
    });
    late Response<Object?> r;
    try {
      r = await _dio.request<Object?>(
        '$baseUrl$path',
        data: data,
        cancelToken: cancellation,
        options: Options(
          method: method,
          contentType: 'application/json',
          headers: auth ? {'Authorization': 'Bearer ${id.bearer}'} : null,
        ),
      );
    } finally {
      deadline.cancel();
    }
    final retry = r.headers.value('retry-after');
    Duration? delay;
    if (retry != null) {
      final seconds = int.tryParse(retry);
      if (seconds != null && seconds >= 0) delay = Duration(seconds: seconds);
    }
    return ApiResponse(
      r.statusCode ?? 503,
      r.data is Map ? Map<String, dynamic>.from(r.data as Map) : null,
      retryAfter: delay,
    );
  }

  @override
  Future<ApiResponse> register(Identity identity) => _request(
    'POST',
    '/v1/installations',
    identity,
    data: identity.toJson(),
    auth: false,
  );
  @override
  Future<ApiResponse> send(Identity identity, String immutableBody) =>
      _request('POST', '/v1/operations', identity, data: immutableBody);
  @override
  Future<ApiResponse> delete(Identity identity) =>
      _request('DELETE', '/v1/installations/current', identity);
}

class SyncWorker extends ChangeNotifier {
  static const _permanentErrors = {400, 401, 403, 404, 409, 410, 413, 415, 422};
  SyncWorker(this.repo, this.identity, this.api, {double Function()? jitter})
    : jitter = jitter ?? Random().nextDouble;
  final KodoRepository repo;
  final IdentityManager identity;
  final MirrorApi api;
  final double Function() jitter;
  Future<void>? _running;
  Timer? _timer;
  bool foreground = true,
      enabled = false,
      deleting = false,
      blocked = false,
      updated = false;
  int pending = 0;
  String? errorCode;
  bool get running => _running != null;
  bool _disposed = false;
  bool registered = false;
  void changed() {
    if (!_disposed) notifyListeners();
  }

  String get status {
    if (deleting) return '待联网完成删除';
    if (identity.problem != null || blocked) return '同步需要处理';
    if (!enabled) return '仅本机';
    if (errorCode != null) return '连接失败，记录已保存在本机';
    if (running) return '正在同步';
    if (updated && pending == 0) return '云端副本已更新';
    return '待同步 $pending 项操作';
  }

  Future<void> load() async {
    final m = await repo.meta();
    enabled = m?['sync_enabled'] == 1;
    deleting = m?['deletion_pending'] == 1;
    pending = await repo.pending();
    final status = m?['last_sync_error_status'] as int?;
    blocked = _permanentErrors.contains(status);
    errorCode = status == null
        ? null
        : (await repo.head())?['last_error_code'] as String? ?? 'http_$status';
    changed();
  }

  Future<void> setEnabled(bool value) async {
    if (value && identity.identity == null) {
      throw DomainError(identity.problem ?? '安全凭据不可用');
    }
    if (deleting) throw const DomainError('请先完成删除');
    await repo.setMeta('sync_enabled', value ? 1 : 0);
    enabled = value;
    updated = false;
    _timer?.cancel();
    changed();
    if (value) await wake(manual: true);
  }

  void setForeground(bool value) {
    foreground = value;
    if (value) {
      unawaited(wake());
    } else {
      _timer?.cancel();
    }
  }

  Future<void> wake({bool manual = false}) {
    if (_running != null) return _running!;
    if (_disposed) return Future.value();
    if (manual) {
      blocked = false;
      errorCode = null;
      _timer?.cancel();
    }
    _running = _run(manual: manual).whenComplete(() {
      _running = null;
      changed();
    });
    changed();
    return _running!;
  }

  Future<void> _run({required bool manual}) async {
    try {
      if (manual) {
        await repo.db.customStatement(
          'UPDATE app_meta SET last_sync_error_status=NULL WHERE id=1',
        );
      }
      pending = await repo.pending();
      if (!enabled ||
          !foreground ||
          deleting ||
          blocked ||
          identity.identity == null) {
        changed();
        return;
      }
      final id = identity.identity!;
      final head = await repo.head();
      final next = head?['next_attempt_at_utc_ms'] as int?;
      if (!manual &&
          next != null &&
          next > repo.clock.now().millisecondsSinceEpoch) {
        _schedule(
          Duration(
            milliseconds: next - repo.clock.now().millisecondsSinceEpoch,
          ),
        );
        return;
      }
      if (!registered) {
        await repo.setMeta('registration_attempted', 1);
        final reg = await api.register(id);
        if (reg.status != 200 && reg.status != 201) {
          await _failure(head, reg);
          return;
        }
        if (reg.body?['installation_id'] != id.id ||
            !['created', 'existing'].contains(reg.body?['status'])) {
          await _failure(
            head,
            ApiResponse(422, {
              'error': {'code': 'registration_ack_mismatch'},
            }),
          );
          return;
        }
        registered = true;
      }
      while (enabled && foreground && !deleting) {
        final h = await repo.head();
        if (h == null) {
          await repo.db.customStatement(
            'UPDATE app_meta SET last_sync_error_status=NULL WHERE id=1',
          );
          updated = true;
          errorCode = null;
          pending = 0;
          changed();
          return;
        }
        updated = false;
        changed();
        final result = await api.send(id, h['body_json'] as String);
        if (result.status != 200 || result.body == null) {
          await _failure(h, result);
          return;
        }
        try {
          await repo.acknowledge(result.body!);
        } on DomainError {
          await _failure(
            h,
            ApiResponse(422, {
              'error': {'code': 'ack_mismatch'},
            }),
          );
          return;
        }
        pending = await repo.pending();
        errorCode = null;
        changed();
      }
    } catch (_) {
      try {
        await _failure(await repo.head(), ApiResponse(503, null));
      } catch (_) {
        errorCode = 'local_storage_error';
        blocked = true;
        updated = false;
        changed();
      }
    }
  }

  Future<void> _failure(Json? head, ApiResponse response) async {
    updated = false;
    final code = response.body?['error'];
    final raw = code is Map ? code['code'] : null;
    errorCode = raw is String && RegExp(r'^[a-z_]{1,80}$').hasMatch(raw)
        ? raw
        : 'http_${response.status}';
    blocked = _permanentErrors.contains(response.status);
    final attempts = (head?['attempts'] as int? ?? 0) + 1;
    final base = min(60, pow(2, min(attempts - 1, 6)).toInt());
    final delay =
        response.retryAfter ??
        Duration(
          milliseconds: min(60000, (base * 1000 * (1 + jitter() * .2)).round()),
        );
    await repo.db.transaction(() async {
      await repo.db.customStatement(
        'UPDATE app_meta SET last_sync_error_status=? WHERE id=1',
        [response.status],
      );
      if (head != null) {
        await repo.db.customStatement(
          'UPDATE outbox SET attempts=?,next_attempt_at_utc_ms=?,last_error_code=? WHERE seq=?',
          [
            attempts,
            repo.clock.now().millisecondsSinceEpoch + delay.inMilliseconds,
            errorCode,
            head['seq'],
          ],
        );
      }
    });
    if (!blocked) _schedule(delay);
    changed();
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    if (foreground && enabled && !deleting && !_disposed) {
      _timer = Timer(delay, () => unawaited(wake()));
    }
  }

  Future<void> stopForDeletion() async {
    deleting = true;
    _timer?.cancel();
    changed();
    await _running;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

class DeletionController extends ChangeNotifier {
  DeletionController(this.worker);
  final SyncWorker worker;
  KodoRepository get repo => worker.repo;
  SecretStore get store => worker.identity.store;
  String? message;
  bool busy = false;
  void clearMessage() {
    if (message != null) {
      message = null;
      notifyListeners();
    }
  }

  Future<void> recover() async {
    try {
      final marker = await store.read('deletion');
      if (marker != null || (await repo.meta())?['deletion_pending'] == 1) {
        await resume();
      }
    } catch (_) {
      message = '删除状态读取失败，数据与凭据已保留。';
      notifyListeners();
    }
  }

  Future<void> begin() async {
    await repo.setMeta('deletion_pending', 1);
    await resume();
  }

  Future<void> cancelWaiting() async {
    if (busy || await store.read('deletion') != null) {
      throw const DomainError('删除已经进入发送阶段，不能取消');
    }
    await repo.setMeta('deletion_pending', 0);
    worker.deleting = false;
    message = null;
    notifyListeners();
  }

  Future<void> resume() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      await worker.stopForDeletion();
      final raw = await store.read('deletion');
      Json? marker = raw == null ? null : jsonDecode(raw) as Json;
      if (marker == null) {
        final meta = await repo.meta();
        if (meta?['registration_attempted'] == 1 && worker.identity.orphaned) {
          throw const DomainError('数据库与凭据不匹配，无法确认此数据库的云端删除；本机数据仍保留。');
        }
        final mustDelete =
            meta?['registration_attempted'] == 1 || worker.identity.orphaned;
        final secret = await store.read('identity');
        if (mustDelete && secret == null) {
          throw const DomainError('凭据丢失，无法确认云端删除。本机数据仍保留，请先导出。');
        }
        marker = {
          'stage': mustDelete ? 'sending' : 'remote_deleted',
          if (secret != null) 'identity': jsonDecode(secret),
        };
        await store.write('deletion', jsonEncode(marker));
      }
      if (marker['stage'] == 'sending') {
        final id = Identity.decode(jsonEncode(marker['identity']));
        final response = await worker.api.delete(id);
        if (response.status != 204) {
          throw const DomainError('待联网完成删除；凭据与删除意图已保留。');
        }
        marker = {'stage': 'remote_deleted'};
        await store.write('deletion', jsonEncode(marker));
      }
      if (marker['stage'] != 'remote_deleted') {
        throw const DomainError('删除状态异常，已保留数据。');
      }
      await repo.clearLocal();
      await store.remove('identity');
      await store.remove('deletion');
      worker.identity.identity = null;
      await worker.identity.open();
      await worker.load();
      worker.registered = false;
      worker.blocked = false;
      worker.updated = false;
      worker.errorCode = null;
      worker.deleting = false;
      worker.changed();
      message = '全部数据已删除';
    } catch (e) {
      message = e is DomainError ? e.message : '待联网完成删除；数据、凭据与删除意图已保留。';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
