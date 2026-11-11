// lib/presentation/screens/dashboard_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/logout_helper.dart';
import '../../providers/dashboard_provider.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/models/match_model.dart';
import '../../data/models/player_model.dart';
import '../../data/models/team_model.dart' as app_team;
import '../../data/models/user_model.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/friendly_error.dart';
import '../profile/profile_screen.dart';
import '../../features/profile/cricket_profile_screen.dart';
import '../../features/discovery/discovery_screen.dart';
import '../../features/community/community_feed_screen.dart';
import '../../data/services/player_service.dart';
import '../../data/services/team_service.dart';
import '../../data/services/match_service.dart';
import '../../data/services/tournament_service.dart';
import '../../data/services/story_service.dart';
import '../../data/services/upload_service.dart';
import '../../data/services/blog_service.dart';
import '../../data/services/community_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/live_stream_service.dart';
import '../../data/models/live_stream_model.dart';
import '../../data/models/notification_model.dart';
import '../../core/services/notification_effect_service.dart';
import '../../core/services/socket_service.dart';
import '../../data/models/blog_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/banner_service.dart';
import '../../data/models/tournament_model.dart';

import 'dart:async';
import '../../core/widgets/profile_avatar.dart';

// ─────────────────────────────────────────────
//  Design Tokens — Professional White Theme
// ─────────────────────────────────────────────
class _DS {
  // Primary palette
  static const primary = Color(0xFF1657CC);
  static const primaryDark = Color(0xFF0D2B5E);
  static const primarySoft = Color(0xFFE8F0FE);
  static const accent = Color(0xFF06B6D4);
  static const accentSoft = Color(0xFFECFEFF);

  // Surfaces — clean white theme
  static const background = Color(0xFFF5F7FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFF);
  static const surfaceBorder = Color(0xFFE8EEFF);

  // Status colors
  static const live = Color(0xFFE31E3C);
  static const liveSoft = Color(0xFFFFF1F1);
  static const gold = Color(0xFFF59E0B);
  static const goldSoft = Color(0xFFFFFBEB);
  static const green = Color(0xFF10B981);
  static const greenSoft = Color(0xFFECFDF5);
  static const purple = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFF5F3FF);

  // Text
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const textHint = Color(0xFFCBD5E1);

  // Gradients
  static const LinearGradient heroGrad = LinearGradient(
    colors: [Color(0xFF0D2B5E), Color(0xFF1657CC), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient appBarGrad = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF0D2B5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient liveGrad = LinearGradient(
    colors: [Color(0xFFE31E3C), Color(0xFFB71C1C)],
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
    BoxShadow(
        color: const Color(0xFF1657CC).withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 4)),
    BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 8,
        offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> heroShadow = [
    BoxShadow(
        color: const Color(0xFF1657CC).withOpacity(0.28),
        blurRadius: 32,
        offset: const Offset(0, 14)),
  ];
  static List<BoxShadow> liveShadow = [
    BoxShadow(
        color: const Color(0xFFE31E3C).withOpacity(0.18),
        blurRadius: 16,
        offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> navShadow = [
    BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, -4)),
    BoxShadow(
        color: const Color(0xFF1657CC).withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, -2)),
  ];

  // Radius
  static const double radiusXXL = 28;
  static const double radiusXL = 22;
  static const double radiusLG = 16;
  static const double radiusMD = 12;
  static const double radiusSM = 8;
  static const double radiusXS = 6;
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
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();
  final SocketService _socketService = SocketService();
  Timer? _badgeRefreshTimer;
  Timer? _liveMatchesRefreshTimer;
  int _unreadNotificationCount = 0;
  int _unreadChatCount = 0;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboard();
      _loadNavBadges();
      final userId =
          Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
      _setupNotificationRealtime(userId);
    });
    _badgeRefreshTimer =
        Timer.periodic(const Duration(seconds: 45), (_) => _loadNavBadges());
    // The dashboard only fetches live matches once on load, so a match that
    // finishes mid-session used to linger in the "Live" section until the
    // user manually pulled to refresh. Poll quietly in the background instead.
    _liveMatchesRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      Provider.of<DashboardProvider>(context, listen: false)
          .fetchDashboardData(silent: true);
    });
  }

  Future<void> _setupNotificationRealtime(String userId) async {
    if (userId.isEmpty || userId == 'guest-user') return;
    try {
      await _socketService.connect();
      _socketService.authenticateUser(userId);
      _socketService.onNotification((data) async {
        await NotificationEffectService.play(
          sound: data is Map
              ? (data['sound']?.toString() ?? 'scores11')
              : 'scores11',
        );
        _loadNavBadges();
      });
      _socketService.onNotificationCount((data) {
        final raw = data is Map ? data['count'] : data;
        final count = int.tryParse(raw?.toString() ?? '');
        if (!mounted || count == null) return;
        setState(() => _unreadNotificationCount = count);
      });
    } catch (_) {
      // Polling keeps badges correct if realtime is unavailable.
    }
  }

  Future<void> _loadNavBadges() async {
    try {
      final results = await Future.wait<dynamic>([
        _notificationService.getUnreadCount(),
        _chatService.getChats(),
      ]);
      final notificationCount = results[0] is int ? results[0] as int : 0;
      final chats = results[1] is List ? results[1] as List : const [];
      final chatCount = chats.fold<int>(0, (sum, chat) {
        if (chat is! Map) return sum;
        final unread = chat['unreadCount'];
        if (unread is int) return sum + unread;
        if (unread is Map) {
          return sum +
              unread.values.fold<int>(
                0,
                (innerSum, value) =>
                    innerSum + (int.tryParse(value?.toString() ?? '') ?? 0),
              );
        }
        return sum + (int.tryParse(unread?.toString() ?? '') ?? 0);
      });
      if (!mounted) return;
      setState(() {
        _unreadNotificationCount = notificationCount;
        _unreadChatCount = chatCount;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _unreadNotificationCount = 0;
        _unreadChatCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _badgeRefreshTimer?.cancel();
    _liveMatchesRefreshTimer?.cancel();
    _socketService.offNotification();
    _socketService.offNotificationCount();
    _fabAnimController.dispose();
    super.dispose();
  }

  bool _isFanRole(AuthProvider authProvider) {
    final role = authProvider.userRole?.toLowerCase();
    return role == 'user';
  }

  List<Widget> _visibleScreens() {
    return const [
      HomeTab(key: ValueKey('home-tab')),
      DiscoveryScreen(key: ValueKey('looking-tab')),
      CricketProfileScreen(key: ValueKey('my-cricket-tab')),
      CommunityFeedScreen(key: ValueKey('community-tab')),
      ProfileTab(key: ValueKey('profile-tab')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DashboardProvider>(
      builder: (context, authProvider, dashboardProvider, child) {
        final isFan = _isFanRole(authProvider);
        final screens = _visibleScreens();
        if (_currentIndex >= screens.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = 0);
          });
        }
        final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            extendBodyBehindAppBar: true,
            drawer: _buildDrawer(authProvider),
            appBar: safeIndex == 0 ? _buildAppBar(dashboardProvider) : null,
            body: Stack(
              children: [
                RefreshIndicator(
                  color: _DS.primary,
                  strokeWidth: 2.5,
                  onRefresh: () => dashboardProvider.refreshDashboard(context),
                  child: IndexedStack(
                    index: safeIndex,
                    children: screens,
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
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 370;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withOpacity(0.06),
      centerTitle: true,
      titleSpacing: 0,
      title: _Scores11AppBarLogo(compact: compact),
      leading: Builder(
        builder: (context) => IconButton(
          constraints: const BoxConstraints.tightFor(width: 42, height: 44),
          padding: EdgeInsets.zero,
          icon: const _AppBarIcon(icon: Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 40, height: 44),
              padding: EdgeInsets.zero,
              icon: const _AppBarIcon(icon: Icons.notifications_outlined),
              onPressed: _openNotificationCenter,
            ),
            if (_unreadNotificationCount > 0)
              _AppBarBadge(
                  count: _unreadNotificationCount, gradient: _DS.liveGrad),
          ],
        ),
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 40, height: 44),
          padding: EdgeInsets.zero,
          icon: const _AppBarIcon(icon: Icons.search_rounded),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const _GlobalCricketSearchScreen()),
          ),
        ),
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 40, height: 44),
          padding: EdgeInsets.zero,
          icon: const _AppBarIcon(icon: Icons.qr_code_scanner_rounded),
          onPressed: _openQrScannerSheet,
        ),
        Stack(
          children: [
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 40, height: 44),
              padding: EdgeInsets.zero,
              icon:
                  const _AppBarIcon(icon: Icons.chat_bubble_outline_rounded),
              onPressed: () async {
                await Navigator.pushNamed(context, '/chats');
                _loadNavBadges();
              },
            ),
            if (_unreadChatCount > 0)
              _AppBarBadge(count: _unreadChatCount, gradient: _DS.greenGrad),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _openQrScannerSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _QrScanEntryScreen()),
    );
  }

  Future<void> _openNotificationCenter() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.28),
      builder: (_) => _NotificationCenterSheet(
        service: _notificationService,
        onOpenAll: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/notifications')
              .then((_) => _loadNavBadges());
        },
        onOpenNotification: (notification) {
          Navigator.pop(context);
          _openNotificationTarget(notification);
        },
        onUnreadChanged: _loadNavBadges,
      ),
    );
    if (mounted) _loadNavBadges();
  }

  void _openNotificationTarget(NotificationModel notification) {
    final id = notification.referenceId?.trim() ?? '';
    final type = notification.type.toLowerCase();
    if (id.isNotEmpty && (type.contains('match') || type.contains('score'))) {
      Navigator.pushNamed(context, '/match/$id');
    } else if (id.isNotEmpty && type.contains('team')) {
      Navigator.pushNamed(context, '/team-detail', arguments: id);
    } else if (id.isNotEmpty && type.contains('tournament')) {
      Navigator.pushNamed(context, '/tournament/$id');
    } else if (id.isNotEmpty &&
        (type.contains('post') ||
            type.contains('community') ||
            type.contains('comment') ||
            type.contains('like'))) {
      Navigator.pushNamed(context, '/post-detail', arguments: id);
    } else if (type.contains('chat')) {
      Navigator.pushNamed(context, '/chats').then((_) => _loadNavBadges());
    } else {
      Navigator.pushNamed(context, '/notifications')
          .then((_) => _loadNavBadges());
    }
  }

  // ── Bottom Navigation Bar ──────────────────
  Widget _buildBottomNav() {
    const fullItems = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home_rounded,
        'label': 'Home'
      },
      {
        'icon': Icons.search_rounded,
        'activeIcon': Icons.search_rounded,
        'label': 'Looking'
      },
      {
        'icon': Icons.sports_cricket_outlined,
        'activeIcon': Icons.sports_cricket,
        'label': 'My Cricket'
      },
      {
        'icon': Icons.forum_outlined,
        'activeIcon': Icons.forum_rounded,
        'label': 'Community'
      },
      {
        'icon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
        'label': 'Profile'
      },
    ];
    final items = fullItems;
    const centerIndex = 2;

    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    final navHeight =
        (compact ? 84.0 : 94.0) + MediaQuery.of(context).padding.bottom;

    return Container(
      height: navHeight,
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 28,
              offset: const Offset(0, -8)),
          BoxShadow(
              color: _DS.primary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 4 : 10, 8, compact ? 4 : 10, 8),
          child: Row(
            children: List.generate(items.length, (index) {
              final isSelected = _currentIndex == index;
              final isCenter = index == centerIndex;
              final iconBox = isCenter
                  ? (compact ? 50.0 : 58.0)
                  : (compact ? 32.0 : 36.0);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(
                        0, isCenter ? (compact ? -6 : -9) : 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: iconBox,
                          height: iconBox,
                          decoration: BoxDecoration(
                            gradient:
                                isSelected || isCenter ? _DS.heroGrad : null,
                            color:
                                isSelected || isCenter ? null : _DS.surfaceAlt,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected || isCenter
                                  ? Colors.white
                                  : _DS.surfaceBorder,
                              width: isCenter ? 4 : 1,
                            ),
                            boxShadow: isSelected || isCenter
                                ? [
                                    BoxShadow(
                                        color: _DS.primary.withOpacity(0.28),
                                        blurRadius: 18,
                                        offset: const Offset(0, 7))
                                  ]
                                : [],
                          ),
                          child: Icon(
                            isSelected
                                ? items[index]['activeIcon'] as IconData
                                : items[index]['icon'] as IconData,
                            color: isSelected || isCenter
                                ? Colors.white
                                : _DS.textMuted,
                            size: isCenter ? (compact ? 24 : 28) : (compact ? 19 : 21),
                          ),
                        ),
                        SizedBox(height: compact ? 2 : 4),
                        Text(
                          items[index]['label'] as String,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? _DS.primary : _DS.textMuted,
                            fontWeight: isSelected || isCenter
                                ? FontWeight.w900
                                : FontWeight.w700,
                            fontSize: compact ? 9.5 : (isCenter ? 10 : 11),
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
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
    final isFan = _isFanRole(authProvider);

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
                _DrawerNavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: _currentIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 0);
                    }),
                _DrawerNavItem(
                    icon: Icons.sports_cricket,
                    label: 'Matches',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/matches');
                    }),
                _DrawerNavItem(
                    icon: Icons.emoji_events_rounded,
                    label: 'Tournaments',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/tournaments');
                    }),
                _DrawerNavItem(
                    icon: Icons.groups_rounded,
                    label: 'Teams',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/teams');
                    }),
                _DrawerNavItem(
                    icon: Icons.people_rounded,
                    label: 'Players',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/players');
                    }),

                const SizedBox(height: 4),
                _DrawerSectionLabel(label: 'FEATURES'),
                _DrawerNavItem(
                    icon: Icons.live_tv_rounded,
                    label: 'Live Matches',
                    badge: 'LIVE',
                    badgeGrad: _DS.liveGrad,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/live-matches');
                    }),
                _DrawerNavItem(
                    icon: Icons.videocam_rounded,
                    label: 'Go Live',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/go-live');
                    }),
                _DrawerNavItem(
                    icon: Icons.video_library_rounded,
                    label: 'Highlights',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/highlights');
                    }),
                _DrawerNavItem(
                    icon: Icons.analytics_outlined,
                    label: 'Scorecards',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/scorecards');
                    }),
                _DrawerNavItem(
                    icon: Icons.leaderboard_outlined,
                    label: 'Leaderboards',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/leaderboards');
                    }),
                _DrawerNavItem(
                    icon: Icons.article_outlined,
                    label: 'Blogs',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/blogs');
                    }),
                _DrawerNavItem(
                    icon: Icons.forum_outlined,
                    label: 'Community',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/community');
                    }),
                _DrawerNavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chats',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/chats');
                    }),
                _DrawerNavItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/notifications');
                    }),

                const SizedBox(height: 4),
                _DrawerSectionLabel(label: 'ACCOUNT'),
                _DrawerNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    isActive: !isFan && _currentIndex == 4,
                    onTap: () {
                      Navigator.pop(context);
                      if (isFan) {
                        Navigator.pushNamed(context, '/profile');
                      } else {
                        setState(() => _currentIndex = 4);
                      }
                    }),
                _DrawerNavItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.settings)),
                _DrawerNavItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () => Navigator.pushNamed(context, '/help-support')),
                _DrawerNavItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.privacyPolicy)),

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
                    _showLogoutDialog(context,
                        Provider.of<AuthProvider>(context, listen: false));
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
    final rootContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _DS.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_DS.radiusXL)),
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
              child:
                  const Icon(Icons.logout_rounded, color: _DS.live, size: 22),
            ),
            const SizedBox(width: 14),
            const Text(
              'Logout',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: _DS.textPrimary),
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
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_DS.radiusMD)),
            ),
            child: const Text('Cancel',
                style: TextStyle(
                    color: _DS.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await performLogout(rootContext);
              if (rootContext.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  rootContext,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _DS.live,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_DS.radiusMD)),
            ),
            child: const Text('Logout',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2), blurRadius: 14)
                  ],
                ),
                child: ClipOval(
                  child: user?.avatar?.url != null
                      ? Image.network(
                          user!.avatar!.url!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
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
                      user?.name ?? 'Scores11 User',
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
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.65), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Online indicator
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Color(0xFF34D399), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Online',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
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
          // Real profile facts only (role + playing style).
          Row(
            children: [
              _StatChip(label: '🏏 ${_titleCase(user?.role ?? 'Player')}'),
              if ((user?.playingStyle ?? '').trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(child: _StatChip(label: user!.playingStyle.trim())),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Scores11AppBarLogo extends StatelessWidget {
  final bool compact;

  const _Scores11AppBarLogo({required this.compact});

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 38.0 : 44.0;
    final fontSize = compact ? 18.0 : 21.0;
    return Semantics(
      label: 'Scores11',
      image: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: logoSize,
              height: logoSize,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_DS.primary, _DS.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sports_cricket,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SCORES11',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _DS.primaryDark,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
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

String _titleCase(String value) => value.isEmpty
    ? value
    : value[0].toUpperCase() + value.substring(1).toLowerCase();

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
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
    final resolvedIconColor =
        iconColor ?? (isActive ? _DS.primary : _DS.textSecondary);
    final resolvedLabelColor =
        labelColor ?? (isActive ? _DS.primary : _DS.textPrimary);
    final resolvedIconBg =
        iconBgColor ?? (isActive ? _DS.primarySoft : _DS.surfaceAlt);

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    return SizedBox(
      width: 38,
      height: 38,
      child: Icon(icon, color: _DS.textPrimary, size: 27),
    );
  }
}

class _AppBarBadge extends StatelessWidget {
  final int count;
  final Gradient gradient;

  const _AppBarBadge({required this.count, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Positioned(
      right: 7,
      top: 7,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 6)
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _NotificationCenterSheet extends StatefulWidget {
  final NotificationService service;
  final VoidCallback onOpenAll;
  final ValueChanged<NotificationModel> onOpenNotification;
  final VoidCallback onUnreadChanged;

  const _NotificationCenterSheet({
    required this.service,
    required this.onOpenAll,
    required this.onOpenNotification,
    required this.onUnreadChanged,
  });

  @override
  State<_NotificationCenterSheet> createState() =>
      _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<_NotificationCenterSheet> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isMarkingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await widget.service.getNotifications(page: 1, limit: 12);
      if (!mounted) return;
      setState(() {
        _notifications = result.notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e, fallback: 'Could not load notifications.');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    if (_isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    try {
      await widget.service.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _notifications =
            _notifications.map((item) => item.copyWith(isRead: true)).toList();
        _isMarkingAll = false;
      });
      widget.onUnreadChanged();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isMarkingAll = false);
    }
  }

  Future<void> _open(NotificationModel notification) async {
    if (!notification.isRead && notification.id.isNotEmpty) {
      try {
        await widget.service.markAsRead(notification.id);
        if (mounted) {
          setState(() {
            _notifications = _notifications
                .map((item) => item.id == notification.id
                    ? item.copyWith(isRead: true)
                    : item)
                .toList();
          });
        }
        widget.onUnreadChanged();
      } catch (_) {}
    }
    widget.onOpenNotification(notification);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((item) => !item.isRead).length;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: _DS.heroGrad,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.notifications_active_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                                color: _DS.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.w900),
                          ),
                          Text(
                            unreadCount == 0
                                ? 'All caught up'
                                : '$unreadCount unread updates',
                            style: const TextStyle(
                                color: _DS.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _notifications.isEmpty || _isMarkingAll
                          ? null
                          : _markAllRead,
                      child: _isMarkingAll
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Read all',
                              style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(scrollController)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: widget.onOpenAll,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('See all notifications'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _DS.primary,
                        side: BorderSide(color: _DS.primary.withOpacity(0.25)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _DS.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: _DS.textMuted, size: 42),
              const SizedBox(height: 10),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _DS.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _loadNotifications, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_notifications.isEmpty) {
      return const _EmptyState(message: 'No notifications yet');
    }
    return RefreshIndicator(
      color: _DS.primary,
      onRefresh: _loadNotifications,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 220 + (index * 35).clamp(0, 240)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _NotificationPreviewTile(
              notification: notification,
              onTap: () => _open(notification),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationPreviewTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationPreviewTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(notification.type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : _DS.primarySoft.withOpacity(0.58),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? _DS.surfaceBorder
                : _DS.primary.withOpacity(0.16),
          ),
          boxShadow: notification.isRead ? [] : _DS.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(_iconFor(notification.type), color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title.isEmpty
                              ? 'Scores11 update'
                              : notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _DS.textPrimary,
                            fontSize: 13.5,
                            fontWeight: notification.isRead
                                ? FontWeight.w800
                                : FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: _DS.live, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _DS.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: const TextStyle(
                        color: _DS.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String type) {
    final value = type.toLowerCase();
    if (value.contains('match') || value.contains('score'))
      return Icons.sports_cricket_rounded;
    if (value.contains('team')) return Icons.groups_rounded;
    if (value.contains('tournament')) return Icons.emoji_events_rounded;
    if (value.contains('wallet') || value.contains('payment'))
      return Icons.account_balance_wallet_rounded;
    if (value.contains('chat')) return Icons.chat_bubble_rounded;
    if (value.contains('follow')) return Icons.person_add_alt_1_rounded;
    if (value.contains('like')) return Icons.favorite_rounded;
    if (value.contains('comment')) return Icons.mode_comment_rounded;
    if (value.contains('community') || value.contains('post'))
      return Icons.forum_rounded;
    return Icons.notifications_rounded;
  }

  static Color _colorFor(String type) {
    final value = type.toLowerCase();
    if (value.contains('match') || value.contains('score')) return _DS.green;
    if (value.contains('team')) return _DS.primary;
    if (value.contains('tournament')) return _DS.gold;
    if (value.contains('wallet') || value.contains('payment'))
      return _DS.purple;
    if (value.contains('chat')) return const Color(0xFF0891B2);
    if (value.contains('community') ||
        value.contains('post') ||
        value.contains('comment') ||
        value.contains('like') ||
        value.contains('follow')) return _DS.purple;
    return _DS.primary;
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CricheroHomeHeader extends StatelessWidget {
  final String userName;
  final UserModel? user;
  final QuickStats stats;
  final int liveCount;
  final int upcomingCount;

  const _CricheroHomeHeader({
    required this.userName,
    required this.user,
    required this.stats,
    required this.liveCount,
    required this.upcomingCount,
  });

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final nameParts =
        userName.split(' ').where((part) => part.trim().isNotEmpty).toList();
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'Cricketer';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ProfileAvatar(user: user, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $firstName! 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DS.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Ready for some cricket action?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _DS.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _HeaderProfilePill(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
    );
  }
}

class _HeaderProfilePill extends StatelessWidget {
  final VoidCallback onTap;

  const _HeaderProfilePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _DS.primary.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View Profile',
              style: TextStyle(color: _DS.primary, fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: _DS.primary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _HeaderMetric({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: color, fontSize: 15, fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DS.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

class _CricHeroQuickActions extends StatelessWidget {
  const _CricHeroQuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        icon: Icons.live_tv_rounded,
        title: 'Live Matches',
        color: _DS.live,
        route: '/matches/live',
      ),
      _ActionData(
        icon: Icons.calendar_month_rounded,
        title: 'Upcoming',
        color: _DS.primary,
        route: AppRoutes.matches,
      ),
      _ActionData(
        icon: Icons.groups_rounded,
        title: 'Teams',
        color: const Color(0xFF8B5CF6),
        route: AppRoutes.teams,
      ),
      _ActionData(
        icon: Icons.emoji_events_rounded,
        title: 'Tournaments',
        color: _DS.gold,
        route: AppRoutes.tournaments,
      ),
      _ActionData(
        icon: Icons.directions_run_rounded,
        title: 'Players',
        color: _DS.green,
        route: AppRoutes.publicPlayers,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.surfaceBorder),
          boxShadow: _DS.cardShadow,
        ),
        child: Row(
          children: actions
              .map((action) => Expanded(
                    child: _CricHeroActionTile(
                      action: action,
                      onTap: () => Navigator.pushNamed(context, action.route),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _CricHeroActionTile extends StatelessWidget {
  final _ActionData action;
  final VoidCallback onTap;

  const _CricHeroActionTile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: action.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(action.icon, color: action.color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            action.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _DS.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTopSwitch extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onChanged;

  const _DashboardTopSwitch({
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.surfaceBorder),
        ),
        child: Row(
          children: [
            _TopSwitchItem(
              label: 'For you',
              icon: Icons.auto_awesome_rounded,
              selected: selectedMode == 'forYou',
              onTap: () => onChanged('forYou'),
            ),
            _TopSwitchItem(
              label: 'Pro club',
              icon: Icons.workspace_premium_rounded,
              selected: selectedMode == 'proClub',
              onTap: () => onChanged('proClub'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSwitchItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TopSwitchItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 42,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: _DS.primary.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17, color: selected ? _DS.primary : _DS.textMuted),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? _DS.primary : _DS.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryRail extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final List<TrendingPlayer> players;

  const _StoryRail({
    required this.posts,
    required this.players,
  });

  @override
  State<_StoryRail> createState() => _StoryRailState();
}

class _StoryRailState extends State<_StoryRail> {
  final StoryService _storyService = StoryService();
  final UploadService _uploadService = UploadService();
  List<StoryItem> _backendStories = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final stories = await _storyService.getActiveStories();
      if (!mounted) return;
      setState(() => _backendStories = stories);
    } catch (_) {}
  }

  Future<void> _showCreateStorySheet() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                      color: _DS.surfaceBorder,
                      borderRadius: BorderRadius.circular(999))),
              const SizedBox(height: 16),
              const Text('Add story',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _DS.textPrimary)),
              const SizedBox(height: 12),
              ListTile(
                leading:
                    const Icon(Icons.photo_library_rounded, color: _DS.primary),
                title: const Text('Upload photo'),
                onTap: () => Navigator.pop(context, 'image'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_rounded, color: _DS.live),
                title: const Text('Upload video'),
                onTap: () => Navigator.pop(context, 'video'),
              ),
            ],
          ),
        ),
      ),
    );
    if (type == null || _isUploading) return;

    setState(() => _isUploading = true);
    try {
      final file = type == 'video'
          ? await _uploadService.pickVideoFromGallery()
          : await _uploadService.pickImageFromGallery();
      if (file == null) {
        if (mounted) setState(() => _isUploading = false);
        return;
      }
      final uploaded = type == 'video'
          ? await _uploadService.uploadVideo(file, folder: 'scores11/stories')
          : await _uploadService.uploadImage(file, folder: 'scores11/stories');
      final data = uploaded?['data'];
      final url =
          data is Map ? (data['url'] ?? data['secureUrl'])?.toString() : null;
      final publicId = data is Map ? data['publicId']?.toString() : null;
      if (url == null || url.isEmpty) throw Exception('Upload failed');
      await _storyService.createStory(
          mediaUrl: url, mediaType: type, publicId: publicId);
      await _loadStories();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story uploaded for 24 hours')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(
            content: Text(
              friendlyError(e, fallback: 'Could not upload story.'),
            ),
          ));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stories = _buildStories(auth);
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final story = stories[index];
          return _StoryBubble(
            story: story,
            isMine: index == 0,
            onTap: () {
              if (index == 0) {
                _showCreateStorySheet();
              } else if (story.route.isEmpty) {
                _showStoryPreview(story);
              } else if (story.route.isNotEmpty) {
                Navigator.pushNamed(context, story.route,
                    arguments: story.arguments);
              }
            },
          );
        },
      ),
    );
  }

  List<_StoryData> _buildStories(AuthProvider auth) {
    final user = auth.user;
    final userName =
        user?.name.trim().isNotEmpty == true ? user!.name.trim() : 'You';
    final list = <_StoryData>[
      _StoryData(
        title: 'Your story',
        subtitle: userName,
        imageUrl: _avatarFor(userName),
        icon: _isUploading ? Icons.hourglass_top_rounded : Icons.add_rounded,
        route: '/profile',
      ),
    ];

    for (final story in _backendStories.take(12)) {
      list.add(_StoryData(
        title: story.userName,
        subtitle: _expiresIn(story.expiresAt),
        imageUrl: _safeUrl(story.userAvatar) ?? story.mediaUrl,
        icon: story.mediaType == 'video'
            ? Icons.play_arrow_rounded
            : Icons.photo_camera_rounded,
        route: '',
      ));
    }

    for (final post in widget.posts.take(8)) {
      final author = (post['userName'] ?? post['name'] ?? 'Player').toString();
      final images = post['images'] is List ? post['images'] as List : const [];
      final image =
          images.isNotEmpty ? _safeUrl(images.first?.toString()) : null;
      final id = (post['id'] ?? post['_id'] ?? '').toString();
      list.add(_StoryData(
        title: author,
        subtitle: post['timeAgo']?.toString() ?? 'Story',
        imageUrl: image ?? _avatarFor(author),
        icon: _looksVideo(post)
            ? Icons.play_arrow_rounded
            : Icons.photo_camera_rounded,
        route: id.isEmpty ? '/community' : '/post-detail',
        arguments: id.isEmpty ? null : id,
      ));
    }

    if (list.length < 8) {
      for (final player in widget.players.take(8 - list.length)) {
        final name =
            player.name.trim().isEmpty ? 'Cricketer' : player.name.trim();
        list.add(_StoryData(
          title: name,
          subtitle: player.team.shortName.isNotEmpty
              ? player.team.shortName
              : 'Player',
          imageUrl: _avatarFor(name),
          icon: Icons.sports_cricket_rounded,
          route: player.id.isEmpty
              ? '/public-players'
              : '/player-profile/${player.id}',
        ));
      }
    }

    return list;
  }

  void _showStoryPreview(_StoryData story) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.82),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          insetPadding: const EdgeInsets.all(18),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                CachedNetworkImage(
                  imageUrl: story.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.68,
                  errorWidget: (_, __, ___) => Container(
                    height: 420,
                    color: _DS.textPrimary,
                    child: const Icon(Icons.photo_rounded,
                        color: Colors.white, size: 56),
                  ),
                ),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.72),
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(story.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(story.subtitle,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.78),
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _looksVideo(Map<String, dynamic> post) {
    final type =
        (post['type'] ?? post['mediaType'] ?? '').toString().toLowerCase();
    final url =
        (post['video'] ?? post['videoUrl'] ?? '').toString().toLowerCase();
    return type.contains('video') ||
        url.endsWith('.mp4') ||
        url.endsWith('.mov');
  }

  static String? _safeUrl(String? value) {
    final url = value?.trim();
    if (url == null || url.isEmpty || url == 'null') return null;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty ? url : null;
  }

  static String _avatarFor(String name) {
    final encoded =
        Uri.encodeComponent(name.trim().isEmpty ? 'Scores11' : name.trim());
    return 'https://ui-avatars.com/api/?name=$encoded&background=1A56DB&color=fff&bold=true&size=180';
  }

  static String _expiresIn(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.inMinutes <= 0) return 'Expired';
    if (diff.inHours <= 0) return '${diff.inMinutes}m left';
    return '${diff.inHours}h left';
  }
}

class _StoryData {
  final String title;
  final String subtitle;
  final String imageUrl;
  final IconData icon;
  final String route;
  final Object? arguments;

  const _StoryData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.route,
    this.arguments,
  });
}

class _StoryBubble extends StatelessWidget {
  final _StoryData story;
  final bool isMine;
  final VoidCallback onTap;

  const _StoryBubble({
    required this.story,
    required this.isMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isMine
                        ? _DS.heroGrad
                        : const LinearGradient(
                            colors: [_DS.live, _DS.gold, _DS.primary]),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: story.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: _DS.primarySoft,
                        child: const Icon(Icons.person_rounded,
                            color: _DS.primary),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isMine ? _DS.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(story.icon,
                      size: 13, color: isMine ? Colors.white : _DS.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              story.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _DS.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900),
            ),
            Text(
              story.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _DS.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProClubRail extends StatelessWidget {
  final int tournamentCount;
  final int teamCount;
  final int playerCount;

  const _ProClubRail({
    required this.tournamentCount,
    required this.teamCount,
    required this.playerCount,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _ProClubData(Icons.workspace_premium_rounded, 'Pro clubs',
          '$teamCount teams', _DS.primary, '/teams'),
      _ProClubData(Icons.emoji_events_rounded, 'Tournaments',
          '$tournamentCount active', _DS.gold, '/tournaments'),
      _ProClubData(Icons.leaderboard_rounded, 'Leaders', '$playerCount players',
          _DS.green, '/leaderboard'),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => Navigator.pushNamed(context, item.route),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 156,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _DS.surfaceBorder),
                boxShadow: _DS.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(item.icon, color: item.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _DS.textPrimary)),
                        const SizedBox(height: 3),
                        Text(item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _DS.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProClubData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  const _ProClubData(
      this.icon, this.title, this.subtitle, this.color, this.route);
}

class _DashboardMarquee extends StatefulWidget {
  final int liveCount;
  final int upcomingCount;
  final int tournamentCount;

  const _DashboardMarquee({
    required this.liveCount,
    required this.upcomingCount,
    required this.tournamentCount,
  });

  @override
  State<_DashboardMarquee> createState() => _DashboardMarqueeState();
}

class _DashboardMarqueeState extends State<_DashboardMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _message {
    final liveText = widget.liveCount > 0
        ? '${widget.liveCount} live match${widget.liveCount == 1 ? '' : 'es'} now'
        : 'Live match updates available';
    final upcomingText = widget.upcomingCount > 0
        ? '${widget.upcomingCount} upcoming match${widget.upcomingCount == 1 ? '' : 'es'}'
        : 'Upcoming fixtures refresh automatically';
    final tournamentText = widget.tournamentCount > 0
        ? '${widget.tournamentCount} tournament${widget.tournamentCount == 1 ? '' : 's'} to explore'
        : 'Create teams, follow players, and track every score';

    return '$liveText    •    $upcomingText    •    $tournamentText    •    Scores11 keeps cricket live, fast, and simple';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 360;
    final tight = screenWidth < 330;
    final horizontalMargin = compact ? 10.0 : 16.0;
    final textStyle = TextStyle(
      color: _DS.primaryDark.withOpacity(0.82),
      fontSize: compact ? 11.5 : 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.1,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: Container(
        height: compact ? 40 : 44,
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(_DS.radiusLG),
          border: Border.all(color: _DS.surfaceBorder),
          boxShadow: _DS.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: tight ? 9 : 12),
              decoration: BoxDecoration(
                gradient: _DS.liveGrad,
                borderRadius: BorderRadius.circular(_DS.radiusLG),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_rounded,
                      color: Colors.white, size: tight ? 16 : 17),
                  if (!tight) ...[
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final painter = TextPainter(
                    text: TextSpan(text: _message, style: textStyle),
                    maxLines: 1,
                    textDirection: Directionality.of(context),
                  )..layout();
                  final textWidth = painter.width;
                  final gap = constraints.maxWidth;
                  final travel = textWidth + gap;

                  return ClipRect(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(-travel * _controller.value, 0),
                          child: child,
                        );
                      },
                      child: Row(
                        children: [
                          SizedBox(width: gap),
                          Text(_message, maxLines: 1, style: textStyle),
                          SizedBox(width: gap),
                          Text(_message, maxLines: 1, style: textStyle),
                        ],
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
}

// ─────────────────────────────────────────────
//  HomeTab
// ─────────────────────────────────────────────
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ScrollController _scrollController = ScrollController();
  final CommunityService _feedService = CommunityService();
  final Set<String> _likedPosts = {};
  List<Map<String, dynamic>> _feedPosts = [];
  bool _postsLoading = true;
  bool _postsLoadingMore = false;
  bool _hasMorePosts = true;
  int _postsPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onHomeScroll);
    _loadFeedPosts();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onHomeScroll)
      ..dispose();
    super.dispose();
  }

  void _onHomeScroll() {
    if (!_scrollController.hasClients || _postsLoadingMore || !_hasMorePosts)
      return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 360) {
      _loadMoreFeedPosts();
    }
  }

  Future<void> _loadFeedPosts() async {
    setState(() {
      _postsLoading = true;
      _postsPage = 1;
      _hasMorePosts = true;
    });
    try {
      final result = await _feedService.getPosts(page: 1, limit: 8);
      if (!mounted) return;
      setState(() {
        _feedPosts = result.posts;
        _likedPosts
          ..clear()
          ..addAll(result.posts
              .where((post) => post['isLiked'] == true)
              .map((post) => _postId(post))
              .where((id) => id.isNotEmpty));
        _hasMorePosts = result.hasMore;
        _postsPage = result.page;
        _postsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedPosts = [];
        _hasMorePosts = false;
        _postsLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, fallback: 'Could not load community posts.')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadMoreFeedPosts() async {
    if (_postsLoadingMore || !_hasMorePosts) return;
    setState(() => _postsLoadingMore = true);
    try {
      final nextPage = _postsPage + 1;
      final result = await _feedService.getPosts(page: nextPage, limit: 8);
      if (!mounted) return;
      setState(() {
        _feedPosts = [..._feedPosts, ...result.posts];
        _hasMorePosts = result.hasMore;
        _postsPage = result.page;
        _postsLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _postsLoadingMore = false);
    }
  }

  Future<void> _toggleFeedLike(Map<String, dynamic> post) async {
    final id = _postId(post);
    if (id.isEmpty) return;
    final wasLiked = _likedPosts.contains(id);
    setState(() {
      if (wasLiked) {
        _likedPosts.remove(id);
      } else {
        _likedPosts.add(id);
      }
      final index = _feedPosts.indexWhere((item) => _postId(item) == id);
      if (index != -1) {
        final updated = Map<String, dynamic>.from(_feedPosts[index]);
        final likes = _readCount(updated['likes']);
        updated['likes'] = (likes + (wasLiked ? -1 : 1)).clamp(0, 999999);
        _feedPosts[index] = updated;
      }
    });

    try {
      final updated = await _feedService.likePost(id);
      if (!mounted || updated.isEmpty) return;
      final index = _feedPosts.indexWhere((item) => _postId(item) == id);
      if (index != -1) {
        setState(() {
          _feedPosts[index] = updated;
          if (updated['isLiked'] == true) {
            _likedPosts.add(id);
          } else {
            _likedPosts.remove(id);
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasLiked) {
          _likedPosts.add(id);
        } else {
          _likedPosts.remove(id);
        }
      });
    }
  }

  void _openFeedPost(Map<String, dynamic> post) {
    final id = _postId(post);
    if (id.isNotEmpty) {
      Navigator.pushNamed(context, '/post-detail', arguments: id);
    } else {
      Navigator.pushNamed(context, '/community');
    }
  }

  Future<void> _openCommentSheet(Map<String, dynamic> post) async {
    final id = _postId(post);
    if (id.isEmpty) return;
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.28),
      builder: (_) => _DashboardCommentSheet(
        post: post,
        service: _feedService,
      ),
    );
    if (!mounted || updated == null || updated.isEmpty) return;
    final index = _feedPosts.indexWhere((item) => _postId(item) == id);
    if (index != -1) {
      setState(() => _feedPosts[index] = updated);
    }
  }

  Future<void> _shareFeedPost(Map<String, dynamic> post) async {
    final id = _postId(post);
    final link =
        id.isEmpty ? 'scores11://community' : 'scores11://community/post/$id';
    if (id.isNotEmpty) {
      try {
        final updated = await _feedService.sharePost(id);
        if (mounted && updated.isNotEmpty) {
          final index = _feedPosts.indexWhere((item) => _postId(item) == id);
          if (index != -1) setState(() => _feedPosts[index] = updated);
        }
      } catch (_) {}
    }
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shortcut link copied: $link'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String _postId(Map<String, dynamic> post) =>
      (post['id'] ?? post['_id'] ?? '').toString();

  static int _readCount(dynamic value) {
    if (value is int) return value;
    if (value is List) return value.length;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final data = dashboardProvider.dashboardData;
    final carouselLiveMatches = dashboardProvider.carouselLiveMatches;
    final dashboardLiveMatches = dashboardProvider.liveMatches.toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    final recentCompletedMatches = dashboardProvider.recentCompletedMatches;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name.trim().isNotEmpty == true
        ? auth.user!.name.trim()
        : 'Cricketer';

    if (dashboardProvider.isLoading && data == null) {
      return const Center(child: CircularProgressIndicator(color: _DS.primary));
    }

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      // With extendBodyBehindAppBar the Scaffold already folds the app bar
      // height into padding.top; adding kToolbarHeight again left a blank band.
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + (screenWidth < 360 ? 4 : 6),
        bottom: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenWidth < 360 ? 4 : 6),
          _CricheroHomeHeader(
            userName: userName,
            user: auth.user,
            stats: dashboardProvider.quickStats,
            liveCount: dashboardLiveMatches.length,
            upcomingCount: dashboardProvider.upcomingMatches.length,
          ),
          const SizedBox(height: 12),

          // Live match spotlight — mirrors the reference home screen's
          // priority order: greeting → live match card → quick actions →
          // match hub (live/upcoming/completed) → the rest.
          // Only matches that are live right now; otherwise a clear empty card.
          _LiveScoreCarousel(
            liveMatches: carouselLiveMatches,
            dashboardLiveMatches: dashboardLiveMatches,
            completedMatches: recentCompletedMatches,
          ),
          const SizedBox(height: 18),

          const _CricHeroQuickActions(),
          // Promotional banners managed from the admin panel (hidden when none).
          const _BannerCarousel(),
          SizedBox(height: screenWidth < 360 ? 12 : 14),
          _CricheroMatchHub(
            liveMatches: dashboardLiveMatches,
            upcomingMatches: dashboardProvider.upcomingMatches,
            completedMatches: recentCompletedMatches,
          ),
          SizedBox(height: screenWidth < 360 ? 12 : 14),
          _TopPerformersSection(players: dashboardProvider.trendingPlayers),
          SizedBox(height: screenWidth < 360 ? 12 : 14),

          _StoryRail(
            posts: _feedPosts,
            players: dashboardProvider.trendingPlayers,
          ),
          const SizedBox(height: 12),
          _DashboardMarquee(
            liveCount: dashboardLiveMatches.length,
            upcomingCount: dashboardProvider.upcomingMatches.length,
            tournamentCount: dashboardProvider.latestTournaments.length,
          ),
          const SizedBox(height: 14),

          _FollowingYouRail(
            players: dashboardProvider.trendingPlayers,
            posts: _feedPosts,
          ),
          const SizedBox(height: 18),
          _DashboardPostFeed(
            posts: _feedPosts,
            isLoading: _postsLoading,
            isLoadingMore: _postsLoadingMore,
            hasMore: _hasMorePosts,
            likedPostIds: _likedPosts,
            onRefresh: _loadFeedPosts,
            onOpen: _openFeedPost,
            onLike: _toggleFeedLike,
            onComment: _openCommentSheet,
            onShare: _shareFeedPost,
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
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _DS.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  // ── Live Header ────────────────────────────
  Widget _buildLiveHeader(
    BuildContext context,
    int count, {
    int completedCount = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: _DS.live, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Now',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _DS.textPrimary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    gradient: _DS.liveGrad,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (completedCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _DS.greenSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _DS.green.withOpacity(0.18)),
              ),
              child: Text(
                '$completedCount done',
                style: const TextStyle(
                  color: _DS.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
                style: TextStyle(
                    color: _DS.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
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
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.72), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _DS.accent.withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.sports_cricket,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 330;
              final buttons = [
                _HeroButton(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Create Match',
                  onTap: () => Navigator.pushNamed(context, '/create-match'),
                  isPrimary: true,
                ),
                _HeroButton(
                  icon: Icons.emoji_events_rounded,
                  label: 'Tournaments',
                  onTap: () => Navigator.pushNamed(context, '/tournaments'),
                  isPrimary: false,
                ),
              ];
              if (compact) {
                return Column(
                  children: [
                    buttons[0],
                    const SizedBox(height: 10),
                    buttons[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: buttons[0]),
                  const SizedBox(width: 10),
                  Expanded(child: buttons[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Quick Stats ────────────────────────────
  Widget _buildQuickStatsRow(QuickStats stats) {
    final cards = [
      _QuickStatCard(
        title: 'Matches',
        value: stats.totalMatches.toString(),
        subtitle: '${stats.weekMatches} this week',
        icon: Icons.sports_cricket_rounded,
        color: _DS.primary,
        gradient: const [Color(0xFF1657CC), Color(0xFF3B82F6)],
      ),
      _QuickStatCard(
        title: 'Live',
        value: stats.liveMatches.toString(),
        subtitle: '${stats.todayMatches} today',
        icon: Icons.live_tv_rounded,
        color: _DS.live,
        gradient: const [Color(0xFFEF4444), Color(0xFFF87171)],
        isLive: true,
      ),
      _QuickStatCard(
        title: 'Teams',
        value: stats.totalTeams.toString(),
        subtitle: 'registered',
        icon: Icons.groups_rounded,
        color: _DS.green,
        gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
      ),
      _QuickStatCard(
        title: 'Players',
        value: stats.totalPlayers.toString(),
        subtitle: '${stats.activeTournaments} active cups',
        icon: Icons.person_rounded,
        color: _DS.purple,
        gradient: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth < 360 ? 10.0 : 12.0;
        final cardHeight = (constraints.maxWidth * 0.42).clamp(136.0, 158.0);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(_DS.radiusXL),
            border: Border.all(color: _DS.surfaceBorder),
            boxShadow: _DS.cardShadow,
          ),
          child: Column(
            children: cards
                .asMap()
                .entries
                .where((entry) => entry.key.isEven)
                .map((entry) {
              final first = entry.value;
              final second = cards[entry.key + 1];

              return Padding(
                padding: EdgeInsets.only(bottom: entry.key == 0 ? spacing : 0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(height: cardHeight, child: first),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: SizedBox(height: cardHeight, child: second),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── Quick Actions ──────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final featured = [
      _ActionData(
        icon: Icons.add_circle_outline_rounded,
        title: 'Create Match',
        subtitle: 'Start scoring',
        color: _DS.primary,
        route: '/create-match',
      ),
      _ActionData(
        icon: Icons.analytics_outlined,
        title: 'Scorecard',
        subtitle: 'Live details',
        color: const Color(0xFFF97316),
        route: '/scorecard',
      ),
    ];

    final actions = [
      _ActionData(
          icon: Icons.live_tv_rounded,
          title: 'Live',
          subtitle: 'Matches',
          color: _DS.live,
          route: '/live-matches'),
      _ActionData(
          icon: Icons.group_add_rounded,
          title: 'Team',
          subtitle: 'Create',
          color: _DS.purple,
          route: '/create-team'),
      _ActionData(
          icon: Icons.person_add_rounded,
          title: 'Player',
          subtitle: 'Create',
          color: _DS.green,
          route: '/create-player'),
      _ActionData(
          icon: Icons.emoji_events_rounded,
          title: 'Cups',
          subtitle: 'Tournaments',
          color: _DS.gold,
          route: '/tournaments'),
      _ActionData(
          icon: Icons.leaderboard_rounded,
          title: 'Leaders',
          subtitle: 'Rankings',
          color: const Color(0xFF0EA5E9),
          route: '/leaderboard'),
      _ActionData(
          icon: Icons.forum_outlined,
          title: 'Community',
          subtitle: 'Posts',
          color: const Color(0xFF0284C7),
          route: '/community'),
      _ActionData(
          icon: Icons.event_available_rounded,
          title: 'Schedule',
          subtitle: 'Fixtures',
          color: const Color(0xFF2563EB),
          route: AppRoutes.scheduledMatches),
      _ActionData(
          icon: Icons.fact_check_rounded,
          title: 'Results',
          subtitle: 'Completed',
          color: const Color(0xFF059669),
          route: AppRoutes.completedMatches),
      _ActionData(
          icon: Icons.people_rounded,
          title: 'Players',
          subtitle: 'Browse',
          color: _DS.primary,
          route: '/players'),
      _ActionData(
          icon: Icons.person_search_rounded,
          title: 'Search',
          subtitle: 'Public',
          color: const Color(0xFF0EA5E9),
          route: AppRoutes.publicPlayers),
      _ActionData(
          icon: Icons.article_rounded,
          title: 'Blogs',
          subtitle: 'Stories',
          color: const Color(0xFF0891B2),
          route: AppRoutes.blogs),
      _ActionData(
          icon: Icons.notifications_outlined,
          title: 'Alerts',
          subtitle: 'Updates',
          color: _DS.purple,
          route: '/notifications'),
      _ActionData(
          icon: Icons.videocam_rounded,
          title: 'Live Stream',
          subtitle: 'Go live',
          color: const Color(0xFFDB2777),
          route: '/go-live'),
      _ActionData(
          icon: Icons.video_library_rounded,
          title: 'Highlights',
          subtitle: 'Replays',
          color: const Color(0xFFE11D48),
          route: '/highlights'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusXL),
        border: Border.all(color: _DS.surfaceBorder),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 360;
              final cards = featured.map((action) {
                return _QuickActionCard(
                  icon: action.icon,
                  title: action.title,
                  subtitle: action.subtitle,
                  color: action.color,
                  isFeatured: true,
                  onTap: action.title == 'Scorecard'
                      ? () {
                          final firstMatchId = context
                              .read<DashboardProvider>()
                              .getFirstLiveMatchId();
                          if (firstMatchId == null || firstMatchId.isEmpty) {
                            Navigator.pushNamed(context, '/completed-matches');
                          } else {
                            Navigator.pushNamed(context, '/scorecard',
                                arguments: firstMatchId);
                          }
                        }
                      : () => Navigator.pushNamed(context, action.route),
                );
              }).toList();
              if (stacked) {
                return Column(
                  children: [
                    cards[0],
                    const SizedBox(height: 10),
                    cards[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 620 ? 5 : (width >= 430 ? 4 : 2);
              final ratio = width >= 620
                  ? 0.96
                  : width >= 430
                      ? 0.9
                      : 1.28;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: ratio,
                ),
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return _QuickActionCard(
                    icon: action.icon,
                    title: action.title,
                    subtitle: action.subtitle,
                    color: action.color,
                    onTap: () => Navigator.pushNamed(context, action.route),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Trending Players ───────────────────────
  Widget _buildTrendingPlayersSection(
      BuildContext context, List<TrendingPlayer> players) {
    final visiblePlayers = players.take(8).toList();
    return _DashboardContentShell(
      accent: const Color(0xFFF97316),
      actionLabel: 'View rankings',
      onAction: () => Navigator.pushNamed(context, '/leaderboard'),
      child: SizedBox(
        height: 136,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: visiblePlayers.length,
          itemBuilder: (context, index) => _TrendingPlayerCard(
            player: visiblePlayers[index],
            index: index,
          ),
        ),
      ),
    );
  }

  // ── Upcoming Matches ───────────────────────
  Widget _buildUpcomingMatchesSection(List<UpcomingMatch> matches) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: matches.length > 5 ? 5 : matches.length,
      itemBuilder: (context, index) =>
          _UpcomingMatchCard(match: matches[index]),
    );
  }

  // ── Recent Blogs ───────────────────────────
  Widget _buildRecentBlogsSection(BuildContext context, List<BlogModel> blogs) {
    final visibleBlogs = blogs.take(6).toList();
    return _DashboardContentShell(
      accent: const Color(0xFF0891B2),
      actionLabel: 'All blogs',
      onAction: () => Navigator.pushNamed(context, AppRoutes.blogs),
      child: SizedBox(
        height: 238,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: visibleBlogs.length,
          itemBuilder: (context, index) =>
              _RecentBlogCard(blog: visibleBlogs[index]),
        ),
      ),
    );
  }

  // ── Recent Posts ───────────────────────────
  Widget _buildRecentPostsSection(
      BuildContext context, List<Map<String, dynamic>> posts) {
    final visiblePosts = posts.take(8).toList();
    return _DashboardContentShell(
      accent: _DS.purple,
      actionLabel: 'Community',
      onAction: () => Navigator.pushNamed(context, '/community'),
      child: SizedBox(
        height: 212,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: visiblePosts.length,
          itemBuilder: (context, index) =>
              _RecentPostCard(post: visiblePosts[index]),
        ),
      ),
    );
  }
}

class _DashboardContentShell extends StatelessWidget {
  final Color accent;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  const _DashboardContentShell({
    required this.accent,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusXL),
        border: Border.all(color: _DS.surfaceBorder),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const Spacer(),
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel,
                        style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 13, color: accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
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
  final String subtitle;
  final Color color;
  final String route;
  const _ActionData({
    required this.icon,
    required this.title,
    this.subtitle = '',
    required this.color,
    required this.route,
  });
}

// ─────────────────────────────────────────────
//  Hero Button
// ─────────────────────────────────────────────
class _HeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _HeroButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(_DS.radiusMD),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
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
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final bool isLive;

  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 150 || constraints.maxHeight < 145;
        final padding = compact ? 8.0 : 10.0;
        final iconBox = compact ? 28.0 : 32.0;
        final iconSize = compact ? 15.0 : 17.0;
        final valueSize = compact ? 20.0 : 23.0;
        final titleSize = compact ? 10.5 : 12.0;
        final subtitleSize = compact ? 8.0 : 9.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: color.withOpacity(0.055),
            borderRadius: BorderRadius.circular(_DS.radiusLG),
            border: Border.all(color: color.withOpacity(0.12)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -20,
                child: Icon(
                  icon,
                  size: compact ? 58 : 68,
                  color: color.withOpacity(0.08),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: iconBox,
                        height: iconBox,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.first.withOpacity(0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: iconSize),
                      ),
                      const Spacer(),
                      if (isLive)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 5 : 6,
                            vertical: compact ? 2 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: _DS.liveSoft,
                            borderRadius: BorderRadius.circular(999),
                            border:
                                Border.all(color: _DS.live.withOpacity(0.18)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: compact ? 4 : 5,
                                height: compact ? 4 : 5,
                                decoration: const BoxDecoration(
                                    color: _DS.live, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'NOW',
                                style: TextStyle(
                                  color: _DS.live,
                                  fontSize: compact ? 7 : 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          maxLines: 1,
                          style: TextStyle(
                            color: color,
                            fontSize: valueSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _DS.textPrimary,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _DS.textSecondary,
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Quick Action Card — Improved
// ─────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isFeatured;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    this.subtitle = '',
    required this.color,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(isFeatured ? 14 : 11),
        decoration: BoxDecoration(
          gradient: isFeatured
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.72)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isFeatured ? null : color.withOpacity(0.045),
          borderRadius:
              BorderRadius.circular(isFeatured ? _DS.radiusLG : _DS.radiusMD),
          border: Border.all(
            color: isFeatured
                ? Colors.white.withOpacity(0.16)
                : color.withOpacity(0.14),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isFeatured ? 0.22 : 0.08),
              blurRadius: isFeatured ? 18 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isFeatured
            ? Row(
                children: [
                  _QuickActionIcon(icon: icon, color: color, isFeatured: true),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _QuickActionText(
                          title: title, subtitle: subtitle, isFeatured: true)),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QuickActionIcon(icon: icon, color: color),
                  const SizedBox(height: 9),
                  _QuickActionText(title: title, subtitle: subtitle),
                ],
              ),
      ),
    );
  }
}

class _QuickActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isFeatured;
  const _QuickActionIcon(
      {required this.icon, required this.color, this.isFeatured = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFeatured ? 44 : 42,
      height: isFeatured ? 44 : 42,
      decoration: BoxDecoration(
        color: isFeatured ? Colors.white.withOpacity(0.18) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: isFeatured
                ? Colors.white.withOpacity(0.20)
                : color.withOpacity(0.12)),
      ),
      child: Icon(icon,
          color: isFeatured ? Colors.white : color, size: isFeatured ? 22 : 21),
    );
  }
}

class _QuickActionText extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isFeatured;
  const _QuickActionText(
      {required this.title, required this.subtitle, this.isFeatured = false});

  @override
  Widget build(BuildContext context) {
    final titleColor = isFeatured ? Colors.white : _DS.textPrimary;
    final subColor =
        isFeatured ? Colors.white.withOpacity(0.78) : _DS.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isFeatured ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: isFeatured ? TextAlign.left : TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w900,
            fontSize: isFeatured ? 13 : 12,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: isFeatured ? TextAlign.left : TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subColor,
              fontWeight: FontWeight.w600,
              fontSize: isFeatured ? 10 : 9,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Live Score Carousel
// ─────────────────────────────────────────────
class _CricheroMatchHub extends StatelessWidget {
  final List<LiveMatch> liveMatches;
  final List<UpcomingMatch> upcomingMatches;
  final List<Match> completedMatches;

  const _CricheroMatchHub({
    required this.liveMatches,
    required this.upcomingMatches,
    required this.completedMatches,
  });

  @override
  Widget build(BuildContext context) {
    if (upcomingMatches.isEmpty) return const SizedBox.shrink();
    final visible = upcomingMatches.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Matches',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _DS.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.matches),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: _DS.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: _DS.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _DS.surfaceBorder),
              boxShadow: _DS.cardShadow,
            ),
            child: Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  _UpcomingMatchListCard(match: visible[index], grouped: true),
                  if (index != visible.length - 1)
                    const Divider(height: 1, color: _DS.surfaceBorder),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingMatchListCard extends StatelessWidget {
  final UpcomingMatch match;
  final bool grouped;
  const _UpcomingMatchListCard({required this.match, this.grouped = false});

  @override
  Widget build(BuildContext context) {
    final team1Name = match.team1.shortName.isNotEmpty
        ? match.team1.shortName
        : match.team1.name;
    final team2Name = match.team2.shortName.isNotEmpty
        ? match.team2.shortName
        : match.team2.name;
    final matchLabel = [
      if (match.format.trim().isNotEmpty) match.format.toUpperCase(),
      if (match.tournament.name.trim().isNotEmpty) match.tournament.name,
    ].join(' · ');

    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/scorecard', arguments: match.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: grouped
            ? null
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _DS.surfaceBorder),
                boxShadow: _DS.cardShadow,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (matchLabel.isNotEmpty)
              Text(
                matchLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _DS.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _TeamLogoChip(logo: match.team1.logo, name: team1Name),
                      const SizedBox(width: 8),
                      Text(
                        'vs',
                        style: TextStyle(
                          color: _DS.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child:
                            _TeamLogoChip(logo: match.team2.logo, name: team2Name),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 12, color: _DS.primary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM, h:mm a').format(match.scheduledDate),
                      style: const TextStyle(
                        color: _DS.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamLogoChip extends StatelessWidget {
  final String? logo;
  final String name;
  const _TeamLogoChip({required this.logo, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _DS.surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(color: _DS.surfaceBorder),
          ),
          child: (logo != null && logo!.trim().isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: logo!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Icon(Icons.shield_rounded, size: 12, color: _DS.primary),
                )
              : Icon(Icons.shield_rounded, size: 12, color: _DS.primary),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _DS.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopPerformersSection extends StatelessWidget {
  final List<TrendingPlayer> players;
  const _TopPerformersSection({required this.players});

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();
    final visible = players.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Performers',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _DS.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: _DS.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: _DS.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _TopPerformerCard(player: visible[index], index: index),
          ),
        ),
      ],
    );
  }
}

class _TopPerformerCard extends StatelessWidget {
  final TrendingPlayer player;
  final int index;
  const _TopPerformerCard({required this.player, required this.index});

  static String _avatarFor(String name) {
    final encoded = Uri.encodeComponent(name.trim().isEmpty ? 'Player' : name);
    return 'https://ui-avatars.com/api/?name=$encoded&background=E8F0FE&color=1657CC&bold=true&size=180';
  }

  @override
  Widget build(BuildContext context) {
    late final IconData badgeIcon;
    late final Color badgeColor;
    late final String value;
    late final String label;
    switch (index) {
      case 0:
        badgeIcon = Icons.emoji_events_rounded;
        badgeColor = const Color(0xFF2563EB);
        value = player.stats.runs.toString();
        label = 'Runs';
        break;
      case 1:
        badgeIcon = Icons.local_fire_department_rounded;
        badgeColor = const Color(0xFFF97316);
        value = player.stats.wickets.toString();
        label = 'Wickets';
        break;
      case 2:
        badgeIcon = Icons.star_rounded;
        badgeColor = const Color(0xFF16A34A);
        value = player.stats.strikeRate.toStringAsFixed(1);
        label = 'Strike Rate';
        break;
      default:
        badgeIcon = Icons.bolt_rounded;
        badgeColor = const Color(0xFF9333EA);
        value = player.stats.wickets.toString();
        label = 'Wickets';
    }

    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, '/player-profile/${player.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 122,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.surfaceBorder),
          boxShadow: _DS.cardShadow,
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _DS.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: _avatarFor(player.name),
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Icon(Icons.person, color: _DS.primary, size: 30),
                  ),
                ),
                Positioned(
                  top: -4,
                  left: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(badgeIcon, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _DS.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _DS.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: _DS.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home spotlight when no match is being scored right now.
class _NoLiveMatchCard extends StatelessWidget {
  const _NoLiveMatchCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _DS.surfaceBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: _DS.liveSoft, shape: BoxShape.circle),
              child: const Icon(Icons.sports_cricket_rounded, color: _DS.live, size: 26),
            ),
            const SizedBox(height: 12),
            const Text(
              'No live match available',
              style: TextStyle(color: _DS.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Matches being scored right now will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _DS.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/create-match'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Start a match'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _DS.primary,
                side: const BorderSide(color: _DS.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveScoreCarousel extends StatefulWidget {
  final List<Match> liveMatches;
  final List<LiveMatch> dashboardLiveMatches;
  final List<Match> completedMatches;
  const _LiveScoreCarousel({
    required this.liveMatches,
    this.dashboardLiveMatches = const [],
    required this.completedMatches,
    super.key,
  });

  @override
  State<_LiveScoreCarousel> createState() => _LiveScoreCarouselState();
}

class _LiveScoreCarouselState extends State<_LiveScoreCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;
  late Timer _timer;
  final Map<String, LiveStreamModel> _streamsByMatchId = {};

  List<_DashboardCarouselItem> get _items => [
        if (widget.liveMatches.where((match) => match.isLive).isNotEmpty)
          ...widget.liveMatches
              .where((match) => match.isLive)
              .map((match) => _DashboardCarouselItem.match(match, true))
        else
          ...widget.dashboardLiveMatches
              .map(_DashboardCarouselItem.dashboardLive),
      ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    _loadLiveStreamsForMatches();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final itemCount = _items.length;
      if (itemCount == 0 || !_pageController.hasClients) return;
      final nextIndex = (_currentIndex + 1) % itemCount;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _LiveScoreCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.liveMatches.map((match) => match.id).join(',');
    final newIds = widget.liveMatches.map((match) => match.id).join(',');
    final oldDashboardIds =
        oldWidget.dashboardLiveMatches.map((match) => match.id).join(',');
    final newDashboardIds =
        widget.dashboardLiveMatches.map((match) => match.id).join(',');
    if (oldIds != newIds || oldDashboardIds != newDashboardIds) {
      _loadLiveStreamsForMatches();
    }
  }

  Future<void> _loadLiveStreamsForMatches() async {
    final matchIds = {
      ...widget.liveMatches.map((match) => match.id),
      ...widget.dashboardLiveMatches.map((match) => match.id),
    }..removeWhere((id) => id.trim().isEmpty);
    if (matchIds.isEmpty) return;

    try {
      final streams = await LiveStreamService.getLiveStreams(status: 'live');
      final byMatch = <String, LiveStreamModel>{};
      for (final stream in streams) {
        final matchId = stream.matchId?.trim() ?? '';
        if (matchIds.contains(matchId)) byMatch[matchId] = stream;
      }
      if (!mounted) return;
      setState(() {
        _streamsByMatchId
          ..clear()
          ..addAll(byMatch);
      });
    } catch (e) {
      debugPrint('Dashboard live stream links skipped: $e');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const _NoLiveMatchCard();
    if (_currentIndex >= items.length) _currentIndex = 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardHeight = screenWidth < 360 ? 244.0 : 236.0;
        return SizedBox(
          height: cardHeight,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/scorecard',
                        arguments: item.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: item.match != null
                          ? _DashboardMatchCard(
                              match: item.match!,
                              isLive: item.isLive,
                              stream: _streamsByMatchId[item.id],
                            )
                          : _LiveMatchCard(
                              match: item.dashboardLiveMatch!,
                              stream: _streamsByMatchId[item.id],
                            ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: items.asMap().entries.map((entry) {
                    final isSelected = _currentIndex == entry.key;
                    return GestureDetector(
                      onTap: () => _pageController.animateToPage(entry.key,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut),
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
      },
    );
  }
}

class _DashboardCarouselItem {
  final Match? match;
  final LiveMatch? dashboardLiveMatch;
  final bool isLive;

  const _DashboardCarouselItem.match(this.match, this.isLive)
      : dashboardLiveMatch = null;

  const _DashboardCarouselItem.dashboardLive(this.dashboardLiveMatch)
      : match = null,
        isLive = true;

  String get id => match?.id ?? dashboardLiveMatch?.id ?? '';
}

// ─────────────────────────────────────────────
//  Live Hero Card — dark gradient spotlight card
// ─────────────────────────────────────────────
class _LiveHeroCard extends StatelessWidget {
  final String team1Name;
  final String? team1Logo;
  final String team2Name;
  final String? team2Logo;
  final String team1Caption;
  final String team2Caption;
  final String scoreText;
  final String oversText;
  final String battingCaption;
  final bool isLive;
  final String matchLabel;
  final int? viewerCount;
  final String footerText;
  final String actionLabel;

  const _LiveHeroCard({
    required this.team1Name,
    required this.team1Logo,
    required this.team2Name,
    required this.team2Logo,
    required this.team1Caption,
    required this.team2Caption,
    required this.scoreText,
    required this.oversText,
    required this.battingCaption,
    required this.isLive,
    required this.matchLabel,
    required this.viewerCount,
    required this.footerText,
    required this.actionLabel,
  });

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2A6B), Color(0xFF14418C), Color(0xFF1E63C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: const DecorationImage(
          image: AssetImage('score 11/Home Dashboard without text.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          opacity: 0.22,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14418C).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _DS.live,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLive ? 'LIVE' : 'COMPLETED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  matchLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (viewerCount != null && viewerCount! > 0) ...[
                Icon(Icons.remove_red_eye_outlined,
                    size: 14, color: Colors.white.withOpacity(0.85)),
                const SizedBox(width: 4),
                Text(
                  _formatCount(viewerCount!),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeroTeamColumn(
                  name: team1Name,
                  logo: team1Logo,
                  caption: team1Caption,
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (scoreText.isNotEmpty) ...[
                      Text(
                        scoreText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (oversText.isNotEmpty)
                        Text(
                          oversText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ] else
                      Icon(Icons.emoji_events_rounded,
                          color: Colors.white.withOpacity(0.85), size: 26),
                    const SizedBox(height: 6),
                    if (isLive)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _DS.live,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (battingCaption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          battingCaption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _HeroTeamColumn(
                  name: team2Name,
                  logo: team2Logo,
                  caption: team2Caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  footerText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: Color(0xFF14418C),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.play_arrow_rounded,
                        size: 15, color: Color(0xFF14418C)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTeamColumn extends StatelessWidget {
  final String name;
  final String? logo;
  final String caption;

  const _HeroTeamColumn({
    required this.name,
    required this.logo,
    this.caption = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: (logo != null && logo!.trim().isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: logo!,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF14418C)),
                )
              : const Icon(Icons.shield_rounded, color: Color(0xFF14418C)),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _DashboardMatchCard extends StatelessWidget {
  final Match match;
  final bool isLive;
  final LiveStreamModel? stream;
  const _DashboardMatchCard({
    required this.match,
    required this.isLive,
    this.stream,
  });

  @override
  Widget build(BuildContext context) {
    // The side that batted first is shown on the left; the big score is
    // always the side batting now (team2 often bats first after the toss).
    final firstSide = match.firstBattingSide;
    final secondSide = firstSide == 1 ? 2 : 1;
    final battingTeamNum = isLive ? match.currentBattingSide : 0;
    var scoreText = '';
    var oversText = '';
    if (battingTeamNum != 0) {
      final teamScore =
          battingTeamNum == 1 ? match.score.team1 : match.score.team2;
      scoreText = '${teamScore.runs}/${teamScore.wickets}';
      if (teamScore.overs.isNotEmpty) oversText = '(${teamScore.overs} overs)';
    }
    String sideScore(int side) =>
        side == 1 ? match.team1ScoreDisplay : match.team2ScoreDisplay;
    // Caption under the side that is not batting right now.
    final leftCaption = battingTeamNum == secondSide ? sideScore(firstSide) : '';
    final rightCaption = battingTeamNum == firstSide ? 'Yet to Bat' : '';
    String sideName(int side) =>
        _shortTeamName(side == 1 ? match.team1 : match.team2);
    String? sideLogo(int side) {
      final data = side == 1 ? match.team1Data : match.team2Data;
      return data is Map ? data['logo']?.toString() : null;
    }
    final matchLabel = [
      match.format.toUpperCase(),
      if (match.matchNumber != null) 'Match ${match.matchNumber}',
    ].join(' · ');

    return _LiveHeroCard(
      team1Name: sideName(firstSide),
      team1Logo: sideLogo(firstSide),
      team2Name: sideName(secondSide),
      team2Logo: sideLogo(secondSide),
      team1Caption: leftCaption,
      team2Caption: rightCaption,
      scoreText: scoreText,
      oversText: oversText,
      battingCaption: isLive ? 'Batting' : '',
      isLive: isLive,
      matchLabel: matchLabel,
      viewerCount: stream?.viewerCount,
      footerText: isLive ? _tossText(match) : _resultSummary(match),
      actionLabel: isLive ? 'Watch Live' : 'View Scorecard',
    );
  }

  static String _shortTeamName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'Team';
    final words = clean.split(RegExp(r'\s+'));
    if (words.length == 1) return clean;
    final initials = words.take(3).map((word) => word[0].toUpperCase()).join();
    return initials.length >= 2 ? initials : clean;
  }

  static String _liveSummary(Match match) {
    final side = match.currentBattingSide;
    final battingTeam = side == 2 ? match.team2 : match.team1;
    final score = side == 2 ? match.team2ScoreDisplay : match.team1ScoreDisplay;
    return '${_shortTeamName(battingTeam)} batting: $score';
  }

  static String _resultSummary(Match match) {
    final result = match.result;
    if (result?.message?.trim().isNotEmpty == true)
      return result!.message!.trim();
    if (result?.winner?.trim().isNotEmpty == true &&
        result?.margin?.trim().isNotEmpty == true) {
      return '${result!.winner} won by ${result.margin}';
    }
    if (result?.margin?.trim().isNotEmpty == true)
      return result!.margin!.trim();
    return 'Match completed';
  }

  static String _dateTimeLabel(DateTime date, String? startTime) {
    final months = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final time = startTime != null && startTime.trim().isNotEmpty
        ? startTime.trim()
        : _formatTime(date);
    return '${date.day} ${months[date.month - 1]}, $time';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String _tossWinnerName(Match match) {
    final winner = match.toss?.winner?.trim() ?? '';
    if (winner.isEmpty) return 'Team';
    if (winner == match.team1Id || winner == match.team1)
      return _shortTeamName(match.team1);
    if (winner == match.team2Id || winner == match.team2)
      return _shortTeamName(match.team2);
    return _looksLikeId(winner) ? 'Team' : _shortTeamName(winner);
  }

  static String _tossText(Match match) {
    final toss = match.toss;
    if (toss == null) return 'Toss pending';

    final winner = _tossWinnerName(match);
    final decision = toss.decision?.trim();
    if (winner == 'Team' && (decision == null || decision.isEmpty)) {
      return 'Toss pending';
    }
    if (decision == null || decision.isEmpty) return 'Toss $winner';
    return 'Toss $winner ${decision.toLowerCase()}';
  }

  static bool _looksLikeId(String value) {
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value.trim());
  }
}

// ─────────────────────────────────────────────
//  Live Match Card — Refined
// ─────────────────────────────────────────────
class _LiveMatchCard extends StatelessWidget {
  final LiveMatch match;
  final LiveStreamModel? stream;
  const _LiveMatchCard({required this.match, this.stream});

  @override
  Widget build(BuildContext context) {
    final firstSide = match.firstBattingSide;
    final secondSide = firstSide == 1 ? 2 : 1;
    final battingTeamNum = match.currentBattingSide;
    final battingRuns = battingTeamNum == 1
        ? (match.team1Score ?? match.currentRuns)
        : (match.team2Score ?? match.currentRuns);
    final battingWkts = battingTeamNum == 1
        ? (match.team1Wickets ?? match.currentWickets)
        : (match.team2Wickets ?? match.currentWickets);
    final battingOvers = battingTeamNum == 1
        ? (match.team1Overs ?? match.currentOvers)
        : (match.team2Overs ?? match.currentOvers);
    final scoreText = battingRuns != null ? '$battingRuns/${battingWkts ?? 0}' : '';
    final oversText = (battingOvers != null && battingOvers.isNotEmpty)
        ? '($battingOvers overs)'
        : '';
    // Left = side that batted first; caption under the side not batting now.
    final leftCaption = battingTeamNum == secondSide
        ? (match.scoreForTeam(firstSide) ?? '')
        : '';
    final rightCaption = battingTeamNum == firstSide ? 'Yet to Bat' : '';
    final left = firstSide == 1 ? match.team1 : match.team2;
    final right = firstSide == 1 ? match.team2 : match.team1;
    final matchLabel = [
      if (match.format.trim().isNotEmpty) match.format.toUpperCase(),
      if (match.tournament.name.trim().isNotEmpty) match.tournament.name,
    ].join(' · ');

    return _LiveHeroCard(
      team1Name: left.shortName.isNotEmpty ? left.shortName : left.name,
      team1Logo: left.logo,
      team2Name: right.shortName.isNotEmpty ? right.shortName : right.name,
      team2Logo: right.logo,
      team1Caption: leftCaption,
      team2Caption: rightCaption,
      scoreText: scoreText,
      oversText: oversText,
      battingCaption: 'Batting',
      isLive: true,
      matchLabel: matchLabel,
      viewerCount: stream?.viewerCount,
      footerText: _tossText(match),
      actionLabel: 'Watch Live',
    );
  }

  static String _tossWinnerName(LiveMatch match) {
    final winner = match.tossWinner?.trim() ?? '';
    if (winner.isEmpty) return 'Team';
    if (winner == match.team1.id ||
        winner == match.team1.name ||
        winner == match.team1.shortName) {
      return match.team1.shortName.isNotEmpty
          ? match.team1.shortName
          : match.team1.name;
    }
    if (winner == match.team2.id ||
        winner == match.team2.name ||
        winner == match.team2.shortName) {
      return match.team2.shortName.isNotEmpty
          ? match.team2.shortName
          : match.team2.name;
    }
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(winner) ? 'Team' : winner;
  }

  static String _tossText(LiveMatch match) {
    final hasWinner = match.tossWinner?.trim().isNotEmpty == true;
    final hasDecision = match.tossDecision?.trim().isNotEmpty == true;
    if (!hasWinner && !hasDecision) return 'Toss pending';

    final winner = hasWinner ? _tossWinnerName(match) : 'Team';
    final decision = match.tossDecision?.trim();
    if (decision == null || decision.isEmpty) return 'Toss $winner';
    return 'Toss $winner ${decision.toLowerCase()}';
  }

  static String _dateTimeLabel(DateTime date) {
    final months = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${_formatTime(date)}';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _LiveInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _LiveInfoChip(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CarouselActionLinks extends StatelessWidget {
  final String matchId;
  final String? tournamentId;
  final String? streamId;

  const _CarouselActionLinks({
    required this.matchId,
    this.tournamentId,
    this.streamId,
  });

  @override
  Widget build(BuildContext context) {
    final liveStreamId = streamId?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DS.primary.withOpacity(0.09)),
      ),
      child: Row(
        children: [
          _LiveBlueLink(
            icon: liveStreamId.isNotEmpty
                ? Icons.play_circle_fill_rounded
                : Icons.insights_rounded,
            label: liveStreamId.isNotEmpty ? 'Watch' : 'Insight',
            color: liveStreamId.isNotEmpty ? _DS.live : _DS.primary,
            onTap: () {
              if (liveStreamId.isNotEmpty) {
                Navigator.pushNamed(context, '/live-stream/$liveStreamId');
              } else {
                Navigator.pushNamed(context, '/scorecard', arguments: matchId);
              }
            },
          ),
          _ActionDivider(),
          _LiveBlueLink(
            icon: Icons.table_chart_outlined,
            label: 'Table',
            onTap: () {
              final id = tournamentId?.trim() ?? '';
              if (id.isNotEmpty) {
                Navigator.pushNamed(context, '/points-table', arguments: id);
              } else {
                Navigator.pushNamed(context, '/tournaments');
              }
            },
          ),
          _ActionDivider(),
          _LiveBlueLink(
            icon: Icons.leaderboard_rounded,
            label: 'Leaderboard',
            onTap: () => Navigator.pushNamed(context, '/leaderboard'),
          ),
        ],
      ),
    );
  }
}

class _StreamLiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: _DS.live.withOpacity(0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _DS.live.withOpacity(0.18)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.live_tv_rounded, size: 11, color: _DS.live),
          SizedBox(width: 3),
          Text(
            'STREAM',
            style: TextStyle(
              color: _DS.live,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: _DS.surfaceBorder,
    );
  }
}

class _LiveBlueLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _LiveBlueLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _DS.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentBallsRow extends StatelessWidget {
  final List<LiveBall> balls;
  const _RecentBallsRow({required this.balls});

  @override
  Widget build(BuildContext context) {
    final visible = balls.length > 6 ? balls.sublist(balls.length - 6) : balls;
    return Row(
      children: [
        const Text(
          'This over',
          style: TextStyle(
            color: _DS.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: visible.map((ball) {
              final isBoundary = ball.label == '4' || ball.label == '6';
              final color = ball.isWicket
                  ? _DS.live
                  : isBoundary
                      ? _DS.green
                      : _DS.primary;
              return Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.24)),
                ),
                child: Text(
                  ball.label,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: ball.label.length > 2 ? 8 : 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MatchTeamRow extends StatelessWidget {
  final String teamName;
  final String? score;
  final bool isBatting;
  const _MatchTeamRow(
      {required this.teamName, this.score, this.isBatting = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  teamName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _DS.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isBatting) ...[
                const SizedBox(width: 5),
                const Icon(Icons.sports_cricket_rounded,
                    size: 13, color: _DS.live),
              ],
            ],
          ),
        ),
        if (score != null) ...[
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 118),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                score!,
                maxLines: 1,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: _DS.primary),
              ),
            ),
          ),
        ],
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

class _BannerSlide {
  final ImageProvider image;
  final String title;
  final String cta;
  final VoidCallback? onTap;
  const _BannerSlide(this.image, this.title, this.cta, this.onTap);
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentIndex = 0;
  Timer? _timer;
  List<_BannerSlide> _slides = const [];

  // Slides are the active banners from Admin panel → Banners (position
  // "home"). With none configured the carousel takes no space.
  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadBanners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients || _slides.length < 2) return;
      final next = (_currentIndex + 1) % _slides.length;
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    });
  }

  Future<void> _loadBanners() async {
    final banners = await BannerService().getDashboardBanners();
    final usable = banners.where((b) => b.image.trim().isNotEmpty).toList();
    if (!mounted || usable.isEmpty) return;
    setState(() {
      _currentIndex = 0;
      _slides = usable.map((b) {
        final link = (b.link ?? '').trim();
        VoidCallback? onTap;
        if (link.startsWith('/')) {
          onTap = () => Navigator.pushNamed(context, link);
        } else if (link.startsWith('http')) {
          onTap = () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
        }
        return _BannerSlide(
          CachedNetworkImageProvider(b.image),
          b.title,
          onTap == null ? '' : 'Open',
          onTap,
        );
      }).toList();
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    if (slides.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 196,
      margin: const EdgeInsets.only(top: 14),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final slide = slides[index];
              return GestureDetector(
                onTap: slide.onTap,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: _DS.primary,
                    borderRadius: BorderRadius.circular(_DS.radiusXL),
                    image: DecorationImage(image: slide.image, fit: BoxFit.cover),
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    alignment: Alignment.bottomLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_DS.radiusXL),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            slide.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                              shadows: [
                                Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 4)
                              ],
                            ),
                          ),
                        ),
                        if (slide.cta.isNotEmpty && slide.onTap != null)
                          ElevatedButton(
                            onPressed: slide.onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _DS.gold,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Text(slide.cta,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (slides.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (index) {
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
  final int index;
  const _TrendingPlayerCard({required this.player, required this.index});

  @override
  Widget build(BuildContext context) {
    final rank = player.rank > 0 ? player.rank : index + 1;
    final team = player.team.shortName.isNotEmpty
        ? player.team.shortName
        : player.team.name;
    return GestureDetector(
      onTap: player.id.isEmpty
          ? null
          : () => Navigator.pushNamed(context, '/player-profile/${player.id}'),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF7ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(_DS.radiusLG),
          border: Border.all(color: const Color(0xFFF97316).withOpacity(0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFF59E0B)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFF97316).withOpacity(0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name.isNotEmpty ? player.name : 'Player',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: _DS.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        team.isNotEmpty ? team : player.role,
                        style: const TextStyle(
                            fontSize: 10,
                            color: _DS.textSecondary,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                    child: _MiniMetric(
                        label: 'Runs',
                        value: '${player.stats.runs}',
                        color: const Color(0xFFF97316))),
                const SizedBox(width: 8),
                Expanded(
                    child: _MiniMetric(
                        label: 'Wkts',
                        value: '${player.stats.wickets}',
                        color: _DS.primary)),
                const SizedBox(width: 8),
                Expanded(
                    child: _MiniMetric(
                        label: 'SR',
                        value: player.stats.strikeRate.toStringAsFixed(0),
                        color: _DS.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniMetric(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 1),
          Text(label,
              style: const TextStyle(
                  color: _DS.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700)),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                gradient: _DS.heroGrad,
                borderRadius: BorderRadius.circular(13)),
            child:
                const Icon(Icons.sports_cricket, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.team1.shortName}  vs  ${match.team2.shortName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _DS.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(match.tournament.name,
                    style:
                        const TextStyle(color: _DS.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    gradient: _DS.heroGrad,
                    borderRadius: BorderRadius.circular(7)),
                child: Text(match.format.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 5),
              Text(_formatDate(match.scheduledDate),
                  style: const TextStyle(color: _DS.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
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
    final title =
        blog.title.trim().isEmpty ? 'Untitled Blog' : blog.title.trim();
    final excerpt = (blog.excerpt?.trim().isNotEmpty ?? false)
        ? blog.excerpt!.trim()
        : 'Read the latest cricket story, match insights, and updates from Scores11.';
    final author = (blog.author?.trim().isNotEmpty ?? false)
        ? blog.author!.trim()
        : 'Scores11 Team';
    final date = _formatBlogDate(blog.createdAt);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.blogs),
      child: Container(
        width: 232,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(_DS.radiusXL),
          border: Border.all(color: const Color(0xFF0891B2).withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0891B2).withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: blog.imageUrl ?? '',
                  height: 118,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 118,
                    color: _DS.surfaceAlt,
                    child: const Icon(Icons.article_outlined,
                        color: _DS.textMuted),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 118,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE0F2FE), Color(0xFFF0FDFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.article_rounded,
                        color: Color(0xFF0891B2), size: 34),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.64),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'BLOG',
                          style: TextStyle(
                            color: Color(0xFF0891B2),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (date.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.36),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Text(
                            date,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: _DS.textPrimary,
                        height: 1.22,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      excerpt,
                      style: const TextStyle(
                        color: _DS.textSecondary,
                        fontSize: 10,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0891B2).withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            size: 15,
                            color: Color(0xFF0891B2),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            author,
                            style: const TextStyle(
                              color: _DS.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0891B2).withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Color(0xFF0891B2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBlogDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
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
    final author = post['author'] is Map ? post['author'] as Map : null;
    final content = (post['content'] ?? post['text'] ?? '').toString();
    final userName = (post['userName'] ??
            post['name'] ??
            author?['name'] ??
            author?['fullName'] ??
            'Community')
        .toString();
    final images = post['images'];
    final image =
        images is List && images.isNotEmpty ? images.first?.toString() : null;
    final likes = post['likesCount'] ?? post['likes'] ?? 0;
    final comments = post['commentsCount'] ?? post['comments'] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/community'),
      child: Container(
        width: 218,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(_DS.radiusLG),
          border: Border.all(color: _DS.purple.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [_DS.purple, _DS.purple.withOpacity(0.72)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: _DS.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        (post['timeAgo'] ?? post['createdAt'] ?? 'recent')
                            .toString(),
                        style: const TextStyle(
                            color: _DS.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                content.isNotEmpty
                    ? content
                    : 'New community update from Scores11.',
                style: const TextStyle(
                    fontSize: 11,
                    height: 1.42,
                    color: _DS.textSecondary,
                    fontWeight: FontWeight.w600),
                maxLines: image == null ? 5 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (image != null && image.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CachedNetworkImage(
                  imageUrl: image,
                  height: 58,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    height: 58,
                    color: _DS.surfaceAlt,
                    child: const Icon(Icons.image_outlined,
                        size: 20, color: _DS.textMuted),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _PostMetric(icon: Icons.thumb_up_alt_outlined, value: '$likes'),
                const SizedBox(width: 10),
                _PostMetric(
                    icon: Icons.mode_comment_outlined, value: '$comments'),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                      color: _DS.purple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Post',
                      style: TextStyle(
                          color: _DS.purple,
                          fontSize: 9,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  const _PostMetric({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _DS.textSecondary),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 10,
                color: _DS.textSecondary,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _DashboardPostFeed extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Set<String> likedPostIds;
  final Future<void> Function() onRefresh;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final ValueChanged<Map<String, dynamic>> onLike;
  final ValueChanged<Map<String, dynamic>> onComment;
  final ValueChanged<Map<String, dynamic>> onShare;

  const _DashboardPostFeed({
    required this.posts,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.likedPostIds,
    required this.onRefresh,
    required this.onOpen,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _DS.purpleSoft,
                  borderRadius: BorderRadius.circular(_DS.radiusSM),
                ),
                child: const Icon(Icons.dynamic_feed_rounded,
                    size: 17, color: _DS.purple),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Posts',
                  style: TextStyle(
                    color: _DS.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Create post',
                onPressed: () => Navigator.pushNamed(context, '/create-post')
                    .then((_) => onRefresh()),
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: _DS.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 42),
              child:
                  Center(child: CircularProgressIndicator(color: _DS.primary)),
            )
          else if (posts.isEmpty)
            const _EmptyState(message: 'No posts available right now')
          else ...[
            ...posts.map((post) {
              final postId = (post['id'] ?? post['_id'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _DashboardPostCard(
                  post: post,
                  isLiked: likedPostIds.contains(postId),
                  onOpen: () => onOpen(post),
                  onLike: () => onLike(post),
                  onComment: () => onComment(post),
                  onShare: () => onShare(post),
                ),
              );
            }),
            if (isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                    child: CircularProgressIndicator(
                        color: _DS.primary, strokeWidth: 2.4)),
              )
            else if (!hasMore)
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 18),
                child: Center(
                  child: Text(
                    'You are all caught up',
                    style: TextStyle(
                        color: _DS.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DashboardPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isLiked;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const _DashboardPostCard({
    required this.post,
    required this.isLiked,
    required this.onOpen,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  State<_DashboardPostCard> createState() => _DashboardPostCardState();
}

class _DashboardPostCardState extends State<_DashboardPostCard> {
  bool _showReaction = false;

  void _handleLike() {
    setState(() => _showReaction = true);
    widget.onLike();
    Timer(const Duration(milliseconds: 760), () {
      if (mounted) setState(() => _showReaction = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final author =
        (post['userName'] ?? post['name'] ?? 'Scores11 User').toString();
    final avatar =
        _safeUrl((post['userAvatar'] ?? post['avatar'])?.toString()) ??
            _avatarFor(author);
    final content = (post['content'] ?? post['caption'] ?? '').toString();
    final timeAgo = (post['timeAgo'] ?? post['time'] ?? 'recent').toString();
    final images = post['images'] is List ? post['images'] as List : const [];
    final image = images.isNotEmpty ? _safeUrl(images.first?.toString()) : null;
    final likes = _count(post['likes']);
    final comments = _count(post['comments']);
    final shares = _count(post['shares']);
    final postId = (post['id'] ?? post['_id'] ?? '').toString();

    return InkWell(
      onTap: widget.onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _DS.surfaceBorder),
          boxShadow: _DS.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatar,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 42,
                        height: 42,
                        color: _DS.primarySoft,
                        child: const Icon(Icons.person_rounded,
                            color: _DS.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _DS.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                              color: _DS.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Share shortcut',
                    onPressed: widget.onShare,
                    icon: const Icon(Icons.more_horiz_rounded,
                        color: _DS.textMuted),
                  ),
                ],
              ),
            ),
            if (content.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text(
                  content,
                  style: const TextStyle(
                      color: _DS.textPrimary,
                      fontSize: 13,
                      height: 1.42,
                      fontWeight: FontWeight.w600),
                ),
              ),
            if (image != null)
              Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    height: 220,
                    placeholder: (_, __) =>
                        Container(height: 220, color: _DS.surfaceAlt),
                    errorWidget: (_, __, ___) => Container(
                      height: 160,
                      color: _DS.surfaceAlt,
                      child: const Center(
                          child: Icon(Icons.image_outlined,
                              color: _DS.textMuted, size: 34)),
                    ),
                  ),
                  AnimatedScale(
                    scale: _showReaction ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: _showReaction ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('❤️', style: TextStyle(fontSize: 42)),
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$likes likes  •  $comments comments  •  $shares shares',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _DS.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _DS.surfaceBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  _PostActionButton(
                    icon: widget.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: widget.isLiked ? 'Liked' : 'Like',
                    color: widget.isLiked ? _DS.live : _DS.textSecondary,
                    onTap: _handleLike,
                  ),
                  _PostActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: 'Comment',
                    color: _DS.textSecondary,
                    onTap: widget.onComment,
                  ),
                  _PostActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: _DS.textSecondary,
                    onTap: widget.onShare,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int _count(dynamic value) {
    if (value is int) return value;
    if (value is List) return value.length;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _safeUrl(String? value) {
    final url = value?.trim();
    if (url == null ||
        url.isEmpty ||
        url == 'null' ||
        url == 'default-avatar-url') return null;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty ? url : null;
  }

  static String _avatarFor(String name) {
    final encoded = Uri.encodeComponent(
        name.trim().isEmpty ? 'Scores11 User' : name.trim());
    return 'https://ui-avatars.com/api/?name=$encoded&background=1A56DB&color=fff&bold=true&size=160';
  }
}

class _DashboardCommentSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final CommunityService service;

  const _DashboardCommentSheet({
    required this.post,
    required this.service,
  });

  @override
  State<_DashboardCommentSheet> createState() => _DashboardCommentSheetState();
}

class _DashboardCommentSheetState extends State<_DashboardCommentSheet> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _updatedPost;

  String get _postId =>
      (widget.post['id'] ?? widget.post['_id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final comments = await widget.service.getComments(_postId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e, fallback: 'Could not load community updates.');
        _loading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final updated =
          await widget.service.addComment(_postId, {'content': text});
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _updatedPost = updated;
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
      setState(() {
        _error = friendlyError(e, fallback: 'Could not load community updates.');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _DS.surfaceBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Comments',
                          style: TextStyle(
                            color: _DS.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, _updatedPost),
                        icon: const Icon(Icons.close_rounded,
                            color: _DS.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: _DS.primary))
                      : _error != null
                          ? _CommentError(
                              message: _error!, onRetry: _loadComments)
                          : _comments.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No comments yet',
                                    style: TextStyle(
                                        color: _DS.textMuted,
                                        fontWeight: FontWeight.w700),
                                  ),
                                )
                              : ListView.separated(
                                  controller: controller,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  itemCount: _comments.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _CommentTile(comment: _comments[index]),
                                ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Write a comment',
                              filled: true,
                              fillColor: _DS.surfaceAlt,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: _DS.surfaceBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: _DS.surfaceBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: _DS.primary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submitComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _DS.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final user = comment['user'] is Map
        ? Map<String, dynamic>.from(comment['user'] as Map)
        : const <String, dynamic>{};
    final name = (comment['userName'] ??
            user['name'] ??
            user['fullName'] ??
            'Scores11 User')
        .toString();
    final text = (comment['content'] ?? '').toString();
    final avatar = _DashboardPostCardState._safeUrl(
          (comment['userAvatar'] ?? user['avatar'] ?? user['profileImage'])
              ?.toString(),
        ) ??
        _DashboardPostCardState._avatarFor(name);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatar,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              width: 36,
              height: 36,
              color: _DS.primarySoft,
              child: const Icon(Icons.person_rounded,
                  color: _DS.primary, size: 18),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _DS.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _DS.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _DS.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900),
                ),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: const TextStyle(
                        color: _DS.textSecondary,
                        height: 1.35,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CommentError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _DS.live, size: 34),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _DS.textSecondary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _PostActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PostActionButton({
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
        icon: Icon(icon, size: 18, color: color),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: TextButton.styleFrom(
          foregroundColor: color,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _FollowingYouRail extends StatefulWidget {
  final List<TrendingPlayer> players;
  final List<Map<String, dynamic>> posts;

  const _FollowingYouRail({
    required this.players,
    required this.posts,
  });

  @override
  State<_FollowingYouRail> createState() => _FollowingYouRailState();
}

class _FollowingYouRailState extends State<_FollowingYouRail> {
  static const _followKey = 'scores11_following_ids';
  final Set<String> _followingIds = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _followingIds
        ..clear()
        ..addAll(prefs.getStringList(_followKey) ?? const []);
      _loaded = true;
    });
  }

  Future<void> _toggleFollow(String id) async {
    setState(() {
      if (_followingIds.contains(id)) {
        _followingIds.remove(id);
      } else {
        _followingIds.add(id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_followKey, _followingIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _DS.greenSoft,
                  borderRadius: BorderRadius.circular(_DS.radiusSM),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    size: 17, color: _DS.green),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Players to follow',
                  style: TextStyle(
                    color: _DS.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.publicPlayers),
                child: const Text('See All',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 204,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration:
                    Duration(milliseconds: 260 + (index * 55).clamp(0, 280)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(22 * (1 - value), 0),
                      child: child,
                    ),
                  );
                },
                child: _FollowingCard(
                  item: item,
                  isFollowing: _loaded && _followingIds.contains(item.id),
                  onFollow: () => _toggleFollow(item.id),
                  onTap: () => _openItem(context, item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<_FollowingItem> _buildItems() {
    final playerItems = widget.players.take(8).map((player) {
      final title =
          player.name.trim().isEmpty ? 'Cricket Player' : player.name.trim();
      final subtitle = [
        player.role.trim().isEmpty ? 'Player' : player.role,
        player.team.shortName.trim().isEmpty
            ? player.team.name
            : player.team.shortName,
      ].where((value) => value.trim().isNotEmpty).join(' • ');
      return _FollowingItem(
        id: 'player:${player.id.isEmpty ? title : player.id}',
        routeId: player.id,
        type: _FollowingType.player,
        title: title,
        subtitle: subtitle.isEmpty
            ? '${player.stats.runs} runs • ${player.stats.wickets} wickets'
            : subtitle,
        imageUrl: _avatarFor(title),
        badge:
            '#${player.rank == 0 ? widget.players.indexOf(player) + 1 : player.rank}',
        accent: _DS.primary,
      );
    }).toList();

    final postItems = widget.posts.take(6).map((post) {
      final author = post['author'] is Map
          ? Map<String, dynamic>.from(post['author'] as Map)
          : <String, dynamic>{};
      final images = post['images'] is List ? post['images'] as List : const [];
      final name = (post['userName'] ??
              post['name'] ??
              author['name'] ??
              author['fullName'] ??
              'Community')
          .toString();
      final content =
          (post['content'] ?? post['caption'] ?? 'New cricket update')
              .toString();
      final rawImage = images.isNotEmpty ? images.first?.toString() : null;
      final avatar =
          author['profileImage']?.toString() ?? author['avatar']?.toString();
      return _FollowingItem(
        id: 'post:${(post['_id'] ?? post['id'] ?? name).toString()}',
        routeId: (post['_id'] ?? post['id'] ?? '').toString(),
        type: _FollowingType.post,
        title: name,
        subtitle: content,
        imageUrl:
            _usableUrl(rawImage) ?? _usableUrl(avatar) ?? _avatarFor(name),
        badge: 'Post',
        accent: _DS.purple,
      );
    }).toList();

    return [...playerItems, ...postItems];
  }

  void _openItem(BuildContext context, _FollowingItem item) {
    if (item.type == _FollowingType.player && item.routeId.isNotEmpty) {
      Navigator.pushNamed(context, '/player-profile/${item.routeId}');
      return;
    }
    if (item.type == _FollowingType.post && item.routeId.isNotEmpty) {
      Navigator.pushNamed(context, '/post-detail', arguments: item.routeId);
      return;
    }
    Navigator.pushNamed(
        context,
        item.type == _FollowingType.player
            ? AppRoutes.publicPlayers
            : '/community');
  }

  static String _avatarFor(String name) {
    final encoded =
        Uri.encodeComponent(name.trim().isEmpty ? 'Scores11' : name.trim());
    return 'https://ui-avatars.com/api/?name=$encoded&background=1A56DB&color=fff&bold=true&size=256';
  }

  static String? _usableUrl(String? value) {
    final url = value?.trim();
    if (url == null ||
        url.isEmpty ||
        url == 'null' ||
        url == 'default-avatar-url') return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return url;
  }
}

enum _FollowingType { player, post }

class _FollowingItem {
  final String id;
  final String routeId;
  final _FollowingType type;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String badge;
  final Color accent;

  const _FollowingItem({
    required this.id,
    required this.routeId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.badge,
    required this.accent,
  });
}

class _FollowingCard extends StatelessWidget {
  final _FollowingItem item;
  final bool isFollowing;
  final VoidCallback onFollow;
  final VoidCallback onTap;

  const _FollowingCard({
    required this.item,
    required this.isFollowing,
    required this.onFollow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 174,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                  imageUrl: item.imageUrl,
                  height: 92,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: _DS.surfaceAlt),
                  errorWidget: (context, url, error) => Container(
                    color: _DS.surfaceAlt,
                    child: Icon(
                      item.type == _FollowingType.player
                          ? Icons.person_rounded
                          : Icons.forum_rounded,
                      color: item.accent,
                      size: 34,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.35)
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badge,
                      style: TextStyle(
                          color: item.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _DS.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _DS.textSecondary,
                        fontSize: 10.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: onFollow,
                      icon: Icon(
                          isFollowing ? Icons.check_rounded : Icons.add_rounded,
                          size: 16),
                      label: Text(isFollowing ? 'Following' : 'Follow'),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor:
                            isFollowing ? _DS.greenSoft : _DS.primary,
                        foregroundColor: isFollowing ? _DS.green : Colors.white,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w900),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Other Tabs
// ─────────────────────────────────────────────
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}

enum _SearchResultType { player, match, team, tournament }

class _SearchResultItem {
  final _SearchResultType type;
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SearchResultItem({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _GlobalCricketSearchScreen extends StatefulWidget {
  const _GlobalCricketSearchScreen();

  @override
  State<_GlobalCricketSearchScreen> createState() =>
      _GlobalCricketSearchScreenState();
}

class _GlobalCricketSearchScreenState
    extends State<_GlobalCricketSearchScreen> {
  static const _recentKey = 'scores11_global_search_recent';

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PlayerService _playerService = PlayerService();
  final TeamService _teamService = TeamService();
  final MatchService _matchService = MatchService();
  final TournamentService _tournamentService = TournamentService();

  Timer? _debounce;
  String _query = '';
  bool _isLoading = false;
  _SearchResultType? _activeType;
  List<String> _recent = [];
  List<_SearchResultItem> _results = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _recent = prefs.getStringList(_recentKey) ?? const []);
  }

  Future<void> _saveRecent(String value) async {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return;
    final next = [
      cleaned,
      ..._recent.where((item) => item.toLowerCase() != cleaned.toLowerCase())
    ].take(8).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, next);
    if (mounted) setState(() => _recent = next);
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 350), () => _runSearch(value));
  }

  Future<void> _runSearch(String value) async {
    final query = value.trim();
    if (query.length < 2) {
      if (mounted) setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait<dynamic>([
        _playerService
            .searchPlayers(query, limit: 8)
            .catchError((_) => <Player>[]),
        _teamService
            .searchTeams(query, limit: 8)
            .catchError((_) => <app_team.Team>[]),
        _matchService.searchMatches(query).catchError((_) => <Match>[]),
        _tournamentService
            .searchTournaments(query, limit: 8)
            .catchError((_) => <Tournament>[]),
      ]);

      final players = (responses[0] as List<Player>).map((player) {
        return _SearchResultItem(
          type: _SearchResultType.player,
          id: player.id,
          title: player.name.isNotEmpty ? player.name : 'Unnamed player',
          subtitle: [
            player.playerRole ?? player.role ?? 'Player',
            player.teamName,
          ]
              .where(
                  (item) => item != null && item.toString().trim().isNotEmpty)
              .join(' • '),
          icon: Icons.person_search_rounded,
          color: _DS.primary,
        );
      });

      final teams = (responses[1] as List<app_team.Team>).map((team) {
        return _SearchResultItem(
          type: _SearchResultType.team,
          id: team.id,
          title: team.name.isNotEmpty ? team.name : 'Unnamed team',
          subtitle: [
            team.shortName,
            team.city,
            '${team.players.length} players',
          ]
              .where(
                  (item) => item != null && item.toString().trim().isNotEmpty)
              .join(' • '),
          icon: Icons.groups_rounded,
          color: _DS.green,
        );
      });

      final matches = (responses[2] as List<Match>).take(8).map((match) {
        return _SearchResultItem(
          type: _SearchResultType.match,
          id: match.id,
          title:
              '${_teamLabel(match.team1Data, match.team1)} vs ${_teamLabel(match.team2Data, match.team2)}',
          subtitle:
              '${match.status} • ${match.format} • ${_shortDate(match.scheduledDate)}',
          icon: Icons.sports_cricket_rounded,
          color: _DS.live,
        );
      });

      final tournaments = (responses[3] as List<Tournament>).map((tournament) {
        return _SearchResultItem(
          type: _SearchResultType.tournament,
          id: tournament.id,
          title: tournament.name.isNotEmpty
              ? tournament.name
              : 'Unnamed tournament',
          subtitle: [
            tournament.status,
            tournament.format,
            tournament.venue,
          ]
              .where(
                  (item) => item != null && item.toString().trim().isNotEmpty)
              .join(' • '),
          icon: Icons.emoji_events_rounded,
          color: _DS.gold,
        );
      });

      if (!mounted) return;
      setState(() {
        _results = [...players, ...matches, ...teams, ...tournaments];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
  }

  void _openResult(_SearchResultItem item) {
    _saveRecent(_query.isNotEmpty ? _query : item.title);
    switch (item.type) {
      case _SearchResultType.player:
        Navigator.pushNamed(context, '/player-profile/${item.id}');
        break;
      case _SearchResultType.team:
        Navigator.pushNamed(context, '/team-detail', arguments: item.id);
        break;
      case _SearchResultType.match:
        Navigator.pushNamed(context, '/match/${item.id}');
        break;
      case _SearchResultType.tournament:
        Navigator.pushNamed(context, '/tournament/${item.id}');
        break;
    }
  }

  void _useSuggestion(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _onChanged(value);
    _runSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'players near me',
      'live match',
      'opening batsman',
      'teams',
      'tournament',
      'scorecard',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: _DS.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _DS.surfaceBorder),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _onChanged,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          _saveRecent(value);
                          _runSearch(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search players, teams, matches',
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: _DS.textMuted),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_query.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: _DS.textMuted),
                                  onPressed: () {
                                    _controller.clear();
                                    _onChanged('');
                                  },
                                ),
                              IconButton(
                                tooltip: 'Scan QR',
                                icon: const Icon(Icons.qr_code_scanner_rounded,
                                    color: _DS.textPrimary),
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const _QrScanEntryScreen())),
                              ),
                            ],
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.trim().length < 2
                  ? _SearchLanding(
                      recent: _recent,
                      suggestions: suggestions,
                      onUse: _useSuggestion)
                  : _SearchResults(
                      isLoading: _isLoading,
                      results: _results,
                      activeType: _activeType,
                      onTypeSelected: (type) =>
                          setState(() => _activeType = type),
                      onTap: _openResult,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _teamLabel(dynamic raw, String fallback) {
    if (raw is Map) {
      return (raw['shortName'] ?? raw['name'] ?? fallback).toString();
    }
    return fallback;
  }

  static String _shortDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _SearchLanding extends StatelessWidget {
  final List<String> recent;
  final List<String> suggestions;
  final ValueChanged<String> onUse;

  const _SearchLanding(
      {required this.recent, required this.suggestions, required this.onUse});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      children: [
        if (recent.isNotEmpty) ...[
          const _SearchSectionTitle(title: 'Recent searches'),
          const SizedBox(height: 8),
          ...recent.map((item) => _SearchChipRow(
              icon: Icons.history_rounded,
              label: item,
              onTap: () => onUse(item))),
          const SizedBox(height: 18),
        ],
        const _SearchSectionTitle(title: 'Suggested'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((item) {
            return ActionChip(
              avatar: const Icon(Icons.north_west_rounded,
                  size: 16, color: _DS.primary),
              label: Text(item),
              backgroundColor: _DS.primarySoft,
              side: BorderSide(color: _DS.primary.withOpacity(0.12)),
              labelStyle: const TextStyle(
                  color: _DS.primary, fontWeight: FontWeight.w700),
              onPressed: () => onUse(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  final bool isLoading;
  final List<_SearchResultItem> results;
  final _SearchResultType? activeType;
  final ValueChanged<_SearchResultType?> onTypeSelected;
  final ValueChanged<_SearchResultItem> onTap;

  const _SearchResults({
    required this.isLoading,
    required this.results,
    required this.activeType,
    required this.onTypeSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _DS.primary));
    }
    if (results.isEmpty) {
      return const _EmptyState(
          message: 'No players, matches, teams, or tournaments found');
    }

    final types = [
      _SearchResultType.player,
      _SearchResultType.match,
      _SearchResultType.team,
      _SearchResultType.tournament,
    ];
    final visibleTypes = activeType == null ? types : [activeType!];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SearchCategoryChip(
                label: 'All',
                count: results.length,
                selected: activeType == null,
                onTap: () => onTypeSelected(null),
              ),
              ...types.map((type) {
                final count = results.where((item) => item.type == type).length;
                return _SearchCategoryChip(
                  label: _typeLabel(type),
                  count: count,
                  selected: activeType == type,
                  onTap: () => onTypeSelected(type),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...visibleTypes.expand((type) {
          final items = results.where((item) => item.type == type).toList();
          if (items.isEmpty) return <Widget>[];
          return [
            _SearchCategoryHeader(type: type, count: items.length),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child:
                      _SearchResultTile(item: item, onTap: () => onTap(item)),
                )),
            const SizedBox(height: 6),
          ];
        }),
      ],
    );
  }

  static String _typeLabel(_SearchResultType type) {
    switch (type) {
      case _SearchResultType.player:
        return 'Players';
      case _SearchResultType.match:
        return 'Matches';
      case _SearchResultType.team:
        return 'Teams';
      case _SearchResultType.tournament:
        return 'Tournaments';
    }
  }
}

class _SearchCategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _SearchCategoryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Text('$label ($count)'),
        selectedColor: _DS.primary,
        backgroundColor: const Color(0xFFF7F9FC),
        side: BorderSide(color: selected ? _DS.primary : _DS.surfaceBorder),
        labelStyle: TextStyle(
          color: selected ? Colors.white : _DS.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SearchCategoryHeader extends StatelessWidget {
  final _SearchResultType type;
  final int count;

  const _SearchCategoryHeader({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    final meta = _categoryMeta(type);
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
              color: meta.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(meta.icon, color: meta.color, size: 15),
        ),
        const SizedBox(width: 8),
        Text(
          '${meta.label} ($count)',
          style: const TextStyle(
              color: _DS.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final _SearchResultItem item;
  final VoidCallback onTap;

  const _SearchResultTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.surfaceBorder),
          boxShadow: _DS.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _DS.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                      item.subtitle.isEmpty
                          ? _categoryMeta(item.type).singularLabel
                          : item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: _DS.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _DS.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SearchCategoryMeta {
  final String label;
  final String singularLabel;
  final IconData icon;
  final Color color;

  const _SearchCategoryMeta(
      this.label, this.singularLabel, this.icon, this.color);
}

_SearchCategoryMeta _categoryMeta(_SearchResultType type) {
  switch (type) {
    case _SearchResultType.player:
      return const _SearchCategoryMeta(
          'Players', 'Player', Icons.person_search_rounded, _DS.primary);
    case _SearchResultType.match:
      return const _SearchCategoryMeta(
          'Matches', 'Match', Icons.sports_cricket_rounded, _DS.live);
    case _SearchResultType.team:
      return const _SearchCategoryMeta(
          'Teams', 'Team', Icons.groups_rounded, _DS.green);
    case _SearchResultType.tournament:
      return const _SearchCategoryMeta(
          'Tournaments', 'Tournament', Icons.emoji_events_rounded, _DS.gold);
  }
}

class _SearchSectionTitle extends StatelessWidget {
  final String title;
  const _SearchSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            color: _DS.textPrimary, fontSize: 15, fontWeight: FontWeight.w900));
  }
}

class _SearchChipRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SearchChipRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _DS.textMuted),
      title: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing:
          const Icon(Icons.north_west_rounded, size: 18, color: _DS.textMuted),
      onTap: onTap,
    );
  }
}

class _QrScanEntryScreen extends StatefulWidget {
  const _QrScanEntryScreen();

  @override
  State<_QrScanEntryScreen> createState() => _QrScanEntryScreenState();
}

class _QrScanEntryScreenState extends State<_QrScanEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final ImagePicker _imagePicker = ImagePicker();
  final TeamService _teamService = TeamService();
  bool _isHandlingScan = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQrValue(String value) async {
    if (_isHandlingScan) return;
    final payload = _parseQrPayload(value.trim());
    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Scores11 QR code')));
      return;
    }
    setState(() => _isHandlingScan = true);
    await _scannerController.stop();
    if (!mounted) return;
    await _openQrPayload(payload);
    if (!mounted) return;
    setState(() => _isHandlingScan = false);
    _scannerController.start();
  }

  void _onDetect(BarcodeCapture capture) {
    final value = _firstQrValue(capture);
    if (value == null) return;
    HapticFeedback.mediumImpact();
    _controller.text = value;
    _handleQrValue(value);
  }

  Future<void> _scanFromGallery() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final capture = await _scannerController.analyzeImage(image.path);
    final value = capture == null ? null : _firstQrValue(capture);
    if (value == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR code found in selected image')),
      );
      return;
    }
    _controller.text = value;
    _handleQrValue(value);
  }

  String? _firstQrValue(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  _QrPayload? _parseQrPayload(String value) {
    if (value.isEmpty) return null;
    if (value.startsWith('{')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          final appName = (map['app'] ?? map['source'] ?? 'scores11')
              .toString()
              .toLowerCase();
          if (appName != 'scores11' &&
              appName != 'crick11' &&
              appName != 'cric11') return null;
          final type =
              (map['type'] ?? map['entity'] ?? '').toString().toLowerCase();
          return _QrPayload(
            type: type,
            id: (map['id'] ??
                    map['userId'] ??
                    map['playerId'] ??
                    map['teamId'] ??
                    map['matchId'] ??
                    '')
                .toString(),
            playerId: map['playerId']?.toString(),
            teamId: map['teamId']?.toString(),
            matchId: map['matchId']?.toString(),
            title: map['name']?.toString(),
          );
        }
      } catch (_) {}
    }

    final uri = Uri.tryParse(value);
    final path = uri?.path ?? value;
    final segments =
        path.split('/').where((part) => part.trim().isNotEmpty).toList();
    if (uri != null && uri.scheme == 'scores11') {
      final host = uri.host.toLowerCase();
      final typeFromQuery =
          (uri.queryParameters['type'] ?? uri.queryParameters['entity'] ?? '')
              .toLowerCase();
      final id = uri.queryParameters['id'] ??
          uri.queryParameters['playerId'] ??
          uri.queryParameters['teamId'] ??
          uri.queryParameters['matchId'] ??
          (segments.isNotEmpty ? segments.last : '');
      if (host == 'qr' && typeFromQuery.isNotEmpty) {
        return _QrPayload(
          type: typeFromQuery,
          id: id,
          playerId: uri.queryParameters['playerId'] ??
              (typeFromQuery.contains('player') ||
                      typeFromQuery.contains('profile')
                  ? id
                  : null),
          teamId: uri.queryParameters['teamId'] ??
              (typeFromQuery.contains('team') ? id : null),
          matchId: uri.queryParameters['matchId'] ??
              (typeFromQuery.contains('match') ? id : null),
          title: uri.queryParameters['name'],
        );
      }
      if (host == 'profile' || host == 'user' || host == 'player') {
        return _QrPayload(
          type: 'profile',
          id: id,
          playerId: uri.queryParameters['playerId'] ?? id,
          title: uri.queryParameters['name'],
        );
      }
      if (host == 'team') {
        return _QrPayload(
            type: 'team',
            id: id,
            teamId: id,
            title: uri.queryParameters['name']);
      }
      if (host == 'match') {
        return _QrPayload(type: 'match', id: id, matchId: id);
      }
    }
    if (segments.length >= 2 &&
        segments[segments.length - 2].contains('player')) {
      return _QrPayload(
          type: 'profile', id: segments.last, playerId: segments.last);
    }
    if (segments.length >= 2 &&
        segments[segments.length - 2].contains('profile')) {
      return _QrPayload(
          type: 'profile', id: segments.last, playerId: segments.last);
    }
    if (segments.length >= 2 &&
        segments[segments.length - 2].contains('user')) {
      return _QrPayload(
          type: 'profile', id: segments.last, playerId: segments.last);
    }
    if (segments.length >= 2 &&
        segments[segments.length - 2].contains('team')) {
      return _QrPayload(type: 'team', id: segments.last, teamId: segments.last);
    }
    if (segments.length >= 2 &&
        segments[segments.length - 2].contains('match')) {
      return _QrPayload(
          type: 'match', id: segments.last, matchId: segments.last);
    }
    if (value.startsWith('player:'))
      return _QrPayload(
          type: 'profile',
          id: value.substring(7),
          playerId: value.substring(7));
    if (value.startsWith('profile:'))
      return _QrPayload(
          type: 'profile',
          id: value.substring(8),
          playerId: value.substring(8));
    if (value.startsWith('user:'))
      return _QrPayload(
          type: 'profile',
          id: value.substring(5),
          playerId: value.substring(5));
    if (value.startsWith('team:'))
      return _QrPayload(
          type: 'team', id: value.substring(5), teamId: value.substring(5));
    if (value.startsWith('match:'))
      return _QrPayload(
          type: 'match', id: value.substring(6), matchId: value.substring(6));
    if (RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value)) {
      return _QrPayload(type: 'profile', id: value, playerId: value);
    }
    return null;
  }

  Future<void> _openQrPayload(_QrPayload payload) async {
    if (payload.type.contains('team')) {
      Navigator.pushNamed(context, '/team-detail',
          arguments: payload.teamId ?? payload.id);
      return;
    }
    if (payload.type.contains('match')) {
      Navigator.pushNamed(context, '/match/${payload.matchId ?? payload.id}');
      return;
    }
    if (payload.type.contains('profile') ||
        payload.type.contains('player') ||
        payload.type.contains('user')) {
      await _showProfileQrActions(payload);
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Unsupported Scores11 QR')));
  }

  Future<void> _showProfileQrActions(_QrPayload payload) async {
    final playerId = (payload.playerId?.isNotEmpty == true
            ? payload.playerId
            : payload.id) ??
        '';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                        color: _DS.surfaceBorder,
                        borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 16),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                      gradient: _DS.heroGrad,
                      borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.person_search_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                Text(payload.title ?? 'Scores11 Profile',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _DS.textPrimary)),
                const SizedBox(height: 4),
                const Text('Choose what you want to do',
                    style: TextStyle(
                        color: _DS.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                _QrActionTile(
                  icon: Icons.account_circle_rounded,
                  title: 'View profile',
                  subtitle: 'Open cricket profile details',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/player-profile/$playerId');
                  },
                ),
                _QrActionTile(
                  icon: Icons.group_add_rounded,
                  title: 'Add to my team',
                  subtitle: 'Select one of your teams and add this player',
                  onTap: () {
                    Navigator.pop(context);
                    _selectTeamAndAddPlayer(playerId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectTeamAndAddPlayer(String playerId) async {
    try {
      final teams = await _teamService.getMyTeams();
      if (!mounted) return;
      if (teams.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Create a team first to add this player')));
        return;
      }
      final selected = await showModalBottomSheet<app_team.Team>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            children: [
              const Text('Add to team',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _DS.textPrimary)),
              const SizedBox(height: 10),
              ...teams.map((team) => ListTile(
                    leading:
                        const Icon(Icons.groups_rounded, color: _DS.primary),
                    title: Text(team.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${team.players.length} players'),
                    onTap: () => Navigator.pop(context, team),
                  )),
            ],
          ),
        ),
      );
      if (selected == null) return;
      await _teamService.addPlayer(selected.id, playerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Player added to ${selected.name}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(
            content: Text(
              friendlyError(e, fallback: 'Could not add player.'),
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: _DS.textPrimary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.qr_code_scanner_rounded, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Scan Profile QR',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            height: 340,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _DS.surfaceBorder),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) {
                    return Container(
                      color: const Color(0xFFF7F9FC),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined,
                              size: 54, color: _DS.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'Camera unavailable: ${error.errorCode.name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: _DS.textSecondary,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _QrFramePainter()),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: _QrToolButton(
                          icon: _torchOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          label: 'Flash',
                          onTap: () async {
                            await _scannerController.toggleTorch();
                            if (!mounted) return;
                            setState(() => _torchOn = !_torchOn);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QrToolButton(
                          icon: Icons.photo_library_outlined,
                          label: 'Gallery',
                          onTap: _scanFromGallery,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isHandlingScan)
                  Container(
                    color: Colors.black.withOpacity(0.32),
                    child: const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Scan or paste QR data',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _DS.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'profile:ID, team:ID, match:ID or Scores11 URL',
              prefixIcon: const Icon(Icons.qr_code_2_rounded),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _DS.surfaceBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _DS.primary)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _handleQrValue(_controller.text),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Read QR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DS.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPayload {
  final String type;
  final String id;
  final String? playerId;
  final String? teamId;
  final String? matchId;
  final String? title;

  const _QrPayload({
    required this.type,
    required this.id,
    this.playerId,
    this.teamId,
    this.matchId,
    this.title,
  });
}

class _QrActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QrActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DS.surfaceBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _DS.primarySoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: _DS.primary),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: _DS.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: _DS.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: _DS.textMuted),
      ),
    );
  }
}

class _QrToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QrToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: _DS.primary),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: _DS.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withOpacity(0.28);
    final scanSize = size.width * 0.68;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2 - 16;
    final rect = Rect.fromLTWH(left, top, scanSize, scanSize);
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(22)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlay);

    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const corner = 34.0;
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    final points = [
      [
        Offset(r.left, r.top + corner),
        Offset(r.left, r.top),
        Offset(r.left + corner, r.top)
      ],
      [
        Offset(r.right - corner, r.top),
        Offset(r.right, r.top),
        Offset(r.right, r.top + corner)
      ],
      [
        Offset(r.right, r.bottom - corner),
        Offset(r.right, r.bottom),
        Offset(r.right - corner, r.bottom)
      ],
      [
        Offset(r.left + corner, r.bottom),
        Offset(r.left, r.bottom),
        Offset(r.left, r.bottom - corner)
      ],
    ];
    for (final group in points) {
      final path = Path()
        ..moveTo(group[0].dx, group[0].dy)
        ..lineTo(group[1].dx, group[1].dy)
        ..lineTo(group[2].dx, group[2].dy);
      canvas.drawPath(path, cornerPaint);
    }

    final linePaint = Paint()
      ..shader = const LinearGradient(colors: [_DS.accent, _DS.primary])
          .createShader(rect)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(rect.left + 22, rect.center.dy),
      Offset(rect.right - 22, rect.center.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _DS.textPrimary)),
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
            decoration:
                BoxDecoration(color: _DS.surfaceAlt, shape: BoxShape.circle),
            child:
                const Icon(Icons.inbox_rounded, size: 36, color: _DS.textMuted),
          ),
          const SizedBox(height: 14),
          Text(message,
              style: const TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
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
                const Text('LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1)),
                const Spacer(),
                Expanded(
                  child: Text(match.tournament.name,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end),
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
                          Text(match.team1.shortName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: _DS.textPrimary)),
                          if (match.scoreForTeam(1) != null)
                            Text(match.scoreForTeam(1)!,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: _DS.primary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                          color: _DS.surfaceAlt,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('VS',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _DS.primary,
                              fontSize: 14)),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(match.team2.shortName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: _DS.textPrimary)),
                          if (match.scoreForTeam(2) != null)
                            Text(match.scoreForTeam(2)!,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: _DS.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/match/${match.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DS.live,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_DS.radiusMD)),
                    ),
                    child: const Text('View Live Match',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
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
                    Text(match.team1.shortName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: _DS.textPrimary)),
                    Text(match.team1.name,
                        style: const TextStyle(
                            fontSize: 10, color: _DS.textSecondary),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                        gradient: _DS.heroGrad,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('VS',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 13)),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: _DS.primarySoft,
                        borderRadius: BorderRadius.circular(7)),
                    child: Text(match.format.toUpperCase(),
                        style: const TextStyle(
                            color: _DS.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(match.team2.shortName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: _DS.textPrimary)),
                    Text(match.team2.name,
                        style: const TextStyle(
                            fontSize: 10, color: _DS.textSecondary),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: _DS.textMuted),
              const SizedBox(width: 5),
              Text(_formatDate(match.scheduledDate),
                  style:
                      const TextStyle(color: _DS.textSecondary, fontSize: 11)),
              const SizedBox(width: 14),
              const Icon(Icons.emoji_events_outlined,
                  size: 12, color: _DS.textMuted),
              const SizedBox(width: 5),
              Expanded(
                  child: Text(match.tournament.name,
                      style: const TextStyle(
                          color: _DS.textSecondary, fontSize: 11),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/match/${match.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _DS.primary,
                side: BorderSide(color: _DS.primary.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_DS.radiusMD)),
              ),
              child: const Text('View Details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
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
                const Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(tournament.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                ),
                if (isLive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(7)),
                    child: const Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8)),
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
                    _TournamentInfoChip(
                        icon: Icons.sports_cricket,
                        label: tournament.format.toUpperCase()),
                    const SizedBox(width: 8),
                    _TournamentInfoChip(
                        icon: Icons.category_outlined, label: tournament.type),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: _DS.textMuted),
                    const SizedBox(width: 4),
                    Text(
                        '${tournament.venue ?? 'TBD'}, ${tournament.city ?? 'TBD'}',
                        style: const TextStyle(
                            fontSize: 12, color: _DS.textSecondary)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: _DS.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(tournament.startDate)} — ${_formatDate(tournament.endDate)}',
                      style: const TextStyle(
                          fontSize: 12, color: _DS.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                        context, '/tournament/${tournament.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _DS.primary,
                      side: BorderSide(color: _DS.primary.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_DS.radiusMD)),
                    ),
                    child: const Text('View Tournament',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
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
          Text(label,
              style: const TextStyle(
                  color: _DS.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
