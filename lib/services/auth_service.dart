import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ghanaserve/models/auth_models.dart';
import 'package:ghanaserve/services/api_client.dart';

class AuthService {
  static const _userKey = 'current_user';
  final ApiClient _api;

  AuthService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<AuthResult> signUp(SignUpRequest request) =>
      _request('/auth/register', request.toJson());
  Future<AuthResult> signIn(SignInRequest request) =>
      _request('/auth/login', request.toJson());
  Future<AuthResult> signInAsAdmin(SignInRequest request) =>
      _request('/auth/admin-login', request.toJson());
  Future<AuthResult> signInWithGhanaCard(GhanaCardSignInRequest request) =>
      _request('/auth/login/ghana-card', request.toJson());

  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      await _api.dio.post('/auth/reset-password', data: request.toJson());
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<CitizenUser> verifyAccount(VerifyAccountRequest request) async {
    try {
      final response =
          await _api.dio.post('/auth/verify-account', data: request.toJson());
      final user =
          CitizenUser.fromJson(Map<String, dynamic>.from(response.data));
      await _persistUser(user);
      return user;
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<AuthResult> _request(String path, Map<String, dynamic> data) async {
    try {
      final response = await _api.dio.post(path, data: data);
      final result =
          AuthResult.fromJson(Map<String, dynamic>.from(response.data));
      await _persistSession(result);
      return result;
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<CitizenUser> updateUser(CitizenUser user) async {
    try {
      final response = await _api.dio.patch('/auth/me', data: user.toJson());
      final updated =
          CitizenUser.fromJson(Map<String, dynamic>.from(response.data));
      await _persistUser(updated);
      return updated;
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {
    try {
      await _api.dio.post('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword
      });
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> signOut() async {
    try {
      final refresh = await _api.storage.read(key: 'refresh_token');
      await _api.dio.post('/auth/logout', data: {'refresh_token': refresh});
    } catch (_) {}
    await _api.storage.delete(key: 'access_token');
    await _api.storage.delete(key: 'refresh_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<CitizenUser?> getSessionUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return CitizenUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasValidSession() async =>
      await _api.storage.read(key: 'access_token') != null;

  Future<void> _persistSession(AuthResult result) async {
    await _api.storage.write(key: 'access_token', value: result.accessToken);
    await _api.storage.write(key: 'refresh_token', value: result.refreshToken);
    await _persistUser(result.user);
  }

  Future<void> _persistUser(CitizenUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
