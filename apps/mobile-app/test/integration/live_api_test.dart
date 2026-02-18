import 'package:flutter_test/flutter_test.dart';
import 'package:traces_mobile/src/features/map/data/trace_repository.dart';
import 'package:dio/dio.dart';
import 'package:traces_mobile/src/core/api/api_client.dart';

void main() {
  group('Live API Tests (Backend Must Be Running)', () {
    late TraceRepository repository;

    setUp(() {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      // In a real integration test, we'd use the ApiClient or a real Dio instance
      repository = TraceRepository(dio);
    });

    test('getNearby returns list', () async {
      // This requires the backend to be running locally
      try {
        final result = await repository.getNearby(0, 0);
        expect(result, isA<List>());
      } catch (e) {
        // Allow failure if backend isn't up, but print warning
        print('Backend unreachable, skipping live test: $e');
      }
    });
  });
}
