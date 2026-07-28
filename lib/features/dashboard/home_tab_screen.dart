﻿import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../data/models/dashboard_model.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../data/services/notification_service.dart';
import '../../../data/services/community_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Timer? _refreshTimer;

  final CommunityService _communityService = CommunityService();
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _posts = [];
  int _notificationCount = 0;
  int _postsPage = 1;
  bool _postsHasMore = true;
  bool _postsLoadingMore = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onPostsScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DashboardProvider>();
      provider.refreshDashboard();
      _loadPosts();
      _loadNotificationCount();
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        context.read<DashboardProvider>().refreshDashboard(context);
        _loadNotificationCount();
      }
    });
  }

  Future<void> _loadNotificationCount() async {
    final count = await _notificationService.getUnreadCount();
    if (!mounted) return;
    setState(() => _notificationCount = count);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DashboardProvider, AuthProvider>(
      builder: (context, provider, authProvider, child) {
        final user = authProvider.user;
        
        return RefreshIndicator(
          onRefresh: () => provider.refreshDashboard(context),
          child: provider.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildWelcomeSection(context, user),
                  if ((provider.quickStats?.liveMatches ?? 0) > 0)
                    _buildLiveMatchesSection(provider),
                  _buildQuickActionsSection(context),
                  _buildStatsSection(provider),
                  _buildUpcomingMatchesSection(provider),
                  _buildTrendingPlayersSection(provider),
                  _buildLatestTournamentsSection(provider),
                  _buildLatestPostsSection(),
                  if (provider.error != null || provider.isMockData)
                    _buildStatusBanner(provider),
                ],
              ),
        );
      },
    );
  }

  SliverAppBar _buildWelcomeSection(BuildContext context, dynamic user) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: ProfileAvatar(
              user: user,
              radius: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello, ${user?.name ?? 'Cricketer'} 👋', 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.address?.city ?? 'Your City',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.pushNamed(context, '/notifications').then((_) => _loadNotificationCount()),
            ),
            if (_notificationCount > 0)
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: Text(
                    _notificationCount > 99 ? '99+' : '$_notificationCount',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => Navigator.pushNamed(context, '/players/search'),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildLiveMatchesSection(DashboardProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🔴 Live Matches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Builder(
                  builder: (context) => TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/matches/live'),
                    child: const Text('See All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...provider.liveMatches.take(3).map((match) => _LiveMatchCard(match: match)).toList(),
            if (provider.liveMatches.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 12),
              Builder(
                  builder: (context) => TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/matches/live'),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text('View ${provider.liveMatches.length} Live Matches'),
                  ),
                ),
              )
            else if (provider.liveMatches.isEmpty)
              _EmptyLiveSection(),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildQuickActionsSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚡ Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _QuickActionButton(
                  icon: Icons.sports_cricket,
                  label: 'Create Match',
                  route: '/create-match',
                ),
                _QuickActionButton(
                  icon: Icons.event_available_rounded,
                  label: 'Scheduled',
                  route: '/scheduled-matches',
                ),
                _QuickActionButton(
                  icon: Icons.fact_check_rounded,
                  label: 'Completed',
                  route: '/completed-matches',
                ),
                _QuickActionButton(
                  icon: Icons.emoji_events_outlined,
                  label: 'Join Tournament',
                  route: '/tournaments/join',
                ),
                _QuickActionButton(
                  icon: Icons.group_add,
                  label: 'Create Team',
                  route: '/create-team',
                ),
                _QuickActionButton(
                  icon: Icons.wallet,
                  label: 'Wallet',
                  route: '/wallet',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStatsSection(DashboardProvider provider) {
    final stats = provider.quickStats;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _StatCard(label: 'Live', value: '${stats?.liveMatches ?? 0}', icon: Icons.sports_cricket)),
            Expanded(child: _StatCard(label: 'Today', value: '${stats?.todayMatches ?? 0}', icon: Icons.today)),
            Expanded(child: _StatCard(label: 'Teams', value: '${stats?.totalTeams ?? 0}', icon: Icons.groups)),
            Expanded(child: _StatCard(label: 'Players', value: '${stats?.totalPlayers ?? 0}', icon: Icons.people)),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildUpcomingMatchesSection(DashboardProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📅 Upcoming', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Builder(
                  builder: (context) => TextButton(onPressed: () => Navigator.pushNamed(context, '/matches'), child: const Text('See All')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...provider.upcomingMatches.take(2).map((match) => _UpcomingMatchCard(match: match)).toList(),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildTrendingPlayersSection(DashboardProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('⭐ Trending Players', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => Navigator.pushNamed(context, '/leaderboard'), child: const Text('Leaderboard')),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.trendingPlayers.length,
                itemBuilder: (context, index) {
                  final player = provider.trendingPlayers[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text('${player.rank}º', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Icon(Icons.person, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(height: 8),
                            Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            Text('${player.stats.runs}R ${player.stats.wickets}W', style: TextStyle(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildLatestTournamentsSection(DashboardProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏆 Tournaments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...provider.latestTournaments.take(3).map((tournament) => _TournamentCard(tournament: tournament)).toList(),
          ],
        ),
      ),
    );
  }

  void _onPostsScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _postsLoadingMore = true);
    try {
      final result = await _communityService.getPosts(page: 1);
      if (mounted) {
        setState(() {
          _posts = result.posts;
          _postsPage = 1;
          _postsHasMore = result.hasMore ?? true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load posts: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _postsLoadingMore = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_postsLoadingMore || !_postsHasMore) return;
    setState(() => _postsLoadingMore = true);
    try {
      _postsPage++;
      final result = await _communityService.getPosts(page: _postsPage);
      if (mounted) {
        setState(() {
          _posts.addAll(result.posts);
          _postsHasMore = result.hasMore ?? false;
        });
      }
    } catch (e) {
      _postsPage--;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load more failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _postsLoadingMore = false);
    }
  }

  SliverToBoxAdapter _buildLatestPostsSection() {
    if (_posts.isEmpty && !_postsLoadingMore) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📱 Latest Posts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/community'),
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 400,
              child: ListView.builder(
                itemCount: _posts.length + (_postsHasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _posts.length) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  return _PostCard(post: _posts[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStatusBanner(DashboardProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: provider.isMockData ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: provider.isMockData ? Colors.orange : Colors.red),
        ),
        child: Row(
          children: [
            Icon(provider.isMockData ? Icons.offline_bolt : Icons.error, color: provider.isMockData ? Colors.orange : Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(provider.isMockData ? 'Demo Mode (Server offline)' : 'Error: ${provider.error}')),
            if (provider.isMockData)
              TextButton(onPressed: () => provider.refreshDashboard(context), child: const Text('Retry'))
            else
              IconButton(onPressed: provider.clearError, icon: const Icon(Icons.close)),
          ],
        ),
      ),
    );
  }

  // Widget builders
  Widget _LiveMatchCard({required DashboardMatch match}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text('${match.team1Name ?? match.team1 ?? 'Team 1'} vs ${match.team2Name ?? match.team2 ?? 'Team 2'}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${match.scoreString ?? 'Live'} • ${match.format ?? ''}'),
            Text('IPL 2024', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        onTap: () => Navigator.pushNamed(context, '/match-detail', arguments: match.id),
      ),
    );
  }

  Widget _UpcomingMatchCard({required DashboardMatch match}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text('${match.team1ShortName ?? match.team1 ?? 'Team 1'} vs ${match.team2ShortName ?? match.team2 ?? 'Team 2'}'),
        subtitle: Text(match.scheduledDate != null 
          ? '${match.format ?? ''} • ${TimeOfDay.fromDateTime(match.scheduledDate!).format(context)}'
          : '${match.format ?? ''}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.pushNamed(context, '/match-detail', arguments: match.id),
      ),
    );
  }

  Widget _QuickActionButton({
    required IconData icon,
    required String label,
    required String route,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _StatCard({required String label, required String value, required IconData icon}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _TournamentCard({required DashboardTournament tournament}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: AppColors.secondary),
        title: Text(tournament.name),
        subtitle: Text('${tournament.format} • ${tournament.totalTeams} teams'),
        trailing: Text((tournament.isPaid ?? false) ? '\$${(tournament.entryFee ?? 0)}' : 'Free'),
        onTap: () => Navigator.pushNamed(context, '/tournament-detail', arguments: tournament.id),
      ),
    );
  }

  Widget _EmptyLiveSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.sports_cricket_outlined, size Ascending 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No Live Matches', style: TextStyle(fontSize Ascending 16)),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/matches'), child: const Text('Browse Matches')),
          ],
        ),
      ),
    );
  }

  Widget _PostCard({required Map<String, dynamic> post}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: Ascending 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children Ascending [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        post['createdAt'] ?? 'Just now',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              post['content'] ?? 'Post content...',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          
          // Mock Image
          if ((post['images'] as List?)?.isNotEmpty ?? false)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                Ascending color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                image: (post['images'] Ascending List).isNotEmpty 
                  ? DecorationImage(
                      image: NetworkImage(post['images'][0]),
                      fit: BoxFit.cover,
                    ) 
                  : null,
              ),
            ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.thumb_up_outlined,
                    label: '${post['likes'] ?? 0}',
                    onTap: () => _communityService.likePost(post['id']),
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon Ascending Icons.comment_outlined,
                    label: '${post['comments'] ?? 0}',
                    onTap: () => Navigator.pushNamed(context, '/post-detail', arguments: post['id']),
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_outlined,
                    label: '${post['shares'] ?? 0}',
                    onTap: () => _communityService.sharePost(post['id']),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ActionButton({
    required IconData Ascending icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding Ascending const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

