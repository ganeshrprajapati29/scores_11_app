import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/services/community_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _commentController = TextEditingController();

  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await _communityService.getPostById(widget.postId);
      final comments = await _communityService.getComments(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = post;
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e, fallback: 'Could not load post.');
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    final updated = await _runPostAction(() => _communityService.likePost(widget.postId));
    if (updated != null) setState(() => _post = updated);
  }

  Future<void> _sharePost() async {
    if (_post == null) return;
    final content = (_post!['content'] ?? 'Scores11 community post').toString();
    await Share.share(content.trim().isEmpty ? 'Scores11 community post' : content);
    final updated = await _runPostAction(() => _communityService.sharePost(widget.postId));
    if (updated != null) setState(() => _post = updated);
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final updated = await _communityService.addComment(widget.postId, {'content': text});
      if (!mounted) return;
      _commentController.clear();
      setState(() {
        _post = updated;
        _comments = (updated['commentItems'] is List)
            ? (updated['commentItems'] as List)
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : _comments;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(friendlyError(e, fallback: 'Could not complete the action.'));
    }
  }

  Future<Map<String, dynamic>?> _runPostAction(
    Future<Map<String, dynamic>> Function() action,
  ) async {
    try {
      final updated = await action();
      return updated.isEmpty ? null : updated;
    } catch (e) {
      if (mounted) _snack(friendlyError(e, fallback: 'Could not add comment.'));
      return null;
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: 'Post',
        showBackButton: true,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _post == null ? null : _sharePost,
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 38),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(onPressed: _loadPost, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_post == null) {
      return const Center(child: Text('Post not found'));
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPost,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
                  _PostCard(
                    post: _post!,
                    onLike: _toggleLike,
                    onShare: _sharePost,
                  ),
                  const SizedBox(height: 14),
                  _CommentsCard(comments: _comments),
                ],
              ),
            ),
          ),
          _CommentInput(
            controller: _commentController,
            submitting: _submitting,
            onSubmit: _submitComment,
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;
  final VoidCallback onShare;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final author = (post['userName'] ?? 'Scores11 User').toString();
    final avatar = _safeUrl((post['userAvatar'] ?? post['avatar'])?.toString()) ?? _avatarFor(author);
    final content = (post['content'] ?? '').toString();
    final images = post['images'] is List ? post['images'] as List : const [];
    final image = images.isNotEmpty ? _safeUrl(images.first?.toString()) : null;
    final liked = post['isLiked'] == true;

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(url: avatar, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    Text(
                      (post['timeAgo'] ?? post['time'] ?? '').toString(),
                      style: const TextStyle(color: Color(0xFF667085), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (content.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(height: 1.5, fontWeight: FontWeight.w600)),
          ],
          if (image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                image,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: const Color(0xFFF2F4F7),
                  child: const Icon(Icons.image_outlined, color: Color(0xFF98A2B3)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_count(post['likes'])} likes  •  ${_count(post['comments'])} comments  •  ${_count(post['shares'])} shares',
                  style: const TextStyle(color: Color(0xFF667085), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              _ActionButton(
                icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: liked ? 'Liked' : 'Like',
                color: liked ? Colors.redAccent : const Color(0xFF667085),
                onTap: onLike,
              ),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: const Color(0xFF667085),
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentsCard extends StatelessWidget {
  final List<Map<String, dynamic>> comments;

  const _CommentsCard({required this.comments});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments (${comments.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No comments yet',
                  style: TextStyle(color: Color(0xFF98A2B3), fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            ...comments.map((comment) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CommentTile(comment: comment),
                )),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final user = comment['user'] is Map ? Map<String, dynamic>.from(comment['user'] as Map) : const <String, dynamic>{};
    final name = (comment['userName'] ?? user['name'] ?? user['fullName'] ?? 'Scores11 User').toString();
    final avatar = _safeUrl((comment['userAvatar'] ?? user['avatar'] ?? user['profileImage'])?.toString()) ?? _avatarFor(name);
    final content = (comment['content'] ?? '').toString();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(url: avatar, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(content, style: const TextStyle(color: Color(0xFF475467), height: 1.35)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;

  const _CommentInput({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a comment',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 46,
              height: 46,
              child: ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;

  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final double size;

  const _Avatar({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: AppColors.primary.withOpacity(0.1),
          child: Icon(Icons.person_rounded, color: AppColors.primary, size: size * 0.5),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: color,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

int _count(dynamic value) {
  if (value is int) return value;
  if (value is List) return value.length;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _safeUrl(String? value) {
  final url = value?.trim();
  if (url == null || url.isEmpty || url == 'null' || url == 'default-avatar-url') return null;
  final uri = Uri.tryParse(url);
  return uri != null && uri.hasScheme && uri.host.isNotEmpty ? url : null;
}

String _avatarFor(String name) {
  final encoded = Uri.encodeComponent(name.trim().isEmpty ? 'Scores11 User' : name.trim());
  return 'https://ui-avatars.com/api/?name=$encoded&background=1A56DB&color=fff&bold=true&size=160';
}
