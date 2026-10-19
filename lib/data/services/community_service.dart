import '../../core/services/api_client.dart';

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

  Future<PaginatedPosts> getPosts({
    int page = 1,
    int limit = 20,
    String? tag,
    String? search,
  }) async {
    final response = await _apiClient.get('/community/posts', queryParameters: {
      'page': page,
      'limit': limit,
      if (tag != null && tag.isNotEmpty) 'tag': tag,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    final posts = _extractPosts(response.data).map(_normalizePost).toList();
    final pagination = _extractPagination(response.data);
    final totalPages = _readInt(pagination['pages'] ?? pagination['totalPages'], 1);
    final total = _readInt(pagination['total'], posts.length);

    return PaginatedPosts(
      posts: posts,
      page: _readInt(pagination['page'], page),
      limit: _readInt(pagination['limit'], limit),
      total: total,
      totalPages: totalPages,
      hasMore: pagination.isNotEmpty ? page < totalPages : posts.length >= limit,
    );
  }

  Future<List<Map<String, dynamic>>> getPostsList({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await getPosts(page: page, limit: limit);
    return result.posts;
  }

  /// Most-used hashtags of the last 30 days: [{tag: '#cricket', posts: 12}].
  Future<List<Map<String, dynamic>>> getTrendingTags({int limit = 10}) async {
    final response = await _apiClient.get('/community/trending-tags', queryParameters: {'limit': limit});
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! List) return [];
    return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Future<Map<String, dynamic>> getPostById(String id) async {
    final response = await _apiClient.get('/community/posts/$id');
    final post = _extractPost(response.data);
    return post == null ? {} : _normalizePost(post);
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData) async {
    final response = await _apiClient.post('/community', data: postData);
    final post = _extractPost(response.data);
    return post == null ? {} : _normalizePost(post);
  }

  Future<Map<String, dynamic>> updatePost(String id, Map<String, dynamic> postData) async {
    final response = await _apiClient.put('/community/$id', data: postData);
    final post = _extractPost(response.data);
    return post == null ? {} : _normalizePost(post);
  }

  Future<void> deletePost(String id) async {
    await _apiClient.delete('/community/$id');
  }

  Future<Map<String, dynamic>> likePost(String postId) async {
    final response = await _apiClient.post('/community/$postId/like');
    final post = _extractPost(response.data);
    return post == null ? {} : _normalizePost(post);
  }

  Future<Map<String, dynamic>> sharePost(String postId) async {
    final response = await _apiClient.post('/community/$postId/share');
    final post = _extractPost(response.data);
    return post == null ? {} : _normalizePost(post);
  }

  Future<List<Map<String, dynamic>>> getComments(String postId, {int page = 1, int limit = 20}) async {
    final post = await getPostById(postId);
    final comments = post['commentItems'] ?? post['comments'];
    if (comments is List) {
      return comments.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> addComment(String postId, Map<String, dynamic> commentData) async {
    final response = await _apiClient.post('/community/$postId/comments', data: commentData);
    final post = _extractPost(response.data);
    return post == null ? {} : _normalizePost(post);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _apiClient.delete('/community/$postId/comments/$commentId');
  }

  Future<void> reportPost(String postId, Map<String, dynamic> reportData) async {
    await _apiClient.post('/community/$postId/report', data: reportData);
  }

  List<Map<String, dynamic>> _extractPosts(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const ['data', 'posts', 'items', 'results', 'docs']) {
        final value = map[key];
        if (value is List) {
          return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
        if (value is Map) {
          final nested = _extractPosts(value);
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return [];
  }

  Map<String, dynamic>? _extractPost(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const ['data', 'post', 'item', 'result']) {
        final value = map[key];
        if (value is Map) return Map<String, dynamic>.from(value);
      }
      return map;
    }
    return null;
  }

  Map<String, dynamic> _extractPagination(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final pagination = map['pagination'];
      if (pagination is Map) return Map<String, dynamic>.from(pagination);
      final nested = map['data'];
      if (nested is Map && nested['pagination'] is Map) {
        return Map<String, dynamic>.from(nested['pagination'] as Map);
      }
    }
    return {};
  }

  Map<String, dynamic> _normalizePost(Map<String, dynamic> post) {
    final user = post['user'] is Map ? Map<String, dynamic>.from(post['user'] as Map) : null;
    final imageUrls = <String>[];

    final image = post['image'];
    if (image is Map && (image['url']?.toString().isNotEmpty ?? false)) {
      imageUrls.add(image['url'].toString());
    } else if (image is String && image.isNotEmpty) {
      imageUrls.add(image);
    }

    final images = post['images'];
    if (images is List) {
      for (final item in images) {
        if (item is Map && (item['url']?.toString().isNotEmpty ?? false)) {
          imageUrls.add(item['url'].toString());
        } else if (item is String && item.isNotEmpty) {
          imageUrls.add(item);
        }
      }
    }

    final likes = post['likes'];
    final comments = post['comments'];
    final authorId = (post['userId'] ?? user?['_id'] ?? user?['id'] ?? '').toString();
    // First non-empty value: posts carry an empty top-level "name" field.
    final userName = [
      post['userName'],
      user?['name'],
      user?['fullName'],
      user?['username'],
      post['name'],
    ].map((v) => v?.toString().trim() ?? '').firstWhere(
          (v) => v.isNotEmpty,
          orElse: () => 'Scores11 User',
        );
    final userAvatar = _readImageUrl(
      post['userAvatar'] ?? post['avatar'] ?? user?['avatar'] ?? user?['profileImage'],
    );
    final timeAgo = _timeAgo(post['createdAt'] ?? post['updatedAt']);

    return {
      ...post,
      'id': (post['_id'] ?? post['id'] ?? '').toString(),
      'authorId': authorId,
      'userId': authorId,
      'userName': userName,
      'user': userName,
      'userAvatar': userAvatar,
      'avatar': userAvatar,
      'content': (post['content'] ?? '').toString(),
      'images': imageUrls.toSet().toList(),
      'likes': _readInt(post['likesCount'], likes is List ? likes.length : _readInt(likes, 0)),
      'comments': _readInt(post['commentsCount'], comments is List ? comments.length : _readInt(comments, 0)),
      'commentItems': comments is List ? comments.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [],
      'shares': _readInt(post['sharesCount'], _readInt(post['shares'], 0)),
      'isLiked': post['isLiked'] == true,
      'isFollowingAuthor': post['isFollowingAuthor'] == true,
      'canFollowAuthor': post['canFollowAuthor'] == true,
      'timeAgo': timeAgo,
      'time': timeAgo,
    };
  }

  String? _readImageUrl(dynamic value) {
    if (value == null) return null;
    final raw = value is Map
        ? (value['url'] ?? value['secureUrl'] ?? value['path'])
        : value;
    final text = raw?.toString().trim() ?? '';
    // Placeholders like "default-avatar-url" are not loadable images.
    return text.startsWith('http') ? text : null;
  }

  int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _timeAgo(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
