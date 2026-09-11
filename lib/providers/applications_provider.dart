import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ghanaserve/models/service_model.dart';
import 'package:ghanaserve/services/api_client.dart';

final applicationsProvider = AsyncNotifierProvider<ApplicationsNotifier, List<CitizenApplication>>(ApplicationsNotifier.new);

class ApplicationsNotifier extends AsyncNotifier<List<CitizenApplication>> {
  static const _cacheVersion = 'v2';
  String? _userId;
  bool _hasLoaded = false;

  @override
  Future<List<CitizenApplication>> build() async => const [];

  Future<void> loadForUser(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _userId == userId && _hasLoaded) return;
    _userId = userId;
    try {
      final response = await ref.read(apiClientProvider).dio.get('/applications/');
      final payload = response.data is Map
          ? (response.data['results'] as List<dynamic>? ?? const [])
          : response.data as List<dynamic>;
      final items = payload
          .map((item) => CitizenApplication.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      state = AsyncData(items);
      _hasLoaded = true;
      await _saveCache(userId, items);
    } on DioException catch (error) {
      final cached = await _readCache(userId);
      if (cached != null) {
        state = AsyncData(cached);
        _hasLoaded = true;
      } else {
        state = AsyncError(ApiClient.mapError(error), StackTrace.current);
      }
    }
  }

  Future<void> addApplication(CitizenApplication application) async => upsertApplication(application);

  Future<void> upsertApplication(CitizenApplication application) async {
    final api = ref.read(apiClientProvider).dio;
    try {
      Response<dynamic> response;
      try {
        response = await api.put(
          '/applications/${application.id}/',
          data: application.toJson(),
        );
      } on DioException catch (error) {
        if (error.response?.statusCode != 404) rethrow;
        response = await api.post('/applications/', data: application.toJson());
      }
      final saved = CitizenApplication.fromJson(Map<String, dynamic>.from(response.data));
      final current = <CitizenApplication>[...(state.valueOrNull ?? const [])];
      final index = current.indexWhere((item) => item.id == saved.id);
      if (index == -1) {
        current.insert(0, saved);
      } else {
        current[index] = saved;
      }
      state = AsyncData(current);
      final userId = _userId;
      if (userId != null) await _saveCache(userId, current);
    } on DioException catch (error) {
      if (application.status != ApplicationStatus.draft) {
        throw ApiClient.mapError(error);
      }
      // Keep an unfinished application visible locally while the API is unavailable.
      final current = <CitizenApplication>[...(state.valueOrNull ?? const [])];
      final index = current.indexWhere((item) => item.id == application.id);
      if (index == -1) {
        current.insert(0, application);
      } else {
        current[index] = application;
      }
      state = AsyncData(current);
      if (_userId != null) await _saveCache(_userId!, current);
    }
  }

  Future<void> uploadDocument({
    required String applicationId,
    required PlatformFile file,
  }) async {
    try {
      final multipart = file.bytes != null
          ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
          : file.path != null
              ? await MultipartFile.fromFile(file.path!, filename: file.name)
              : null;
      if (multipart == null) {
        throw const AuthException('The selected document could not be read.');
      }
      await ref.read(apiClientProvider).dio.post(
        '/applications/documents/',
        data: FormData.fromMap({
          'application': applicationId,
          'name': file.name,
          'file': multipart,
        }),
        options: Options(contentType: Headers.multipartFormDataContentType),
      );
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> deleteApplication(String applicationId) async {
    try {
      await ref.read(apiClientProvider).dio.delete('/applications/$applicationId/');
      state = AsyncData(<CitizenApplication>[...(state.valueOrNull ?? const [])]..removeWhere((item) => item.id == applicationId));
      final userId = _userId;
      if (userId != null) await _saveCache(userId, state.valueOrNull ?? const []);
    } on DioException catch (error) { throw ApiClient.mapError(error); }
  }

  Future<void> _saveCache(String userId, List<CitizenApplication> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'applications_${_cacheVersion}_$userId',
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<CitizenApplication>?> _readCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('applications_${_cacheVersion}_$userId');
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((item) => CitizenApplication.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }
}
