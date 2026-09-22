import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo_app/core/storage/identity.dart';
import 'package:kodo_app/core/sync/worker.dart';

class CancellableAdapter implements HttpClientAdapter {
  int active = 0, maxActive = 0, cancellations = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'DELETE') {
      expect(
        active,
        0,
        reason: 'Deletion must not overlap a timed-out transport',
      );
      return ResponseBody.fromString('', 204);
    }
    active++;
    if (active > maxActive) maxActive = active;
    final response = Completer<ResponseBody>();
    cancelFuture?.then((_) {
      cancellations++;
      active--;
      response.complete(ResponseBody.fromString('{}', 200));
    });
    return response.future;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'total deadline cancels transport before retry or deletion; completed request timer is cleared',
    () async {
      final adapter = CancellableAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final api = HttpMirrorApi(
        'http://localhost',
        dio: dio,
        requestTimeout: const Duration(milliseconds: 30),
      );
      final id = Identity.generate();
      for (var i = 0; i < 2; i++) {
        await expectLater(
          api.send(id, '{}'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
        expect(adapter.active, 0);
      }
      expect(adapter.maxActive, 1);
      expect(adapter.cancellations, 2);
      expect((await api.delete(id)).status, 204);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(adapter.cancellations, 2);
      dio.close(force: true);
    },
  );
}
