import 'package:dio/dio.dart';
import '../models/live_stream_model.dart';
import '../../core/config/api_config.dart';

class LiveStreamService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Map<String, dynamic>> getLiveStreams({
    String? status,
    String? category,
    String? streamType,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get('/live-streams', queryParameters: {
        if (status != null) 'status': status,
        if (category != null) 'category': category,
        if (streamType != null) 'streamType': streamType,
        if (search != null) 'search': search,
        'page': page,
        'limit': limit,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFeaturedStreams({int limit = 10}) async {
    try {
      final response = await _dio.get('/live-streams/featured', queryParameters: {
        'limit': limit,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLiveStreamById(String streamId) async {
    try {
      final response = await _dio.get('/live-streams/$streamId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createLiveStream(Map<String, dynamic> streamData) async {
    try {
      final response = await _dio.post('/live-streams', data: streamData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateLiveStream(String streamId, Map<String, dynamic> updateData) async {
    try {
      final response = await _dio.put('/live-streams/$streamId', data: updateData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteLiveStream(String streamId) async {
    try {
      final response = await _dio.delete('/live-streams/$streamId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> startLiveStream(String streamId) async {
    try {
      final response = await _dio.post('/live-streams/$streamId/start');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> endLiveStream(String streamId) async {
    try {
      final response = await _dio.post('/live-streams/$streamId/end');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> joinLiveStream(String streamId) async {
    try {
      final response = await _dio.post('/live-streams/$streamId/join');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> leaveLiveStream(String streamId) async {
    try {
      final response = await _dio.post('/live-streams/$streamId/leave');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendChatMessage(String streamId, String message) async {
    try {
      final response = await _dio.post('/live-streams/$streamId/chat', data: {
        'message': message,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> likeLiveStream(String streamId) async {
    try {
      final response = await _dio.post('/live-streams/$streamId/like');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyStreams({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get('/live-streams/my/streams', queryParameters: {
        'page': page,
        'limit': limit,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Parse helpers
  LiveStreamModel parseLiveStream(Map<String, dynamic> json) {
    return LiveStreamModel.fromJson(json['data'] ?? json);
  }

  List<LiveStreamModel> parseLiveStreams(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is List) {
      return data.map((e) => LiveStreamModel.fromJson(e)).toList();
    } else if (data is Map && data['docs'] != null) {
      return (data['docs'] as List).map((e) => LiveStreamModel.fromJson(e)).toList();
    }
    return [];
  }
}
