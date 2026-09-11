import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  final FlutterSecureStorage storage;
  late final Dio dio;

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:8000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

  ApiClient({FlutterSecureStorage? storageOverride}) : storage = storageOverride ?? const FlutterSecureStorage() {
    final configuredBaseUrl = const String.fromEnvironment('API_BASE_URL');
    final baseUrl = configuredBaseUrl.isNotEmpty ? configuredBaseUrl : _defaultBaseUrl();

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: _accessKey);
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401 || error.requestOptions.path.endsWith('/auth/refresh')) {
          handler.next(error); return;
        }
        final refresh = await storage.read(key: _refreshKey);
        if (refresh == null) { handler.next(error); return; }
        try {
          final response = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post('/auth/refresh', data: {'refresh_token': refresh});
          final token = response.data['access_token'] as String;
          await storage.write(key: _accessKey, value: token);
          error.requestOptions.headers['Authorization'] = 'Bearer $token';
          handler.resolve(await dio.fetch(error.requestOptions));
        } catch (_) { handler.next(error); }
      },
    ));
  }

  static AuthException mapError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) return AuthException(data['message'] as String);
    if (data is Map && data['detail'] is String) return AuthException(data['detail'] as String);
    if (data is Map && data.values.isNotEmpty && data.values.first is List) {
      final messages = data.values.first as List;
      if (messages.isNotEmpty) return AuthException(messages.first.toString());
    }
    switch (error.response?.statusCode) {
      case 401: return const AuthException('Your session has expired.');
      case 409: return const AuthException('An account with this email already exists.');
      case 422: return const AuthException('Some fields are invalid.');
      default: return const AuthException('A network error occurred. Please try again.');
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}