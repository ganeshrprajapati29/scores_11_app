import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/models/highlight_model.dart';
import '../../data/services/highlight_service.dart';
import '../../data/services/upload_service.dart';
import '../../providers/auth_provider.dart';
import 'highlight_player_screen.dart';

/// Highlights feed. With [matchId] it shows only that match's videos
/// (live replay + clips) and new uploads are attached to the match.
class HighlightsScreen extends StatefulWidget {
  final String? matchId;
  final String? matchTitle;

  const HighlightsScreen({super.key, this.matchId, this.matchTitle});

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  final HighlightService _service = HighlightService();
  final ScrollController _scroll = ScrollController();

  List<HighlightModel> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _loadMore();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.getHighlights(matchId: widget.matchId, page: 1);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _hasMore = result.hasMore;
        _page = 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e, fallback: 'Could not load highlights.');
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final result =
          await _service.getHighlights(matchId: widget.matchId, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.items];
        _hasMore = result.hasMore;
        _page += 1;
      });
    } catch (_) {
      // Keep what is shown; the next scroll retries.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _openAddSheet() async {
    final auth = context.read<AuthProvider>();
    if (auth.status != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add highlights')),
      );
      return;
    }
    final created = await showModalBottomSheet<HighlightModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddHighlightSheet(matchId: widget.matchId),
    );
    if (created != null && mounted) {
      setState(() => _items = [created, ..._items]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Highlight added'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _open(HighlightModel item) async {
    final result = await Navigator.push<HighlightModel?>(
      context,
      MaterialPageRoute(builder: (_) => HighlightPlayerScreen(highlight: item)),
    );
    if (!mounted) return;
    if (result == null) {
      // Deleted from the player screen.
      setState(() => _items.removeWhere((h) => h.id == item.id));
    } else {
      setState(() {
        final i = _items.indexWhere((h) => h.id == item.id);
        if (i >= 0) _items[i] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.matchTitle?.isNotEmpty == true
        ? 'Highlights • ${widget.matchTitle}'
        : 'Highlights';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: title, showBackButton: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.video_call_rounded),
        label: const Text('Add highlight'),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 12),
        Center(child: Text(_error!, textAlign: TextAlign.center)),
        const SizedBox(height: 12),
        Center(child: TextButton(onPressed: _load, child: const Text('Retry'))),
      ]);
    }
    if (_items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 12),
        const Center(
          child: Text('No highlights yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'YouTube live replays appear here automatically.\nYou can also add a clip.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ]);
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: _items.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _HighlightCard(item: _items[i], onTap: () => _open(_items[i]));
      },
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final HighlightModel item;
  final VoidCallback onTap;

  const _HighlightCard({required this.item, required this.onTap});

  String _duration(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return m >= 60 ? '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final duration = _duration(item.durationSeconds);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0.5,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                if ((item.thumbnail ?? '').isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: item.thumbnail!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: Colors.black87),
                  )
                else
                  Container(color: Colors.black87),
                const Center(
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: _Badge(
                    text: item.isReplay ? 'FULL REPLAY' : 'HIGHLIGHT',
                    color: item.isReplay ? AppColors.live : AppColors.primary,
                  ),
                ),
                if (duration.isNotEmpty)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: _Badge(text: duration, color: Colors.black87),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (item.matchTitle.isNotEmpty) item.matchTitle,
                      if (item.uploaderName.isNotEmpty) item.uploaderName,
                    ].join(' • '),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.visibility_outlined, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${item.views}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 14),
                    Icon(item.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 15, color: item.isLiked ? AppColors.live : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${item.likeCount}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    Icon(item.isYoutube ? Icons.smart_display : Icons.videocam,
                        size: 16, color: item.isYoutube ? Colors.red : AppColors.textSecondary),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
      );
}

class _AddHighlightSheet extends StatefulWidget {
  final String? matchId;
  const _AddHighlightSheet({this.matchId});

  @override
  State<_AddHighlightSheet> createState() => _AddHighlightSheetState();
}

class _AddHighlightSheetState extends State<_AddHighlightSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final HighlightService _service = HighlightService();
  final UploadService _upload = UploadService();

  bool _useYoutube = true;
  File? _video;
  bool _saving = false;
  double _progress = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final file = await _upload.pickVideoFromGallery();
    if (file != null && mounted) setState(() => _video = file);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_useYoutube && _video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a video first')),
      );
      return;
    }
    setState(() {
      _saving = true;
      _progress = 0;
    });
    try {
      final created = _useYoutube
          ? await _service.addYoutubeHighlight(
              title: _titleCtrl.text.trim(),
              youtubeUrl: _urlCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              matchId: widget.matchId,
            )
          : await _service.uploadHighlight(
              title: _titleCtrl.text.trim(),
              video: _video!,
              description: _descCtrl.text.trim(),
              matchId: widget.matchId,
              onProgress: (sent, total) {
                if (total > 0 && mounted) setState(() => _progress = sent / total);
              },
            );
      if (mounted) Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, fallback: 'Could not save highlight.')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + inset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add highlight',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('YouTube link'), icon: Icon(Icons.smart_display)),
                  ButtonSegment(value: false, label: Text('Upload video'), icon: Icon(Icons.upload)),
                ],
                selected: {_useYoutube},
                onSelectionChanged: _saving ? null : (s) => setState(() => _useYoutube = s.first),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                maxLength: 150,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 6),
              if (_useYoutube)
                TextFormField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'YouTube link',
                    hintText: 'https://youtu.be/...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    final host = Uri.tryParse(value)?.host.toLowerCase() ?? '';
                    final ok = RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value) ||
                        host.contains('youtube.com') ||
                        host.contains('youtu.be');
                    return ok ? null : 'Enter a valid YouTube link';
                  },
                )
              else
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: Text(
                    _video == null
                        ? 'Choose video from gallery'
                        : _video!.path.split(Platform.pathSeparator).last,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              if (_saving && !_useYoutube) ...[
                LinearProgressIndicator(value: _progress > 0 && _progress < 1 ? _progress : null),
                const SizedBox(height: 6),
                Text(
                  _progress < 1 ? 'Uploading ${(_progress * 100).round()}%' : 'Processing video...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
              ],
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
