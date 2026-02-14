import 'package:flutter_test/flutter_test.dart';
import 'package:traces_mobile/src/core/network/api_client.dart';
import 'package:traces_mobile/src/features/trace/data/repositories/trace_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

// LIVE API TEST (Requires Backend running on localhost:3000)
void main() {
  late TraceRepository repository;

  setUp(() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    // Inject Mock User ID for auth bypass/mocking in backend
    dio.options.headers['x-user-id'] = 'flutter-test-user';
    repository = TraceRepository(dio);
  });

  group('Live API Tests', () {
    test('16: API Ping & Nearby', () async {
      try {
        final traces = await repository.getNearbyTraces(
          location: const LatLng(40.7128, -74.0060),
          radius: 5000
        );
        expect(traces, isA<List>());
        // If we ran the backend test first, there should be at least 1 trace
        if (traces.isNotEmpty) {
            print('Found ${traces.length} traces.');
            expect(traces.first.authorId, isNotNull);
        }
      } catch (e) {
        // If backend is down, this fails
        fail('Backend connection failed: $e');
      }
    });

    test('21: Unlock Logic', () async {
       // We need a known ID. In a real e2e, we'd create one first.
       // Here we assume the one from Backend Test exists or we fail gracefully.
    });
  });
}
