import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/api_client.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  final ApiClient _apiClient = ApiClient();

  /// Active messages for the home page ticker/slider, admin-posted.
  Future<List<Announcement>> getActiveAnnouncements() async {
    try {
      final response = await _apiClient.get('/announcements/active');

      if (response.statusCode == 200) {
        final raw = response.data;
        final List<dynamic> data = raw is List
            ? raw
            : raw is Map && raw['data'] is List
                ? raw['data'] as List
                : const [];
        return data.map((json) => Announcement.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('AnnouncementService error: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('AnnouncementService unexpected error: $e');
      return [];
    }
  }
}
