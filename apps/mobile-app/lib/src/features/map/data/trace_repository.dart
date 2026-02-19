import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final traceRepositoryProvider = Provider<TraceRepository>((ref) {
  return TraceRepository(ref.read(apiClientProvider));
});

class TraceRepository {
  final Dio _dio;

  TraceRepository(this._dio);

  Future<List<dynamic>> getNearby(double lat, double long, {double radius = 500}) async {
    try {
      final response = await _dio.get('/traces/nearby', queryParameters: {
        'lat': lat,
        'long': long,
        'radius': radius,
      });
      return response.data as List<dynamic>;
    } catch (e) {
      print("Get Nearby Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> getInBounds(double minLat, double maxLat, double minLong, double maxLong) async {
    try {
      final response = await _dio.get('/traces/bounds', queryParameters: {
        'minLat': minLat,
        'maxLat': maxLat,
        'minLong': minLong,
        'maxLong': maxLong,
      });
      return response.data as List<dynamic>;
    } catch (e) {
      print("Get Bounds Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> search(String query, double lat, double long) async {
    try {
      // Use the 'nearby' endpoint which supports text search (AI)
      final response = await _dio.get('/traces/nearby', queryParameters: {
        'searchText': query,
        'lat': lat,
        'long': long,
        'radius': 5000, // Widen search radius
      });
      return response.data as List<dynamic>;
    } catch (e) {
      print("Search Error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> createTrace(Map<String, dynamic> data) async {
    final response = await _dio.post('/traces', data: data);
    return response.data;
  }

  Future<List<dynamic>> getMyTraces() async {
    final response = await _dio.get('/traces/me');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getTraceDetails(String id) async {
    final response = await _dio.get('/traces/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> unlockTrace(String id, double lat, double long) async {
    final response = await _dio.post('/traces/$id/unlock', data: {
      'lat': lat,
      'long': long,
    });
    return response.data;
  }

  Future<void> likeTrace(String id) async {
    await _dio.post('/traces/$id/like');
  }

  Future<void> commentTrace(String id, String content) async {
    await _dio.post('/traces/$id/comment', data: {'content': content});
  }
}
