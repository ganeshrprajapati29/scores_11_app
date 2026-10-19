import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/live_stream_model.dart';

class LiveStreamService {
  static final ApiClient _apiClient = ApiClient();
  static IO.Socket? _socket;

  static const String zenstreamRtmpServer =
      r'rtmp://live-ingest-01.vd0.co:1935/livestream';
  static const String zenstreamChatSecret = 'BuQxQfkqRLb6mbkb';

  static Function(Map<String, dynamic>)? _onNewChatMessage;
  static Function(Map<String, dynamic>)? _onViewerJoined;
  static Function(Map<String, dynamic>)? _onViewerLeft;
  static Function(Map<String, dynamic>)? _onStreamEnded;

  static Future<LiveStreamModel> createStream(Map<String, dynamic> data) async {
    final res = await _apiClient.post(
      '/live-streams',
      data: {
        ...data,
        'provider': data['provider'] ?? 'zenstream',
        if ((data['provider'] ?? 'zenstream') != 'youtube')
          'rtmpServer': zenstreamRtmpServer,
      },
    );
    final raw = res.data;
    debugPrint('createStream response: ${raw.runtimeType} = $raw');

    if (raw is String) {
      return _fallbackStreamFromInput(data, _extractId(raw));
    }

    final streamData = _extractStreamMap(raw);
    if (streamData == null) {
      throw Exception('Invalid live stream response from server');
    }

    final stream = LiveStreamModel.fromJson({...data, ...streamData});
    if (stream.id.isEmpty) {
      return _fallbackStreamFromInput(data, _extractId(streamData.toString()));
    }
    return stream;
  }

  static Future<Map<String, dynamic>> getYoutubeStatus() async {
    final res = await _apiClient.get('/live-streams/youtube/status');
    final payload = _extractPayload(res.data);
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return {};
  }

  static Future<String> getYoutubeAuthUrl() async {
    final res = await _apiClient.get('/live-streams/youtube/auth-url');
    final payload = _extractPayload(res.data);
    if (payload is Map) {
      return payload['authUrl']?.toString() ?? '';
    }
    return '';
  }

  static Future<void> disconnectYoutube() async {
    await _apiClient.post('/live-streams/youtube/disconnect');
  }

  static Future<List<LiveStreamModel>> getLiveStreams({
    String status = 'live',
    int page = 1,
    String? matchId,
  }) async {
    final res = await _apiClient.get(
      '/live-streams',
      queryParameters: {
        'page': page,
        'status': status,
        if (matchId != null && matchId.isNotEmpty) 'matchId': matchId,
      },
    );
    final payload = _extractPayload(res.data);
    final dynamic rawList = payload is List
        ? payload
        : payload is Map
            ? payload['results'] ??
                payload['items'] ??
                payload['streams'] ??
                payload['data'] ??
                const []
            : const [];
    final List list = rawList is List ? rawList : const [];

    return list
        .whereType<Map>()
        .map((json) => LiveStreamModel.fromJson(Map<String, dynamic>.from(json)))
        .where((stream) => stream.id.isNotEmpty)
        .toList();
  }

  static Future<LiveStreamModel> getStream(String streamId) async {
    final res = await _apiClient.get('/live-streams/$streamId');
    final streamData = _extractStreamMap(res.data);
    if (streamData == null) {
      throw Exception('Invalid stream data format');
    }
    return LiveStreamModel.fromJson(streamData);
  }

  static Future<void> startStream(String streamId) async {
    if (streamId.trim().isEmpty) {
      throw Exception('Missing stream id');
    }
    await _apiClient.post('/live-streams/$streamId/start');
  }

  /// What YouTube receives from the host: streamStatus (active/inactive),
  /// health (good/ok/bad/noData) and lifeCycleStatus (ready/live/complete).
  static Future<Map<String, dynamic>> getStreamHealth(String streamId) async {
    final res = await _apiClient.get('/live-streams/$streamId/health');
    final payload = _extractPayload(res.data);
    return payload is Map ? Map<String, dynamic>.from(payload) : {};
  }

  /// RTMP server + key of the host's own stream (hidden from public reads).
  static Future<Map<String, dynamic>> getStreamIngest(String streamId) async {
    final res = await _apiClient.get('/live-streams/$streamId/ingest');
    final payload = _extractPayload(res.data);
    return payload is Map ? Map<String, dynamic>.from(payload) : {};
  }

  static Future<void> endStream(String streamId) async {
    if (streamId.trim().isEmpty) return;
    await _apiClient.post('/live-streams/$streamId/end');
  }

  static Future<void> joinStream(String streamId) async {
    if (streamId.trim().isEmpty) return;
    await _apiClient.post('/live-streams/$streamId/join');
  }

  static Future<void> leaveStream(String streamId) async {
    if (streamId.trim().isEmpty) return;
    await _apiClient.post('/live-streams/$streamId/leave');
  }

  static Future<Map<String, dynamic>> sendChatMessage(
    String streamId,
    String message,
  ) async {
    final res = await _apiClient.post(
      '/live-streams/$streamId/chat',
      data: {'message': message},
    );
    final payload = _extractPayload(res.data);
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return {};
  }

  static Future<LiveStreamModel> likeStream(String streamId) async {
    final res = await _apiClient.post('/live-streams/$streamId/like');
    final streamData = _extractStreamMap(res.data);
    if (streamData == null) {
      throw Exception('Invalid stream data format');
    }
    return LiveStreamModel.fromJson(streamData);
  }

  static dynamic _extractPayload(dynamic raw) {
    if (raw is Map) {
      final data = raw['data'];
      final message = raw['message'];
      if (data is Map || data is List) return data;
      if (message is Map || message is List) return message;
      if (data != null) return data;
      return raw['stream'] ?? raw;
    }
    return raw;
  }

  static Map<String, dynamic>? _extractStreamMap(dynamic raw) {
    final payload = _extractPayload(raw);
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return null;
  }

  static String _extractId(String value) {
    var streamId = value.trim();
    if (streamId.contains(':')) {
      streamId = streamId.split(':').last.trim();
    } else if (streamId.contains(',')) {
      streamId = streamId.split(',').last.trim();
    }
    return streamId;
  }

  static LiveStreamModel _fallbackStreamFromInput(
    Map<String, dynamic> data,
    String streamId,
  ) {
    return LiveStreamModel(
      id: streamId,
      userId: data['userId']?.toString() ?? '',
      matchId: data['matchId']?.toString(),
      title: data['title']?.toString() ?? 'Live Stream',
      description: data['description']?.toString(),
      streamType: data['streamType']?.toString() ?? 'mobile',
      streamQuality: data['streamQuality']?.toString() ?? '720p',
      streamKey: data['streamKey']?.toString() ?? streamId,
      rtmpUrl: data['rtmpUrl']?.toString() ?? zenstreamRtmpServer,
      provider: data['provider']?.toString() ?? 'zenstream',
      youtubeUrl: data['youtubeUrl']?.toString(),
      youtubeVideoId: data['youtubeVideoId']?.toString(),
      youtubeBroadcastId: data['youtubeBroadcastId']?.toString(),
      youtubeStreamId: data['youtubeStreamId']?.toString(),
      youtubeIngestionAddress: data['youtubeIngestionAddress']?.toString(),
      status: 'pending',
      viewerCount: 0,
      likes: 0,
      category: data['category']?.toString() ?? 'cricket',
      tags: List<String>.from(data['tags'] ?? const []),
      isPrivate: data['isPrivate'] == true,
      duration: 0,
      lookingFor: List<String>.from(data['lookingFor'] ?? const []),
      requirements: data['requirements']?.toString(),
      isFeatured: false,
      isPremium: false,
      createdAt: DateTime.now(),
    );
  }

  static Future<void> initSocket() async {
    final token = await _apiClient.getAccessToken();
    _socket = IO.io(
      ApiConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders(token != null ? {'Authorization': token} : {})
          .enableAutoConnect()
          .build(),
    );

    _socket!.connect();
    _socket!.onConnect((_) => debugPrint('Live stream socket connected'));
    _socket!.on('newChatMessage', (data) => _safeCallback(_onNewChatMessage, data));
    _socket!.on('viewerJoined', (data) => _safeCallback(_onViewerJoined, data));
    _socket!.on('viewerLeft', (data) => _safeCallback(_onViewerLeft, data));
    _socket!.on('streamEnded', (data) => _safeCallback(_onStreamEnded, data));
  }

  static void _safeCallback(
    Function(Map<String, dynamic>)? callback,
    dynamic data,
  ) {
    if (callback == null || data is! Map) return;
    callback(Map<String, dynamic>.from(data));
  }

  /// Viewers can open a stream without visiting Go Live, so connect lazily.
  static Future<void> joinStreamRoom(String streamId) async {
    if (_socket == null) await initSocket();
    _socket?.emit('joinStream', streamId);
  }
  static void leaveStreamRoom(String streamId) => _socket?.emit('leaveStream', streamId);

  static void registerChatCallback(Function(Map<String, dynamic>) callback) =>
      _onNewChatMessage = callback;
  static void registerViewerJoinedCallback(Function(Map<String, dynamic>) callback) =>
      _onViewerJoined = callback;
  static void registerViewerLeftCallback(Function(Map<String, dynamic>) callback) =>
      _onViewerLeft = callback;
  static void registerStreamEndedCallback(Function(Map<String, dynamic>) callback) =>
      _onStreamEnded = callback;

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
