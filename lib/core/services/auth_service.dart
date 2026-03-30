
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// import '../api_client.dart';
import '../../data/models/user_model.dart';
import '../../core/config/api_config.dart';
import 'user_service.dart';
import 'api_client.dart' as api_client;

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
static const String _tokenKey = 'access_token';
static const String _refreshTokenKey = 'refresh_token';

  // Save tokens
  static Future<void> saveTokens({
    required String token,
    String? refreshToken,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    // Save user data
    // TODO: Extract real userId from JWT token decode if needed
    await UserService.saveUserData(userId: 'user_from_token');
  }

  // Get access token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Logout
  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await UserService.clearUserData();
  }

  // ADD: Actual login method
  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    // final apiClient = ApiClient();
    final apiClient = api_client.ApiClient();
    try {
      final response = await apiClient.post(
        '${ApiConfig.auth}/login',
        data: {'identifier': identifier, 'password': password},
      );
      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        await saveTokens(
          token: data['data']['accessToken'],
          refreshToken: data['data']['refreshToken'],
        );
      }
      return data;
    } on DioException catch (e) {
      return {'success': false, 'message': apiClient.parseDioError(e)};
    }
  }

  // ADD: Get current user (AuthProvider expects this)
  static Future<UserModel?> getCurrentUser() async {
    // final apiClient = ApiClient();
    final apiClient = api_client.ApiClient();
     
    try {
      final token = await getToken();
      if (token == null) return null;
      
      final response = await apiClient.get('${ApiConfig.users}/me');
      return UserModel.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      debugPrint('Failed to get current user: $e');
      return null;
    }
  }
}
  
  

 