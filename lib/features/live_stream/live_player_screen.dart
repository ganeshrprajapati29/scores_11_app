import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../data/models/live_stream_model.dart';
import '../../data/services/live_stream_service.dart';

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
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  Timer? _pollTimer;

  bool _isLoading = true;
  bool _isPlayerLoading = false;
  String? _error;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    try {
      final stream = await LiveStreamService.getStream(widget.streamId);
      if (!mounted) return;
      setState(() {
        _stream = stream;
        _isLoading = false;
      });

      try {
        await LiveStreamService.joinStream(widget.streamId);
        LiveStreamService.joinStreamRoom(widget.streamId);
      } catch (e) {
        debugPrint('Public stream join skipped: $e');
      }
      LiveStreamService.registerStreamEndedCallback((_) {
        if (mounted) {
          setState(() {
            _stream?.status = 'ended';
          });
          _disposePlayer();
        }
      });

      await _tryInitPlayer(stream);
      _tryInitYoutubePlayer(stream);
      _startStreamPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startStreamPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted) return;
      try {
        final updated = await LiveStreamService.getStream(widget.streamId);
        if (!mounted) return;
        setState(() => _stream = updated);

        if (updated.status == 'ended') {
          _disposePlayer();
          _pollTimer?.cancel();
          return;
        }

        await _tryInitPlayer(updated);
        _tryInitYoutubePlayer(updated);
      } catch (e) {
        debugPrint('Live stream polling error: $e');
      }
    });
  }

  Future<void> _tryInitPlayer(LiveStreamModel stream) async {
    if (stream.isYoutube) return;
    final url = _playableUrl(stream);
    if (url == null || url == _currentUrl || _isPlayerLoading) return;

    setState(() {
      _isPlayerLoading = true;
      _error = null;
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
      );

      _disposePlayer();
      _videoPlayerController = controller;
      _chewieController = chewie;
      _currentUrl = url;
    } catch (e) {
      debugPrint('Video player init error: $e');
      _currentUrl = null;
    } finally {
      if (mounted) setState(() => _isPlayerLoading = false);
    }
  }

  void _tryInitYoutubePlayer(LiveStreamModel stream) {
    if (!stream.isYoutube || _youtubeController != null) return;
    final videoId = stream.youtubeVideoId ??
        YoutubePlayer.convertUrlToId(stream.youtubeUrl ?? stream.streamUrl ?? '');
    if (videoId == null || videoId.isEmpty) return;

    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        isLive: true,
        enableCaption: false,
      ),
    );
    if (mounted) setState(() {});
  }

  String? _playableUrl(LiveStreamModel stream) {
    final urls = [
      stream.hlsUrl,
      stream.streamUrl,
    ].whereType<String>().map((url) => url.trim()).where((url) => url.isNotEmpty);

    for (final url in urls) {
      final lower = url.toLowerCase();
      if (lower.contains('.m3u8') || lower.contains('.mp4')) {
        return url;
      }
    }
    return null;
  }

  void _disposePlayer() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _youtubeController?.dispose();
    _youtubeController = null;
    _currentUrl = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    LiveStreamService.leaveStream(widget.streamId).catchError(
      (e) => debugPrint('Public stream leave skipped: $e'),
    );
    LiveStreamService.leaveStreamRoom(widget.streamId);
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null) {
      return _messageScaffold(
        icon: Icons.error_outline_rounded,
        title: 'Unable to load stream',
        message: _error!,
      );
    }

    final stream = _stream;
    if (stream == null) {
      return _messageScaffold(
        icon: Icons.live_tv_rounded,
        title: 'Stream not found',
        message: 'Please refresh and try again.',
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildPlayerBody(stream)),
            _buildTopBar(stream),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerBody(LiveStreamModel stream) {
    if (stream.status == 'ended') {
      return _centerMessage(
        icon: Icons.stop_circle_outlined,
        title: 'Stream ended',
        message: 'This live stream is no longer broadcasting.',
      );
    }

    if (_chewieController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _chewieController!.aspectRatio ?? 16 / 9,
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    if (stream.isYoutube && _youtubeController != null) {
      return Center(
        child: YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.redAccent,
          ),
          builder: (context, player) => AspectRatio(
            aspectRatio: 16 / 9,
            child: player,
          ),
        ),
      );
    }

    return _centerMessage(
      icon: Icons.sensors_rounded,
      title: _isPlayerLoading ? 'Starting video...' : 'Waiting for video feed',
      message: stream.isYoutube
          ? 'Opening YouTube live player. Please check that the YouTube live URL is public or unlisted.'
          : 'The stream is live. Video playback will start as soon as HLS is ready.',
      showLoader: true,
    );
  }

  Widget _buildTopBar(LiveStreamModel stream) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.72), Colors.transparent],
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stream.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stream.status == 'live' ? 'LIVE' : stream.statusDisplay,
                  style: TextStyle(
                    color: stream.status == 'live' ? Colors.redAccent : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageScaffold({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _centerMessage(icon: icon, title: title, message: message),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerMessage({
    required IconData icon,
    required String title,
    required String message,
    bool showLoader = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLoader)
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
              )
            else
              Icon(icon, color: Colors.white70, size: 42),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
