import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/live_stream_model.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveStreamService {
  static final ApiClient _apiClient = ApiClient();
  static IO.Socket? _socket;
  
  // Agora Engine instance (v6.x singleton)
  static RtcEngine? _engine;
  static bool _isJoined = false;
  static String? _currentChannel;
  static int? _currentUid;

  // Stream callbacks
  static Function(int)? onUserJoined;
  static Function(int)? onUserOffline;
  static Function(int)? onFirstRemoteVideoFrame;
  static Function(int)? onFirstRemoteAudioFrame;
  static Function(int, String)? onError;

  // Initialize Agora Engine for v6.x (6.5.3)
  static Future<void> initAgoraEngine() async {
    if (_engine != null) return;
    
    try {
      // Request permissions first
      await _requestPermissions();
      
      // v6.x initialization - create singleton engine then initialize
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineConfig(
        appId: ApiConfig.agoraAppId,
      ));
      
      // Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Joined channel: ${connection.channelId}');
            _isJoined = true;
            _currentChannel = connection.channelId;
            _currentUid = connection.localUid;
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('👤 User joined: $remoteUid');
            onUserJoined?.call(remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('👋 User offline: $remoteUid, reason: $reason');
            onUserOffline?.call(remoteUid);
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('❌ Agora Error: $err, $msg');
            onError?.call(err.index, msg);
          },
          onFirstRemoteVideoFrame: (RtcConnection connection, int remoteUid, int width, int height, int elapsed) {
            debugPrint('🎥 First remote video frame: $remoteUid');
            onFirstRemoteVideoFrame?.call(remoteUid);
          },
          onFirstRemoteAudioFrame: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('🎤 First remote audio frame: $remoteUid');
            onFirstRemoteAudioFrame?.call(remoteUid);
          },
          onConnectionLost: (RtcConnection connection) {
            debugPrint('🔌 Connection lost');
          },
        ),
      );
      
      debugPrint('✅ Agora v6.x Engine initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Agora v6.x: $e');
      rethrow;
    }
  }
  
  static Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      debugPrint('⚠️ Camera or microphone permission denied');
    }
  }

  // v6.x Video encoder config
  static Future<void> setupVideoConfig() async {
    if (_engine == null) await initAgoraEngine();
    await _engine!.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        codecType: VideoCodecType.videoCodecVp8,
        dimensions: VideoDimensions(width: 720, height: 1280),
        bitrate: VideoEncoderBitrateKbps.standard720P,
        frameRate: 30,
      ),
    );
  }

  static Future<void> enableVideo() async {
    if (_engine == null) await initAgoraEngine();
    await _engine!.enableVideo();
  }

  static Future<void> enableAudio() async {
    if (_engine == null) await initAgoraEngine();
    await _engine!.enableAudio();
  }

  // Join as publisher (host)
  static Future<void> joinAsPublisher(String channelName, String token, int uid) async {
    if (_engine == null) await initAgoraEngine();
    
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
    
    await _engine!.startPreview();
  }

  // Join as subscriber (viewer)
  static Future<void> joinAsSubscriber(String channelName, String token, int uid) async {
    if (_engine == null) await initAgoraEngine();
    
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
  }

  static Future<void> switchCamera() async {
    if (_engine != null) await _engine!.switchCamera();
  }

  static Future<void> muteLocalAudio(bool muted) async {
    if (_engine != null) await _engine!.muteLocalAudioStream(muted);
  }

  static Future<void> muteLocalVideo(bool muted) async {
    if (_engine != null) await _engine!.muteLocalVideoStream(muted);
  }

  static RtcEngine? getEngine() => _engine;

  static Future<void> leaveChannel() async {
    if (_engine != null && _isJoined) {
      await _engine!.leaveChannel();
      _isJoined = false;
      _currentChannel = null;
      _currentUid = null;
      debugPrint('👋 Left channel');
    }
  }

  static Future<void> disposeEngine() async {
    if (_engine != null) {
      await leaveChannel();
      await _engine!.release();
      _engine = null;
      debugPrint('🔧 Agora Engine disposed');
    }
  }

  // API Calls (unchanged)
  static Future<LiveStreamModel> createStream(Map<String, dynamic> data) async {
    final res = await _apiClient.post('/live-streams', data: data);
    return LiveStreamModel.fromJson(res.data['data'] ?? res.data);
  }

  static Future<List<LiveStreamModel>> getLiveStreams({String status = 'live', int page = 1}) async {
    final res = await _apiClient.get('/live-streams', 
      queryParameters: {'page': page, 'status': status});
    final data = res.data['data'] ?? res.data;
    final List list = data['results'] ?? [];
    return list.map((json) => LiveStreamModel.fromJson(json)).toList();
  }

  static Future<LiveStreamModel> getStream(String streamId) async {
    final res = await _apiClient.get('/live-streams/$streamId');
    return LiveStreamModel.fromJson(res.data['data'] ?? res.data);
  }

  static Future<Map<String, dynamic>> getRtcToken(String streamId, int uid, 
      {String role = 'publisher'}) async {
    final res = await _apiClient.post('/live-streams/$streamId/token', 
      data: {'uid': uid, 'role': role});
    return res.data['data'] ?? res.data;
  }

  static Future<void> startStream(String streamId) async {
    debugPrint('🎥 Starting stream: $streamId');
    try {
      await _apiClient.post('/live-streams/$streamId/start');
      debugPrint('✅ Stream $streamId started successfully');
    } catch (e) {
      debugPrint('❌ Failed to start stream $streamId: $e');
      rethrow;
    }
  }

  static Future<void> endStream(String streamId) async {
    debugPrint('🔴 Ending stream: $streamId');
    try {
      await _apiClient.post('/live-streams/$streamId/end');
      debugPrint('✅ Stream $streamId ended successfully');
      await leaveChannel();
    } catch (e) {
      debugPrint('❌ Failed to end stream $streamId: $e');
      rethrow;
    }
  }

  static Future<void> joinStream(String streamId) async {
    debugPrint('👋 Joining stream: $streamId');
    try {
      await _apiClient.post('/live-streams/$streamId/join');
      debugPrint('✅ Joined stream $streamId');
    } catch (e) {
      debugPrint('❌ Failed to join stream $streamId: $e');
      rethrow;
    }
  }

  static Future<void> leaveStream(String streamId) async {
    debugPrint('👋 Leaving stream: $streamId');
    try {
      await _apiClient.post('/live-streams/$streamId/leave');
      debugPrint('✅ Left stream $streamId');
    } catch (e) {
      debugPrint('❌ Failed to leave stream $streamId: $e');
    }
  }

  static Future<Map<String, dynamic>> sendChatMessage(String streamId, String message) async {
    final res = await _apiClient.post('/live-streams/$streamId/chat', 
      data: {'message': message});
    return res.data['data'] ?? res.data;
  }

  static Future<LiveStreamModel> likeStream(String streamId) async {
    final res = await _apiClient.post('/live-streams/$streamId/like');
    return LiveStreamModel.fromJson(res.data['data'] ?? res.data);
  }

  // Socket.IO Methods (unchanged)
  static Future<void> initSocket() async {
    final token = await AuthService.getToken();
    _socket = IO.io(ApiConfig.socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setExtraHeaders(token != null ? {'Authorization': token} : {})
        .enableAutoConnect()
        .build());
    
    _socket!.connect();

    _socket!.onConnect((_) => debugPrint('✅ LiveStream socket connected'));
    _socket!.onDisconnect((_) => debugPrint('❌ LiveStream socket disconnected'));
    _socket!.onConnectError((error) => debugPrint('🔌 Socket connection error: $error'));
  }

  static void joinStreamRoom(String streamId) {
    _socket?.emit('joinStream', streamId);
  }

  static void leaveStreamRoom(String streamId) {
    _socket?.emit('leaveStream', streamId);
  }

  static void onStreamStarted(Function(Map<String, dynamic>) callback) {
    _socket?.on('streamStarted', (data) => callback(Map<String, dynamic>.from(data)));
  }

  static void onStreamEnded(Function(Map<String, dynamic>) callback) {
    _socket?.on('streamEnded', (data) => callback(Map<String, dynamic>.from(data)));
  }

  static void onViewerJoined(Function(Map<String, dynamic>) callback) {
    _socket?.on('viewerJoined', (data) => callback(Map<String, dynamic>.from(data)));
  }

  static void onViewerLeft(Function(Map<String, dynamic>) callback) {
    _socket?.on('viewerLeft', (data) => callback(Map<String, dynamic>.from(data)));
  }

  static void onNewChatMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('newChatMessage', (data) => callback(Map<String, dynamic>.from(data)));
  }

  static void onStreamLiked(Function(Map<String, dynamic>) callback) {
    _socket?.on('streamLiked', (data) => callback(Map<String, dynamic>.from(data)));
  }

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}

