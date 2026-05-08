import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/services/connectivity_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  static final Logger _logger = Logger();

  static Future<String?> getToken() async {
    final instance = ApiClient();
    return await instance.getAccessToken();
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String role = 'user',
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
    String? dateOfBirth,
    String? nationality,
  }) async {
    try {
      if (kDebugMode) _logger.i('Register API call');
      
      final username = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
      
      final response = await _apiClient.post(
        '${ApiConfig.auth}/register',
        data: {
          'email': email,
          'password': password,
          'fullName': name,
          'username': username,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'role': role,
          if (role == 'player') ...{
            'playerRole': playerRole ?? 'batsman',
            'battingStyle': battingStyle ?? 'right-hand bat',
            'bowlingStyle': bowlingStyle ?? 'none',
            if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
            'nationality': nationality ?? 'India',
          },
        },
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = _convertToMap(response.data?['data']);
        final userData = _convertToMap(data['user']);
        final accessToken = data['accessToken'] ?? data['token'];
        final refreshToken = data['refreshToken'];
        
        if (accessToken != null && refreshToken != null) {
          await _apiClient.setTokens(accessToken.toString(), refreshToken.toString());
        }
        
        final userModel = UserModel.fromJson(userData);
        return {
          'success': true,
          'data': {'user': userModel, 'accessToken': accessToken, 'refreshToken': refreshToken}
        };
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Registration failed'};
    } on DioException catch (e) {
      if (kDebugMode) _logger.e('Register DioException: ${e.type}, ${e.response?.statusCode}');
      return {'success': false, 'message': _handleDioError(e)};
    } catch (e) {
      if (kDebugMode) _logger.e('Register error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Map<String, dynamic> _convertToMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is Map<dynamic, dynamic>) return Map<String, dynamic>.from(data);
    return {};
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final connectivity = ConnectivityService();
    final isOnline = await connectivity.isConnected();
    if (!isOnline) {
      _logger.w('No internet connection');
      return {'success': false, 'message': 'No Internet Connection. Please check your network.'};
    }

    try {
      if (kDebugMode) _logger.i('Login API call to ${ApiConfig.auth}/login');
      final response = await _apiClient.post(
        '${ApiConfig.auth}/login',
        data: {'identifier': identifier, 'password': password},
      );
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData == null) {
          return {'success': false, 'message': 'Empty server response'};
        }
        
        final data = _convertToMap(responseData is Map ? responseData['data'] : null);
        final userData = _convertToMap(data['user']);
        
        if (userData.isEmpty) {
          _logger.w('No user data in login response');
        }
        
        final accessToken = data['accessToken'] ?? data['token'];
        final refreshToken = data['refreshToken'];
        
        if (accessToken != null && refreshToken != null) {
          await _apiClient.setTokens(accessToken.toString(), refreshToken.toString());
        }
        
        UserModel? userModel;
        try {
          if (userData.isNotEmpty) {
            userModel = UserModel.fromJson(userData);
          }
        } catch (e) {
          _logger.w('Failed to parse user model: $e');
        }
        
        return {
          'success': true,
          'data': {'user': userModel, 'accessToken': accessToken, 'refreshToken': refreshToken}
        };
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Login failed - please check your credentials'};
    } on DioException catch (e) {
      if (kDebugMode) _logger.e('Login DioException: ${e.type}');
      return {'success': false, 'message': _handleDioError(e)};
    } catch (e) {
      if (kDebugMode) _logger.e('Login error: $e');
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }
  
  Future<dynamic> getUserStats() async {
    if (!kDebugMode) return null;
    
    try {
      if (kDebugMode) _logger.i('Fetching user stats /me/stats');
      final response = await _apiClient.get('/me/stats');
      
      if (response.statusCode == 200) {
        final data = response.data is Map ? response.data['data'] : null;
        if (kDebugMode) _logger.i('User stats OK');
        return data;
      }
      return null;
    } on DioException catch (e) {
      if (kDebugMode && e.response?.statusCode != 404) {
        _logger.w('Stats error: ${e.type} (${e.response?.statusCode})');
      }
      return null;
    } catch (e) {
      if (kDebugMode) _logger.w('Stats error: $e');
      return null;
    }
  }

  String _handleDioError(DioException e) {
    if (kDebugMode) {
      _logger.w('DioError: ${e.type} | ${e.message}');
      if (e.response != null) _logger.w('Response: ${e.response!.statusCode}');
    }
    
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'Connection timeout. Check internet.',
      DioExceptionType.badResponse => (e.response?.statusCode == 401 
        ? 'Invalid credentials' 
        : e.response?.statusCode == 404 
        ? 'Server not found' 
        : e.response?.statusCode == 500 
        ? 'Server error' 
        : e.response?.data?['message']?.toString() ?? 'Server error'),
      DioExceptionType.cancel => 'Request cancelled',
      DioExceptionType.connectionError => 'No internet connection',
      _ => e.message ?? 'Network error',
    };
  }

  Future<Map<String, dynamic>> sendOTP(String identifier) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/send-otp',
        data: {'identifier': identifier},
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': {'otp': response.data?['data']?['otp']}};
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Failed to send OTP'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String identifier, String otp) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/verify-otp',
        data: {'identifier': identifier, 'otp': otp},
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'OTP verified'};
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/forgot-password',
        data: {'identifier': identifier},
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': {'otp': response.data?['data']?['otp']}};
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Request failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String identifier, String otp, String newPassword) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/reset-password',
        data: {'identifier': identifier, 'otp': otp, 'newPassword': newPassword},
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password reset successful'};
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Reset failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('${ApiConfig.auth}/logout');
    } catch (e) {
      // Ignore logout API errors
    } finally {
      await _apiClient.clearTokens();
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get('${ApiConfig.auth}/me');
      if (response.statusCode == 200) {
        final userData = _convertToMap(response.data?['data']);
        return UserModel.fromJson(userData);
      }
      throw Exception(response.data?['message'] ?? 'Failed to get user');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      if (response.statusCode != 200) {
        throw Exception(response.data?['message'] ?? 'Change password failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  Future<Map<String, dynamic>> getUserProfileWithStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.auth}/profile');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': _convertToMap(response.data?['data']),
        };
      }
      return {'success': false, 'message': 'Profile fetch failed'};
    } catch (e) {
      _logger.w('Profile stats error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
