import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/services/connectivity_service.dart';
import '../models/user_model.dart';
import 'dart:developer';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  // Static method to get token (for backward compatibility)
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
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'role': role,
        },
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Safely extract data from response
        final responseData = response.data;
        final data = responseData is Map ? _convertToMap(responseData['data']) : <String, dynamic>{};
        
        // Safely extract user data - handle nested objects properly
        Map<String, dynamic> userData = {};
        final userRaw = data['user'];
        if (userRaw != null) {
          userData = _convertToMap(userRaw);
        }
        
        // Handle both cases: when refreshToken is in data or nested
        final accessToken = data['accessToken'] ?? data['token'];
        final refreshToken = data['refreshToken'] ?? data['refreshToken'];
        
        if (accessToken != null && refreshToken != null) {
          await _apiClient.setTokens(accessToken.toString(), refreshToken.toString());
        }
        
        // Create UserModel from the map
        final userModel = UserModel.fromJson(userData);
        
        return {
          'success': true,
          'data': {
            'user': userModel,
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          }
        };
      }
      return {'success': false, 'message': response.data['message'] ?? 'Registration failed'};
    } on DioException catch (e) {
      debugPrint('❌ REGISTER DioException: type=${e.type}, message=${e.message}, status=${e.response?.statusCode}, response=${e.response?.data}');
      final message = _handleDioError(e);
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('❌ REGISTER Unknown error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Helper method to convert any type to Map<String, dynamic>
  Map<String, dynamic> _convertToMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    // Handle case where data might be from Dio response
    if (data is Map<dynamic, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final connectivityService = ConnectivityService();
    final isOnline = await connectivityService.isConnected();
    if (!isOnline) {
      debugPrint('🚫 LOGIN: No internet connection detected by ConnectivityService');
      return {'success': false, 'message': 'No Internet Connection. Please check your network and try again.'};
    }
    debugPrint('✅ LOGIN: Network available, attempting API call to ${ApiConfig.baseUrl}${ApiConfig.auth}/login');
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        // Safely extract data from response
        final responseData = response.data;
        final data = responseData is Map ? _convertToMap(responseData['data']) : <String, dynamic>{};
        
        // Safely extract user data - handle nested objects properly
        Map<String, dynamic> userData = {};
        final userRaw = data['user'];
        if (userRaw != null) {
          userData = _convertToMap(userRaw);
        }
        
        // Handle both cases: when refreshToken is in data or nested
        final accessToken = data['accessToken'] ?? data['token'];
        final refreshToken = data['refreshToken'] ?? data['refreshToken'];
        
        if (accessToken != null && refreshToken != null) {
          await _apiClient.setTokens(accessToken.toString(), refreshToken.toString());
        }
        
        // Create UserModel from the map
        final userModel = UserModel.fromJson(userData);
        
        return {
          'success': true,
          'data': {
            'user': userModel,
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          }
        };
      }
      return {'success': false, 'message': response.data['message'] ?? 'Login failed'};
    } on DioException catch (e) {
      final message = _handleDioError(e);
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  /// Get user stats with proper error handling and type safety
  Future<dynamic> getUserStats() async {
    try {
      debugPrint('📊 Fetching user stats from API...');
      final response = await _apiClient.get('/user/stats');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        final data = responseData is Map ? responseData['data'] : null;
        
        if (data != null) {
          debugPrint('✅ User stats fetched successfully');
          debugPrint('📊 User stats type: ${data.runtimeType}');
          
          // Return data as-is - let the provider handle the type conversion
          return data;
        } else {
          debugPrint('⚠️ User stats data is null');
          return null;
        }
      } else {
        debugPrint('⚠️ User stats API returned status code: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio error fetching user stats: ${e.type}');
      if (e.response != null) {
        debugPrint('❌ Response status: ${e.response?.statusCode}');
        debugPrint('❌ Response data: ${e.response?.data}');
        
        // If 404, stats endpoint might not exist yet - that's fine
        if (e.response?.statusCode == 404) {
          debugPrint('⚠️ User stats endpoint not found (404) - this is normal if not implemented yet');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error fetching user stats: $e');
      return null;
    }
  }

  // Helper method to handle Dio errors
  String _handleDioError(DioException e) {
    debugPrint('🔍 Handling DioError: ${e.type} | ${e.message}');
    if (e.response != null) {
      debugPrint('📡 Response: ${e.response!.statusCode} - ${e.response!.data}');
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        if (statusCode == 401) {
          return 'Invalid credentials. Please check your email and password.';
        } else if (statusCode == 404) {
          return 'Server not found. Please try again later.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return data?['message'] ?? 'An error occurred';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      default:
        return e.message ?? 'An unexpected error occurred';
    }
  }

  Future<Map<String, dynamic>> sendOTP(String identifier) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/send-otp',
        data: {'identifier': identifier},
      );
      
      if (response.statusCode == 200) {
        // In development, OTP is returned in response
        final otp = response.data['data']?['otp'];
        return {'success': true, 'data': {'otp': otp}};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed to send OTP'};
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
        return {'success': true, 'message': 'OTP verified successfully'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Invalid OTP'};
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
        final otp = response.data['data']?['otp'];
        return {'success': true, 'data': {'otp': otp}};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed to process request'};
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
        return {'success': true, 'message': 'Password reset successfully'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed to reset password'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('${ApiConfig.auth}/logout');
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _apiClient.clearTokens();
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get('${ApiConfig.auth}/me');
      if (response.statusCode == 200) {
        // Safely convert response data to Map
        final userData = _convertToMap(response.data['data']);
        return UserModel.fromJson(userData);
      }
      throw Exception(response.data['message'] ?? 'Failed to get user');
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
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getAccessToken();
    return token != null;
  }
  
  /// Get user profile with stats (combined endpoint if available)
  Future<Map<String, dynamic>> getUserProfileWithStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.auth}/profile');
      if (response.statusCode == 200) {
        final data = _convertToMap(response.data['data']);
        return {
          'success': true,
          'data': data,
        };
      }
      return {'success': false, 'message': 'Failed to get profile'};
    } catch (e) {
      debugPrint('❌ Error getting user profile with stats: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}