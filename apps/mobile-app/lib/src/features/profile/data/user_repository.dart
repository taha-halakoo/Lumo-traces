import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/api/api_client.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(apiClientProvider));
});

class UserRepository {
  final Dio _dio;
  final Box _profileBox = Hive.box('profile');
  final Box _settingsBox = Hive.box('settings');

  UserRepository(this._dio);

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/users/me');
      await _profileBox.put('me', response.data);
      return response.data;
    } catch (e) {
      return Map<String, dynamic>.from(_profileBox.get('me', defaultValue: {}));
    }
  }

  Future<List<dynamic>> getLeaderboard({String? scope, String? timeframe}) async {
    final Map<String, dynamic> query = {};
    if (scope != null) query['scope'] = scope.toLowerCase();
    if (timeframe != null) query['timeframe'] = timeframe.toLowerCase();
    
    final response = await _dio.get('/users/leaderboard', queryParameters: query);
    return response.data;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.put('/users/me', data: data);
    final current = Map<String, dynamic>.from(_profileBox.get('me', defaultValue: {}));
    await _profileBox.put('me', {...current, ...data});
  }

  Future<Map<String, dynamic>> getProfile(String id) async {
    final response = await _dio.get('/users/$id');
    return response.data;
  }

  Future<List<dynamic>> getUserTraces(String id) async {
    final response = await _dio.get('/traces/user/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _dio.get('/users/settings');
      await _settingsBox.putAll(response.data);
      return response.data;
    } catch (e) {
      return Map<String, dynamic>.from(_settingsBox.toMap());
    }
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await _dio.put('/users/settings', data: data);
    await _settingsBox.putAll(data);
  }

  Future<void> follow(String targetId) async {
    await _dio.post('/users/follow', data: {'targetId': targetId});
  }

  Future<void> unfollow(String targetId) async {
    await _dio.post('/users/unfollow', data: {'targetId': targetId});
  }

  Future<bool> getFollowStatus(String targetId) async {
    final response = await _dio.get('/users/follow/$targetId');
    return response.data['isFollowing'];
  }

  Future<Map<String, dynamic>> getDiscovery({double? lat, double? long}) async {
    final Map<String, dynamic> query = {};
    if (lat != null) query['lat'] = lat;
    if (long != null) query['long'] = long;
    
    final response = await _dio.get('/traces/discovery', queryParameters: query);
    return response.data;
  }

  Future<List<dynamic>> getFriends() async {
    final response = await _dio.get('/users/friends');
    return response.data;
  }
}
