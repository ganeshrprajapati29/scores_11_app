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
      return blogs.isNotEmpty ? blogs : _getFallbackBlogs();
    } on DioException catch (e) {
      debugPrint('BlogService error: ${e.message}');
      return _getFallbackBlogs();
    } catch (e) {
      debugPrint('BlogService error: $e');
      return _getFallbackBlogs();
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

  List<BlogModel> _getFallbackBlogs() {
    return [
      BlogModel(
        id: 'fallback1',
        title: 'IPL 2024 Preview',
        author: 'Scores11 Team',
        excerpt: 'Get ready for the biggest cricket festival with fresh updates and match insights.',
        content: 'Get ready for the biggest cricket festival with fresh updates, match insights, and team analysis from Scores11.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      BlogModel(
        id: 'fallback2',
        title: 'T20 World Cup Analysis',
        author: 'Scores11 Team',
        excerpt: 'Complete analysis of the tournament, key players, and winning strategies.',
        content: 'Complete analysis of the tournament, key players, and winning strategies for cricket fans.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}
