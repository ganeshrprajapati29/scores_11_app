import '../../core/services/api_client.dart';
import '../../data/models/blog_model.dart';
import 'package:flutter/foundation.dart';

/// Simple service for blog operations
class BlogService {
  final ApiClient _apiClient = ApiClient();

  /// Get recent blogs with pagination
  Future<List<BlogModel>> getBlogs({
    int page = 1,
    int limit = 10,
    bool sortByRecent = true,
  }) async {
    try {
      final response = await _apiClient.get('/blogs', queryParameters: {
        'page': page,
        'limit': limit,
        if (sortByRecent) 'sort': 'createdAt',
      });

      // Compatible with blogs_screen parsing
      List<dynamic> rawBlogs = response.data['data'] ?? 
                              response.data['blogs'] ?? 
                              response.data;

      List<BlogModel> blogs = [];
      for (final item in rawBlogs) {
        if (item is Map<String, dynamic>) {
          try {
            blogs.add(BlogModel.fromJson(item));
          } catch (e) {
            debugPrint('Parse error for blog: $e');
          }
        }
      }
      return blogs;
    } catch (e) {
      debugPrint('BlogService error: $e');
      return [];
    }
  }

  /// Get single blog by ID
  Future<BlogModel?> getBlogById(String id) async {
    try {
      final response = await _apiClient.get('/blogs/$id');
      final data = response.data['data'] ?? response.data;
      if (data is Map<String, dynamic>) {
        return BlogModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Get blog error: $e');
      return null;
    }
  }
}
