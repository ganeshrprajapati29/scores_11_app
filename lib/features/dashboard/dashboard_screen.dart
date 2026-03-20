import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../core/config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../data/services/user_service.dart';
import '../matches/match_list_screen.dart';
import '../teams/team_list_screen.dart';
import '../tournaments/tournament_list_screen.dart';
import '../dashboard/home_tab_screen.dart';
import 'widgets/mock_tab_content.dart';
import '../profile/profile_screen.dart';
import '../../core/constants/app_routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final UserService _userService = UserService();

  int _followers = 0;
  int _following = 0;
  int _profileViews = 0;
  bool _isLoadingStats = false;

final List<Widget> _screens = [
    const Expanded(child: HomeTab()),
    const Expanded(child: MockTabContent(
      title: 'Matches',
      icon: Icons.sports_cricket,
      description: 'Your upcoming and live matches',
      items: ['IPL 2024 - MI vs CSK (Live)', 'DC vs KKR (Today 7PM)', 'RCB vs PBKS (Tomorrow)'],
    )),
    const Expanded(child: MockTabContent(
      title: 'Tournaments',
      icon: Icons.emoji_events,
      description: 'Join tournaments and compete',
      items: ['IPL 2024', 'T20 Blast', 'Local League', 'World Cup Qualifier'],
    )),
    const Expanded(child: MockTabContent(
      title: 'Teams',
      icon: Icons.groups,
      description: 'Manage your teams',
      items: ['My IPL Team', 'T20 Blast Squad', 'Local League Team'],
    )),
    const Expanded(child: MockTabContent(
      title: 'Profile',
      icon: Icons.person,
      description: 'Your cricket profile',
      items: ['Edit Profile', 'View Stats', 'Privacy Settings'],
    )),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

Future<void> _loadUserStats() async {
    setState(() => _isLoadingStats = true);
    try {
      // Load real user stats from API
      final stats = await context.read<DashboardProvider>().loadUserStats();
      setState(() {
        _followers = stats.followers ?? 0;
        _following = stats.following ?? 0;
        _profileViews = stats.profileViews ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading user stats: $e');
      // Fallback mock data
      setState(() {
        _followers = 124;
        _following = 45;
        _profileViews = 5678;
      });
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Widget _buildUserProfileSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) return const SizedBox(height: 120);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: user.avatar?.url != null
                        ? Image.network(
                            user.avatar!.url!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: AppColors.primaryGradient),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, size: 35, color: Colors.white),
                            ),
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: AppColors.primaryGradient),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person, size: 35, color: Colors.white),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? 'Cricketer',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Playing Style: ${_getPlayingStyle(user)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _UserStatCard(label: 'Profile Views', value: '$_profileViews', icon: Icons.visibility)),
                  Expanded(child: _UserStatCard(label: 'Followers', value: '$_followers', icon: Icons.people)),
                  Expanded(child: _UserStatCard(label: 'Following', value: '$_following', icon: Icons.person_add_alt_1)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getPlayingStyle(user) {
    // Extract from user data or default
    return user.playingStyle ?? 'All Rounder';
  }

@override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DashboardProvider>(
      builder: (context, authProvider, dashboardProvider, child) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildUserProfileSection(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadUserStats,
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _screens,
                      ),
                    ),
                  ),
                ],
              ),
              // Loading overlay
              if (_isLoadingStats || dashboardProvider.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_cricket_outlined),
                  activeIcon: Icon(Icons.sports_cricket),
                  label: 'Matches',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events_outlined),
                  activeIcon: Icon(Icons.emoji_events),
                  label: 'Tournaments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.groups_outlined),
                  activeIcon: Icon(Icons.groups),
                  label: 'Teams',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) => DrawerHeader(
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
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final user = authProvider.user;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: user?.avatar?.url != null
                                ? Image.network(
                                    user!.avatar!.url!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.person, size: 30, color: AppColors.primary),
                                    ),
                                  )
                                : const CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.person, size: 30, color: AppColors.primary),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Consumer<AuthProvider>(
                              builder: (context, auth, child) => Text(
                                auth.user?.name ?? 'Cric11 User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'crick11.com/profile',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: AppColors.primary),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.emoji_events, color: AppColors.primary),
            title: Text('Tournaments'),
            onTap: () => Navigator.pushNamed(context, '/tournaments'),
          ),
          ListTile(
            leading: Icon(Icons.sports_cricket, color: AppColors.primary),
            title: Text('Matches'),
            onTap: () => Navigator.pushNamed(context, '/matches'),
          ),
          ListTile(
            leading: Icon(Icons.groups, color: AppColors.primary),
            title: Text('Teams'),
            onTap: () => Navigator.pushNamed(context, '/teams'),
          ),
          ListTile(
            leading: Icon(Icons.wallet, color: AppColors.primary),
            title: Text('Wallet'),
            onTap: () => Navigator.pushNamed(context, '/wallet'),
          ),
          ListTile(
            leading: Icon(Icons.person, color: AppColors.primary),
            title: Text('Profile'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: AppColors.primary),
            title: Text('Settings'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          ListTile(
            leading: Icon(Icons.help, color: AppColors.primary),
            title: Text('Help'),
            onTap: () => Navigator.pushNamed(context, '/support'),
          ),
          const Divider(),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text('Logout', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                auth.logout();
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              final user = auth.user;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? 'Cricketer'}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to play some cricket?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.add, color: Colors.white),
                            label: Text('Create Match'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/tournaments'),
                          icon: Icon(Icons.emoji_events, color: Colors.white),
                          label: Text('Tournaments'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add_circle_outline,
                  title: 'Create Team',
                  color: AppColors.primary,
                  onTap: () => Navigator.pushNamed(context, '/create-team'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.emoji_events_outlined,
                  title: 'Join Tournament',
                  color: AppColors.secondary,
                  onTap: () => Navigator.pushNamed(context, '/tournaments'),
                ),
              ),
            ],
          ),
          // Add more sections as needed
        ],
      ),
    );
  }
}

class _UserStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _UserStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}





