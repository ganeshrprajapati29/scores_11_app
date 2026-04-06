import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/banner_model.dart';

class BannerService {
  final ApiClient _apiClient = ApiClient();

  /// Get active banners for dashboard (position: 'home')
  Future<List<Banner>> getDashboardBanners() async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.baseUrl}/banners/public/home',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
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
