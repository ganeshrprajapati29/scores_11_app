import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/api_client.dart';
import '../models/banner_model.dart';

class BannerService {
  final ApiClient _apiClient = ApiClient();

  /// Get active banners for dashboard (position: 'home')
  Future<List<Banner>> getDashboardBanners() async {
    try {
      final response = await _apiClient.get('/banners/public/home');

      if (response.statusCode == 200) {
        final raw = response.data;
        final List<dynamic> data = raw is List
            ? raw
            : raw is Map && raw['data'] is List
                ? raw['data'] as List
                : const [];
        return data.map((json) => Banner.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('BannerService error: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('BannerService unexpected error: $e');
      return [];
    }
  }
}
