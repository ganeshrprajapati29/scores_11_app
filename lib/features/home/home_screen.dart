import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../data/services/dashboard_service.dart';

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
    // Load dashboard data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDropdown() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Options', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildFilterOption('Matches', Icons.sports_cricket),
            _buildFilterOption('Players', Icons.person),
            _buildFilterOption('Teams', Icons.group),
            _buildFilterOption('Tournaments', Icons.emoji_events),
            _buildFilterOption('Clubs', Icons.groups),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final user = authProvider.user;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: () => dashboardProvider.refreshDashboard(),
        child: CustomScrollView(
          slivers: [
            // Dynamic App Bar
            SliverAppBar(
              expandedHeight: _isSearching ? 60 : 120,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search players, teams, matches...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
                      onSubmitted: (value) {
                        _performSearch(value);
                      },
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cric11', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        if (user != null)
                          Text(
                            'Welcome, ${user.name ?? 'User'}',
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                      ],
                    ),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                      }
                    });
                  },
                ),
                // Notification Icon with badge
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${dashboardProvider.quickStats.liveMatches}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                // Chat/Message Icon
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    Navigator.pushNamed(context, '/messages');
                  },
                ),
                // Filter/Dropdown button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.tune),
                  onSelected: (value) {
                    if (value == 'filter') {
                      _showFilterDropdown();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'filter',
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Filter'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sort',
                      child: Row(
                        children: [
                          Icon(Icons.sort, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Sort'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget _buildQuickShortcuts() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _shortcuts.length,
              itemBuilder: (context, index) {
                final shortcut = _shortcuts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, shortcut['route']);
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(shortcut['icon'], color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(shortcut['label'], style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
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

  Widget _buildLiveMatchesSection(DashboardProvider provider) {
    if (provider.isLoading && provider.liveMatches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🔴 Live Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('See All')),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    if (provider.liveMatches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🔴 Live Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('See All')),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_cricket, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('No live matches right now', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🔴 Live Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pushNamed(context, '/matches'), child: const Text('See All')),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.liveMatches.length,
              itemBuilder: (context, index) {
                final match = provider.liveMatches[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/match-detail', arguments: match.id);
                  },
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(match.team1.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(match.team1.shortName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(match.team2.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(match.team2.shortName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        if (match.innings != null) ...[
                          Text(
                            match.innings!.scoreString,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(match.status, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                        if (match.tournament != null)
                          Text(
                            match.tournament!.name,
                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingPlayersSection(DashboardProvider provider) {
    if (provider.trendingPlayers.isEmpty && !provider.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('⭐ Trending Players', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pushNamed(context, '/players'), child: const Text('Find Players')),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: provider.isLoading && provider.trendingPlayers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.trendingPlayers.take(10).length,
                    itemBuilder: (context, index) {
                      final player = provider.trendingPlayers[index];
                      return Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/player-profile', arguments: player.id);
                                  },
                                  child: CircleAvatar(
                                    radius: 35,
                                    backgroundColor: AppColors.primary,
                                    backgroundImage: player.avatar != null ? NetworkImage(player.avatar!) : null,
                                    child: player.avatar == null
                                        ? Text(player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P', 
                                            style: const TextStyle(color: Colors.white, fontSize: 24))
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Text('#${player.rank}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              player.name,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${player.stats.runs} runs',
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestTournamentsSection(DashboardProvider provider) {
    if (provider.latestTournaments.isEmpty && !provider.isLoading) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🏆 Latest Tournaments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pushNamed(context, '/tournaments'), child: const Text('See All')),
            ],
          ),
          const SizedBox(height: 8),
          ...provider.latestTournaments.take(3).map((tournament) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tournament.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${tournament.format} • ${tournament.totalTeams} teams', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        if (tournament.prizeMoney != null)
                          Text('Prize: ₹${tournament.prizeMoney!.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/tournament-detail', arguments: tournament.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('View'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection(DashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Quick Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Live Matches', '${provider.quickStats.liveMatches}', Icons.play_circle, AppColors.error),
              _buildStatCard('Tournaments', '${provider.quickStats.activeTournaments}', Icons.emoji_events, AppColors.primary),
              _buildStatCard('Teams', '${provider.quickStats.totalTeams}', Icons.group, AppColors.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildFindCricketSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🔍 Find Cricket Near You', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Find players, teams, and tournaments near your location', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/discover'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
            child: const Text('Explore Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, 'Home'),
              _buildNavItem(1, Icons.explore, 'Looking'),
              _buildNavItem(2, Icons.sports_cricket, 'My Cricket'),
              _buildNavItem(3, Icons.people, 'Community'),
              _buildNavItem(4, Icons.store, 'Store'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
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
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => Text(
                    auth.user?.name ?? 'Cric11 User',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text('user@scores11.com', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
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
          )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      Navigator.pushNamed(context, '/search', arguments: query);
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        switch (index) {
          case 0:
            break;
          case 1:
            Navigator.pushNamed(context, '/discover');
            break;
          case 2:
            Navigator.pushNamed(context, '/my-cricket');
            break;
          case 3:
            Navigator.pushNamed(context, '/community');
            break;
          case 4:
            Navigator.pushNamed(context, '/store');
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

