import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/user_model.dart';

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
          if (phone != null) 'phone': phone,
          'role': role,
        },
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'];
        await _apiClient.setTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        return {
          'success': true,
          'data': {
            'user': UserModel.fromJson(data['user']),
            'accessToken': data['accessToken'],
            'refreshToken': data['refreshToken'],
          }
        };
      }
      return {'success': false, 'message': response.data['message'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/login',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _apiClient.setTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        return {
          'success': true,
          'data': {
            'user': UserModel.fromJson(data['user']),
            'accessToken': data['accessToken'],
            'refreshToken': data['refreshToken'],
          }
        };
      }
      return {'success': false, 'message': response.data['message'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
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
        return UserModel.fromJson(response.data['data']);
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
}
