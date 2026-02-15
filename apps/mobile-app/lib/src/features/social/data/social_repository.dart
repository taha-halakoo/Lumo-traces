import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.read(apiClientProvider));
});

class SocialRepository {
  final Dio _dio;
  SocialRepository(this._dio);

  Future<List<dynamic>> getFriends() async {
    final response = await _dio.get('/users/friends');
    return response.data as List<dynamic>;
  }

  Future<void> sendRequest(String targetId) async {
    await _dio.post('/users/requests', data: {'targetId': targetId});
  }
}
