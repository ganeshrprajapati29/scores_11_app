import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../data/services/live_stream_service.dart';
import '../../data/models/live_stream_model.dart';
import 'dart:async';

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
  String? _error;

  // ✅ FIX: late use karo (nullable hata diya)
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  Timer? _pollTimer;

  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    try {
      final stream = await LiveStreamService.getStream(widget.streamId);
      setState(() => _stream = stream);

      await LiveStreamService.joinStream(widget.streamId);
      LiveStreamService.joinStreamRoom(widget.streamId);

      LiveStreamService.registerChatCallback((data) {
        if (mounted) {
          setState(() => _messages.add(ChatMessage.fromJson(data)));
          _scrollToBottom();
        }
      });

      LiveStreamService.registerStreamEndedCallback((data) {
        if (mounted) Navigator.pop(context);
      });

      if (!widget.isHost) {
        _startHlsPolling();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _startHlsPolling() {    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {      if (!mounted) return;      try {        final updated = await LiveStreamService.getStream(widget.streamId);        if (mounted) setState(() => _stream = updated);        if (updated.hlsUrl != null &&            updated.hlsUrl!.isNotEmpty &&            _chewieController == null) {          await _initPlayer();          timer.cancel();        }      } catch (e) {        debugPrint('Polling error: $e');      }    });  }

  Future<void> _initPlayer() async {    if (_stream?.hlsUrl == null || _stream!.hlsUrl!.isEmpty) {      debugPrint('⚠️ No HLS URL available yet');      return;    }    _videoPlayerController = VideoPlayerController.networkUrl(      Uri.parse(_stream!.hlsUrl!),    );    await _videoPlayerController.initialize();    _chewieController = ChewieController(      videoPlayerController: _videoPlayerController,      autoPlay: true,      looping: false,      showControls: true,      allowFullScreen: true,      aspectRatio:          _videoPlayerController.value.aspectRatio == 0              ? 16 / 9              : _videoPlayerController.value.aspectRatio,    );    if (mounted) setState(() {});  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _chewieController?.dispose();
    _videoPlayerController.dispose();
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
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // ✅ VIDEO PLAYER
          (_chewieController != null)
              ? AspectRatio(
                  aspectRatio:
                      _chewieController!.aspectRatio ?? 16 / 9,
                  child: Chewie(controller: _chewieController!),
                )
              : const Center(child: CircularProgressIndicator()),

          // ✅ TOP BAR
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    _stream!.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ CHAT MODEL
class ChatMessage {
  final String userId;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.userId,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {    String timestampStr = json['timestamp'] ?? DateTime.now().toIso8601String();    DateTime timestamp;    try {      timestamp = DateTime.parse(timestampStr);    } catch (e) {      debugPrint('Invalid timestamp: $timestampStr, using now');      timestamp = DateTime.now();    }    return ChatMessage(      userId: json['userId'] ?? '',      message: json['message'] ?? '',      timestamp: timestamp,    );  }
}