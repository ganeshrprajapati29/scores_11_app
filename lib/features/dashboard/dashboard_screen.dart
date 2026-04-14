// lib/presentation/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/models/user_model.dart';
import '../../core/constants/app_routes.dart';
import '../profile/profile_screen.dart';
import '../../features/matches/match_list_screen.dart';
import '../../features/tournaments/tournament_list_screen.dart';
import '../../data/services/blog_service.dart';
import '../../data/services/community_service.dart';
import '../../data/models/blog_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/teams/team_list_screen.dart';

import 'dart:async';
import '../../core/widgets/profile_avatar.dart';

// ─────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────
class _DS {
  // Primary palette
  static const deepNavy   = Color(0xFF0A1628);
  static const navy       = Color(0xFF0D2147);
  static const royalBlue  = Color(0xFF1A56DB);
  static const skyBlue    = Color(0xFF3B82F6);
  static const accentCyan = Color(0xFF06B6D4);

  // Surface
  static const surface    = Color(0xFFF8FAFF);
  static const card       = Colors.white;
  static const cardAlt    = Color(0xFFF1F5FE);

  // Status
  static const live       = Color(0xFFEF4444);
  static const gold       = Color(0xFFF59E0B);
  static const green      = Color(0xFF10B981);

  // Text
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient heroGrad = LinearGradient(
    colors: [Color(0xFF0D2147), Color(0xFF1A56DB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient appBarGrad = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF0D2147)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient liveGrad = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldGrad = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenGrad = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> heroShadow = [
    BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 12)),
  ];
  static List<BoxShadow> liveShadow = [
    BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6)),
  ];

  // Radius
  static const double radiusXL  = 24;
  static const double radiusLG  = 18;
  static const double radiusMD  = 14;
  static const double radiusSM  = 10;
}

// ─────────────────────────────────────────────
//  Main DashboardScreen
// ─────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _fabAnimController;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _screens = [
      const HomeTab(key: ValueKey('home-tab')),
      MatchListScreen(key: const ValueKey('match-list')),
      TournamentListScreen(key: const ValueKey('tournament-list')),
      TeamListScreen(key: const ValueKey('team-list')),
      const ProfileTab(key: ValueKey('profile-tab')),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboard();
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DashboardProvider>(
      builder: (context, authProvider, dashboardProvider, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: _DS.surface,
            extendBodyBehindAppBar: true,
            drawer: _buildDrawer(authProvider),
            appBar: _buildAppBar(dashboardProvider),
            body: Stack(
              children: [
                RefreshIndicator(
                  color: _DS.royalBlue,
                  onRefresh: () => dashboardProvider.refreshDashboard(context),
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
                if (dashboardProvider.isLoading)
                  _buildLoadingOverlay(),
              ],
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
          ),
        );
      },
    );
  }

  // ── Loading Overlay ────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: _DS.deepNavy.withOpacity(0.45),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_DS.radiusXL),
            boxShadow: [
              BoxShadow(
                color: _DS.royalBlue.withOpacity(0.18),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  color: _DS.royalBlue,
                  strokeWidth: 3,
                  backgroundColor: _DS.cardAlt,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ────────────────────────────────
  PreferredSizeWidget _buildAppBar(DashboardProvider dashboardProvider) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    flexibleSpace: Container(
      decoration: const BoxDecoration(gradient: _DS.appBarGrad),
    ),

    // ✅ TITLE (Responsive)
    title: LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // Logo
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_DS.royalBlue, _DS.accentCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _DS.accentCyan.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_cricket,
                color: Colors.white,
                size: 18,
              ),
            ),

            const SizedBox(width: 10),

            // ✅ Text Responsive (Important)
            Expanded(
              child: Text(
                'Scores11',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        );
      },
    ),

    // ✅ Drawer Button
    leading: Builder(
      builder: (context) => IconButton(
        icon: const _AppBarIcon(icon: Icons.menu_rounded),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    ),

    // ✅ ACTIONS (Responsive)
    actions: [
      // Notifications with badge
      Stack(
        children: [
          IconButton(
            icon: const _AppBarIcon(icon: Icons.notifications_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, '/notifications'),
          ),

          if (dashboardProvider.quickStats.liveMatches > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                decoration: BoxDecoration(
                  gradient: _DS.liveGrad,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _DS.live.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${dashboardProvider.quickStats.liveMatches}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // Search
      IconButton(
        icon: const _AppBarIcon(icon: Icons.search_rounded),
        onPressed: () => Navigator.pushNamed(context, '/players'),
      ),

      // Chat
      IconButton(
        icon: const _AppBarIcon(icon: Icons.chat_bubble_outline),
        onPressed: () => Navigator.pushNamed(context, '/chats'),
      ),

      const SizedBox(width: 4),
    ],
  );
}

  // ── Bottom Nav Bar ────────────────────────
  Widget _buildBottomNavigationBar() {
    const items = [
      {'icon': Icons.home_outlined,           'activeIcon': Icons.home_rounded,       'label': 'Home'},
      {'icon': Icons.sports_cricket_outlined, 'activeIcon': Icons.sports_cricket,     'label': 'Matches'},
      {'icon': Icons.emoji_events_outlined,   'activeIcon': Icons.emoji_events,       'label': 'Cups'},
      {'icon': Icons.groups_outlined,         'activeIcon': Icons.groups,             'label': 'Teams'},
      {'icon': Icons.person_outline_rounded,  'activeIcon': Icons.person_rounded,     'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: _DS.royalBlue.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = _currentIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 18 : 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? _DS.heroGrad : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [BoxShadow(color: _DS.royalBlue.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? items[index]['activeIcon'] as IconData
                            : items[index]['icon'] as IconData,
                        color: isSelected ? Colors.white : _DS.textMuted,
                        size: 22,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 7),
                        Text(
                          items[index]['label'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Drawer ─────────────────────────────────
  Widget _buildDrawer(AuthProvider authProvider) {
    final user = authProvider.user;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            decoration: const BoxDecoration(
              gradient: _DS.heroGrad,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                    ),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12),
                    ],
                  ),
                  child: ClipOval(
                    child: user?.avatar?.url != null
                        ? Image.network(
                            user!.avatar!.url!,
                            width: 62,
                            height: 62,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _defaultAvatarWidget(),
                          )
                        : _defaultAvatarWidget(),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'Cric11 User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Stats chips
                Row(
                  children: [
                    _DrawerStatChip(label: 'Player'),
                    const SizedBox(width: 8),
                    _DrawerStatChip(label: '⭐ Pro'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerSection('MAIN'),
                _buildDrawerItem(icon: Icons.dashboard_rounded, title: 'Dashboard', isActive: _currentIndex == 0, onTap: () { Navigator.pop(context); setState(() => _currentIndex = 0); }),
                _buildDrawerItem(icon: Icons.sports_cricket, title: 'Matches', isActive: _currentIndex == 1, onTap: () { Navigator.pop(context); setState(() => _currentIndex = 1); }),
                _buildDrawerItem(icon: Icons.emoji_events_rounded, title: 'Tournaments', isActive: _currentIndex == 2, onTap: () { Navigator.pop(context); setState(() => _currentIndex = 2); }),
                _buildDrawerItem(icon: Icons.groups_rounded, title: 'Teams', isActive: _currentIndex == 3, onTap: () { Navigator.pop(context); setState(() => _currentIndex = 3); }),
                _buildDrawerItem(icon: Icons.people_rounded, title: 'Players', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/players'); }),

                _buildDrawerSection('FEATURES'),
                _buildDrawerItem(icon: Icons.live_tv_rounded, title: 'Live Matches', badge: 'LIVE', badgeColor: _DS.live, onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/live-matches'); }),
                _buildDrawerItem(icon: Icons.analytics_outlined, title: 'Scorecards', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/scorecards'); }),
                _buildDrawerItem(icon: Icons.leaderboard_outlined, title: 'Leaderboards', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/leaderboards'); }),
                _buildDrawerItem(icon: Icons.article_outlined, title: 'Blogs', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/blogs'); }),
                _buildDrawerItem(icon: Icons.forum_outlined, title: 'Community', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/community'); }),
                _buildDrawerItem(icon: Icons.chat_bubble_outline_rounded, title: 'Chats', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/chats'); }),
                _buildDrawerItem(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/notifications'); }),

                _buildDrawerSection('ACCOUNT'),
                _buildDrawerItem(icon: Icons.person_rounded, title: 'Profile', isActive: _currentIndex == 4, onTap: () { Navigator.pop(context); setState(() => _currentIndex = 4); }),
                _buildDrawerItem(icon: Icons.settings_rounded, title: 'Settings', onTap: () => Navigator.pushNamed(context, AppRoutes.settings)),
_buildDrawerItem(icon: Icons.help_outline_rounded, title: 'Help & Support', onTap: () => Navigator.pushNamed(context, '/help-support')),
                _buildDrawerItem(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy)),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFEEF2FF)),
                ),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  color: const Color(0xFFEF4444),
                  onTap: () { Navigator.pop(context); _showLogoutDialog(context, Provider.of<AuthProvider>(context, listen: false)); },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: _DS.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _defaultAvatarWidget() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_DS.royalBlue, _DS.accentCyan]),
      ),
      child: const Icon(Icons.person, size: 32, color: Colors.white),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    bool isActive = false,
    String? badge,
    Color? badgeColor,
  }) {
    final itemColor = color ?? (isActive ? _DS.royalBlue : _DS.textPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: isActive ? _DS.heroGrad : null,
            color: isActive ? null : (color != null ? color.withOpacity(0.1) : _DS.cardAlt),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: isActive ? Colors.white : itemColor, size: 19),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: itemColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? _DS.royalBlue).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor ?? _DS.royalBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: isActive ? _DS.royalBlue.withOpacity(0.06) : null,
        onTap: onTap,
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _DS.live.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: _DS.live, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Logout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: _DS.textSecondary, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(color: _DS.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _DS.live,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Drawer Stat Chip
// ─────────────────────────────────────────────
class _DrawerStatChip extends StatelessWidget {
  final String label;
  const _DrawerStatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AppBar Icon Button
// ─────────────────────────────────────────────
class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  const _AppBarIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    );
  }
}

// ─────────────────────────────────────────────
//  HomeTab
// ─────────────────────────────────────────────
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final data = dashboardProvider.dashboardData;

    if (dashboardProvider.isLoading && data == null) {
      return const Center(
        child: CircularProgressIndicator(color: _DS.royalBlue),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 4,
        bottom: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Welcome Hero
          _buildWelcomeHero(context),
          const SizedBox(height: 20),

          // Live Matches
          if (dashboardProvider.hasLiveMatches) ...[
            _buildLiveMatchesSection(context, dashboardProvider.liveMatches),
            const SizedBox(height: 20),
          ],

          // Banner Carousel
          const _BannerCarousel(),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Stats
                _buildQuickStatsRow(dashboardProvider.quickStats),
                const SizedBox(height: 24),

                // Quick Actions
                _buildSectionHeader('Quick Actions', Icons.bolt_rounded, color: _DS.gold),
                const SizedBox(height: 14),
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // Trending Players
                if (dashboardProvider.hasTrendingPlayers) ...[
                  _buildSectionHeader('Trending Players', Icons.trending_up_rounded, color: const Color(0xFFF97316)),
                  const SizedBox(height: 14),
                  _buildTrendingPlayersSection(dashboardProvider.trendingPlayers),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Trending Teams', Icons.trending_up_rounded, color: _DS.green),
                  const SizedBox(height: 14),
                ],

                // Upcoming Matches
                if (dashboardProvider.hasUpcomingMatches) ...[
                  _buildSectionHeader('Upcoming Matches', Icons.schedule_rounded, color: _DS.royalBlue),
                  const SizedBox(height: 14),
                  _buildUpcomingMatchesSection(dashboardProvider.upcomingMatches),
                  const SizedBox(height: 24),
                ],

                // Recent Blogs
                if (dashboardProvider.hasRecentBlogs) ...[
                  _buildSectionHeader('Recent Blogs', Icons.article_rounded, color: const Color(0xFF0891B2)),
                  const SizedBox(height: 14),
                  _buildRecentBlogsSection(dashboardProvider.recentBlogs),
                  const SizedBox(height: 24),
                ],

                // Community Posts
                if (dashboardProvider.hasRecentPosts) ...[
                  _buildSectionHeader('Community Posts', Icons.forum_rounded, color: _DS.royalBlue),
                  const SizedBox(height: 14),
                  _buildRecentPostsSection(dashboardProvider.recentPosts),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ─────────────────────────
  Widget _buildSectionHeader(String title, IconData? icon, {Color? color}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: (color ?? _DS.royalBlue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color ?? _DS.royalBlue),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _DS.textPrimary,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ── Welcome Hero ───────────────────────────
  Widget _buildWelcomeHero(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: _DS.heroGrad,
        borderRadius: BorderRadius.circular(_DS.radiusXL),
        boxShadow: _DS.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hey, ${user?.name?.split(' ').first ?? 'Cricketer'} 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Ready to dominate the pitch?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _DS.accentCyan.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.sports_cricket, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Create Match',
                  onTap: () => Navigator.pushNamed(context, '/create-match'),
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroButton(
                  icon: Icons.emoji_events_rounded,
                  label: 'Tournaments',
                  onTap: () => Navigator.pushNamed(context, '/tournaments'),
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick Stats ────────────────────────────
  Widget _buildQuickStatsRow(QuickStats stats) {
    return Row(
      children: [
        Expanded(child: _QuickStatCard(title: 'Matches', value: stats.totalMatches.toString(), icon: Icons.sports_cricket, gradient: const [Color(0xFF1A56DB), Color(0xFF3B82F6)])),
        const SizedBox(width: 10),
        Expanded(child: _QuickStatCard(title: 'Live', value: stats.liveMatches.toString(), icon: Icons.live_tv_rounded, gradient: const [Color(0xFFEF4444), Color(0xFFF87171)], isLive: true)),
        const SizedBox(width: 10),
        Expanded(child: _QuickStatCard(title: 'Cups', value: stats.totalTournaments.toString(), icon: Icons.emoji_events, gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)])),
      ],
    );
  }

  // ── Quick Actions ──────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      // Row 1
      [
        _ActionData(icon: Icons.add_circle_outline_rounded, title: 'Create Match', color: _DS.royalBlue, route: '/create-match'),
        _ActionData(icon: Icons.group_add_rounded, title: 'Create Team', color: const Color(0xFF7C3AED), route: '/create-team'),
        _ActionData(icon: Icons.person_add_rounded, title: 'Create Player', color: _DS.green, route: '/create-player'),
        _ActionData(icon: Icons.emoji_events_rounded, title: 'Join Cup', color: _DS.gold, route: '/tournaments'),
      ],
      // Row 2
      [
        _ActionData(icon: Icons.forum_outlined, title: 'Community', color: const Color(0xFF0284C7), route: '/community'),
        _ActionData(icon: Icons.chat_bubble_outline_rounded, title: 'Chats', color: const Color(0xFF0891B2), route: '/chats'),
        _ActionData(icon: Icons.notifications_outlined, title: 'Notifications', color: const Color(0xFF7C3AED), route: '/notifications'),
        _ActionData(icon: Icons.leaderboard_rounded, title: 'Leaderboard', color: _DS.gold, route: '/leaderboard'),
      ],
      // Row 3
      [
        _ActionData(icon: Icons.analytics_outlined, title: 'Scorecard', color: const Color(0xFFF97316), route: '/scorecard'),
        _ActionData(icon: Icons.people_rounded, title: 'Players', color: _DS.royalBlue, route: '/players'),
        _ActionData(icon: Icons.article_outlined, title: 'Live Matches', color: _DS.green, route: '/live-matches'),
        _ActionData(icon: Icons.live_tv_rounded, title: 'Go Live', color: const Color(0xFFDB2777), route: '/go-live'),
      ],
      // Row 4 – full width
      [
        _ActionData(icon: Icons.article_rounded, title: 'Blogs', color: const Color(0xFF0891B2), route: AppRoutes.blogs),
        _ActionData(icon: Icons.groups_rounded, title: 'Teams', color: _DS.green, route: '/teams'),
        _ActionData(icon: Icons.emoji_events_rounded, title: 'Tournaments', color: _DS.gold, route: '/tournaments'),
      ],
    ];

    return Column(
      children: actions.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: entry.value.asMap().entries.map((e) {
              final action = e.value;
              Widget card;
              if (action.title == 'Scorecard') {
                // Use Consumer for first live match id
                card = Consumer<DashboardProvider>(
                  builder: (context, provider, child) {
                    final firstMatchId = provider.getFirstLiveMatchId();
                    return _QuickActionCard(
                      icon: action.icon,
                      title: action.title,
                      color: action.color,
                      onTap: () => Navigator.pushNamed(context, '/scorecard', arguments: firstMatchId ?? ''),
                    );
                  },
                );
              } else {
                card = _QuickActionCard(
                  icon: action.icon,
                  title: action.title,
                  color: action.color,
                  onTap: () => Navigator.pushNamed(context, action.route),
                );
              }
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: e.key == 0 ? 0 : 8),
                  child: card,
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // ── Live Matches Section ───────────────────
  Widget _buildLiveMatchesSection(BuildContext context, List<LiveMatch> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _DS.live,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Matches',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _DS.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/matches/live'),
                style: TextButton.styleFrom(
                  foregroundColor: _DS.royalBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: _DS.royalBlue.withOpacity(0.08),
                ),
                child: const Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _LiveScoreCarousel(matches: matches),
        if (matches.length > 3)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/matches/live'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text('View all ${matches.length} Live Matches'),
              style: TextButton.styleFrom(foregroundColor: _DS.royalBlue),
            ),
          ),
      ],
    );
  }

  // ── Trending Players ───────────────────────
  Widget _buildTrendingPlayersSection(List<TrendingPlayer> players) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: players.length,
        itemBuilder: (context, index) => _TrendingPlayerCard(player: players[index]),
      ),
    );
  }

  // ── Upcoming Matches ───────────────────────
  Widget _buildUpcomingMatchesSection(List<UpcomingMatch> matches) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: matches.length > 5 ? 5 : matches.length,
      itemBuilder: (context, index) => _UpcomingMatchCard(match: matches[index]),
    );
  }

  // ── Recent Blogs ───────────────────────────
  Widget _buildRecentBlogsSection(List<BlogModel> blogs) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: blogs.length,
        itemBuilder: (context, index) => _RecentBlogCard(blog: blogs[index]),
      ),
    );
  }

  // ── Recent Posts ───────────────────────────
  Widget _buildRecentPostsSection(List<Map<String, dynamic>> posts) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        itemBuilder: (context, index) => _RecentPostCard(post: posts[index]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Action Data helper
// ─────────────────────────────────────────────
class _ActionData {
  final IconData icon;
  final String title;
  final Color color;
  final String route;
  const _ActionData({required this.icon, required this.title, required this.color, required this.route});
}

// ─────────────────────────────────────────────
//  Live Score Carousel
// ─────────────────────────────────────────────
class _LiveScoreCarousel extends StatefulWidget {
  final List<LiveMatch> matches;
  const _LiveScoreCarousel({required this.matches, super.key});

  @override
  State<_LiveScoreCarousel> createState() => _LiveScoreCarouselState();
}

class _LiveScoreCarouselState extends State<_LiveScoreCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (widget.matches.isEmpty) return;
      final nextIndex = (_currentIndex + 1) % widget.matches.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matches.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 170,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: widget.matches.length,
            itemBuilder: (context, index) {
              final match = widget.matches[index];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/match/${match.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _LiveMatchCard(match: match),
                ),
              );
            },
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.matches.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(entry.key, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentIndex == entry.key ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: _currentIndex == entry.key ? _DS.heroGrad : null,
                      color: _currentIndex == entry.key ? null : _DS.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Banner Carousel
// ─────────────────────────────────────────────
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({super.key});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentIndex = 0;
  late Timer _timer;

  final List<String> _bannerImages = [
    'https://static.vecteezy.com/system/resources/thumbnails/023/406/904/small/cricket-championship-banner-design-with-3d-red-ball-wicket-stumps-helmet-on-green-and-blue-playground-view-vector.jpg',
    'https://www.shutterstock.com/image-vector/illustration-batsman-playing-cricket-championship-600nw-2481429069.jpg',
    'https://t4.ftcdn.net/jpg/02/53/94/65/360_F_253946510_p1P2Izhc8XTglKaj025hTfFHxJwzVfIB.jpg',
    'https://static.vecteezy.com/system/resources/thumbnails/023/419/300/small/t20-cricket-fever-is-back-concept-with-cartoon-cricketer-players-in-action-pose-and-abstract-waves-on-blue-halftone-background-vector.jpg',
    'https://img.freepik.com/premium-vector/banner-with-cricket-tournaments-bat_1302-18992.jpg?semt=ais_incoming&w=740&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final next = (_currentIndex + 1) % _bannerImages.length;
      _pageController.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _bannerImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(_bannerImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // CTA
          Positioned(
            bottom: 18,
            left: 28,
            right: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Join Live\nContests Now!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                    shadows: [Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 4)],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/tournaments'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DS.gold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: const Text('Play Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
          ),
          // Dots
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_bannerImages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == index ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_currentIndex == index ? 1.0 : 0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Other Tabs
// ─────────────────────────────────────────────
class MatchesTab extends StatelessWidget {
  const MatchesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

    return RefreshIndicator(
      onRefresh: () => dashboardProvider.refreshDashboard(context),
      child: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          left: 16,
          right: 16,
          bottom: 24,
        ),
        children: [
          if (dashboardProvider.hasLiveMatches) ...[
            _SectionTitle(title: 'Live Matches', icon: Icons.circle, iconColor: _DS.live),
            const SizedBox(height: 12),
            ...dashboardProvider.liveMatches.map((match) => _LiveMatchDetailCard(match: match)),
            const SizedBox(height: 24),
          ],
          if (dashboardProvider.hasUpcomingMatches) ...[
            const _SectionTitle(title: 'Upcoming Matches', icon: Icons.schedule_rounded),
            const SizedBox(height: 12),
            ...dashboardProvider.upcomingMatches.map((match) => _UpcomingMatchDetailCard(match: match)),
          ],
          if (!dashboardProvider.hasLiveMatches && !dashboardProvider.hasUpcomingMatches)
            const _EmptyState(message: 'No matches available right now'),
        ],
      ),
    );
  }
}

class TournamentsTab extends StatelessWidget {
  const TournamentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final tournaments = dashboardProvider.latestTournaments;

    return RefreshIndicator(
      onRefresh: () => dashboardProvider.refreshDashboard(context),
      child: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          left: 16,
          right: 16,
          bottom: 24,
        ),
        children: [
          const _SectionTitle(title: 'Tournaments', icon: Icons.emoji_events_rounded),
          const SizedBox(height: 12),
          if (tournaments.isNotEmpty)
            ...tournaments.map((t) => _TournamentCard(tournament: t))
          else
            const _EmptyState(message: 'No tournaments available'),
        ],
      ),
    );
  }
}

class TeamsTab extends StatelessWidget {
  const TeamsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Teams feature coming soon!'));
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}

// ─────────────────────────────────────────────
//  Reusable Sub-widgets
// ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  const _SectionTitle({required this.title, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: iconColor ?? _DS.royalBlue),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _DS.textPrimary),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _DS.cardAlt,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded, size: 36, color: _DS.textMuted),
          ),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(color: _DS.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeroButton({required this.icon, required this.label, required this.onTap, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.35)),
          boxShadow: isPrimary ? [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isPrimary ? _DS.royalBlue : Colors.white),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? _DS.royalBlue : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final bool isLive;

  const _QuickStatCard({required this.title, required this.value, required this.icon, required this.gradient, this.isLive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(_DS.radiusMD),
        boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.32), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: Colors.white, size: 17),
              ),
              if (isLive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500)),
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

  const _QuickActionCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_DS.radiusMD),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: _DS.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 10.5,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveMatchCard extends StatelessWidget {
  final LiveMatch match;
  const _LiveMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_DS.radiusLG),
        boxShadow: _DS.cardShadow,
        border: Border.all(color: _DS.live.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: _DS.liveGrad,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: _DS.live.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.white),
                    SizedBox(width: 4),
                    Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _DS.cardAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  match.format.toUpperCase(),
                  style: const TextStyle(color: _DS.royalBlue, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Score rows
          _MatchTeamRow(teamName: match.team1.shortName, score: match.team1Score?.toString()),
          const SizedBox(height: 8),
          _MatchTeamRow(teamName: match.team2.shortName, score: match.team2Score?.toString()),
          const SizedBox(height: 12),
          // Tournament
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, size: 12, color: _DS.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  match.tournament.name,
                  style: const TextStyle(color: _DS.textMuted, fontSize: 10, overflow: TextOverflow.ellipsis),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchTeamRow extends StatelessWidget {
  final String teamName;
  final String? score;
  const _MatchTeamRow({required this.teamName, this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(teamName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _DS.textPrimary)),
        if (score != null)
          Text(score!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _DS.royalBlue)),
      ],
    );
  }
}

class _TrendingPlayerCard extends StatelessWidget {
  final TrendingPlayer player;
  const _TrendingPlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_DS.radiusMD),
        boxShadow: _DS.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: _DS.heroGrad,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#${player.rank}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(player.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _DS.textPrimary), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(player.team.shortName, style: const TextStyle(fontSize: 10, color: _DS.textSecondary)),
                const SizedBox(height: 2),
                Text('${player.stats.runs} runs · avg ${player.stats.average}', style: const TextStyle(fontSize: 9, color: _DS.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingMatchCard extends StatelessWidget {
  final UpcomingMatch match;
  const _UpcomingMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_DS.radiusLG),
        boxShadow: _DS.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: _DS.heroGrad,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.sports_cricket, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.team1.shortName}  vs  ${match.team2.shortName}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _DS.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(match.tournament.name, style: const TextStyle(color: _DS.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(gradient: _DS.heroGrad, borderRadius: BorderRadius.circular(8)),
                child: Text(match.format.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 5),
              Text(_formatDate(match.scheduledDate), style: const TextStyle(color: _DS.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─────────────────────────────────────────────
//  Recent Blog Card
// ─────────────────────────────────────────────
class _RecentBlogCard extends StatelessWidget {
  final BlogModel blog;
  const _RecentBlogCard({required this.blog});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_DS.radiusMD),
        boxShadow: _DS.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: blog.imageUrl ?? '',
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(height: 110, color: _DS.cardAlt, child: const Icon(Icons.article_outlined, color: _DS.textMuted)),
                errorWidget: (context, url, error) => Container(height: 110, color: _DS.cardAlt, child: const Icon(Icons.article_outlined, color: _DS.textMuted)),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(blog.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _DS.textPrimary, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text(blog.excerpt ?? '', style: const TextStyle(color: _DS.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (blog.author != null) ...[
                  const SizedBox(height: 3),
                  Text('by ${blog.author}', style: const TextStyle(color: _DS.textMuted, fontSize: 9)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Recent Post Card
// ─────────────────────────────────────────────
class _RecentPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _RecentPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final content  = post['content'] ?? '';
    final userName = post['userName'] ?? 'User';
    final image    = (post['images'] as List?)?.isNotEmpty == true ? post['images'][0] : null;

    return Container(
      width: 168,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_DS.radiusMD),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: _DS.heroGrad,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: _DS.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(post['timeAgo'] ?? 'recent', style: const TextStyle(color: _DS.textMuted, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Expanded(
            child: Text(content, style: const TextStyle(fontSize: 11, height: 1.4, color: _DS.textSecondary), maxLines: 4, overflow: TextOverflow.ellipsis),
          ),
          if (image != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: CachedNetworkImage(
                imageUrl: image,
                height: 56,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(height: 56, color: _DS.cardAlt, child: const Icon(Icons.image, size: 20, color: _DS.textMuted)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.thumb_up_outlined, size: 13, color: _DS.textSecondary),
              const SizedBox(width: 4),
              Text('${post['likes'] ?? 0}', style: const TextStyle(fontSize: 10, color: _DS.textSecondary)),
              const Spacer(),
              const Icon(Icons.comment_outlined, size: 13, color: _DS.textSecondary),
              const SizedBox(width: 4),
              Text('${post['comments'] ?? 0}', style: const TextStyle(fontSize: 10, color: _DS.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Detail Cards
// ─────────────────────────────────────────────
class _LiveMatchDetailCard extends StatelessWidget {
  final LiveMatch match;
  const _LiveMatchDetailCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_DS.radiusLG),
        boxShadow: _DS.liveShadow,
        border: Border.all(color: _DS.live.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: _DS.liveGrad,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 7, color: Colors.white),
                const SizedBox(width: 6),
                const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                const Spacer(),
                Text(match.tournament.name, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(match.team1.shortName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: _DS.textPrimary)),
                          if (match.team1Score != null)
                            Text(match.team1Score.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _DS.royalBlue)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(color: _DS.cardAlt, borderRadius: BorderRadius.circular(11)),
                      child: const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: _DS.royalBlue, fontSize: 14)),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(match.team2.shortName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: _DS.textPrimary)),
                          if (match.team2Score != null)
                            Text(match.team2Score.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _DS.royalBlue)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/match/${match.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DS.live,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Live Match', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingMatchDetailCard extends StatelessWidget {
  final UpcomingMatch match;
  const _UpcomingMatchDetailCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_DS.radiusLG),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(match.team1.shortName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: _DS.textPrimary)),
                    Text(match.team1.name, style: const TextStyle(fontSize: 10, color: _DS.textSecondary), textAlign: TextAlign.center),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(gradient: _DS.heroGrad, borderRadius: BorderRadius.circular(11)),
                    child: const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13)),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: _DS.cardAlt, borderRadius: BorderRadius.circular(7)),
                    child: Text(match.format.toUpperCase(), style: const TextStyle(color: _DS.royalBlue, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(match.team2.shortName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: _DS.textPrimary)),
                    Text(match.team2.name, style: const TextStyle(fontSize: 10, color: _DS.textSecondary), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: _DS.textMuted),
              const SizedBox(width: 5),
              Text(_formatDate(match.scheduledDate), style: const TextStyle(color: _DS.textSecondary, fontSize: 11)),
              const SizedBox(width: 14),
              const Icon(Icons.emoji_events_outlined, size: 12, color: _DS.textMuted),
              const SizedBox(width: 5),
              Expanded(child: Text(match.tournament.name, style: const TextStyle(color: _DS.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/match/${match.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _DS.royalBlue,
                side: BorderSide(color: _DS.royalBlue.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final isLive = tournament.status == 'live';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_DS.radiusLG),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: isLive ? _DS.liveGrad : _DS.heroGrad,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(tournament.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14), overflow: TextOverflow.ellipsis),
                ),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(8)),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    _TournamentInfoChip(icon: Icons.sports_cricket, label: tournament.format.toUpperCase()),
                    const SizedBox(width: 8),
                    _TournamentInfoChip(icon: Icons.category_outlined, label: tournament.type),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: _DS.textMuted),
                    const SizedBox(width: 4),
                    Text('${tournament.venue.name}, ${tournament.venue.city}', style: const TextStyle(fontSize: 12, color: _DS.textSecondary)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: _DS.textMuted),
                    const SizedBox(width: 4),
                    Text('${_formatDate(tournament.startDate)} — ${_formatDate(tournament.endDate)}', style: const TextStyle(fontSize: 12, color: _DS.textSecondary)),
                  ],
                ),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/tournament/${tournament.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _DS.royalBlue,
                      side: BorderSide(color: _DS.royalBlue.withOpacity(0.35)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Tournament', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _TournamentInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TournamentInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _DS.cardAlt,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _DS.royalBlue),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: _DS.royalBlue, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}