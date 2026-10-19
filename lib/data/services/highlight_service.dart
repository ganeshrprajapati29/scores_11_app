import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/services/api_client.dart';
import '../models/highlight_model.dart';

/// Mirrors backend/src/modules/highlight/highlight.routes.js
class HighlightService {
  final ApiClient _apiClient = ApiClient();

  Future<({List<HighlightModel> items, bool hasMore})> getHighlights({
    String? matchId,
    String? userId,
    String? kind,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get('/highlights', queryParameters: {
      'page': page,
      'limit': limit,
      if (matchId != null && matchId.isNotEmpty) 'matchId': matchId,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (kind != null) 'kind': kind,
    });
    final data = response.data['data'];
    final results = data is Map ? data['results'] : null;
    final items = results is List
        ? results
            .whereType<Map>()
            .map((e) => HighlightModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <HighlightModel>[];
    final totalPages = data is Map ? (data['totalPages'] as num?)?.toInt() ?? 1 : 1;
    return (items: items, hasMore: page < totalPages);
  }

  Future<HighlightModel> addYoutubeHighlight({
    required String title,
    required String youtubeUrl,
    String? description,
    String? matchId,
  }) async {
    final response = await _apiClient.post('/highlights', data: {
      'title': title,
      'youtubeUrl': youtubeUrl,
      if (description != null && description.isNotEmpty) 'description': description,
      if (matchId != null && matchId.isNotEmpty) 'matchId': matchId,
    });
    return HighlightModel.fromJson(Map<String, dynamic>.from(response.data['data']));
  }

  Future<HighlightModel> uploadHighlight({
    required String title,
    required File video,
    String? description,
    String? matchId,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      if (matchId != null && matchId.isNotEmpty) 'matchId': matchId,
      'video': await MultipartFile.fromFile(
        video.path,
        filename: video.path.split(Platform.pathSeparator).last,
      ),
    });
    final response = await _apiClient.uploadFile(
      '/highlights',
      formData: formData,
      onSendProgress: onProgress,
      // Video upload + server-side transcode can take minutes.
      timeout: const Duration(minutes: 5),
    );
    return HighlightModel.fromJson(Map<String, dynamic>.from(response.data['data']));
  }

  Future<void> recordView(String id) async {
    try {
      await _apiClient.post('/highlights/$id/view');
    } catch (_) {
      // View counts are best-effort.
    }
  }

  Future<({bool isLiked, int likeCount})> toggleLike(String id) async {
    final response = await _apiClient.post('/highlights/$id/like');
    final data = response.data['data'] as Map;
    return (
      isLiked: data['isLiked'] == true,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> deleteHighlight(String id) async {
    await _apiClient.delete('/highlights/$id');
  }
}
