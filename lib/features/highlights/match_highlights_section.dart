import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/highlight_model.dart';
import '../../data/services/highlight_service.dart';
import 'highlight_player_screen.dart';
import 'highlights_screen.dart';

/// Horizontal strip of a match's replay + clips, with "View all / Add".
class MatchHighlightsSection extends StatefulWidget {
  final String matchId;
  final String matchTitle;

  const MatchHighlightsSection({
    super.key,
    required this.matchId,
    this.matchTitle = '',
  });

  @override
  State<MatchHighlightsSection> createState() => _MatchHighlightsSectionState();
}

class _MatchHighlightsSectionState extends State<MatchHighlightsSection> {
  final HighlightService _service = HighlightService();
  List<HighlightModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.matchId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final result = await _service.getHighlights(matchId: widget.matchId, limit: 10);
      if (mounted) setState(() => _items = result.items);
    } catch (_) {
      // Section simply shows its empty state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAll() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HighlightsScreen(
          matchId: widget.matchId,
          matchTitle: widget.matchTitle,
        ),
      ),
    );
    _load();
  }

  Future<void> _play(HighlightModel item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HighlightPlayerScreen(highlight: item)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.video_library_rounded, color: AppColors.live),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Highlights & Replays',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
            TextButton(
              onPressed: _openAll,
              child: Text(_items.isEmpty ? 'Add' : 'View all'),
            ),
          ]),
          const SizedBox(height: 8),
          if (_loading)
            const SizedBox(
              height: 110,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No videos yet. A YouTube live of this match is saved here as a full replay when it ends, or tap Add to post a clip.',
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final item = _items[i];
                  return GestureDetector(
                    onTap: () => _play(item),
                    child: SizedBox(
                      width: 190,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Stack(fit: StackFit.expand, children: [
                                if ((item.thumbnail ?? '').isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: item.thumbnail!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        Container(color: Colors.black87),
                                  )
                                else
                                  Container(color: Colors.black87),
                                const Center(
                                  child: Icon(Icons.play_circle_fill,
                                      color: Colors.white, size: 36),
                                ),
                                if (item.isReplay)
                                  Positioned(
                                    left: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.live,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('REPLAY',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
