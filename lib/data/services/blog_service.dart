import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/api_client.dart';
import '../models/blog_model.dart';

class BlogService {
  final ApiClient _apiClient = ApiClient();

  Future<List<BlogModel>> getBlogs({
    int page = 1,
    int limit = 10,
    bool sortByRecent = true,
  }) async {
    try {
      final response = await _apiClient.get('/blogs/published', queryParameters: {
        'page': page,
        'limit': limit,
        if (sortByRecent) 'sort': 'createdAt',
      });

      final blogs = _parseBlogList(response.data);
      return blogs;
    } on DioException catch (e) {
      debugPrint('BlogService error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('BlogService error: $e');
      rethrow;
    }
  }

  Future<BlogModel?> getBlogById(String id) async {
    try {
      final response = await _apiClient.get('/blogs/id/$id');
      final data = _extractBlogMap(response.data);
      return data == null ? null : BlogModel.fromJson(data);
    } on DioException catch (e) {
      debugPrint('Get blog error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Get blog error: $e');
      return null;
    }
  }

  List<BlogModel> _parseBlogList(dynamic responseData) {
    final rawBlogs = _extractBlogList(responseData);
    final blogs = <BlogModel>[];

    for (final item in rawBlogs) {
      final map = _asStringMap(item);
      if (map == null) continue;
      try {
        blogs.add(BlogModel.fromJson(map));
      } catch (e) {
        debugPrint('Parse error for blog: $e');
      }
    }

    return blogs;
  }

  List<dynamic> _extractBlogList(dynamic data) {
    if (data is List) return data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final candidates = [
        map['data'],
        map['blogs'],
        map['items'],
        map['results'],
        map['docs'],
      ];

      for (final candidate in candidates) {
        if (candidate is List) return candidate;
        if (candidate is Map) {
          final nested = _extractBlogList(candidate);
          if (nested.isNotEmpty) return nested;
        }
      }
    }

    return const [];
  }

  Map<String, dynamic>? _extractBlogMap(dynamic data) {
    final direct = _asStringMap(data);
    if (direct == null) return null;

    for (final key in const ['data', 'blog', 'item', 'result']) {
      final nested = _asStringMap(direct[key]);
      if (nested != null) return nested;
    }

    return direct;
  }

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
