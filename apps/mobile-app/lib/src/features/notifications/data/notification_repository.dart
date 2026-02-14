import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiClientProvider));
});

class NotificationRepository {
  final Dio _dio;
  NotificationRepository(this._dio);

  Future<List<dynamic>> getNotifications() async {
    final response = await _dio.get('/notifications');
    return response.data as List<dynamic>;
  }

  Future<void> markAsRead(String id) async {
    await _dio.post('/notifications/$id/read');
  }
}
