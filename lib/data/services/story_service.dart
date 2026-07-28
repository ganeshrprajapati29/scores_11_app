import '../../core/services/api_client.dart';

class StoryItem {
  final String id;
  final String userName;
  final String? userAvatar;
  final String caption;
  final String mediaUrl;
  final String mediaType;
  final DateTime createdAt;
  final DateTime expiresAt;

  const StoryItem({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.caption,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : <String, dynamic>{};
    final avatar = user['avatar'] is Map
        ? user['avatar']['url']?.toString()
        : user['avatar']?.toString() ?? user['profileImage']?.toString();
    final media = json['media'] is Map ? Map<String, dynamic>.from(json['media'] as Map) : <String, dynamic>{};
    return StoryItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userName: (user['name'] ?? user['fullName'] ?? json['userName'] ?? 'Scores11 User').toString(),
      userAvatar: avatar,
      caption: (json['caption'] ?? '').toString(),
      mediaUrl: (media['url'] ?? json['mediaUrl'] ?? json['url'] ?? '').toString(),
      mediaType: (json['mediaType'] ?? 'image').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now().add(const Duration(hours: 24)),
    );
  }
}

class StoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<StoryItem>> getActiveStories({int page = 1, int limit = 30}) async {
    final response = await _apiClient.get('/stories', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    final raw = data is Map && data['data'] is List ? data['data'] as List : const [];
    return raw.whereType<Map>().map((item) => StoryItem.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<StoryItem> createStory({
    required String mediaUrl,
    required String mediaType,
    String? publicId,
    String caption = '',
    String? thumbnail,
  }) async {
    final response = await _apiClient.post('/stories', data: {
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'publicId': publicId,
      'caption': caption,
      'thumbnail': thumbnail,
    });
    final data = response.data is Map ? response.data['data'] : null;
    return StoryItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> markViewed(String id) async {
    await _apiClient.post('/stories/$id/view');
  }
}
