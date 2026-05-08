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
import '../../data/models/tournament_model.dart';

import 'dart:async';
import '../../core/widgets/profile_avatar.dart';

// ─────────────────────────────────────────────
//  Design Tokens — Professional White Theme
// ─────────────────────────────────────────────
class _DS {
  // Primary palette
  static const primary     = Color(0xFF1A56DB);
  static const primaryDark = Color(0xFF0D2147);
  static const primarySoft = Color(0xFFEEF4FF);
  static const accent      = Color(0xFF06B6D4);
  static const accentSoft  = Color(0xFFECFEFF);

  // Surfaces — clean white theme
  static const background  = Color(0xFFF5F7FF);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF8FAFF);
  static const surfaceBorder = Color(0xFFE8EEFF);

  // Status colors
  static const live        = Color(0xFFEF4444);
  static const liveSoft    = Color(0xFFFFF1F1);
  static const gold        = Color(0xFFF59E0B);
  static const goldSoft    = Color(0xFFFFFBEB);
  static const green       = Color(0xFF10B981);
  static const greenSoft   = Color(0xFFECFDF5);
  static const purple      = Color(0xFF7C3AED);
  static const purpleSoft  = Color(0xFFF5F3FF);

  // Text
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFF94A3B8);
  static const textHint      = Color(0xFFCBD5E1);

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
  static const LinearGradient purpleGrad = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows — softer, more refined
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> heroShadow = [
    BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.28), blurRadius: 32, offset: const Offset(0, 14)),
  ];
  static List<BoxShadow> liveShadow = [
    BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> navShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4)),
    BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2)),
  ];

  // Radius
  static const double radiusXXL = 28;
  static const double radiusXL  = 22;
  static const double radiusLG  = 16;
  static const double radiusMD  = 12;
  static const double radiusSM  = 8;
  static const double radiusXS  = 6;
}

// ─────────────────────────────────────────────
//  Main DashboardScreen
// ─────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
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
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: _DS.background,
            extendBodyBehindAppBar: true,
            drawer: _buildDrawer(authProvider),
            appBar: _buildAppBar(dashboardProvider),
            body: Stack(
              children: [
                RefreshIndicator(
                  color: _DS.primary,
                  strokeWidth: 2.5,
                  onRefresh: () => dashboardProvider.refreshDashboard(context),
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
                if (dashboardProvider.isLoading) _buildLoadingOverlay(),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(),
          ),
        );
      },
    );
  }

  // ── Loading Overlay ────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(_DS.radiusXL),
            boxShadow: [
              BoxShadow(
                color: _DS.primary.withOpacity(0.14),
                blurRadius: 48,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  color: _DS.primary,
                  strokeWidth: 2.5,
                  backgroundColor: _DS.primarySoft,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Loading...',
                style: TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
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
      title: Row(
        children: [
          // Logo container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_DS.primary, _DS.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _DS.accent.withOpacity(0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.sports_cricket, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scores11',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Cricket Live',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const _AppBarIcon(icon: Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      actions: [
        // Notification bell with live badge
        Stack(
          children: [
            IconButton(
              icon: const _AppBarIcon(icon: Icons.notifications_outlined),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
            if (dashboardProvider.quickStats.liveMatches > 0)
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    gradient: _DS.liveGrad,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [BoxShadow(color: _DS.live.withOpacity(0.5), blurRadius: 6)],
                  ),
                  child: Center(
                    child: Text(
                      '${dashboardProvider.quickStats.liveMatches}',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const _AppBarIcon(icon: Icons.search_rounded),
          onPressed: () => Navigator.pushNamed(context, '/players'),
        ),
        IconButton(
          icon: const _AppBarIcon(icon: Icons.chat_bubble_outline_rounded),
          onPressed: () => Navigator.pushNamed(context, '/chats'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Bottom Navigation Bar ──────────────────
  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.home_outlined,           'activeIcon': Icons.home_rounded,       'label': 'Home'},
      {'icon': Icons.sports_cricket_outlined, 'activeIcon': Icons.sports_cricket,     'label': 'Matches'},
      {'icon': Icons.emoji_events_outlined,   'activeIcon': Icons.emoji_events,       'label': 'Cups'},
      {'icon': Icons.groups_outlined,         'activeIcon': Icons.groups,             'label': 'Teams'},
      {'icon': Icons.person_outline_rounded,  'activeIcon': Icons.person_rounded,     'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        boxShadow: _DS.navShadow,
        border: const Border(top: BorderSide(color: Color(0xFFEEF2FF), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = _currentIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 16 : 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? _DS.heroGrad : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isSelected
                        ? [BoxShadow(color: _DS.primary.withOpacity(0.32), blurRadius: 12, offset: const Offset(0, 4))]
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
                        const SizedBox(width: 6),
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
      backgroundColor: _DS.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(_DS.radiusXXL),
          bottomRight: Radius.circular(_DS.radiusXXL),
        ),
      ),
      child: Column(
        children: [
          // ── Drawer Header ───────────────────
          _DrawerHeader(user: user),

          // ── Nav Items ───────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: [
                _DrawerSectionLabel(label: 'MAIN'),
                _DrawerNavItem(icon: Icons.dashboard_rounded,     label: 'Dashboard',    isActive: _currentIndex == 0, onTap: () { Navigator.pop(context); setState(() => _currentIndex = 0); }),
                _DrawerNavItem(icon: Icons.sports_cricket,        label: 'Matches',      isActive: _currentIndex == 1, onTap: () { Navigator.pop(context); setState(() => _currentIndex = 1); }),
                _DrawerNavItem(icon: Icons.emoji_events_rounded,  label: 'Tournaments',  isActive: _currentIndex == 2, onTap: () { Navigator.pop(context); setState(() => _currentIndex = 2); }),
                _DrawerNavItem(icon: Icons.groups_rounded,        label: 'Teams',        isActive: _currentIndex == 3, onTap: () { Navigator.pop(context); setState(() => _currentIndex = 3); }),
                _DrawerNavItem(icon: Icons.people_rounded,        label: 'Players',      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/players'); }),

                const SizedBox(height: 4),
                _DrawerSectionLabel(label: 'FEATURES'),
                _DrawerNavItem(icon: Icons.live_tv_rounded,       label: 'Live Matches',  badge: 'LIVE', badgeGrad: _DS.liveGrad,  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/live-matches'); }),
                _DrawerNavItem(icon: Icons.analytics_outlined,    label: 'Scorecards',    onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/scorecards'); }),
                _DrawerNavItem(icon: Icons.leaderboard_outlined,  label: 'Leaderboards',  onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/leaderboards'); }),
                _DrawerNavItem(icon: Icons.article_outlined,      label: 'Blogs',         onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/blogs'); }),
                _DrawerNavItem(icon: Icons.forum_outlined,        label: 'Community',     onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/community'); }),
                _DrawerNavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chats',   onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/chats'); }),
                _DrawerNavItem(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/notifications'); }),

                const SizedBox(height: 4),
                _DrawerSectionLabel(label: 'ACCOUNT'),
                _DrawerNavItem(icon: Icons.person_rounded,        label: 'Profile',       isActive: _currentIndex == 4, onTap: () { Navigator.pop(context); setState(() => _currentIndex = 4); }),
                _DrawerNavItem(icon: Icons.settings_rounded,      label: 'Settings',      onTap: () => Navigator.pushNamed(context, AppRoutes.settings)),
                _DrawerNavItem(icon: Icons.help_outline_rounded,  label: 'Help & Support', onTap: () => Navigator.pushNamed(context, '/help-support')),
                _DrawerNavItem(icon: Icons.privacy_tip_outlined,  label: 'Privacy Policy', onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy)),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: _DS.surfaceBorder, height: 1),
                ),

                // Logout
                _DrawerNavItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  iconColor: _DS.live,
                  labelColor: _DS.live,
                  iconBgColor: _DS.liveSoft,
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context, Provider.of<AuthProvider>(context, listen: false));
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Drawer Footer ───────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _DS.primarySoft,
              borderRadius: BorderRadius.circular(_DS.radiusMD),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_cricket, size: 16, color: _DS.primary),
                const SizedBox(width: 8),
                Text(
                  'Scores11 v1.0.0',
                  style: const TextStyle(
                    color: _DS.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _DS.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusXL)),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _DS.liveSoft,
                borderRadius: BorderRadius.circular(_DS.radiusMD),
              ),
              child: const Icon(Icons.logout_rounded, color: _DS.live, size: 22),
            ),
            const SizedBox(width: 14),
            const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _DS.textPrimary),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout from your account?',
          style: TextStyle(color: _DS.textSecondary, fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusMD)),
            ),
            child: const Text('Cancel', style: TextStyle(color: _DS.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _DS.live,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusMD)),
            ),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Drawer Header Widget
// ─────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final dynamic user;
  const _DrawerHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: _DS.heroGrad,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 14)],
                ),
                child: ClipOval(
                  child: user?.avatar?.url != null
                      ? Image.network(
                          user!.avatar!.url!,
                          width: 64, height: 64, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _DefaultAvatar(),
                        )
                      : _DefaultAvatar(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Cric11 User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Online indicator
                    Row(
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Online',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stat chips row
          Row(
            children: [
              _StatChip(label: '🏏 Player'),
              const SizedBox(width: 8),
              _StatChip(label: '⭐ Pro'),
              const SizedBox(width: 8),
              _StatChip(label: '🏆 Active'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _DS.heroGrad),
      child: const Icon(Icons.person, size: 32, color: Colors.white),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Drawer Section Label
// ─────────────────────────────────────────────
class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  const _DrawerSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: _DS.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Drawer Nav Item — Redesigned
// ─────────────────────────────────────────────
class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final String? badge;
  final LinearGradient? badgeGrad;
  final Color? iconColor;
  final Color? labelColor;
  final Color? iconBgColor;

  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.badge,
    this.badgeGrad,
    this.iconColor,
    this.labelColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? (isActive ? _DS.primary : _DS.textSecondary);
    final resolvedLabelColor = labelColor ?? (isActive ? _DS.primary : _DS.textPrimary);
    final resolvedIconBg = iconBgColor ?? (isActive ? _DS.primarySoft : _DS.surfaceAlt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Material(
        color: isActive ? _DS.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(_DS.radiusMD),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_DS.radiusMD),
          splashColor: _DS.primary.withOpacity(0.08),
          highlightColor: _DS.primary.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: resolvedIconBg,
                    borderRadius: BorderRadius.circular(_DS.radiusSM),
                    border: isActive
                        ? Border.all(color: _DS.primary.withOpacity(0.2))
                        : null,
                  ),
                  child: Icon(icon, color: resolvedIconColor, size: 18),
                ),
                const SizedBox(width: 13),
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: resolvedLabelColor,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Badge
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: badgeGrad,
                      color: badgeGrad == null ? _DS.primarySoft : null,
                      borderRadius: BorderRadius.circular(_DS.radiusXS),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        color: badgeGrad != null ? Colors.white : _DS.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                // Active indicator
                if (isActive)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      color: _DS.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AppBar Icon Widget
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
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
      return const Center(child: CircularProgressIndicator(color: _DS.primary));
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
          const SizedBox(height: 14),

          // Welcome Hero
          _buildWelcomeHero(context),
          const SizedBox(height: 20),

          // Live Matches
          if (dashboardProvider.hasLiveMatches) ...[
            _buildLiveHeader(context, dashboardProvider.liveMatches.length),
            const SizedBox(height: 12),
            _LiveScoreCarousel(matches: dashboardProvider.liveMatches),
            const SizedBox(height: 20),
          ],

          // Banner Carousel
          const _BannerCarousel(),
          const SizedBox(height: 22),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Stats
                _buildQuickStatsRow(dashboardProvider.quickStats),
                const SizedBox(height: 26),

                // Quick Actions
                _buildSectionHeader('Quick Actions', Icons.bolt_rounded, color: _DS.gold),
                const SizedBox(height: 14),
                _buildQuickActions(context),
                const SizedBox(height: 26),

                // Trending Players
                if (dashboardProvider.hasTrendingPlayers) ...[
                  _buildSectionHeader('Trending Players', Icons.trending_up_rounded, color: const Color(0xFFF97316)),
                  const SizedBox(height: 14),
                  _buildTrendingPlayersSection(dashboardProvider.trendingPlayers),
                  const SizedBox(height: 26),
                ],

                // Upcoming Matches
                if (dashboardProvider.hasUpcomingMatches) ...[
                  _buildSectionHeader('Upcoming Matches', Icons.schedule_rounded, color: _DS.primary),
                  const SizedBox(height: 14),
                  _buildUpcomingMatchesSection(dashboardProvider.upcomingMatches),
                  const SizedBox(height: 26),
                ],

                // Recent Blogs
                if (dashboardProvider.hasRecentBlogs) ...[
                  _buildSectionHeader('Recent Blogs', Icons.article_rounded, color: const Color(0xFF0891B2)),
                  const SizedBox(height: 14),
                  _buildRecentBlogsSection(dashboardProvider.recentBlogs),
                  const SizedBox(height: 26),
                ],

                // Community Posts
                if (dashboardProvider.hasRecentPosts) ...[
                  _buildSectionHeader('Community Posts', Icons.forum_rounded, color: _DS.purple),
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
  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (color ?? _DS.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(_DS.radiusSM),
          ),
          child: Icon(icon, size: 16, color: color ?? _DS.primary),
        ),
        const SizedBox(width: 10),
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

  // ── Live Header ────────────────────────────
  Widget _buildLiveHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: _DS.live, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          const Text(
            'Live Now',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _DS.textPrimary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(gradient: _DS.liveGrad, borderRadius: BorderRadius.circular(20)),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/matches/live'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _DS.primarySoft,
                borderRadius: BorderRadius.circular(_DS.radiusSM),
              ),
              child: const Text(
                'See All',
                style: TextStyle(color: _DS.primary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Welcome Hero ───────────────────────────
  Widget _buildWelcomeHero(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final firstName = user?.name?.split(' ').first ?? 'Cricketer';

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
                      'Hey, $firstName 👋',
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
                      style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _DS.accent.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.sports_cricket, color: Colors.white, size: 26),
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
      [
        _ActionData(icon: Icons.add_circle_outline_rounded, title: 'Create Match',   color: _DS.primary,              route: '/create-match'),
        _ActionData(icon: Icons.group_add_rounded,          title: 'Create Team',    color: _DS.purple,               route: '/create-team'),
        _ActionData(icon: Icons.person_add_rounded,         title: 'Create Player',  color: _DS.green,                route: '/create-player'),
        _ActionData(icon: Icons.emoji_events_rounded,       title: 'Join Cup',       color: _DS.gold,                 route: '/tournaments'),
      ],
      [
        _ActionData(icon: Icons.forum_outlined,             title: 'Community',      color: const Color(0xFF0284C7),  route: '/community'),
        _ActionData(icon: Icons.chat_bubble_outline_rounded,title: 'Chats',          color: const Color(0xFF0891B2),  route: '/chats'),
        _ActionData(icon: Icons.notifications_outlined,     title: 'Alerts',         color: _DS.purple,               route: '/notifications'),
        _ActionData(icon: Icons.leaderboard_rounded,        title: 'Leaderboard',    color: _DS.gold,                 route: '/leaderboard'),
      ],
      [
        _ActionData(icon: Icons.analytics_outlined,         title: 'Scorecard',      color: const Color(0xFFF97316),  route: '/scorecard'),
        _ActionData(icon: Icons.people_rounded,             title: 'Players',        color: _DS.primary,              route: '/players'),
        _ActionData(icon: Icons.article_outlined,           title: 'Live Matches',   color: _DS.green,                route: '/live-matches'),
        _ActionData(icon: Icons.live_tv_rounded,            title: 'Go Live',        color: const Color(0xFFDB2777),  route: '/go-live'),
      ],
      [
        _ActionData(icon: Icons.article_rounded,            title: 'Blogs',          color: const Color(0xFF0891B2),  route: AppRoutes.blogs),
        _ActionData(icon: Icons.groups_rounded,             title: 'Teams',          color: _DS.green,                route: '/teams'),
        _ActionData(icon: Icons.emoji_events_rounded,       title: 'Tournaments',    color: _DS.gold,                 route: '/tournaments'),
      ],
    ];

    return Column(
      children: actions.asMap().entries.map((entry) {
        final row = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: row.asMap().entries.map((e) {
              final action = e.value;
              Widget card;
              if (action.title == 'Scorecard') {
                card = Consumer<DashboardProvider>(
                  builder: (context, provider, child) {
                    final firstMatchId = provider.getFirstLiveMatchId();
                    return _QuickActionCard(
                      icon: action.icon, title: action.title, color: action.color,
                      onTap: () => Navigator.pushNamed(context, '/scorecard', arguments: firstMatchId ?? ''),
                    );
                  },
                );
              } else {
                card = _QuickActionCard(
                  icon: action.icon, title: action.title, color: action.color,
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
//  Action Data
// ─────────────────────────────────────────────
class _ActionData {
  final IconData icon;
  final String title;
  final Color color;
  final String route;
  const _ActionData({required this.icon, required this.title, required this.color, required this.route});
}

// ─────────────────────────────────────────────
//  Hero Button
// ─────────────────────────────────────────────
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
          color: isPrimary ? Colors.white : Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(_DS.radiusMD),
          border: isPrimary ? null : Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: isPrimary ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isPrimary ? _DS.primary : Colors.white),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isPrimary ? _DS.primary : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Quick Stat Card
// ─────────────────────────────────────────────
class _QuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final bool isLive;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(_DS.radiusMD),
        boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: Colors.white, size: 17),
              ),
              if (isLive)
                Container(
                  width: 7, height: 7,
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

// ─────────────────────────────────────────────
//  Quick Action Card — Improved
// ─────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(_DS.radiusMD),
          border: Border.all(color: _DS.surfaceBorder, width: 1),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
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
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
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
    _pageController = PageController(viewportFraction: 0.9);
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
      height: 168,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: widget.matches.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/match/${widget.matches[index].id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _LiveMatchCard(match: widget.matches[index]),
                ),
              );
            },
          ),
          // Dot indicators
          Positioned(
            bottom: 10,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.matches.asMap().entries.map((entry) {
                final isSelected = _currentIndex == entry.key;
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(entry.key, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isSelected ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? _DS.primary : _DS.textHint,
                      borderRadius: BorderRadius.circular(3),
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
//  Live Match Card — Refined
// ─────────────────────────────────────────────
class _LiveMatchCard extends StatelessWidget {
  final LiveMatch match;
  const _LiveMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusLG),
        border: Border.all(color: _DS.live.withOpacity(0.1)),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Live badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: _DS.liveGrad,
                  borderRadius: BorderRadius.circular(7),
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
              // Format badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _DS.primarySoft,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  match.format.toUpperCase(),
                  style: const TextStyle(color: _DS.primary, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MatchTeamRow(teamName: match.team1.shortName, score: match.team1Score?.toString()),
          const SizedBox(height: 8),
          _MatchTeamRow(teamName: match.team2.shortName, score: match.team2Score?.toString()),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, size: 12, color: _DS.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  match.tournament.name,
                  style: const TextStyle(color: _DS.textMuted, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
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
          Text(score!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _DS.primary)),
      ],
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
      height: 196,
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
                  borderRadius: BorderRadius.circular(_DS.radiusXL),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(_bannerImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_DS.radiusXL),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                    ),
                  ),
                ),
              );
            },
          ),
          // CTA overlay
          Positioned(
            bottom: 18, left: 28, right: 28,
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
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Play Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
          ),
          // Dots
          Positioned(
            bottom: 58, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_bannerImages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_currentIndex == index ? 1.0 : 0.45),
                    borderRadius: BorderRadius.circular(3),
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
//  Trending Player Card
// ─────────────────────────────────────────────
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
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusMD),
        border: Border.all(color: _DS.surfaceBorder),
        boxShadow: _DS.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(gradient: _DS.heroGrad, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text('#${player.rank}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
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

// ─────────────────────────────────────────────
//  Upcoming Match Card — Refined
// ─────────────────────────────────────────────
class _UpcomingMatchCard extends StatelessWidget {
  final UpcomingMatch match;
  const _UpcomingMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusLG),
        border: Border.all(color: _DS.surfaceBorder),
        boxShadow: _DS.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(gradient: _DS.heroGrad, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.sports_cricket, color: Colors.white, size: 22),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(gradient: _DS.heroGrad, borderRadius: BorderRadius.circular(7)),
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
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusMD),
        border: Border.all(color: _DS.surfaceBorder),
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
                height: 110, width: double.infinity, fit: BoxFit.cover,
                placeholder: (context, url) => Container(height: 110, color: _DS.surfaceAlt, child: const Icon(Icons.article_outlined, color: _DS.textMuted)),
                errorWidget: (context, url, error) => Container(height: 110, color: _DS.surfaceAlt, child: const Icon(Icons.article_outlined, color: _DS.textMuted)),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
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
                const SizedBox(height: 4),
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
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusMD),
        border: Border.all(color: _DS.surfaceBorder),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(gradient: _DS.heroGrad, shape: BoxShape.circle),
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
                height: 56, width: double.infinity, fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(height: 56, color: _DS.surfaceAlt, child: const Icon(Icons.image, size: 20, color: _DS.textMuted)),
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
//  Other Tabs
// ─────────────────────────────────────────────
class MatchesTab extends StatelessWidget {
  const MatchesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

    return RefreshIndicator(
      color: _DS.primary,
      onRefresh: () => dashboardProvider.refreshDashboard(context),
      child: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          left: 16, right: 16, bottom: 24,
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
      color: _DS.primary,
      onRefresh: () => dashboardProvider.refreshDashboard(context),
      child: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          left: 16, right: 16, bottom: 24,
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
          Icon(icon, size: 13, color: iconColor ?? _DS.primary),
          const SizedBox(width: 6),
        ],
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _DS.textPrimary)),
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
            width: 72, height: 72,
            decoration: BoxDecoration(color: _DS.surfaceAlt, shape: BoxShape.circle),
            child: const Icon(Icons.inbox_rounded, size: 36, color: _DS.textMuted),
          ),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(color: _DS.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
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
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusLG),
        border: Border.all(color: _DS.live.withOpacity(0.1)),
        boxShadow: _DS.liveShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              gradient: _DS.liveGrad,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 7, color: Colors.white),
                const SizedBox(width: 6),
                const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
                const Spacer(),
                Expanded(
                  child: Text(match.tournament.name, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11), overflow: TextOverflow.ellipsis, textAlign: TextAlign.end),
                ),
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
                            Text(match.team1Score.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _DS.primary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(color: _DS.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                      child: const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: _DS.primary, fontSize: 14)),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(match.team2.shortName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: _DS.textPrimary)),
                          if (match.team2Score != null)
                            Text(match.team2Score.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _DS.primary)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusMD)),
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
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusLG),
        border: Border.all(color: _DS.surfaceBorder),
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
                    decoration: BoxDecoration(gradient: _DS.heroGrad, borderRadius: BorderRadius.circular(10)),
                    child: const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13)),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: _DS.primarySoft, borderRadius: BorderRadius.circular(7)),
                    child: Text(match.format.toUpperCase(), style: const TextStyle(color: _DS.primary, fontSize: 9, fontWeight: FontWeight.w800)),
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
                foregroundColor: _DS.primary,
                side: BorderSide(color: _DS.primary.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusMD)),
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

// ─────────────────────────────────────────────
//  Tournament Card
// ─────────────────────────────────────────────
class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final isLive = tournament.status == 'live';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusLG),
        border: Border.all(color: _DS.surfaceBorder),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: isLive ? _DS.liveGrad : _DS.heroGrad,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
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
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(7)),
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
                    Text('${tournament.venue ?? 'TBD'}, ${tournament.city ?? 'TBD'}', style: const TextStyle(fontSize: 12, color: _DS.textSecondary)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: _DS.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(tournament.startDate)} — ${_formatDate(tournament.endDate)}',
                      style: const TextStyle(fontSize: 12, color: _DS.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/tournament/${tournament.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _DS.primary,
                      side: BorderSide(color: _DS.primary.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusMD)),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
    return '${date.day}/${date.month}/${date.year}';
  }
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
        color: _DS.primarySoft,
        borderRadius: BorderRadius.circular(_DS.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _DS.primary),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: _DS.primary, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}