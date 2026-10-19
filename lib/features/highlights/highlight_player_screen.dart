import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/models/highlight_model.dart';
import '../../data/services/highlight_service.dart';
import '../../providers/auth_provider.dart';

/// Plays one highlight. Pops with the updated model (likes/views), or with
/// `null` when the owner deleted it.
class HighlightPlayerScreen extends StatefulWidget {
  final HighlightModel highlight;
  const HighlightPlayerScreen({super.key, required this.highlight});

  @override
  State<HighlightPlayerScreen> createState() => _HighlightPlayerScreenState();
}

class _HighlightPlayerScreenState extends State<HighlightPlayerScreen> {
  final HighlightService _service = HighlightService();
  late HighlightModel _item = widget.highlight;

  YoutubePlayerController? _youtube;
  VideoPlayerController? _video;
  ChewieController? _chewie;
  String? _playerError;
  bool _liking = false;

  @override
  void initState() {
    super.initState();
    _item = _item.copyWith(views: _item.views + 1);
    _service.recordView(_item.id);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (_item.isYoutube) {
      _youtube = YoutubePlayerController(
        initialVideoId: _item.youtubeVideoId!,
        flags: const YoutubePlayerFlags(autoPlay: true, enableCaption: false),
      );
      return;
    }
    final url = _item.videoUrl ?? '';
    if (url.isEmpty) {
      setState(() => _playerError = 'Video is not available');
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _chewie = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
        );
      });
    } catch (e) {
      if (mounted) setState(() => _playerError = 'Could not play this video');
    }
  }

  @override
  void dispose() {
    _youtube?.dispose();
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_liking) return;
    if (context.read<AuthProvider>().status != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like highlights')),
      );
      return;
    }
    setState(() => _liking = true);
    try {
      final result = await _service.toggleLike(_item.id);
      if (mounted) {
        setState(() => _item = _item.copyWith(isLiked: result.isLiked, likeCount: result.likeCount));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete highlight?'),
        content: const Text('This video will be removed from Scores11.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteHighlight(_item.id);
      if (mounted) Navigator.pop(context, null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  void _share() {
    final link = _item.isYoutube
        ? 'https://www.youtube.com/watch?v=${_item.youtubeVideoId}'
        : (_item.videoUrl ?? '');
    Share.share('${_item.title}\n$link');
  }

  Widget _player() {
    if (_youtube != null) {
      return YoutubePlayer(
        controller: _youtube!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.redAccent,
      );
    }
    if (_chewie != null) {
      return AspectRatio(
        aspectRatio: _chewie!.aspectRatio ?? 16 / 9,
        child: Chewie(controller: _chewie!),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: _playerError != null
            ? Text(_playerError!, style: const TextStyle(color: Colors.white70))
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id ?? '';
    final isOwner = userId.isNotEmpty && userId == _item.uploaderId;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _item);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(_item.isReplay ? 'Full replay' : 'Highlight'),
          actions: [
            IconButton(onPressed: _share, icon: const Icon(Icons.share_rounded)),
            if (isOwner)
              IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _player(),
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Text(_item.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (_item.matchTitle.isNotEmpty) _item.matchTitle,
                        '${_item.views} views',
                        if (_item.uploaderName.isNotEmpty) 'by ${_item.uploaderName}',
                      ].join(' • '),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      OutlinedButton.icon(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _item.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _item.isLiked ? AppColors.live : null,
                        ),
                        label: Text('${_item.likeCount}'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share'),
                      ),
                    ]),
                    if ((_item.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(_item.description!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
