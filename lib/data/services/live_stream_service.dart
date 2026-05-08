import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/live_stream_model.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/services/auth_service.dart';
import 'package:flutter/foundation.dart';

/// Zenstream Live Streaming Service - RTMP/HLS
class LiveStreamService {
  static final ApiClient _apiClient = ApiClient();
  static IO.Socket? _socket;

  /// Zenstream RTMP constants
  static const String zenstreamRtmpServer = r'rtmp://live-ingest-01.vd0.co:1935/livestream';
  static const String zenstreamChatSecret = 'BuQxQfkqRLb6mbkb';

  // Socket callbacks
  static Function(Map<String, dynamic>)? _onNewChatMessage;
  static Function(Map<String, dynamic>)? _onViewerJoined;
  static Function(Map<String, dynamic>)? _onViewerLeft;
  static Function(Map<String, dynamic>)? _onStreamEnded;

  // API Calls
static Future<LiveStreamModel> createStream(Map<String, dynamic> data) async {
    final res = await _apiClient.post('/live-streams', data: data);
    final responseData = res.data;
    debugPrint('📡 createStream FULL response: ${responseData.runtimeType} = $responseData');
    
    // ✅ FIXED: Parse from 'message' field (stream object), not 'data' (success string)
    final Map<String, dynamic>? streamData = responseData['message'];
    if (streamData == null || streamData is! Map<String, dynamic>) {
      debugPrint('❌ Invalid stream data in response[\'message\']: ${streamData.runtimeType}');
      throw Exception('Invalid API response: expected stream object in message field');
    }
    
    if (responseData is String) {
      debugPrint('⚠️ Backend returned string response: $responseData');
      // Parse ID from string (common formats: ID, "created:ID", "ok,ID")
      String streamId = responseData.trim();
      if (streamId.contains(':')) {
        streamId = streamId.split(':').last.trim();
      } else if (streamId.contains(',')) {
        streamId = streamId.split(',').last.trim();
      }
      
      // Create minimal model from input data + extracted ID
      return LiveStreamModel(
        id: streamId,
        userId: data['userId'] ?? '',
        title: data['title'] ?? '',
        description: data['description'],
        streamType: data['streamType'] ?? 'mobile',
        streamQuality: data['streamQuality'] ?? '720p',
        streamKey: streamId,  // Use ID as streamKey temporarily
        status: 'pending',
        viewerCount: 0,
        likes: 0,
        category: 'cricket',
        tags: data['tags'] ?? <String>[],
        isPrivate: data['isPrivate'] ?? false,
        duration: 0,
        lookingFor: List<String>.from(data['lookingFor'] ?? []),
        requirements: data['requirements'],
        isFeatured: false,
        isPremium: false,
        createdAt: DateTime.now(),
      );
    } else {
      // ✅ FIXED: Use response['message'] (actual stream data)
      return LiveStreamModel.fromJson(streamData!);
    }
  }

  static Future<List<LiveStreamModel>> getLiveStreams({String status = 'live', int page = 1}) async {
    final res = await _apiClient.get('/live-streams', queryParameters: {'page': page, 'status': status});
    final data = res.data['data'] ?? res.data;
    final List list = data['results'] ?? [];
    final validated = list.where((item) {
      if (item is! Map) return false;
      final id = item['_id'] ?? item['id'];
      return id != null && id.toString().isNotEmpty;
    }).toList();
    return validated.map((json) => LiveStreamModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  static Future<LiveStreamModel> getStream(String streamId) async {
    final res = await _apiClient.get('/live-streams/$streamId');
    debugPrint('📡 getStream response: ${res.data.runtimeType}');
    final Map<String, dynamic>? streamData = res.data['message'] ?? res.data;
    if (streamData == null || streamData is! Map<String, dynamic>) {
      debugPrint('❌ Invalid getStream data: ${streamData.runtimeType}');
      throw Exception('Invalid stream data format');
    }
    return LiveStreamModel.fromJson(streamData);
  }

  static Future<void> startStream(String streamId) async {
    debugPrint('🎥 Starting Zenstream: $streamId');
    await _apiClient.post('/live-streams/$streamId/start');
    debugPrint('✅ Stream $streamId started (RTMP ready)');
  }

  static Future<void> endStream(String streamId) async {
    debugPrint('🔴 Ending stream: $streamId');
    await _apiClient.post('/live-streams/$streamId/end');
    debugPrint('✅ Stream $streamId ended');
  }

  static Future<void> joinStream(String streamId) async {
    debugPrint('👋 Joining stream: $streamId');
    await _apiClient.post('/live-streams/$streamId/join');
  }

  static Future<void> leaveStream(String streamId) async {
    await _apiClient.post('/live-streams/$streamId/leave');
  }

  static Future<Map<String, dynamic>> sendChatMessage(String streamId, String message) async {
    final res = await _apiClient.post('/live-streams/$streamId/chat', data: {'message': message});
    return res.data['data'] ?? res.data;
  }

  static Future<LiveStreamModel> likeStream(String streamId) async {
    final res = await _apiClient.post('/live-streams/$streamId/like');
    debugPrint('👍 likeStream response: ${res.data.runtimeType}');
    final Map<String, dynamic>? streamData = res.data['message'] ?? res.data;
    if (streamData == null || streamData is! Map<String, dynamic>) {
      debugPrint('❌ Invalid likeStream data: ${streamData.runtimeType}');
      throw Exception('Invalid stream data format');
    }
    return LiveStreamModel.fromJson(streamData);
  }

  // Socket
  static Future<void> initSocket() async {
    final token = await AuthService.getToken();
    _socket = IO.io(ApiConfig.socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setExtraHeaders(token != null ? {'Authorization': token} : {})
        .enableAutoConnect()
        .build());
    
    _socket!.connect();
    _socket!.onConnect((_) => debugPrint('✅ Socket connected'));
    _socket!.on('newChatMessage', (data) => _onNewChatMessage?.call(Map<String, dynamic>.from(data)));
    _socket!.on('viewerJoined', (data) => _onViewerJoined?.call(Map<String, dynamic>.from(data)));
    _socket!.on('viewerLeft', (data) => _onViewerLeft?.call(Map<String, dynamic>.from(data)));
    _socket!.on('streamEnded', (data) => _onStreamEnded?.call(Map<String, dynamic>.from(data)));
  }

  static void joinStreamRoom(String streamId) => _socket?.emit('joinStream', streamId);
  static void leaveStreamRoom(String streamId) => _socket?.emit('leaveStream', streamId);

  static void registerChatCallback(Function(Map<String, dynamic>) callback) => _onNewChatMessage = callback;
  static void registerViewerJoinedCallback(Function(Map<String, dynamic>) callback) => _onViewerJoined = callback;
  static void registerViewerLeftCallback(Function(Map<String, dynamic>) callback) => _onViewerLeft = callback;
  static void registerStreamEndedCallback(Function(Map<String, dynamic>) callback) => _onStreamEnded = callback;

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}

