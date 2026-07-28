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
    // Check internet connectivity first
    final connectivity = ConnectivityService();
    final isOnline = await connectivity.isConnected();
    if (!isOnline) {
      _logger.w('No internet connection');
      return {
        'success': false,
        'message': 'No Internet Connection. Please check your network.'
      };
    }

    try {
      if (kDebugMode) _logger.i('Register API call');

      final username = email
          .split('@')
          .first
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
          .toLowerCase();

      final response = await _apiClient.post(
        '${ApiConfig.auth}/register',
        data: {
          'email': email,
          'password': password,
          'name':
              name, // FIX: Use 'name' instead of 'fullName' to match backend
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

        // Verify tokens are present before saving
        if (accessToken == null || refreshToken == null) {
          if (kDebugMode) _logger.e('Register response missing tokens');
          return {
            'success': false,
            'message': 'Server error: No authentication tokens received'
          };
        }

        // Save tokens using the API client method
        await _apiClient.setTokens(
            accessToken.toString(), refreshToken.toString());

        if (kDebugMode) _logger.i('Tokens saved successfully');

        final userModel = UserModel.fromJson(userData);
        return {
          'success': true,
          'data': {
            'user': userModel,
            'accessToken': accessToken,
            'refreshToken': refreshToken
          }
        };
      }

      // Handle error responses from server
      final errorMessage =
          response.data?['message'] ?? response.data?['data']?['message'];
      return {
        'success': false,
        'message': errorMessage?.toString() ?? 'Registration failed'
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        _logger
            .e('Register DioException: ${e.type}, ${e.response?.statusCode}');
      }
      if (kDebugMode && e.response?.data != null) {
        _logger.e('Error details: ${e.response?.data}');
      }
      return {'success': false, 'message': _handleDioError(e)};
    } catch (e) {
      if (kDebugMode) _logger.e('Register error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.'
      };
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
      return {
        'success': false,
        'message': 'No Internet Connection. Please check your network.'
      };
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

        final data =
            _convertToMap(responseData is Map ? responseData['data'] : null);
        final userData = _convertToMap(data['user']);

        if (userData.isEmpty) {
          _logger.w('No user data in login response');
        }

        final accessToken = data['accessToken'] ?? data['token'];
        final refreshToken = data['refreshToken'];

        if (accessToken != null && refreshToken != null) {
          await _apiClient.setTokens(
              accessToken.toString(), refreshToken.toString());
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
          'data': {
            'user': userModel,
            'accessToken': accessToken,
            'refreshToken': refreshToken
          }
        };
      }
      return {
        'success': false,
        'message': response.data?['message'] ??
            'Login failed - please check your credentials'
      };
    } on DioException catch (e) {
      if (kDebugMode) _logger.e('Login DioException: ${e.type}');
      return {'success': false, 'message': _handleDioError(e)};
    } catch (e) {
      if (kDebugMode) _logger.e('Login error: $e');
      return {
        'success': false,
        'message': 'An error occurred. Please try again.'
      };
    }
  }

  Future<dynamic> getUserStats() async {
    try {
      if (kDebugMode) _logger.i('Fetching user stats /user/me/stats');
      final response = await _apiClient.get('${ApiConfig.users}/me/stats');

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
      DioExceptionType.receiveTimeout =>
        'Connection timeout. Check internet.',
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

  String? _extractErrorCode(dynamic data) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map && first['code'] != null) {
          return first['code'].toString();
        }
      }
      if (data['code'] != null) return data['code'].toString();
    }
    return null;
  }

  bool _isFirebaseProjectMismatch(String? message) {
    final normalized = message?.toLowerCase() ?? '';
    return normalized.contains('project mismatch') ||
        normalized.contains('incorrect "aud"') ||
        normalized.contains('expected') && normalized.contains('got');
  }

  Future<Map<String, dynamic>> firebasePhoneLogin({
    required String idToken,
    String? name,
    String? email,
    String? role,
    String? playerRole,
    String? battingStyle,
    String? bowlingStyle,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/phone/firebase',
        data: {
          'idToken': idToken,
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
          if (email != null && email.trim().isNotEmpty)
            'email': email.trim().toLowerCase(),
          if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
          if (playerRole != null && playerRole.trim().isNotEmpty)
            'playerRole': playerRole.trim(),
          if (battingStyle != null && battingStyle.trim().isNotEmpty)
            'battingStyle': battingStyle.trim(),
          if (bowlingStyle != null && bowlingStyle.trim().isNotEmpty)
            'bowlingStyle': bowlingStyle.trim(),
        },
      );
      if (response.statusCode == 200) {
        final data = _convertToMap(response.data?['data']);
        final userData = _convertToMap(data['user']);
        final accessToken = data['accessToken'] ?? data['token'];
        final refreshToken = data['refreshToken'];
        if (accessToken == null || refreshToken == null || userData.isEmpty) {
          return {
            'success': false,
            'message': 'Invalid authentication response',
          };
        }
        await _apiClient.setTokens(
          accessToken.toString(),
          refreshToken.toString(),
        );
        return {
          'success': true,
          'data': {
            'user': UserModel.fromJson(userData),
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          },
        };
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'Mobile sign-in failed',
      };
    } on DioException catch (e) {
      final errorCode = _extractErrorCode(e.response?.data);
      final rawMessage = e.response?.data?['message']?.toString();
      final isProjectMismatch = _isFirebaseProjectMismatch(rawMessage);
      return {
        'success': false,
        'message': isProjectMismatch
            ? 'Mobile sign-in is not ready on the server. Please try again after the latest update.'
            : rawMessage ?? _handleDioError(e),
        if (errorCode != null) 'code': errorCode,
      };
    }
  }

  /// Sends (or resends) a login/registration OTP to [email]. Pass [name]
  /// when registering a brand-new account; existing accounts ignore it.
  Future<Map<String, dynamic>> requestEmailOtp({
    required String email,
    String? name,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/email/send-otp',
        data: {
          'email': email.trim().toLowerCase(),
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        },
      );
      if (response.statusCode == 200) {
        final data = _convertToMap(response.data?['data']);
        return {'success': true, 'isNewUser': data['isNewUser'] == true};
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'Failed to send OTP',
      };
    } on DioException catch (e) {
      final errorCode = _extractErrorCode(e.response?.data);
      return {
        'success': false,
        'message': e.response?.data?['message']?.toString() ?? _handleDioError(e),
        if (errorCode != null) 'code': errorCode,
      };
    } catch (e) {
      return {'success': false, 'message': 'Unable to send OTP. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/email/verify-otp',
        data: {'email': email.trim().toLowerCase(), 'otp': otp.trim()},
      );
      if (response.statusCode == 200) {
        final data = _convertToMap(response.data?['data']);
        final userData = _convertToMap(data['user']);
        final accessToken = data['accessToken'] ?? data['token'];
        final refreshToken = data['refreshToken'];
        if (accessToken == null || refreshToken == null || userData.isEmpty) {
          return {'success': false, 'message': 'Invalid authentication response'};
        }
        await _apiClient.setTokens(accessToken.toString(), refreshToken.toString());
        return {
          'success': true,
          'data': {
            'user': UserModel.fromJson(userData),
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          },
        };
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'OTP verification failed',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message']?.toString() ?? _handleDioError(e),
      };
    } catch (e) {
      return {'success': false, 'message': 'Unable to verify OTP. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/forgot-password',
        data: {'identifier': identifier},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': {'otp': response.data?['data']?['otp']}
        };
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'Request failed'
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String identifier, String otp, String newPassword) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/reset-password',
        data: {
          'identifier': identifier,
          'otp': otp,
          'newPassword': newPassword
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password reset successful'};
      }
      return {
        'success': false,
        'message': response.data?['message'] ?? 'Reset failed'
      };
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
      final response =
          await _apiClient.get('${ApiConfig.users}/me/full-profile');
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
