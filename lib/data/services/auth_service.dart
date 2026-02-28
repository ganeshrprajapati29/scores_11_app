import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          if (phone != null) 'phone': phone,
        },
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'];
        await _apiClient.setTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        return AuthResponse(
          user: User.fromJson(data['user']),
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
      }
      throw Exception(response.data['message'] ?? 'Registration failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.auth}/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _apiClient.setTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        return AuthResponse(
          user: User.fromJson(data['user']),
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
      }
      throw Exception(response.data['message'] ?? 'Login failed');
    } catch (e) {
      rethrow;
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

  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get('${ApiConfig.auth}/me');
      if (response.statusCode == 200) {
        return User.fromJson(response.data['data']);
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

class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}
