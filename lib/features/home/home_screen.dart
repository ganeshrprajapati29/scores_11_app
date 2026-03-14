import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../data/services/dashboard_service.dart';
import '../../data/services/user_service.dart';
import '../../core/constants/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isDrawerOpen = false;
  final UserService _userService = UserService();

  int _followers = 0;
  int _following = 0;
  int _profileViews = 0;
  bool _isLoadingStats = false;

  final List<Map<String, dynamic>> _shortcuts = [
    {'icon': Icons.group_add, 'label': 'Create Team', 'route': '/create-team'},
    {'icon': Icons.play_arrow, 'label': 'Start Match', 'route': '/create-match'},
    {'icon': Icons.bar_chart, 'label': 'View Stats', 'route': '/stats'},
    {'icon': Icons.emoji_events, 'label': 'My Tournaments', 'route': '/my-tournaments'},
    {'icon': Icons.wallet, 'label': 'Wallet', 'route': '/wallet'},
    {'icon': Icons.history, 'label': 'History', 'route': '/history'},
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home, 'label': 'Home', 'route': '/home'},
    {'icon': Icons.explore, 'label': 'Discover', 'route': '/discover'},
    {'icon': Icons.person, 'label': 'My Profile', 'route': '/profile'},
    {'icon': Icons.group, 'label': 'My Teams', 'route': '/my-teams'},
    {'icon': Icons.emoji_events, 'label': 'Tournaments', 'route': '/my-tournaments'},
    {'icon': Icons.wallet, 'label': 'Wallet', 'route': '/wallet'},
    {'icon': Icons.settings, 'label': 'Settings', 'route': '/settings'},
    {'icon': Icons.help, 'label': 'Help & Support', 'route': '/support'},
  ];

  @override
  void initState() {
    super.initState();
    // Load dashboard and user stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
      _loadUserStats();
    });
  }

  Future<void> _loadUserStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final followersResult = await _userService.getFollowers();
      if (followersResult['success']) {
        final data = jsonDecode(followersResult['data']);
        setState(() => _followers = (data['followers'] as List?)?.length ?? 0);
      }

      final followingResult = await _userService.getFollowing();
      if (followingResult['success']) {
        final data = jsonDecode(followingResult['data']);
        setState(() => _following = (data['following'] as List?)?.length ?? 0);
      }

      final viewsResult = await _userService.getProfileViews();
      if (viewsResult['success']) {
        final data = jsonDecode(viewsResult['data']);
        setState(() => _profileViews = data['views'] ?? 0);
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
    }
    setState(() => _isLoadingStats = false);
  }

  // ... (keep all existing methods: _showFilterDropdown, _buildFilterOption etc.)

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final user = authProvider.user;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(user),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardProvider>().refreshDashboard();
          await _loadUserStats();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: Builder(
                builder: (context) => IconButton(
                  iconSize: 32,
                  icon: Stack(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          _isDrawerOpen ? Icons.close : Icons.menu,
                          semanticLabel: _isDrawerOpen ? 'Close menu' : 'Open menu',
                          key: ValueKey<bool>(_isDrawerOpen),
                          size: 28,
                        ),
                      ),
                      if (dashboardProvider.quickStats.liveMatches > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${dashboardProvider.quickStats.liveMatches}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    setState(() {
                      _isDrawerOpen = !_isDrawerOpen;
                    });
                    if (_scaffoldKey.currentState!.isDrawerOpen) {
                      Navigator.of(context).pop();
                    } else {
                      _scaffoldKey.currentState!.openDrawer();
                    }
                  },
                ),
              ),
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search players, teams, matches...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchController.clear();
                            });
                          },
                        ),
                      ),
                      onSubmitted: (value) => _performSearch(value),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Scores11', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        if (user != null)
                          Text(
                            'Welcome back, ${user.name ?? 'User'}',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                          ),
                      ],
                    ),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () => setState(() => _isSearching = !_isSearching),
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    ),
                    if (dashboardProvider.quickStats.liveMatches > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          child: Text(
                            '${dashboardProvider.quickStats.liveMatches}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => Navigator.pushNamed(context, '/messages'),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.tune),
                  onSelected: (value) => _showFilterDropdown(),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'filter', child: Row(children: [Icon(Icons.filter_list), SizedBox(width: 8), Text('Filter')])),
                    const PopupMenuItem(value: 'sort', child: Row(children: [Icon(Icons.sort), SizedBox(width: 8), Text('Sort')])),
                  ],
                ),
              ],
            ),

            /// NEW: User Profile Summary Section
            SliverToBoxAdapter(
              child: _buildUserProfileSection(user),
            ),

            // Bottom Navigation & Content
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Quick Shortcuts
                  _buildQuickShortcuts(),

                  // Live Matches Section
                  _buildLiveMatchesSection(dashboardProvider),

                  // Trending Players Section
                  _buildTrendingPlayersSection(dashboardProvider),

                  // Latest Tournaments Section
                  _buildLatestTournamentsSection(dashboardProvider),

                  // Quick Stats Section
                  _buildQuickStatsSection(dashboardProvider),

                  // Find Cricket Section
                  _buildFindCricketSection(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildUserProfileSection(UserModel? user) {
    if (user == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: user.avatar?.url != null
                    ? Image.network(
                        user.avatar!.url!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, size: 30, color: AppColors.primary),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, size: 30, color: AppColors.primary),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'User',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user.email ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                icon: const Icon(Icons.person, size: 16),
                label: const Text('View Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: _isLoadingStats
                ? const Row(
                    children: [
                      Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildUserStatCard('Views', '$_profileViews', Icons.visibility),
                      ),
                      Expanded(
                        child: _buildUserStatCard('Followers', '$_followers', Icons.people),
                      ),
                      Expanded(
                        child: _buildUserStatCard('Following', '$_following', Icons.person_add),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatCard(String label, String value, IconData icon) {
    return GestureDetector(
      onTap: _loadUserStats, // Refresh stats
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(UserModel? user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: user?.avatar?.url != null
                          ? Image.network(
                              user!.avatar!.url!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person, size: 25, color: AppColors.primary),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, size: 25, color: AppColors.primary),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user?.name ?? 'Cric11 User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? 'user@scores11.com',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ..._menuItems.map((item) => ListTile(
            leading: Icon(item['icon'], color: AppColors.primary),
            title: Text(item['label']),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, item['route']);
            },
          )).toList(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }

  // Keep all existing methods unchanged: _buildQuickShortcuts, _buildLiveMatchesSection, etc.
  // [Include all the existing _build methods from original home_screen.dart here - truncated for brevity]

  // Placeholder for existing methods - in real implementation, copy all from original
  Widget _buildQuickShortcuts() => Container(); // Original implementation
  Widget _buildLiveMatchesSection(DashboardProvider provider) => Container(); // Original
  Widget _buildTrendingPlayersSection(DashboardProvider provider) => Container(); // Original
  Widget _buildLatestTournamentsSection(DashboardProvider provider) => Container(); // Original
  Widget _buildQuickStatsSection(DashboardProvider provider) => Container(); // Original
  Widget _buildFindCricketSection() => Container(); // Original
  Widget _buildBottomNavigation() => Container(); // Original
  void _showFilterDropdown() {}
  Widget _buildFilterOption(String label, IconData icon) => Container();
  void _performSearch(String query) {}
}


