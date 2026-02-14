import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io'; 
import '../../config/app_config.dart';

final apiClientProvider = Provider((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;
  static const String _boxName = 'settings_box';
  static const String _keyUrl = 'backend_url';

  ApiClient() {
    // Force Config URL
    const String savedUrl = AppConfig.apiBaseUrl;

    _dio = Dio(BaseOptions(
      baseUrl: savedUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (response.data['success'] == true) {
          response.data = response.data['data']; 
          return handler.next(response);
        } else {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              error: response.data['error'] ?? 'Unknown Error',
              type: DioExceptionType.badResponse,
            ),
            true 
          );
        }
      },
    ));
  }

  Dio get client => _dio;

  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
    Hive.box(_boxName).put(_keyUrl, url);
  }
}
