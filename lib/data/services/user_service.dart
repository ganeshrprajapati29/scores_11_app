import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import 'auth_service.dart';

class UserService {
  final String baseUrl = ApiConfig.baseUrl;
  
Future<Map<String, dynamic>> getProfile() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to get profile'};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to update profile'};
    }
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(File file) async {
    final token = await AuthService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/avatar'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('avatar', file.path));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to upload photo'};
    }
  }

  Future<Map<String, dynamic>> updateLocation(double lat, double lng) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/users/location'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'latitude': lat,
        'longitude': lng,
      }),
    );
    
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Failed to update location'};
    }
  }

  Future<Map<String, dynamic>> getQRCode() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/qr-code'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to get QR code'};
    }
  }

  Future<Map<String, dynamic>> getProfileStats(String userId) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to get stats'};
    }
  }

  Future<Map<String, dynamic>> getProfileViews() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile-views'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to get profile views'};
    }
  }

  Future<Map<String, dynamic>> getFollowers() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/followers'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to get followers'};
    }
  }

  Future<Map<String, dynamic>> getFollowing() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/following'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to get following'};
    }
  }

  Future<Map<String, dynamic>> followUser(String userId) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/users/follow/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Failed to follow user'};
    }
  }

  Future<Map<String, dynamic>> unfollowUser(String userId) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/users/follow/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Failed to unfollow user'};
    }
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/users/notifications/preferences'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(preferences),
    );
    
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Failed to update preferences'};
    }
  }

  Future<Map<String, dynamic>> updateLanguage(String languageCode) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/users/language'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'language': languageCode}),
    );
    
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Failed to update language'};
    }
  }

  Future<Map<String, dynamic>> getPurchaseHistory() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/purchases'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to get purchase history'};
    }
  }

  Future<Map<String, dynamic>> clearUserData() async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/users/clear-data'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Failed to clear data'};
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/users/account'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Failed to delete account'};
    }
  }

  Future<Map<String, dynamic>> verifyEmail() async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/users/verify-email'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Failed to send verification email'};
    }
  }

  Future<Map<String, dynamic>> getCricketStats() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/cricket-stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to get cricket stats'};
    }
  }

  Future<Map<String, dynamic>> getAchievements() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/achievements'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to get achievements'};
    }
  }

  Future<Map<String, dynamic>> getEquipment() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/users/equipment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {'success': true, 'data': response.body};
    } else {
      return {'success': false, 'message': 'Failed to get equipment'};
    }
  }

  Future<Map<String, dynamic>> updateEquipment(List<Map<String, dynamic>> equipment) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/users/equipment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'equipment': equipment}),
    );
    
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Failed to update equipment'};
    }
  }

  Future<Map<String, dynamic>> updatePlayingStyle(String style) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/users/playing-style'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'playingStyle': style}),
    );
    
    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Failed to update playing style'};
    }
  }
}
