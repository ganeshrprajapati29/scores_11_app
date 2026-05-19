import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  // Local storage methods (unchanged)
  static Future<void> saveUserData({
    required String userId,
    String? userName,
    String? userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    if (userName != null) await prefs.setString(_userNameKey, userName);
    if (userEmail != null) await prefs.setString(_userEmailKey, userEmail);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);
    if (userId == null || userId.isEmpty) {
      debugPrint('⚠️ No user ID found, using demo');
      await createDemoUser();
      userId = 'demo_user_123';
    }
    return userId;
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }

  static Future<void> createDemoUser() async {
    await saveUserData(
      userId: 'demo_user_123',
      userName: 'Demo User',
      userEmail: 'demo@example.com',
    );
  }

  List<dynamic> _extractList(dynamic raw, String key) {
    if (raw is List) return raw;
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) return data;
      if (data is Map) {
        final keyed = data[key];
        if (keyed is List) return keyed;
        final nestedData = data['data'];
        if (nestedData is List) return nestedData;
      }
      final keyed = raw[key];
      if (keyed is List) return keyed;
    }
    return const [];
  }

  // NEW: API methods for followers/connections
  Future<Map<String, dynamic>> getFollowers({Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.users}/followers',
        queryParameters: queryParameters,
      );
      return {
        'success': true,
        'data': _extractList(response.data, 'followers'),
        'raw': response.data,
      };
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to load followers: $e');
    }
  }

  Future<Map<String, dynamic>> getFollowing({Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.users}/following',
        queryParameters: queryParameters,
      );
      return {
        'success': true,
        'data': _extractList(response.data, 'following'),
        'raw': response.data,
      };
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to load following: $e');
    }
  }

  Future<Map<String, dynamic>> followUser(String userId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.users}/follow/$userId',
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  Future<Map<String, dynamic>> unfollowUser(String userId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.users}/follow/$userId',
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }
}
