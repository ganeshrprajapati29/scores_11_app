import '../../core/services/api_client.dart';

/// Pagination response wrapper for community posts
class PaginatedPosts {
  final List<Map<String, dynamic>> posts;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  PaginatedPosts({
    required this.posts,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });
}

class CommunityService {
  final ApiClient _apiClient = ApiClient();

  /// Get posts with pagination support
  Future<PaginatedPosts> getPosts({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get('/community/posts', queryParams: {
      'page': page,
      'limit': limit,
    });
    final List<dynamic> data = response['data'] ?? [];
    final pagination = response['pagination'] ?? {};
    
    final posts = List<Map<String, dynamic>>.from(data);
    
    return PaginatedPosts(
      posts: posts,
      page: pagination['page'] ?? page,
      limit: pagination['limit'] ?? limit,
      total: pagination['total'] ?? data.length,
      totalPages: pagination['pages'] ?? 1,
      hasMore: page < (pagination['pages'] ?? 1),
    );
  }

  /// Legacy method for backward compatibility
  Future<List<Map<String, dynamic>>> getPostsList({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await getPosts(page: page, limit: limit);
    return result.posts;
  }

  Future<Map<String, dynamic>> getPostById(String id) async {
    final response = await _apiClient.get('/community/posts/$id');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData) async {
    final response = await _apiClient.post('/community/posts', postData);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> updatePost(String id, Map<String, dynamic> postData) async {
    final response = await _apiClient.put('/community/posts/$id', postData);
    return response['data'] ?? {};
  }

  Future<void> deletePost(String id) async {
    await _apiClient.delete('/community/posts/$id');
  }

  Future<void> likePost(String postId) async {
    await _apiClient.post('/community/posts/$postId/like');
  }

  Future<void> unlikePost(String postId) async {
    await _apiClient.delete('/community/posts/$postId/like');
  }

  Future<List<Map<String, dynamic>>> getComments(String postId, {int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/community/posts/$postId/comments', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> addComment(String postId, Map<String, dynamic> commentData) async {
    final response = await _apiClient.post('/community/posts/$postId/comments', commentData);
    return response['data'] ?? {};
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _apiClient.delete('/community/posts/$postId/comments/$commentId');
  }

  Future<void> reportPost(String postId, Map<String, dynamic> reportData) async {
    await _apiClient.post('/community/posts/$postId/report', reportData);
  }

  Future<void> sharePost(String postId) async {
    await _apiClient.post('/community/posts/$postId/share');
  }

  Future<List<Map<String, dynamic>>> getReportedPosts({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/community/reported', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> moderatePost(String postId, String action) async {
    await _apiClient.post('/community/moderate/$postId', {'action': action});
  }
}

