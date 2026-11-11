import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/user_model.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet.';
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        final status = e.response?.statusCode;
        if (data is Map && data['message'] != null) return data['message'].toString();
        if (status == 413) return 'This photo is too large. Please choose a smaller one.';
        return 'Something went wrong on the server. Please try again.';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      default:
        return e.message ?? 'Unknown error';
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.get('${ApiConfig.users}/me');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// [scope]: all | matches | tournaments | practice (profile filter chips).
  Future<Map<String, dynamic>> getFullProfile({String scope = 'all'}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.users}/me/full-profile',
        queryParameters: {'scope': scope},
      );
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('${ApiConfig.users}/me', data: data);
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.uploadFile('${ApiConfig.users}/avatar', formData: formData);
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateLocation(double lat, double lng) async {
    try {
      final response = await _apiClient.put('${ApiConfig.users}/location', data: {
        'latitude': lat,
        'longitude': lng,
      });
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getQRCode() async {
    try {
      final response = await _apiClient.get('${ApiConfig.users}/qr-code');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getProfileStats(String userId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.users}/$userId/stats');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getProfileViews() async {
    try {
      final response = await _apiClient.get('${ApiConfig.users}/profile-views');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getFollowers() async {
    try {
      final response = await _apiClient.get('${ApiConfig.users}/followers');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getFollowing() async {
    try {
      final response = await _apiClient.get('${ApiConfig.users}/following');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> followUser(String userId) async {
    try {
      final response = await _apiClient.post('${ApiConfig.users}/follow/$userId');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> unfollowUser(String userId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.users}/follow/$userId');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    try {
      final response = await _apiClient.put('${ApiConfig.users}/notifications/preferences', data: preferences);
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateLanguage(String languageCode) async {
    try {
      final response = await _apiClient.put('${ApiConfig.users}/language', data: {'language': languageCode});
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getPurchaseHistory() async {
    try {
      final response = await _apiClient.get('${ApiConfig.users}/purchases');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> clearUserData() async {
    try {
      final response = await _apiClient.delete('${ApiConfig.users}/clear-data');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _apiClient.delete('${ApiConfig.users}/account');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> verifyEmail() async {
    try {
      final response = await _apiClient.post('${ApiConfig.users}/verify-email');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getCricketStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.users}/cricket-stats');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getAchievements() async {
    try {
      final response = await _apiClient.get('${ApiConfig.users}/achievements');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getEquipment() async {
    try {
      final response = await _apiClient.get('${ApiConfig.users}/equipment');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateEquipment(List<Map<String, dynamic>> equipment) async {
    try {
      final response = await _apiClient.put('${ApiConfig.users}/equipment', data: {'equipment': equipment});
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updatePlayingStyle(String style) async {
    try {
      final response = await _apiClient.put('${ApiConfig.users}/playing-style', data: {'playingStyle': style});
      return {
        'success': true,
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}

