import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/live_stream_model.dart';
import '../../data/services/live_stream_service.dart';
import '../live_stream/live_player_screen.dart';

/// "Watch live" banner shown on a match when someone is streaming it.
/// Renders nothing when there is no live stream for the match.
class MatchLiveStreamBanner extends StatefulWidget {
  final String matchId;
  const MatchLiveStreamBanner({super.key, required this.matchId});

  @override
  State<MatchLiveStreamBanner> createState() => _MatchLiveStreamBannerState();
}

class _MatchLiveStreamBannerState extends State<MatchLiveStreamBanner> {
  LiveStreamModel? _stream;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _load();
    // A host may go live after this page was opened, or end the stream.
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.matchId.isEmpty) return;
    try {
      final streams = await LiveStreamService.getLiveStreams(
        status: 'live',
        matchId: widget.matchId,
      );
      if (!mounted) return;
      final next = streams.isNotEmpty ? streams.first : null;
      if (next?.id != _stream?.id) setState(() => _stream = next);
    } catch (_) {
      // No banner when the lookup fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _stream;
    if (stream == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: AppColors.live,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LivePlayerScreen(streamId: stream.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(stream.isYoutube ? Icons.smart_display_rounded : Icons.videocam_rounded,
                  color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WATCH LIVE',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                    const SizedBox(height: 2),
                    Text(stream.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 34),
            ]),
          ),
        ),
      ),
    );
  }
}
