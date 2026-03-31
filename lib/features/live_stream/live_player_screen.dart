import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';
import '../../data/services/live_stream_service.dart';
import '../../data/models/live_stream_model.dart';
import '../../providers/auth_provider.dart';

class LivePlayerScreen extends StatefulWidget {
  final String streamId;
  final bool isHost;

  const LivePlayerScreen({
    super.key,
    required this.streamId,
    this.isHost = false,
  });

  @override
  State<LivePlayerScreen> createState() => _LivePlayerScreenState();
}

class _LivePlayerScreenState extends State<LivePlayerScreen> {
  LiveStreamModel? _stream;
  bool _isLoading = true;
  bool _isJoining = false;
  String? _error;
  
  // Agora related
  int? _remoteUid;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;
  
  // Chat
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeStream();
    _setupSocketListeners();
  }

  Future<void> _initializeStream() async {
    try {
      final stream = await LiveStreamService.getStream(widget.streamId);
      setState(() {
        _stream = stream;
        _isLoading = false;
      });
      
      await _joinStream();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _joinStream() async {
    setState(() => _isJoining = true);
    
    try {
      await LiveStreamService.joinStream(widget.streamId);
      
      final uid = DateTime.now().millisecondsSinceEpoch % 1000000;
      final tokenData = await LiveStreamService.getRtcToken(
        widget.streamId,
        uid,
        role: widget.isHost ? 'publisher' : 'subscriber',
      );
      
      await LiveStreamService.initAgoraEngine();
      
      if (widget.isHost) {
        await LiveStreamService.setupVideoConfig();
        await LiveStreamService.enableVideo();
        await LiveStreamService.enableAudio();
        await LiveStreamService.joinAsPublisher(
          tokenData['channel'],
          tokenData['token'],
          uid,
        );
      } else {
        await LiveStreamService.joinAsSubscriber(
          tokenData['channel'],
          tokenData['token'],
          uid,
        );
      }
      
  LiveStreamService.onUserJoined = (uid) {
    if (mounted) {
      setState(() {
        _remoteUid = uid;
      });
      _showSnackBar('User $uid joined the stream');
    }
  };
  
  LiveStreamService.onUserOffline = (uid) {
    if (mounted) {
      setState(() {
        if (_remoteUid == uid) _remoteUid = null;
      });
      _showSnackBar('User $uid left the stream');
    }
  };
  
  LiveStreamService.onFirstRemoteVideoFrame = (uid) {
    if (mounted) {
      setState(() {
        _remoteUid = uid;
      });
    }
  };
      
      setState(() {
        _isJoined = true;
        _isJoining = false;
      });
      
      LiveStreamService.joinStreamRoom(widget.streamId);
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isJoining = false;
      });
      _showSnackBar('Failed to join stream: $e', isError: true);
    }
  }

  void _setupSocketListeners() {
    LiveStreamService.onNewChatMessage((data) {
      setState(() {
        _messages.add(ChatMessage.fromJson(data));
      });
      _scrollToBottom();
    });
    
    LiveStreamService.onViewerJoined((data) {
      _showSnackBar('Viewer joined: ${data['viewerCount']} viewers');
      if (_stream != null) {
        setState(() {
          _stream = LiveStreamModel(
            id: _stream!.id,
            userId: _stream!.userId,
            title: _stream!.title,
            description: _stream!.description,
            streamType: _stream!.streamType,
            streamQuality: _stream!.streamQuality,
            thumbnail: _stream!.thumbnail,
            streamKey: _stream!.streamKey,
            streamUrl: _stream!.streamUrl,
            rtmpUrl: _stream!.rtmpUrl,
            hlsUrl: _stream!.hlsUrl,
            status: _stream!.status,
            viewerCount: data['viewerCount'] ?? _stream!.viewerCount,
            likes: _stream!.likes,
            category: _stream!.category,
            tags: _stream!.tags,
            isPrivate: _stream!.isPrivate,
            password: _stream!.password,
            scheduledAt: _stream!.scheduledAt,
            startedAt: _stream!.startedAt,
            endedAt: _stream!.endedAt,
            duration: _stream!.duration,
            location: _stream!.location,
            pricing: _stream!.pricing,
            equipment: _stream!.equipment,
            lookingFor: _stream!.lookingFor,
            requirements: _stream!.requirements,
            isFeatured: _stream!.isFeatured,
            isPremium: _stream!.isPremium,
            createdAt: _stream!.createdAt,
          );
        });
      }
    });
    
    LiveStreamService.onViewerLeft((data) {
      if (_stream != null) {
        setState(() {
          _stream = LiveStreamModel(
            id: _stream!.id,
            userId: _stream!.userId,
            title: _stream!.title,
            description: _stream!.description,
            streamType: _stream!.streamType,
            streamQuality: _stream!.streamQuality,
            thumbnail: _stream!.thumbnail,
            streamKey: _stream!.streamKey,
            streamUrl: _stream!.streamUrl,
            rtmpUrl: _stream!.rtmpUrl,
            hlsUrl: _stream!.hlsUrl,
            status: _stream!.status,
            viewerCount: data['viewerCount'] ?? _stream!.viewerCount,
            likes: _stream!.likes,
            category: _stream!.category,
            tags: _stream!.tags,
            isPrivate: _stream!.isPrivate,
            password: _stream!.password,
            scheduledAt: _stream!.scheduledAt,
            startedAt: _stream!.startedAt,
            endedAt: _stream!.endedAt,
            duration: _stream!.duration,
            location: _stream!.location,
            pricing: _stream!.pricing,
            equipment: _stream!.equipment,
            lookingFor: _stream!.lookingFor,
            requirements: _stream!.requirements,
            isFeatured: _stream!.isFeatured,
            isPremium: _stream!.isPremium,
            createdAt: _stream!.createdAt,
          );
        });
      }
    });
    
    LiveStreamService.onStreamEnded((data) {
      if (mounted) {
        _showSnackBar('Stream has ended');
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      }
    });
  }

  Future<void> _sendChatMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;
    
    _chatController.clear();
    
    try {
      await LiveStreamService.sendChatMessage(widget.streamId, message);
    } catch (e) {
      _showSnackBar('Failed to send message', isError: true);
    }
  }

  Future<void> _toggleMute() async {
    await LiveStreamService.muteLocalAudio(!_isMuted);
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _toggleVideo() async {
    await LiveStreamService.muteLocalVideo(!_isVideoEnabled);
    setState(() => _isVideoEnabled = !_isVideoEnabled);
  }

  Future<void> _switchCamera() async {
    await LiveStreamService.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  Future<void> _likeStream() async {
    try {
      final updated = await LiveStreamService.likeStream(widget.streamId);
      setState(() {
        _stream = updated;
      });
      _showSnackBar('You liked this stream!');
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _endStream() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Stream'),
        content: const Text('Are you sure you want to end this stream?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await LiveStreamService.endStream(widget.streamId);
        await LiveStreamService.disposeEngine();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showSnackBar('Failed to end stream', isError: true);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    LiveStreamService.leaveStream(widget.streamId);
    LiveStreamService.leaveStreamRoom(widget.streamId);
    LiveStreamService.disposeEngine();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: Stack(
        children: [
          // Video Container
          Container(
            color: Colors.black,
            child: _buildVideoView(),
          ),
          
          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stream?.title ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.visibility, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${_stream?.viewerCount ?? 0} viewers',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.favorite, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${_stream?.likes ?? 0}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.isHost) ...[
                      IconButton(
                        icon: const Icon(Icons.switch_camera, color: Colors.white),
                        onPressed: _switchCamera,
                      ),
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                        ),
                        onPressed: _toggleMute,
                      ),
                      IconButton(
                        icon: Icon(
                          _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                          color: Colors.white,
                        ),
                        onPressed: _toggleVideo,
                      ),
                      IconButton(
                        icon: const Icon(Icons.call_end, color: Colors.red),
                        onPressed: _endStream,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Chat Panel Button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'live_player_chat',
              mini: true,
              onPressed: _showChatPanel,
              child: const Icon(Icons.chat),
            ),
          ),
          
          // Like Button
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _likeStream,
              child: const Icon(Icons.favorite),
            ),
          ),
          
          // Loading overlay
          if (_isJoining)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to stream...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    if (!_isJoined) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Connecting to stream...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    
    final engine = LiveStreamService.getEngine();
    if (engine == null) {
      return const Center(
        child: Text('Initializing...', style: TextStyle(color: Colors.white)),
      );
    }
    
    if (widget.isHost) {
      // Host view - show local video
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else if (_remoteUid != null) {
      // Viewer view - show remote video
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: ''),
        ),
      );
    } else {
      // Waiting for host
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Waiting for host to start streaming...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
  }

  void _showChatPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Chat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildChatMessage(message);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onSubmitted: (_) => _sendChatMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendChatMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUser = message.userId == authProvider.user?.id;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Text(
                    message.userName ?? 'User',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                const SizedBox(height: 2),
                Text(message.message),
                const SizedBox(height: 2),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class ChatMessage {
  final String userId;
  final String? userName;
  final String message;
  final DateTime timestamp;
  
  ChatMessage({
    required this.userId,
    this.userName,
    required this.message,
    required this.timestamp,
  });
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      userId: json['userId'] is Map ? json['userId']['_id'] : json['userId'],
      userName: json['userId'] is Map ? json['userId']['name'] : null,
      message: json['message'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? json['createdAt']) ?? DateTime.now(),
    );
  }
}