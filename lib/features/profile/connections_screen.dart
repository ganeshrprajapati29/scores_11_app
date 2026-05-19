import 'package:flutter/material.dart';
import '../../../core/services/user_service.dart';
import '../../../data/services/chat_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../chat/chat_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();

  List<dynamic> _followers = [];
  List<dynamic> _following = [];

  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConnections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    setState(() => _isLoading = true);
    try {
      final followersResult = await _userService.getFollowers();
      final followingResult = await _userService.getFollowing();

      if (mounted) {
        setState(() {
          _followers = followersResult['data'] is List ? followersResult['data'] as List<dynamic> : [];
          _following = followingResult['data'] is List ? followingResult['data'] as List<dynamic> : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading connections: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unfollowUser(String userId) async {
    try {
      await _userService.unfollowUser(userId);
      _loadConnections();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unfollowed successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    try {
      final userId = (user['id'] ?? user['_id'] ?? user['userId'])?.toString();
      if (userId == null || userId.isEmpty) {
        throw Exception('User id missing');
      }
      final chatInfo = await _chatService.getChatByUserId(userId);
      final chatId = chatInfo['chatId'] ?? '';
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUser: {...user, 'id': userId, '_id': userId},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Connections',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _ConnectionList(
                  users: _followers,
                  type: 'followers',
                  onAction: _unfollowUser,
                  onChat: _startChat,
                  onRefresh: _loadConnections,
                ),
                _ConnectionList(
                  users: _following,
                  type: 'following',
                  onAction: _unfollowUser,
                  onChat: _startChat,
                  onRefresh: _loadConnections,
                ),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: const Color(0xFF999999),
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Followers'),
                const SizedBox(width: 6),
                _CountBadge(count: _followers.length),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Following'),
                const SizedBox(width: 6),
                _CountBadge(count: _following.length),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Count Badge ─────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }
}

// ─── Connection List ──────────────────────────────────────────────────────────
class _ConnectionList extends StatelessWidget {
  final List<dynamic> users;
  final String type;
  final Function(String) onAction;
  final Function(Map<String, dynamic>) onChat;
  final Future<void> Function() onRefresh;

  const _ConnectionList({
    required this.users,
    required this.type,
    required this.onAction,
    required this.onChat,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _EmptyState(type: type);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _UserTile(
            user: user,
            type: type,
            onAction: onAction,
            onChat: onChat,
          );
        },
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String type;
  const _EmptyState({required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F8),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline_rounded, size: 38, color: const Color(0xFFCCCCCC)),
            ),
            const SizedBox(height: 16),
            Text(
              'No $type yet',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 6),
            Text(
              type == 'followers' ? 'Nobody is following you yet' : 'You are not following anyone yet',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── User Tile ────────────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final dynamic user;
  final String type;
  final Function(String) onAction;
  final Function(Map<String, dynamic>) onChat;

  const _UserTile({
    required this.user,
    required this.type,
    required this.onAction,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? user['fullName'] ?? 'Unknown';
    final role = user['role'] ?? user['playingStyle'] ?? 'Player';
    final avatarUrl = user['avatar']?['url'] ?? user['avatar'] ?? user['profileImage'];
    final userId = user['id'] ?? user['_id'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onChat(user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              _UserAvatar(avatarUrl: avatarUrl, initial: name.isNotEmpty ? name[0].toUpperCase() : '?'),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.sports_cricket_rounded, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            role,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action
              _ActionButton(
                label: type == 'followers' ? 'Remove' : 'Unfollow',
                isDestructive: true,
                onPressed: () => onAction(userId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── User Avatar ─────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initial;

  const _UserAvatar({required this.avatarUrl, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _AvatarFallback(initial: initial),
              )
            : _AvatarFallback(initial: initial),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initial;
  const _AvatarFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final bool isDestructive;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.isDestructive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFFFF2F2) : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDestructive ? const Color(0xFFFFB3B3) : AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDestructive ? const Color(0xFFE74C3C) : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

