import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/services/user_service.dart';
import '../../data/services/community_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF8F9FA);
const _kBorder = Color(0xFFEEEFF2);
const _kTextPrimary = Color(0xFF0D1117);
const _kTextSecondary = Color(0xFF6B7280);
const _kTextHint = Color(0xFF9CA3AF);
const _kShadow = Color(0x0A000000);
const _kCardRadius = 16.0;

// ─── Screen ───────────────────────────────────────────────────────────────────

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityService _communityService = CommunityService();

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final result = await _communityService.getPosts(page: 1);
      setState(() {
        _posts = result.posts;
        _hasMore = result.hasMore;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _snack('Error: $e');
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      _currentPage++;
      final result = await _communityService.getPosts(page: _currentPage);
      setState(() {
        _posts.addAll(result.posts);
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _currentPage--;
        _isLoadingMore = false;
      });
      if (mounted) _snack('Error loading more: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FeedTab(
            posts: _posts,
            isLoading: _isLoading,
            isLoadingMore: _isLoadingMore,
            hasMore: _hasMore,
            loadMore: _loadMorePosts,
            loadPosts: _loadPosts,
          ),
          _TrendingTab(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: _kTextPrimary, size: 22),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.forum_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Community',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded,
              color: _kTextSecondary, size: 22),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: _kTextHint,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            indicator: UnderlineTabIndicator(
              borderSide:
                  BorderSide(color: AppColors.primary, width: 2.5),
              insets: const EdgeInsets.symmetric(horizontal: 16),
            ),
            tabs: const [
              Tab(text: 'Feed'),
              Tab(text: 'Trending'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      heroTag:
          'community_feed_post_${DateTime.now().millisecondsSinceEpoch}',
      onPressed: () async {
        final created = await Navigator.pushNamed(context, '/create-post');
        if (created == true) _loadPosts();
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 3,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Post',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}

// ─── Feed Tab ─────────────────────────────────────────────────────────────────

class _FeedTab extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback loadMore;
  final VoidCallback loadPosts;

  const _FeedTab({
    required this.posts,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadMore,
    required this.loadPosts,
  });

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildShimmer();

    if (widget.posts.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: () async => widget.loadPosts(),
      color: AppColors.primary,
      strokeWidth: 2.5,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: widget.posts.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.posts.length) {
            return widget.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          return _PostCard(post: widget.posts[index], index: index);
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEFF2),
      highlightColor: _kBg,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kCardRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.forum_rounded,
                size: 38, color: Color(0xFFB0B8CC)),
          ),
          const SizedBox(height: 18),
          const Text(
            'No posts yet',
            style: TextStyle(
              color: _kTextSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Be the first to start a conversation',
            style: TextStyle(color: _kTextHint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Post Card ────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final int index;

  const _PostCard({required this.post, required this.index});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final CommunityService _communityService = CommunityService();
  final UserService _userService = UserService();
  late Map<String, dynamic> post;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    post = Map<String, dynamic>.from(widget.post);
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await action();
      if (updated.isNotEmpty && mounted) {
        setState(() => post = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e, fallback: 'Post update nahi ho paaya.'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleLike() async {
    final id = post['id']?.toString() ?? '';
    if (id.isEmpty) return;
    await _run(() => _communityService.likePost(id));
  }

  Future<void> _sharePost() async {
    final id = post['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final content = (post['content'] ?? 'Scores11 community post').toString();
    await Share.share(content.trim().isEmpty ? 'Scores11 community post' : content);
    await _run(() => _communityService.sharePost(id));
  }

  Future<void> _addComment() async {
    final id = post['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add comment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Write your comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;
    await _run(() => _communityService.addComment(id, {'content': text}));
  }

  Future<void> _toggleFollow() async {
    final authorId = post['authorId']?.toString() ?? post['userId']?.toString() ?? '';
    if (authorId.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      if (post['isFollowingAuthor'] == true) {
        await _userService.unfollowUser(authorId);
      } else {
        await _userService.followUser(authorId);
      }
      if (mounted) {
        setState(() => post['isFollowingAuthor'] = post['isFollowingAuthor'] != true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e, fallback: 'Action complete nahi ho paaya.'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = (post['images'] as List?)?.whereType<String>().toList() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
            child: Row(
              children: [
                _UserAvatar(
                  avatarUrl: post['userAvatar'],
                  name: post['userName'] ?? 'U',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['userName'] ?? 'Unknown User',
                        style: const TextStyle(
                          color: _kTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        post['timeAgo'] ?? '',
                        style: const TextStyle(
                            color: _kTextHint, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (post['canFollowAuthor'] == true)
                  TextButton(
                    onPressed: _busy ? null : _toggleFollow,
                    child: Text(post['isFollowingAuthor'] == true ? 'Following' : 'Follow'),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded,
                        color: _kTextHint, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          if ((post['content'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                post['content'] ?? '',
                style: const TextStyle(
                  color: _kTextPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),

          // ── Images ──────────────────────────────────────────────────
          if (images.isNotEmpty) ...[
            ClipRRect(
              borderRadius: images.length == 1
                  ? const BorderRadius.vertical(
                      bottom: Radius.circular(_kCardRadius))
                  : BorderRadius.zero,
              child: images.length == 1
                  ? _SingleImage(url: images.first)
                  : _MultiImage(images: images),
            ),
          ],

          // ── Divider ──────────────────────────────────────────────────
          if (images.isEmpty)
            const Divider(height: 1, color: _kBorder),

          // ── Actions ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.thumb_up_outlined,
                  activeIcon: Icons.thumb_up_rounded,
                  label: '${post['likes'] ?? 0}',
                  activeColor: AppColors.primary,
                  active: post['isLiked'] == true,
                  onTap: _toggleLike,
                ),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: '${post['comments'] ?? 0}',
                  activeColor: const Color(0xFF3B82F6),
                  onTap: _addComment,
                ),
                _ActionBtn(
                  icon: Icons.share_outlined,
                  activeIcon: Icons.share_rounded,
                  label: '${post['shares'] ?? 0}',
                  activeColor: const Color(0xFF16A34A),
                  onTap: _sharePost,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms, delay: (widget.index * 50).ms)
        .slideY(begin: 0.05, end: 0, duration: 280.ms, delay: (widget.index * 50).ms);
  }
}

// ─── User Avatar ──────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final dynamic avatarUrl;
  final String name;

  const _UserAvatar({this.avatarUrl, required this.name});

  String? get _url {
    if (avatarUrl is String) {
      final value = avatarUrl as String;
      return value.isEmpty ? null : value;
    }
    if (avatarUrl is Map) {
      final value = avatarUrl['url'] ?? avatarUrl['secureUrl'] ?? avatarUrl['path'];
      final text = value?.toString() ?? '';
      return text.isEmpty ? null : text;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
        border: Border.all(color: _kBorder),
      ),
      child: url != null
          ? ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(name),
              ),
            )
          : _initials(name),
    );
  }

  Widget _initials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ─── Image helpers ────────────────────────────────────────────────────────────

class _SingleImage extends StatelessWidget {
  final String url;
  const _SingleImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 200,
        color: const Color(0xFFF0F2F5),
        child: const Icon(Icons.image_rounded,
            size: 48, color: Color(0xFFB0B8CC)),
      ),
    );
  }
}

class _MultiImage extends StatelessWidget {
  final List<String> images;
  const _MultiImage({required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        children: images.take(3).map((img) {
          return Expanded(
            child: Image.network(
              img,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF0F2F5),
                child: const Icon(Icons.image_rounded,
                    color: Color(0xFFB0B8CC)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color activeColor;
  final bool active;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.activeColor,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? activeIcon : icon,
                size: 18,
                color: active ? activeColor : _kTextHint,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: active ? activeColor : _kTextHint,
                  fontSize: 12,
                  fontWeight: active
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Trending Tab ─────────────────────────────────────────────────────────────

class _TrendingTab extends StatelessWidget {
  final List<Map<String, String>> _trending = const [
    {'tag': '#MIvsCSK', 'posts': '12.5K'},
    {'tag': '#Bumrah', 'posts': '8.2K'},
    {'tag': '#IPLFinal', 'posts': '6.8K'},
    {'tag': '#RohitSharma', 'posts': '5.4K'},
    {'tag': '#Wankhede', 'posts': '3.2K'},
  ];

  const _TrendingTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.local_fire_department_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Trending Topics',
              style: TextStyle(
                color: _kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        ..._trending.asMap().entries.map((entry) {
          final i = entry.key;
          final topic = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_kCardRadius),
              border: Border.all(color: _kBorder),
              boxShadow: const [
                BoxShadow(
                    color: _kShadow,
                    blurRadius: 10,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(_kCardRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(_kCardRadius),
                splashColor: AppColors.primary.withOpacity(0.04),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? AppColors.primary.withOpacity(0.12)
                              : const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#${i + 1}',
                          style: TextStyle(
                            color: i == 0
                                ? AppColors.primary
                                : _kTextSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Tag + count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic['tag'] ?? '',
                              style: const TextStyle(
                                color: _kTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${topic['posts']} posts',
                              style: const TextStyle(
                                  color: _kTextHint, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      // Trend icon
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.trending_up_rounded,
                            color: AppColors.primary, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 260.ms, delay: (i * 60).ms)
              .slideY(begin: 0.05, end: 0, duration: 260.ms, delay: (i * 60).ms);
        }),
      ],
    );
  }
}
