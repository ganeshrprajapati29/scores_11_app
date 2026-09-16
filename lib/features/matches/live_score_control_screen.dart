// lib/presentation/screens/live_score_control_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/live_score_control_provider.dart';
import '../../providers/scorecard_provider.dart';
import '../../data/services/match_service.dart';
import '../../data/services/team_service.dart';
import '../../data/services/player_service.dart';
import '../../data/models/match_model.dart';
import '../../data/models/team_model.dart';
import '../../data/models/player_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../providers/auth_provider.dart';
import '../players/find_player_screen.dart';
import 'scorecard_screen.dart';

// ─────────────────────────────────────────────
//  Design Tokens — White Theme
// ─────────────────────────────────────────────
class _D {
  // Core
  static const primary = Color(0xFF1657CC);
  static const primaryDark = Color(0xFF0D2B5E);
  static const primarySoft = Color(0xFFEEF4FF);
  static const primaryMid = Color(0xFFDEEBFF);

  // Surfaces
  static const bg = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFF);
  static const border = Color(0xFFE4E7EC);

  // Status
  static const live = Color(0xFFE31E3C);
  static const liveSoft = Color(0xFFFFF1F1);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFECFDF5);
  static const gold = Color(0xFFF59E0B);
  static const goldSoft = Color(0xFFFFFBEB);
  static const purple = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFF5F3FF);
  static const teal = Color(0xFF0891B2);
  static const tealSoft = Color(0xFFECFEFF);
  static const orange = Color(0xFFF97316);
  static const orangeSoft = Color(0xFFFFF7ED);
  static const blue = Color(0xFF2563EB);
  static const blueSoft = Color(0xFFEFF6FF);

  // Text
  static const textPrimary = Color(0xFF101828);
  static const textSecondary = Color(0xFF667085);
  static const textMuted = Color(0xFF94A3B8);
  static const text = textPrimary;
  static const muted = textSecondary;

  // Gradients
  static const LinearGradient heroGrad = LinearGradient(
    colors: [Color(0xFF0D2B5E), Color(0xFF1657CC), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient liveGrad = LinearGradient(
    colors: [Color(0xFFE31E3C), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenGrad = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF0F7A36)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF101828).withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> btnShadow(Color c) => [
    BoxShadow(
      color: c.withOpacity(0.28),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Radius
  static const double rXL = 20;
  static const double rLG = 16;
  static const double rMD = 12;
  static const double rSM = 8;
  static const double rXS = 6;
}

// ─────────────────────────────────────────────
//  Main Screen
// ─────────────────────────────────────────────
class LiveScoreControlScreen extends StatefulWidget {
  final String matchId;
  final Match? match;

  const LiveScoreControlScreen({super.key, required this.matchId, this.match});

  @override
  State<LiveScoreControlScreen> createState() => _LiveScoreControlScreenState();
}

class _LiveScoreControlScreenState extends State<LiveScoreControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _scoreButtonsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _scrollToScoreButtons() {
    final context = _scoreButtonsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleInitializeMatch(LiveScoreControlProvider provider) async {
    try {
      await provider.initializeMatch();
      if (!mounted) return;
      if (provider.error == null && provider.currentStatus == 'live') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Match initialized successfully. Set striker, non-striker and bowler now.',
            ),
            backgroundColor: _D.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_D.rMD),
            ),
          ),
        );
        _tabController.animateTo(2);
      } else if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: _D.live,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_D.rMD),
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'Match initialize failed. Please try again.',
          ),
          backgroundColor: _D.live,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_D.rMD),
          ),
        ),
      );
    }
  }

  Future<void> _confirmUndoLastBall(LiveScoreControlProvider provider) async {
    if (!provider.canUndoLastBall) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Undo last ball?'),
        content: const Text(
          'Last scored delivery ko scorecard se reverse kar diya jayega.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text('Undo'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final success = await provider.undoLastBall();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Last ball undo ho gayi.'
              : (provider.error ?? 'Undo failed. Please try again.'),
        ),
        backgroundColor: success ? _D.green : _D.live,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_D.rMD),
        ),
      ),
    );
  }

  Future<void> _confirmSwapStrike(LiveScoreControlProvider provider) async {
    if (provider.currentStriker == null || provider.currentNonStriker == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Swap strike?'),
        content: Text(
          '${provider.currentNonStriker!.name} will be on strike, '
          '${provider.currentStriker!.name} at the non-striker end.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Swap'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final success = await provider.swapStrikeManual();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Strike swapped.'
              : (provider.error ?? 'Swap strike failed. Please try again.'),
        ),
        backgroundColor: success ? _D.green : _D.live,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_D.rMD),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: ChangeNotifierProvider(
        create: (_) => LiveScoreControlProvider()
          ..setUserRole(context.read<AuthProvider>().userRole)
          ..initialize(widget.matchId, widget.match),
        child: Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              // Live Score Banner
              Consumer<LiveScoreControlProvider>(
                builder: (context, provider, _) =>
                    _LiveBanner(provider: provider),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTossTab(),
                    _buildPlayingXiTab(),
                    _buildScoreEntryTab(),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Consumer<LiveScoreControlProvider>(
            builder: (context, provider, _) => _buildFAB(provider),
          ),
          bottomNavigationBar: AnimatedBuilder(
            animation: _tabController.animation ?? _tabController,
            builder: (context, _) =>
                _tabController.index == 2 ? _buildScoreTabActionBar() : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  // ── Bottom action bar (Score tab only) ─────
  Widget _buildScoreTabActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScorecardScreen(matchId: widget.matchId),
                    ),
                  ),
                  icon: const Icon(Icons.bar_chart_rounded, size: 18),
                  label: const Text('Scorecard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _D.primary,
                    side: BorderSide(color: _D.primary.withOpacity(0.35)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_D.rMD)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _scrollToScoreButtons,
                  icon: const Icon(Icons.sports_cricket_rounded, size: 18),
                  label: const Text('Add Ball'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _D.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_D.rMD)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.06),
      titleSpacing: 4,
      leading: IconButton(
        icon: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _D.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back_rounded, color: _D.text, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _D.live, width: 1.2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.sports_cricket, color: _D.primary, size: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Live Score Control',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _D.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Text(
                'Scorer Panel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _D.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            ),
          ),
        ],
      ),
      actions: [
        Consumer<LiveScoreControlProvider>(
          builder: (context, provider, _) => provider.currentStatus == 'live'
              ? Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _D.live,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
          tooltip: 'Open scorecard',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScorecardScreen(matchId: widget.matchId),
            ),
          ),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _D.primarySoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _D.primary.withOpacity(0.25)),
            ),
            child: const Icon(Icons.scoreboard_rounded, color: _D.primary, size: 18),
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _D.border)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: _D.primary,
            unselectedLabelColor: _D.muted,
            indicatorColor: _D.primary,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.edit_rounded, size: 17), text: 'Toss'),
              Tab(icon: Icon(Icons.groups_rounded, size: 17), text: 'Playing XI'),
              Tab(icon: Icon(Icons.edit_note_rounded, size: 17), text: 'Score'),
            ],
          ),
        ),
      ),
    );
  }

  // ── FAB ────────────────────────────────────
  Widget _buildFAB(LiveScoreControlProvider provider) {
    // Add Player Button
    return FloatingActionButton.extended(
      onPressed: () => _showAddPlayerOptions(context, provider),
      backgroundColor: _D.primary,
      elevation: 0,
      icon: const Icon(Icons.person_add_rounded, color: Colors.white),
      label: const Text(
        'Add Player',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ── Player Options Bottom Sheet ────────────────────────
  void _showAddPlayerOptions(
    BuildContext context,
    LiveScoreControlProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _D.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Manage Players & Teams',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.6,
                  children: [
                    if (provider.match != null) ...[
                      _buildOptionTile(
                        icon: Icons.group_add_rounded,
                        title: 'Add to ${provider.match!.team1}',
                        subtitle: 'Add player to this squad',
                        color: _D.primary,
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FindPlayerScreen(
                                teamId: provider.match!.team1Id,
                                matchId: provider.matchId,
                              ),
                            ),
                          );
                          if (mounted) provider.refreshTeamPlayers();
                        },
                      ),
                      _buildOptionTile(
                        icon: Icons.group_add_outlined,
                        title: 'Add to ${provider.match!.team2}',
                        subtitle: 'Add player to this squad',
                        color: _D.purple,
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FindPlayerScreen(
                                teamId: provider.match!.team2Id,
                                matchId: provider.matchId,
                              ),
                            ),
                          );
                          if (mounted) provider.refreshTeamPlayers();
                        },
                      ),
                    ],

                    // Create New Player (Scores11 Style)
                    _buildOptionTile(
                      icon: Icons.person_add_rounded,
                      title: 'Create New Player',
                      subtitle: 'Add a new player',
                      color: _D.green,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/create-player');
                      },
                    ),

                    // Create Team (NEW - Scores11 Style)
                    _buildOptionTile(
                      icon: Icons.groups_rounded,
                      title: 'Create Team',
                      subtitle: 'New team with players',
                      color: _D.primary,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/create-team');
                      },
                    ),

                    // Open Player List
                    _buildOptionTile(
                      icon: Icons.people_rounded,
                      title: 'Player List',
                      subtitle: 'Manage existing players',
                      color: _D.purple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/players');
                      },
                    ),

                    // Team List (NEW)
                    _buildOptionTile(
                      icon: Icons.groups_outlined,
                      title: 'Team List',
                      subtitle: 'Manage teams',
                      color: _D.orange,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/teams');
                      },
                    ),

                    // Player Search
                    _buildOptionTile(
                      icon: Icons.search_rounded,
                      title: 'Search Player',
                      subtitle: 'Find a specific player',
                      color: _D.teal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/player-search');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _D.textSecondary,
                  side: const BorderSide(color: _D.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_D.rMD),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _D.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: _D.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  TAB 1 — Toss
  // ─────────────────────────────────────────
  Widget _buildTossTab() {
    return Consumer<LiveScoreControlProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Toss card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: _D.heroGrad,
                  image: const DecorationImage(
                    image: AssetImage('score 11/Live Control 1080 x 520.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    opacity: 0.20,
                  ),
                  borderRadius: BorderRadius.circular(_D.rXL),
                  boxShadow: [
                    BoxShadow(
                      color: _D.primary.withOpacity(0.28),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Toss Decision',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _TossTeamCard(name: provider.match?.team1 ?? 'Team 1'),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flip,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        _TossTeamCard(
                          name: provider.match?.team2 ?? 'Team 2',
                          isRight: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              if (!provider.tossDone) ...[
                // Select winner
                _SectionHeader(
                  title: 'Who Won the Toss?',
                  icon: Icons.emoji_events_rounded,
                  color: _D.gold,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _TossOptionButton(
                        label: provider.match?.team1 ?? 'Team 1',
                        isSelected: provider.tossWinnerKey == 'team1',
                        onTap: () => provider.setTossWinner('team1'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TossOptionButton(
                        label: provider.match?.team2 ?? 'Team 2',
                        isSelected: provider.tossWinnerKey == 'team2',
                        onTap: () => provider.setTossWinner('team2'),
                      ),
                    ),
                  ],
                ),

                if (provider.tossWinnerKey != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _D.goldSoft,
                      borderRadius: BorderRadius.circular(_D.rMD),
                      border: Border.all(color: _D.gold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: _D.gold,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${provider.tossWinnerName} won the toss',
                          style: const TextStyle(
                            color: _D.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Elected to...',
                    icon: Icons.sports_cricket,
                    color: _D.primary,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _DecisionButton(
                          label: 'Bat First',
                          icon: Icons.sports_cricket,
                          isSelected: provider.tossDecision == 'bat',
                          color: _D.green,
                          onTap: () => provider.setTossDecision('bat'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DecisionButton(
                          label: 'Bowl First',
                          icon: Icons.sports_baseball,
                          isSelected: provider.tossDecision == 'bowl',
                          color: _D.primary,
                          onTap: () => provider.setTossDecision('bowl'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.canSubmitToss
                          ? provider.submitToss
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _D.green,
                        disabledBackgroundColor: _D.border,
                        disabledForegroundColor: _D.textMuted,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_D.rMD),
                        ),
                      ),
                      icon: provider.isTossSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        provider.isTossSaving
                            ? 'Saving Toss...'
                            : 'Save Toss Result',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // Toss done state
                Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _D.surface,
                        borderRadius: BorderRadius.circular(_D.rXL),
                        border: Border.all(color: _D.green.withOpacity(0.25)),
                        boxShadow: _D.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _D.greenSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: _D.green,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Toss Completed!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _D.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _D.greenSoft,
                              borderRadius: BorderRadius.circular(_D.rMD),
                            ),
                            child: Text(
                              '${provider.tossWinnerName} elected to ${provider.tossDecision == 'bat' ? 'Bat First' : 'Bowl First'}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _D.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed:
                      provider.currentScore.runs == 0 &&
                          provider.currentScore.wickets == 0
                      ? () async {
                          final success = await provider.undoToss();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Toss undone. Select the winner again.'
                                    : (provider.error ?? 'Toss undo failed.'),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Undo Toss'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  //  TAB 2 — Playing XI
  // ─────────────────────────────────────────
  Widget _buildPlayingXiTab() {
    return Consumer<LiveScoreControlProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          color: _D.primary,
          onRefresh: () => provider.refreshMatchData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Playing Squad',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _D.textPrimary,
                            ),
                          ),
                          Text(
                            'Select 2-25 players per team, then set captain and vice-captain before going live.',
                            style: TextStyle(
                              color: _D.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SquadCounter(
                      team1Count: provider.selectedTeam1Players.length,
                      team2Count: provider.selectedTeam2Players.length,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Team 1
                _buildTeamPlayersGrid(
                  provider.match?.team1 ?? 'Team 1',
                  provider.team1Players,
                  provider.selectedTeam1Players,
                  (player) => provider.toggleTeam1Player(player),
                  provider: provider,
                  teamNumber: 1,
                  color: _D.primary,
                ),
                const SizedBox(height: 28),

                // Team 2
                _buildTeamPlayersGrid(
                  provider.match?.team2 ?? 'Team 2',
                  provider.team2Players,
                  provider.selectedTeam2Players,
                  (player) => provider.toggleTeam2Player(player),
                  provider: provider,
                  teamNumber: 2,
                  color: _D.purple,
                ),

                const SizedBox(height: 28),

                // Initialize button
                if (provider.canInitialize)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          provider.canInitialize && !provider.isInitializing
                          ? () => _handleInitializeMatch(provider)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _D.purple,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_D.rMD),
                        ),
                        shadowColor: Colors.transparent,
                      ),
                      icon: provider.isInitializing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.sports_cricket,
                              color: Colors.white,
                            ),
                      label: Text(
                        provider.isInitializing
                            ? 'Initializing...'
                            : 'Initialize Live Scoring',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamPlayersGrid(
    String teamName,
    List<Player> availablePlayers,
    List<Player> selectedPlayers,
    Function(Player) onToggle, {
    required LiveScoreControlProvider provider,
    required int teamNumber,
    Color color = _D.primary,
  }) {
    final selectedCount = selectedPlayers.length;
    final captainId = teamNumber == 1
        ? provider.team1CaptainId
        : provider.team2CaptainId;
    final viceCaptainId = teamNumber == 1
        ? provider.team1ViceCaptainId
        : provider.team2ViceCaptainId;
    final teamId = teamNumber == 1
        ? provider.match?.team1Id
        : provider.match?.team2Id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(_D.rMD),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(_D.rSM),
                ),
                child: Icon(Icons.group_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      '$selectedCount selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _D.greenSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 13, color: _D.green),
                      SizedBox(width: 4),
                      Text(
                        'Ready',
                        style: TextStyle(
                          color: _D.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Add player',
                onPressed: teamId == null || teamId.isEmpty
                    ? null
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FindPlayerScreen(
                              teamId: teamId,
                              matchId: provider.matchId,
                            ),
                          ),
                        );
                        if (context.mounted) {
                          await provider.refreshTeamPlayers();
                        }
                      },
                icon: Icon(Icons.person_add_alt_1_rounded, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (selectedPlayers.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Leadership',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: color.withOpacity(0.18))),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedPlayers.map((player) {
              return _CaptainChoiceChip(
                player: player,
                isCaptain: captainId == player.id,
                isViceCaptain: viceCaptainId == player.id,
                color: color,
                onCaptain: () => provider.setTeamCaptain(teamNumber, player),
                onViceCaptain: () =>
                    provider.setTeamViceCaptain(teamNumber, player),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],

        if (availablePlayers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _D.surface,
              borderRadius: BorderRadius.circular(_D.rMD),
              border: Border.all(color: _D.border),
            ),
            child: Column(
              children: [
                Icon(Icons.groups_outlined, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  'No players added yet',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Use add player to build this team list.',
                  style: TextStyle(color: _D.textSecondary, fontSize: 12),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: availablePlayers.length,
            itemBuilder: (context, index) {
              final player = availablePlayers[index];
              final isSelected = selectedPlayers.any((p) => p.id == player.id);
              return GestureDetector(
                onTap: () => onToggle(player),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.07) : _D.surface,
                    borderRadius: BorderRadius.circular(_D.rMD),
                    border: Border.all(
                      color: isSelected ? color.withOpacity(0.4) : _D.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : _D.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.12)
                              : _D.surfaceAlt,
                          borderRadius: BorderRadius.circular(_D.rSM),
                        ),
                        child: Icon(
                          _getRoleIcon(player.role ?? ''),
                          color: isSelected ? color : _D.textMuted,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              player.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isSelected ? color : _D.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Text(
                                  '#${player.jerseyNumber ?? '—'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? color.withOpacity(0.7)
                                        : _D.textMuted,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.check_circle,
                                    size: 11,
                                    color: color,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ─────────────────────────────────────────
  //  TAB 3 — Score Entry
  // ─────────────────────────────────────────
  Widget _buildScoreEntryTab() {
    return Consumer<LiveScoreControlProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            children: [
              _MatchControlSummary(provider: provider),
              const SizedBox(height: 20),

              // Current Players Card
              _CurrentPlayersCard(
                provider: provider,
                onStrikerTap: () => _showPlayerSelector(provider, 'striker'),
                onNonStrikerTap: () =>
                    _showPlayerSelector(provider, 'nonStriker'),
                onBowlerTap: () => _showPlayerSelector(provider, 'bowler'),
                onSwapStrike: () => _confirmSwapStrike(provider),
              ),
              _RequiredActionBanner(provider: provider),
              const SizedBox(height: 20),

              // Score Buttons
              KeyedSubtree(
                key: _scoreButtonsKey,
                child: _ScoreButtonsGrid(provider: provider),
              ),
              const SizedBox(height: 12),
              _UndoLastBallButton(
                provider: provider,
                onPressed: () => _confirmUndoLastBall(provider),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          provider.currentStriker == null &&
                              provider.currentNonStriker == null
                          ? null
                          : () => _ScoreButtonsGrid(
                              provider: provider,
                            )._showRetirementDialog(context, provider),
                      icon: const Icon(Icons.personal_injury_outlined),
                      label: const Text('Retire Batter'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      // Also enabled once the match has just completed, so a
                      // chase that finishes on the winning run still leaves a
                      // window to extend/continue instead of being locked out.
                      onPressed: (provider.currentStatus == 'live' ||
                              provider.currentStatus == 'completed')
                          ? () => _ScoreButtonsGrid(
                              provider: provider,
                            )._showContinuationDialog(context, provider)
                          : null,
                      icon: Icon(
                        provider.practiceContinuationEnabled
                            ? Icons.all_inclusive_rounded
                            : Icons.tune_rounded,
                      ),
                      label: Text(
                        provider.practiceContinuationEnabled
                            ? 'Extension On'
                            : (provider.currentStatus == 'completed'
                                ? 'Reopen & Extend'
                                : 'Extend Innings'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _CurrentOverCard(provider: provider),
              const SizedBox(height: 20),

              _OverSummaryCard(matchId: widget.matchId, provider: provider),
              const SizedBox(height: 20),

              _InlineWagonWheelCard(provider: provider),
              const SizedBox(height: 20),

              _MatchActionBar(provider: provider),
              const SizedBox(height: 20),

              // Extras row
              _ExtrasCard(provider: provider),
              const SizedBox(height: 20),

              _LiveBallScorecardPreview(provider: provider),
            ],
          ),
        );
      },
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'batsman':
        return Icons.sports_cricket;
      case 'bowler':
        return Icons.sports_baseball;
      case 'allrounder':
        return Icons.all_inclusive;
      case 'wicketkeeper':
        return Icons.security;
      default:
        return Icons.person_rounded;
    }
  }

  // ── Player Selector BottomSheet ────────────
  Future<void> _showPlayerSelector(
    LiveScoreControlProvider provider,
    String type,
  ) async {
    final title = type == 'striker'
        ? 'Select Striker'
        : type == 'nonStriker'
        ? 'Select Non-Striker'
        : 'Select Bowler';

    if ((type == 'bowler' && provider.availableBowlers.isEmpty) ||
        (type == 'striker' && provider.availableStrikers.isEmpty) ||
        (type == 'nonStriker' && provider.availableNonStrikers.isEmpty)) {
      await provider.refreshTeamPlayers();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider<LiveScoreControlProvider>.value(
        value: provider,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: _D.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _D.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _D.primarySoft,
                        borderRadius: BorderRadius.circular(_D.rSM),
                      ),
                      child: const Icon(
                        Icons.person_search_rounded,
                        color: _D.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _D.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: _D.border, height: 1),
              Expanded(
                child: Consumer<LiveScoreControlProvider>(
                  builder: (context, prov, _) {
                    final players = type == 'bowler'
                        ? prov.availableBowlers
                        : type == 'striker'
                        ? prov.availableStrikers
                        : prov.availableNonStrikers;

                    if (players.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 44,
                                color: _D.textMuted,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                type == 'bowler'
                                    ? 'No bowlers available'
                                    : 'No batsmen available',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _D.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Add a player to the team or refresh the lineup.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _D.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextButton.icon(
                                onPressed: () => prov.refreshTeamPlayers(),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: const Text('Refresh players'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final isSelected =
                            (type == 'striker' &&
                                prov.currentStriker?.id == player.id) ||
                            (type == 'nonStriker' &&
                                prov.currentNonStriker?.id == player.id) ||
                            (type == 'bowler' &&
                                prov.currentBowler?.id == player.id);

                        return GestureDetector(
                          onTap: () async {
                            if (type == 'striker') {
                              await prov.setStriker(player);
                            } else if (type == 'nonStriker') {
                              await prov.setNonStriker(player);
                            } else if (type == 'bowler') {
                              await prov.setBowler(player);
                            }
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? _D.primarySoft : _D.surface,
                              borderRadius: BorderRadius.circular(_D.rMD),
                              border: Border.all(
                                color: isSelected
                                    ? _D.primary.withOpacity(0.3)
                                    : _D.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _D.primaryMid
                                        : _D.surfaceAlt,
                                    borderRadius: BorderRadius.circular(_D.rSM),
                                  ),
                                  child: Center(
                                    child: Text(
                                      player.jerseyNumber?.toString() ??
                                          (player.name.isNotEmpty
                                              ? player.name[0].toUpperCase()
                                              : '?'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: isSelected
                                            ? _D.primary
                                            : _D.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: _D.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        player.role ?? '',
                                        style: const TextStyle(
                                          color: _D.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: _D.primaryMid,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: _D.primary,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Live Banner Widget
// ─────────────────────────────────────────────
class _CaptainChoiceChip extends StatelessWidget {
  final Player player;
  final bool isCaptain;
  final bool isViceCaptain;
  final Color color;
  final VoidCallback onCaptain;
  final VoidCallback onViceCaptain;

  const _CaptainChoiceChip({
    required this.player,
    required this.isCaptain,
    required this.isViceCaptain,
    required this.color,
    required this.onCaptain,
    required this.onViceCaptain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(_D.rMD),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _D.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _RoleButton(
            label: 'C',
            selected: isCaptain,
            color: _D.gold,
            onTap: onCaptain,
          ),
          const SizedBox(width: 5),
          _RoleButton(
            label: 'VC',
            selected: isViceCaptain,
            color: _D.teal,
            onTap: onViceCaptain,
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: label == 'VC' ? 34 : 28,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : _D.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? color : _D.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _D.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LiveBanner extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _LiveBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: _D.goldSoft,
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: _D.gold,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Initializing live control...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _D.gold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final match = provider.match;
    final team1Name = match?.team1 ?? 'Team 1';
    final team2Name = match?.team2 ?? 'Team 2';
    final team1Batting = provider.isTeam1Batting;

    final liveRuns = provider.currentScore.runs;
    final liveWkts = provider.currentScore.wickets;
    final liveOvers = provider.currentScore.overs;
    final otherScore = team1Batting ? match?.score.team2 : match?.score.team1;
    final otherRuns = otherScore?.runs ?? 0;
    final otherWkts = otherScore?.wickets ?? 0;
    final otherOvers = (otherScore?.overs.isNotEmpty ?? false) ? otherScore!.overs : '0.0';

    final team1Runs = team1Batting ? liveRuns : otherRuns;
    final team1Wkts = team1Batting ? liveWkts : otherWkts;
    final team1Overs = team1Batting ? liveOvers : otherOvers;
    final team2Runs = team1Batting ? otherRuns : liveRuns;
    final team2Wkts = team1Batting ? otherWkts : liveWkts;
    final team2Overs = team1Batting ? otherOvers : liveOvers;

    final tossText = provider.tossDone
        ? '${provider.tossWinnerName ?? ''} chose to ${provider.tossDecision == 'bat' ? 'bat' : 'bowl'}'
        : 'Toss pending';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        gradient: _D.heroGrad,
        image: const DecorationImage(
          image: AssetImage('score 11/Live Control 1080 x 520.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          opacity: 0.24,
        ),
        borderRadius: BorderRadius.circular(_D.rXL),
        boxShadow: _D.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _HeroTeamScore(
                    name: team1Name,
                    logoAsset: 'assets/images/teams/team1_logo.png',
                    runs: team1Runs,
                    wickets: team1Wkts,
                    overs: team1Overs,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: _HeroTeamScore(
                    name: team2Name,
                    logoAsset: 'assets/images/teams/team2_logo.png',
                    runs: team2Runs,
                    wickets: team2Wkts,
                    overs: team2Overs,
                    alignRight: true,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tossText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (provider.canRefresh) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => provider.refreshLiveData(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.refresh_rounded,
                          color: Colors.white70, size: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _HeroStatCol(
                    label: 'Target',
                    value: provider.target?.toString() ?? '-',
                    valueColor: _D.textPrimary,
                  ),
                ),
                Container(width: 1, height: 32, color: _D.border),
                Expanded(
                  child: _HeroStatCol(
                    label: 'Required',
                    value: provider.isSecondInnings
                        ? (provider.requiredRuns?.toString() ?? '-')
                        : '-',
                    valueColor: _D.live,
                    caption: provider.isSecondInnings &&
                            provider.requiredBalls != null
                        ? 'runs in ${provider.requiredBalls} balls'
                        : null,
                  ),
                ),
                Container(width: 1, height: 32, color: _D.border),
                Expanded(
                  child: _HeroStatCol(
                    label: 'CRR',
                    value: provider.currentScore.runRate.toStringAsFixed(2),
                    valueColor: _D.green,
                  ),
                ),
              ],
            ),
          ),
          if (provider.resultMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Text(
                provider.resultMessage!,
                style: const TextStyle(
                  color: _D.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else if (provider.appreciations.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Text(
                provider.appreciations.first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _D.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroTeamScore extends StatelessWidget {
  final String name;
  final String logoAsset;
  final int runs;
  final int wickets;
  final String overs;
  final bool alignRight;
  const _HeroTeamScore({
    required this.name,
    required this.logoAsset,
    required this.runs,
    required this.wickets,
    required this.overs,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: 40,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Image.asset(
        logoAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.shield_rounded, color: _D.primary),
      ),
    );
    final texts = Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          '$runs/$wickets',
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        Text(
          '$overs overs',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10.5),
        ),
      ],
    );
    return Row(
      mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignRight
          ? [Flexible(child: texts), const SizedBox(width: 8), logo]
          : [logo, const SizedBox(width: 8), Flexible(child: texts)],
    );
  }
}

class _HeroStatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String? caption;
  const _HeroStatCol({
    required this.label,
    required this.value,
    required this.valueColor,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 11, color: _D.textMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: valueColor),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, color: _D.textMuted),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Toss Team Card
// ─────────────────────────────────────────────
class _TossTeamCard extends StatelessWidget {
  final String name;
  final bool isRight;
  const _TossTeamCard({required this.name, this.isRight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_D.rLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _D.surfaceAlt,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _D.border),
            ),
            child: const Icon(
              Icons.sports_cricket,
              size: 26,
              color: _D.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: _D.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            isRight ? 'Team 2' : 'Team 1',
            style: const TextStyle(color: _D.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Toss Option Button
// ─────────────────────────────────────────────
class _TossOptionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TossOptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? _D.primary : _D.surface,
          borderRadius: BorderRadius.circular(_D.rMD),
          border: Border.all(
            color: isSelected ? _D.primary : _D.border,
            width: 1.5,
          ),
          boxShadow: isSelected ? _D.btnShadow(_D.primary) : _D.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 18,
              color: isSelected ? Colors.white : _D.textMuted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isSelected ? Colors.white : _D.textPrimary,
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
//  Decision Button (Bat / Bowl)
// ─────────────────────────────────────────────
class _DecisionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _DecisionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : _D.surface,
          borderRadius: BorderRadius.circular(_D.rMD),
          border: Border.all(color: isSelected ? color : _D.border, width: 1.5),
          boxShadow: isSelected ? _D.btnShadow(color) : _D.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: isSelected ? Colors.white : color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? Colors.white : _D.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Squad Counter
// ─────────────────────────────────────────────
class _SquadCounter extends StatelessWidget {
  final int team1Count;
  final int team2Count;
  const _SquadCounter({required this.team1Count, required this.team2Count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.rMD),
        border: Border.all(color: _D.border),
        boxShadow: _D.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CountDot(count: team1Count, color: _D.primary),
          const SizedBox(width: 8),
          const Text('vs', style: TextStyle(color: _D.textMuted, fontSize: 11)),
          const SizedBox(width: 8),
          _CountDot(count: team2Count, color: _D.purple),
        ],
      ),
    );
  }
}

class _CountDot extends StatelessWidget {
  final int count;
  final Color color;
  const _CountDot({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final done = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: done ? _D.greenSoft : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(_D.rXS),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: done ? _D.green : color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Current Players Card
// ─────────────────────────────────────────────
class _CurrentPlayersCard extends StatelessWidget {
  final LiveScoreControlProvider provider;
  final VoidCallback onStrikerTap;
  final VoidCallback onNonStrikerTap;
  final VoidCallback onBowlerTap;
  final VoidCallback onSwapStrike;
  const _CurrentPlayersCard({
    required this.provider,
    required this.onStrikerTap,
    required this.onNonStrikerTap,
    required this.onBowlerTap,
    required this.onSwapStrike,
  });

  @override
  Widget build(BuildContext context) {
    final canSwap =
        provider.currentStriker != null && provider.currentNonStriker != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.rXL),
        border: Border.all(color: _D.border),
        boxShadow: _D.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeader(
                  title: 'Current Players',
                  icon: Icons.people_rounded,
                  color: _D.primary,
                ),
              ),
              IconButton(
                onPressed: canSwap ? onSwapStrike : null,
                icon: const Icon(Icons.swap_horiz_rounded),
                tooltip: 'Swap strike',
                color: _D.primary,
                style: IconButton.styleFrom(
                  backgroundColor: canSwap
                      ? _D.primary.withOpacity(0.08)
                      : _D.surfaceAlt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PlayerChip(
            player: provider.currentStriker,
            name: provider.currentStriker?.name ?? 'Set Striker',
            jersey: provider.currentStriker?.jerseyNumber,
            isSet: provider.currentStriker != null,
            label: 'Striker',
            onStrikeBadge: provider.currentStriker != null,
            icon: Icons.person_rounded,
            color: _D.green,
            onTap: onStrikerTap,
            isFullWidth: true,
            battingStat: provider.currentStriker != null
                ? provider.battingStatFor(provider.currentStriker)
                : null,
          ),
          const SizedBox(height: 10),
          _PlayerChip(
            player: provider.currentNonStriker,
            name: provider.currentNonStriker?.name ?? 'Non-Striker',
            jersey: provider.currentNonStriker?.jerseyNumber,
            isSet: provider.currentNonStriker != null,
            label: 'Non-Striker',
            icon: Icons.person_outline_rounded,
            color: _D.orange,
            onTap: onNonStrikerTap,
            isFullWidth: true,
            battingStat: provider.currentNonStriker != null
                ? provider.battingStatFor(provider.currentNonStriker)
                : null,
          ),
          const SizedBox(height: 10),
          _PlayerChip(
            player: provider.currentBowler,
            name: provider.currentBowler?.name ?? 'Set Bowler',
            jersey: provider.currentBowler?.jerseyNumber,
            isSet: provider.currentBowler != null,
            label: 'Bowler',
            icon: Icons.sports_baseball,
            color: _D.live,
            onTap: onBowlerTap,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final Player? player;
  final String name;
  final int? jersey;
  final bool isSet;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isFullWidth;
  final bool onStrikeBadge;
  final PlayerBattingStat? battingStat;
  const _PlayerChip({
    this.player,
    required this.name,
    required this.jersey,
    required this.isSet,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isFullWidth = false,
    this.onStrikeBadge = false,
    this.battingStat,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSet ? color.withOpacity(0.06) : _D.surfaceAlt,
          borderRadius: BorderRadius.circular(_D.rMD),
          border: Border.all(
            color: isSet ? color.withOpacity(0.25) : _D.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                isSet
                    ? _PlayerAvatar(player: player, color: color, size: 36)
                    : Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _D.border,
                          borderRadius: BorderRadius.circular(_D.rSM),
                        ),
                        child: Icon(icon, color: _D.textMuted, size: 18),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isSet ? _D.textPrimary : _D.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onStrikeBadge) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _D.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'On Strike',
                                style: TextStyle(
                                  color: _D.primary,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: _D.textMuted,
                            ),
                          ),
                          if (jersey != null) ...[
                            const Text(
                              ' · ',
                              style:
                                  TextStyle(fontSize: 10, color: _D.textMuted),
                            ),
                            Text(
                              '#$jersey',
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: _D.textMuted),
              ],
            ),
            if (battingStat != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_D.rSM),
                ),
                child: Row(
                  children: [
                    _TinyStatCol(label: 'Runs', value: '${battingStat!.runs}'),
                    _TinyStatCol(label: 'Balls', value: '${battingStat!.balls}'),
                    _TinyStatCol(label: '4s', value: '${battingStat!.fours}'),
                    _TinyStatCol(label: '6s', value: '${battingStat!.sixes}'),
                    _TinyStatCol(
                        label: 'SR',
                        value: battingStat!.strikeRate.toStringAsFixed(1)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Score Buttons Grid
// ─────────────────────────────────────────────
class _RequiredActionBanner extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _RequiredActionBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    String? message;
    if (provider.error != null && provider.error!.isNotEmpty) {
      message = provider.error;
    } else if (provider.currentStatus == 'live') {
      final missing = <String>[
        if (provider.currentStriker == null) 'striker',
        if (provider.currentNonStriker == null) 'non-striker',
        if (provider.currentBowler == null) 'bowler',
      ];
      if (missing.isNotEmpty)
        message =
            'Required action: select ${missing.join(', ')} to continue scoring.';
    }
    if (message == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _D.goldSoft,
        borderRadius: BorderRadius.circular(_D.rMD),
        border: Border.all(color: _D.gold.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: _D.gold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _D.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UndoLastBallButton extends StatelessWidget {
  final LiveScoreControlProvider provider;
  final VoidCallback onPressed;
  const _UndoLastBallButton({required this.provider, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = provider.canUndoLastBall;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: provider.isUndoing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.undo_rounded),
        label: Text(provider.isUndoing ? 'Undoing...' : 'Undo Last Ball'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _D.live,
          disabledForegroundColor: _D.textMuted,
          side: BorderSide(
            color: enabled ? _D.live.withOpacity(0.45) : _D.border,
          ),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_D.rMD),
          ),
        ),
      ),
    );
  }
}

class _ScoreButtonsGrid extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _ScoreButtonsGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _BtnData('0', _D.textMuted, () => provider.addRuns(0), isRun: true),
      _BtnData(
        '1',
        const Color(0xFF3B82F6),
        () => provider.addRuns(1),
        isRun: true,
      ),
      _BtnData(
        '2',
        const Color(0xFF1D4ED8),
        () => provider.addRuns(2),
        isRun: true,
      ),
      _BtnData(
        '3',
        const Color(0xFF1E40AF),
        () => provider.addRuns(3),
        isRun: true,
      ),
      _BtnData(
        '4',
        _D.orange,
        () => provider.addRuns(4),
        isRun: true,
        isFour: true,
      ),
      _BtnData('5', _D.green, () => provider.addRuns(5), isRun: true),
      _BtnData(
        '6',
        _D.live,
        () => provider.addRuns(6),
        isRun: true,
        isSix: true,
      ),
      _BtnData(
        'Wd',
        _D.purple,
        () => _showExtraRunsDialog(context, 'wide', 'Wide + byes'),
      ),
      _BtnData(
        'Nb',
        _D.teal,
        () => _showExtraRunsDialog(context, 'noBall', 'No ball + bat runs'),
      ),
      _BtnData('B', _D.gold, () => _showExtraRunsDialog(context, 'bye', 'Bye')),
      _BtnData(
        'LB',
        _D.orange,
        () => _showExtraRunsDialog(context, 'legBye', 'Leg Bye'),
      ),
      _BtnData('Custom', _D.green, () => _showCustomRunsDialog(context)),
      _BtnData('DLS', _D.primary, () => _showRainDlsDialog(context)),
      _BtnData('W', _D.live, () => _showWicketDialog(context), isWicket: true),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.rXL),
        border: Border.all(color: _D.border),
        boxShadow: _D.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Score Entry',
            icon: Icons.sports_cricket,
            color: _D.primary,
          ),
          if (provider.isFreeHit) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _D.tealSoft,
                borderRadius: BorderRadius.circular(_D.rSM),
                border: Border.all(color: _D.teal.withOpacity(0.25)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flash_on_rounded, size: 14, color: _D.teal),
                  SizedBox(width: 6),
                  Text(
                    'Free Hit',
                    style: TextStyle(
                      color: _D.teal,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: buttons.map((btn) => _ScoreBtn(data: btn)).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showExtraRunsDialog(
    BuildContext context,
    String type,
    String title,
  ) async {
    final runsController = TextEditingController(text: '0');
    final runs = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_D.rXL)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: title,
                icon: Icons.run_circle_rounded,
                color: _D.gold,
              ),
              const SizedBox(height: 14),
              Text(
                type == 'noBall'
                    ? 'Runs bat se aaye hon to yahan add karein. No ball ka 1 run automatic add hoga.'
                    : type == 'wide'
                    ? 'Wide ka 1 run automatic add hoga. Bhaag kar aaye bye runs yahan add karein.'
                    : 'Extra runs select karein.',
                style: const TextStyle(
                  color: _D.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [0, 1, 2, 3, 4, 5, 6, 7].map((run) {
                  return OutlinedButton(
                    onPressed: () => Navigator.pop(context, run),
                    child: Text(run == 0 ? 'Dot' : '$run'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: runsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: type == 'noBall'
                      ? 'Bat runs on no ball'
                      : 'Custom extra runs',
                  helperText: type == 'noBall'
                      ? 'No ball ka 1 run automatic add hoga'
                      : type == 'wide'
                      ? 'Wide ka 1 run automatic add hoga'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final customRuns = int.tryParse(runsController.text.trim());
                    if (customRuns == null) return;
                    Navigator.pop(context, customRuns);
                  },
                  child: const Text('Add Runs'),
                ),
              ),
            ],
          ),
        );
      },
    );
    runsController.dispose();
    if (runs != null) {
      await provider.addExtra(type, runs: runs);
    }
  }

  Future<void> _showCustomRunsDialog(BuildContext context) async {
    final runsController = TextEditingController(text: '7');
    var isPenalty = false;
    bool? strikeOverride;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_D.rXL)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    title: 'Custom Runs',
                    icon: Icons.edit_rounded,
                    color: _D.green,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: runsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Runs',
                      helperText:
                          'Penalty ON karne par runs team extras me jayenge',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isPenalty,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Penalty runs'),
                    onChanged: (value) =>
                        setSheetState(() => isPenalty = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<bool?>(
                    value: strikeOverride,
                    decoration: const InputDecoration(
                      labelText: 'Strike change',
                    ),
                    items: const [
                      DropdownMenuItem<bool?>(
                        value: null,
                        child: Text('Automatic'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: true,
                        child: Text('Force change'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: false,
                        child: Text('Force same'),
                      ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => strikeOverride = value),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _D.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final runs = int.tryParse(runsController.text.trim());
                        if (runs == null || runs < 0) return;
                        Navigator.pop(context, {
                          'runs': runs,
                          'isPenalty': isPenalty,
                          'strikeOverride': strikeOverride,
                        });
                      },
                      child: const Text('Add Custom Runs'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    runsController.dispose();
    if (result != null) {
      await provider.addCustomRuns(
        runs: result['runs'] as int,
        isPenalty: result['isPenalty'] == true,
        forceStrikeChange: result['strikeOverride'] as bool?,
      );
    }
  }

  Future<void> _showRainDlsDialog(BuildContext context) async {
    final revisedOversController = TextEditingController(
      text: provider.match?.overs.toString() ?? '20',
    );
    var method = 'dls';
    var completeMatch = false;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_D.rXL)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    title: 'Rain / DLS',
                    icon: Icons.water_drop_rounded,
                    color: _D.primary,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Rain ke baad revised overs set karein. Backend revised target, par score, required runs aur result method save karega.',
                    style: TextStyle(
                      color: _D.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(
                      labelText: 'Rain decision',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'dls',
                        child: Text('DLS revised target'),
                      ),
                      DropdownMenuItem(
                        value: 'washout',
                        child: Text('Washed out'),
                      ),
                      DropdownMenuItem(
                        value: 'abandoned',
                        child: Text('Abandoned'),
                      ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => method = value ?? 'dls'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: revisedOversController,
                    enabled: method == 'dls',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Revised overs',
                      helperText:
                          'Example: 20 over match rain ke baad 12 overs',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: completeMatch,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Complete match with this decision'),
                    subtitle: const Text(
                      'Second innings par DLS winner/tie publish karega',
                    ),
                    onChanged: (value) =>
                        setSheetState(() => completeMatch = value),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _D.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final revisedOvers =
                            int.tryParse(revisedOversController.text.trim()) ??
                            provider.match?.overs ??
                            20;
                        Navigator.pop(context, {
                          'method': method,
                          'revisedOvers': revisedOvers,
                          'completeMatch': completeMatch,
                        });
                      },
                      child: const Text('Apply Rain Rule'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    revisedOversController.dispose();
    if (result != null) {
      await provider.applyRainDls(
        method: result['method'] as String,
        revisedOvers: result['revisedOvers'] as int,
        completeMatch: result['completeMatch'] == true,
      );
    }
  }

  Future<void> _showWicketDialog(BuildContext context) async {
    const wicketTypes = [
      ('bowled', 'Bowled'),
      ('caught', 'Caught'),
      ('caught_behind', 'Caught behind'),
      ('caught_and_bowled', 'Caught & bowled'),
      ('lbw', 'LBW'),
      ('stumped', 'Stumped'),
      ('run_out', 'Run out'),
      ('run_out_non_striker', 'Run out non-striker'),
      ('hit_wicket', 'Hit wicket'),
      ('handled_ball', 'Handled ball'),
      ('timed_out', 'Timed out'),
      ('obstructing_field', 'Obstructing field'),
      ('hit_ball_twice', 'Hit ball twice'),
      ('retired_hurt', 'Retire hurt'),
      ('retired_out', 'Retire out'),
      ('retired_not_out', 'Retire not out'),
      ('absent_hurt', 'Absent hurt'),
    ];
    final List<Player> dismissible = [
      if (provider.currentStriker != null) provider.currentStriker!,
      if (provider.currentNonStriker != null) provider.currentNonStriker!,
    ];
    var wicketType = provider.isFreeHit ? 'run_out' : 'bowled';
    var completedRuns = 0;
    final completedRunsController = TextEditingController(text: '0');
    Player? dismissed = provider.currentStriker;
    Player? fielder;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_D.rXL)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final typeOptions = provider.isFreeHit
                ? wicketTypes
                      .where(
                        (type) => const {
                          'run_out',
                          'run_out_non_striker',
                          'handled_ball',
                          'obstructing_field',
                          'hit_ball_twice',
                          'retired_hurt',
                          'retired_not_out',
                        }.contains(type.$1),
                      )
                      .toList()
                : wicketTypes;
            final needsFielder = const {
              'caught',
              'caught_behind',
              'stumped',
              'run_out',
              'run_out_non_striker',
            }.contains(wicketType);
            final fielders = provider.bowlingTeamPlayers;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    title: 'Wicket',
                    icon: Icons.close_rounded,
                    color: _D.live,
                  ),
                  if (provider.isFreeHit) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Free hit active: only run out/fielding dismissals allowed.',
                      style: TextStyle(
                        color: _D.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: wicketType,
                    decoration: const InputDecoration(
                      labelText: 'Wicket method',
                    ),
                    items: typeOptions
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type.$1,
                            child: Text(type.$2),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() {
                          wicketType = value;
                          final newNeedsFielder = const {
                            'caught',
                            'caught_behind',
                            'stumped',
                            'run_out',
                            'run_out_non_striker',
                          }.contains(value);
                          if (!newNeedsFielder) fielder = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Player>(
                    value: dismissed,
                    decoration: const InputDecoration(labelText: 'Who is out?'),
                    items: dismissible
                        .map(
                          (player) => DropdownMenuItem<Player>(
                            value: player,
                            child: Text(player.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setSheetState(() => dismissed = value),
                  ),
                      if (wicketType == 'retired_hurt' ||
                      wicketType == 'retired_out' ||
                      wicketType == 'retired_not_out' ||
                      wicketType == 'absent_hurt') ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: wicketType == 'retired_hurt' || wicketType == 'retired_not_out' || wicketType == 'absent_hurt'
                            ? _D.greenSoft
                            : _D.liveSoft,
                        borderRadius: BorderRadius.circular(_D.rMD),
                        border: Border.all(
                          color:
                              (wicketType == 'retired_hurt' || wicketType == 'retired_not_out' || wicketType == 'absent_hurt'
                                      ? _D.green
                                      : _D.live)
                                  .withOpacity(0.18),
                        ),
                      ),
                      child: Text(
                        wicketType == 'retired_out'
                            ? 'Retire out: full wicket count hoga. Batter dobara batting nahi kar sakta.'
                            : 'Retire/absent not out: wicket count nahi badhega.',
                        style: TextStyle(
                          color: wicketType == 'retired_hurt' || wicketType == 'retired_not_out' || wicketType == 'absent_hurt'
                              ? _D.green
                              : _D.live,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                  if (needsFielder) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Player>(
                      value: fielder,
                      decoration: InputDecoration(
                        labelText: wicketType == 'stumped'
                            ? 'Keeper / fielder'
                            : (wicketType == 'caught' ||
                                  wicketType == 'caught_behind')
                            ? 'Caught by'
                            : 'Run out / assisted by',
                        helperText:
                            'Scorecard me proper dismissal text ke liye select karein',
                      ),
                      items: fielders
                          .map(
                            (player) => DropdownMenuItem<Player>(
                              value: player,
                              child: Text(player.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => fielder = value),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Completed runs before wicket',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _D.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [0, 1, 2, 3, 4, 5, 6, 7].map((run) {
                      final selected = completedRuns == run;
                      return SizedBox(
                        width: 54,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selected
                                ? _D.liveSoft
                                : Colors.white,
                            foregroundColor: selected
                                ? _D.live
                                : _D.textSecondary,
                          ),
                          onPressed: () => setSheetState(() {
                            completedRuns = run;
                            completedRunsController.text = run.toString();
                          }),
                          child: Text('$run'),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: completedRunsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Custom completed runs',
                      helperText:
                          '3 se jyada runs ke liye yahan number daalein',
                    ),
                    onChanged: (value) {
                      final runs = int.tryParse(value);
                      if (runs != null) {
                        setSheetState(() => completedRuns = runs);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: dismissed == null || (needsFielder && fielder == null)
                          ? null
                          : () async {
                              final customRuns = int.tryParse(
                                completedRunsController.text.trim(),
                              );
                              if (customRuns == null) return;
                              Navigator.pop(context);
                              await provider.addWicketDetailed(
                                wicketType: wicketType,
                                dismissedPlayer: dismissed,
                                fielder: fielder,
                                completedRuns: customRuns,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _D.live,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add Wicket'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    completedRunsController.dispose();
  }

  Future<void> _showRetirementDialog(
    BuildContext context,
    LiveScoreControlProvider provider,
  ) async {
    final activeBatters = <Player>[
      if (provider.currentStriker != null) provider.currentStriker!,
      if (provider.currentNonStriker != null) provider.currentNonStriker!,
    ];
    if (activeBatters.isEmpty) return;
    Player batter = activeBatters.first;
    String type = 'retired_hurt';
    final reasonController = TextEditingController(
      text: 'Injury / unable to continue',
    );
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Retire Batter (No Ball)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Player>(
                value: batter,
                decoration: const InputDecoration(
                  labelText: 'Batter leaving field',
                ),
                items: activeBatters
                    .map(
                      (player) => DropdownMenuItem(
                        value: player,
                        child: Text(player.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => batter = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Retirement type'),
                items: const [
                  DropdownMenuItem(
                    value: 'retired_hurt',
                    child: Text('Retired hurt (not out)'),
                  ),
                  DropdownMenuItem(
                    value: 'retired_out',
                    child: Text('Retired out (wicket)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => type = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason shown on scorecard',
                  hintText: 'Injury, tactical retirement, retired out...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'batter': batter,
                'type': type,
                'reason': reasonController.text.trim(),
              }),
              child: const Text('Confirm Retirement'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
    if (result == null || !context.mounted) return;
    final success = await provider.retireBatter(
      batter: result['batter'] as Player,
      type: result['type'] as String,
      reason: (result['reason'] as String).isEmpty
          ? 'Reason not specified'
          : result['reason'] as String,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Retirement saved without recording a ball. Select the replacement batter.'
              : (provider.error ?? 'Retirement failed.'),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? _D.green : _D.live,
      ),
    );
  }

  Future<void> _showContinuationDialog(
    BuildContext context,
    LiveScoreControlProvider provider,
  ) async {
    var afterOvers = provider.continueAfterOvers;
    var afterAllOut = provider.continueAfterAllOut;
    var afterTarget = provider.continueAfterTarget;
    final settings = await showDialog<Map<String, bool>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Practice Match Extension'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: afterOvers,
                onChanged: (value) => setDialogState(() => afterOvers = value),
                title: const Text('Continue after overs'),
                subtitle: const Text(
                  'Keep scoring beyond configured match overs.',
                ),
              ),
              SwitchListTile(
                value: afterAllOut,
                onChanged: (value) => setDialogState(() => afterAllOut = value),
                title: const Text('Continue after 10 wickets'),
                subtitle: const Text('Allow replacement batters for practice.'),
              ),
              SwitchListTile(
                value: afterTarget,
                onChanged: (value) => setDialogState(() => afterTarget = value),
                title: const Text('Continue after target'),
                subtitle: const Text(
                  'Do not auto-finish the second innings after the chase.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'afterOvers': afterOvers,
                'afterAllOut': afterAllOut,
                'afterTarget': afterTarget,
              }),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (settings == null || !context.mounted) return;
    final success = await provider.updatePracticeContinuation(
      afterOvers: settings['afterOvers']!,
      afterAllOut: settings['afterAllOut']!,
      afterTarget: settings['afterTarget']!,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Innings extension settings updated.'
              : (provider.error ?? 'Could not update extension settings.'),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? _D.green : _D.live,
      ),
    );
  }
}

class _BtnData {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isRun;
  final bool isWicket;
  final bool isFour;
  final bool isSix;
  const _BtnData(
    this.label,
    this.color,
    this.onTap, {
    this.isRun = false,
    this.isWicket = false,
    this.isFour = false,
    this.isSix = false,
  });
}

class _ScoreBtn extends StatelessWidget {
  final _BtnData data;
  const _ScoreBtn({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: data.isWicket ? _D.liveSoft : data.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(_D.rMD),
          border: Border.all(
            color: data.isWicket
                ? data.color.withOpacity(0.3)
                : data.color.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data.label,
              style: TextStyle(
                color: data.color,
                fontSize: data.isRun && (data.isFour || data.isSix) ? 22 : 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (data.isFour)
              Text(
                'FOUR',
                style: TextStyle(
                  color: data.color.withOpacity(0.7),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            if (data.isSix)
              Text(
                'SIX',
                style: TextStyle(
                  color: data.color.withOpacity(0.7),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            if (data.isWicket)
              Icon(
                Icons.close_rounded,
                size: 11,
                color: data.color.withOpacity(0.7),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Extras Card
// ─────────────────────────────────────────────
class _InlineWagonWheelCard extends StatefulWidget {
  final LiveScoreControlProvider provider;
  const _InlineWagonWheelCard({required this.provider});

  @override
  State<_InlineWagonWheelCard> createState() => _InlineWagonWheelCardState();
}

class _InlineWagonWheelCardState extends State<_InlineWagonWheelCard> {
  int _zone = 0;
  int _runs = 1;

  static const _zones = [
    'Point',
    'Cover',
    'Mid Off',
    'Mid On',
    'Square Leg',
    'Fine Leg',
    'Third Man',
    'Gully',
  ];
  static const _runsOptions = [0, 1, 2, 3, 4, 6];

  @override
  Widget build(BuildContext context) {
    final canScore =
        widget.provider.currentStriker != null &&
        widget.provider.currentBowler != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.rXL),
        border: Border.all(color: _D.border),
        boxShadow: _D.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeader(
                  title: 'Wagon Wheel Scoring',
                  icon: Icons.radar_rounded,
                  color: _D.green,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _D.greenSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _D.green.withOpacity(0.18)),
                ),
                child: const Text(
                  'Same screen',
                  style: TextStyle(
                    color: _D.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _zones.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.9,
            ),
            itemBuilder: (context, index) {
              final selected = _zone == index;
              return InkWell(
                onTap: () => setState(() => _zone = index),
                borderRadius: BorderRadius.circular(_D.rSM),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _D.greenSoft : _D.surfaceAlt,
                    borderRadius: BorderRadius.circular(_D.rSM),
                    border: Border.all(
                      color: selected ? _D.green.withOpacity(0.5) : _D.border,
                    ),
                  ),
                  child: Text(
                    _zones[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: selected ? _D.green : _D.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: _runsOptions.map((run) {
              final selected = _runs == run;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _runs = run),
                    borderRadius: BorderRadius.circular(_D.rSM),
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? _D.primarySoft : _D.surfaceAlt,
                        borderRadius: BorderRadius.circular(_D.rSM),
                        border: Border.all(
                          color: selected
                              ? _D.primary.withOpacity(0.4)
                              : _D.border,
                        ),
                      ),
                      child: Text(
                        run == 0 ? 'Dot' : '$run',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: selected ? _D.primary : _D.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canScore
                  ? () => widget.provider.addWagonShot(
                      runs: _runs,
                      zone: _zone,
                      label: _zones[_zone],
                    )
                  : null,
              icon: const Icon(Icons.sports_cricket_rounded, size: 18),
              label: Text(
                canScore
                    ? 'Add $_runs to ${_zones[_zone]}'
                    : 'Set striker and bowler first',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _D.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _D.border,
                disabledForegroundColor: _D.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_D.rMD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtrasCard extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _ExtrasCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final wides = (provider.extras['wides'] ?? 0) as int;
    final noBalls = (provider.extras['noBalls'] ?? 0) as int;
    final byes = (provider.extras['byes'] ?? 0) as int;
    final legByes = (provider.extras['legByes'] ?? 0) as int;
    final penalty = (provider.extras['penalty'] ?? 0) as int;
    final total = wides + noBalls + byes + legByes + penalty;

    final extras = [
      {
        'label': 'Total',
        'val': total,
        'icon': Icons.functions_rounded,
        'color': _D.primary,
      },
      {
        'label': 'Wides',
        'val': wides,
        'icon': Icons.width_full,
        'color': _D.purple,
      },
      {
        'label': 'No Balls',
        'val': noBalls,
        'icon': Icons.error_outline,
        'color': _D.teal,
      },
      {
        'label': 'Byes',
        'val': byes,
        'icon': Icons.run_circle,
        'color': _D.gold,
      },
      {
        'label': 'Leg Byes',
        'val': legByes,
        'icon': Icons.sports_soccer,
        'color': _D.orange,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.rXL),
        border: Border.all(color: _D.border),
        boxShadow: _D.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Extras',
            icon: Icons.add_circle_outline,
            color: _D.textSecondary,
          ),
          const SizedBox(height: 14),
          Row(
            children: extras
                .map(
                  (e) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: extras.indexOf(e) == 0 ? 0 : 8,
                      ),
                      child: _ExtraStatBox(
                        label: e['label'] as String,
                        value: (e['val'] as int).toString(),
                        icon: e['icon'] as IconData,
                        color: e['color'] as Color,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ExtraStatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _ExtraStatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            color: _D.textMuted,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: _D.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Current Over Card
// ─────────────────────────────────────────────
class _OverSummaryCard extends StatefulWidget {
  final String matchId;
  final LiveScoreControlProvider provider;
  const _OverSummaryCard({required this.matchId, required this.provider});

  @override
  State<_OverSummaryCard> createState() => _OverSummaryCardState();
}

class _OverSummaryCardState extends State<_OverSummaryCard> {
  final MatchService _matchService = MatchService();
  bool _expanded = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _overs = const [];
  int? _loadedForBallCount;

  Future<void> _toggle() async {
    setState(() => _expanded = !_expanded);
    if (!_expanded) return;
    // Refetch if new balls have been scored since the last load.
    final ballCount = widget.provider.currentOverBalls.length +
        (widget.provider.currentStatus == 'live' ? 1 : 0);
    if (_overs.isNotEmpty && _loadedForBallCount == ballCount) return;
    setState(() => _isLoading = true);
    final overs = await _matchService.getOverSummaryData(widget.matchId);
    if (!mounted) return;
    setState(() {
      _overs = overs;
      _loadedForBallCount = ballCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.rXL),
        border: Border.all(color: _D.border),
        boxShadow: _D.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(_D.rMD),
            child: Row(
              children: [
                const Expanded(
                  child: _SectionHeader(
                    title: 'Over Summary',
                    icon: Icons.summarize_rounded,
                    color: _D.primary,
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _D.textMuted,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 14),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              )
            else if (_overs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: _D.surfaceAlt,
                  borderRadius: BorderRadius.circular(_D.rMD),
                ),
                child: const Center(
                  child: Text(
                    'No overs bowled yet',
                    style: TextStyle(
                      color: _D.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _overs.map((over) {
                  final overNumber = over['overNumber'] ?? 0;
                  final innings = over['innings'] ?? 1;
                  final runs = over['runs'] ?? 0;
                  final wickets = over['wickets'] ?? 0;
                  final balls = (over['balls'] is List)
                      ? List<Map>.from(over['balls'])
                      : const <Map>[];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _D.surfaceAlt,
                      borderRadius: BorderRadius.circular(_D.rMD),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: Text(
                            'Inn $innings · Ov ${overNumber + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _D.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: balls.map((b) {
                              final isWicket = b['isWicket'] == true;
                              final isExtra =
                                  b['isWide'] == true || b['isNoBall'] == true;
                              return Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isWicket
                                      ? _D.live.withOpacity(0.15)
                                      : isExtra
                                          ? _D.orange.withOpacity(0.15)
                                          : _D.border,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  isWicket ? 'W' : '${b['runs'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isWicket
                                        ? _D.live
                                        : _D.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Text(
                          '$runs${wickets > 0 ? '/$wickets' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _D.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}

class _CurrentOverCard extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _CurrentOverCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.rXL),
        border: Border.all(color: _D.border),
        boxShadow: _D.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(
                title: 'Current Over',
                icon: Icons.format_list_numbered_rounded,
                color: _D.primary,
              ),
              Text(
                '${provider.currentScore.overs} overs',
                style: const TextStyle(
                  fontSize: 12,
                  color: _D.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (provider.currentOverBalls.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _D.surfaceAlt,
                borderRadius: BorderRadius.circular(_D.rMD),
              ),
              child: const Column(
                children: [
                  Icon(Icons.sports_cricket, size: 28, color: _D.textMuted),
                  SizedBox(height: 6),
                  Text(
                    'No balls yet',
                    style: TextStyle(
                      color: _D.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.currentOverBalls.length +
                    (provider.currentOverBalls.length < 6 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= provider.currentOverBalls.length) {
                    // Placeholder for the upcoming ball in this over.
                    return Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_D.rMD),
                        border: Border.all(
                          color: _D.border,
                          width: 1.4,
                          style: BorderStyle.solid,
                        ),
                      ),
                    );
                  }

                  final ball = provider.currentOverBalls[index];
                  final isWicket = ball['wicket'] ?? false;
                  final runs = ball['runs'] ?? 0;
                  final isExtra = ball['extra'] != null;
                  final wagonLabel = ball['wagonLabel']?.toString();
                  final hasWagon = wagonLabel != null && wagonLabel.isNotEmpty;

                  // Spec palette: wicket = red, six = green, four = blue,
                  // dot ball = grey, extras = purple, other runs = primary.
                  Color ballColor = isWicket
                      ? _D.live
                      : runs == 6
                      ? _D.green
                      : runs == 4
                      ? _D.blue
                      : isExtra
                      ? _D.purple
                      : runs == 0
                      ? _D.textMuted
                      : _D.primary;

                  // Wickets and boundaries are solid-filled to stand out;
                  // every other delivery keeps the soft tinted look.
                  final isHighlighted = isWicket || runs == 4 || runs == 6;

                  return Container(
                    width: hasWagon ? 70 : 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isHighlighted ? ballColor : ballColor.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(_D.rMD),
                      border: Border.all(
                        color: isHighlighted ? ballColor : ballColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isWicket ? 'W' : runs.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isHighlighted ? Colors.white : ballColor,
                          ),
                        ),
                        if (isExtra)
                          Text(
                            ball['extra'],
                            style: TextStyle(
                              fontSize: 8,
                              color: isHighlighted
                                  ? Colors.white.withOpacity(0.85)
                                  : ballColor.withOpacity(0.8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (hasWagon)
                          Text(
                            wagonLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8,
                              color: isHighlighted
                                  ? Colors.white.withOpacity(0.85)
                                  : ballColor.withOpacity(0.8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (provider.currentBowler != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: _D.border),
            const SizedBox(height: 14),
            _BowlerMiniRow(provider: provider),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Bowler mini stat row (shown under current over)
// ─────────────────────────────────────────────
class _BowlerMiniRow extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _BowlerMiniRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final bowler = provider.currentBowler;
    if (bowler == null) return const SizedBox.shrink();
    final stat = provider.bowlingStatFor(bowler);
    return Row(
      children: [
        _PlayerAvatar(player: bowler, color: _D.purple, size: 40),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bowler.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _D.textPrimary,
                ),
              ),
              Text(
                bowler.bowlingStyle?.trim().isNotEmpty == true
                    ? bowler.bowlingStyle!
                    : 'Bowler',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: _D.textMuted),
              ),
            ],
          ),
        ),
        _TinyStatCol(label: 'Overs', value: stat.overs),
        _TinyStatCol(label: 'Runs', value: '${stat.runs}'),
        _TinyStatCol(label: 'Wickets', value: '${stat.wickets}'),
        _TinyStatCol(label: 'Economy', value: stat.economy.toStringAsFixed(2)),
      ],
    );
  }
}

/// Circular player avatar — shows the player's real photo when available
/// (Player.profileImage / Player.photo), otherwise a colored icon fallback.
class _PlayerAvatar extends StatelessWidget {
  final Player? player;
  final Color color;
  final double size;
  const _PlayerAvatar({required this.player, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final url = player?.profileImage?.trim().isNotEmpty == true
        ? player!.profileImage
        : (player?.photo?.trim().isNotEmpty == true ? player!.photo : null);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(_D.rSM),
      ),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Icon(Icons.person_rounded, color: color, size: size * 0.5),
            )
          : Icon(Icons.person_rounded, color: color, size: size * 0.5),
    );
  }
}

class _TinyStatCol extends StatelessWidget {
  final String label;
  final String value;
  const _TinyStatCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _D.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: _D.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Section Header (reusable)
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_D.rSM),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _D.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MatchControlSummary extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _MatchControlSummary({required this.provider});

  @override
  Widget build(BuildContext context) {
    final tossText = provider.tossDone
        ? '${provider.tossWinnerName} chose ${provider.tossDecision == 'bat' ? 'bat' : 'bowl'}'
        : 'Toss pending';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.rXL),
        border: Border.all(color: _D.border),
        boxShadow: _D.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Match Control',
            icon: Icons.sync_alt_rounded,
            color: _D.primary,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  label: 'Innings',
                  value: '${provider.inningsNumber}',
                  color: _D.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                  label: 'Batting',
                  value: provider.battingTeamName,
                  color: _D.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                  label: 'Bowling',
                  value: provider.bowlingTeamName,
                  color: _D.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoPill(
            label: 'Toss',
            value: tossText,
            color: _D.gold,
            fullWidth: true,
          ),
          if (provider.isSecondInnings && provider.target != null) ...[
            const SizedBox(height: 10),
            _InfoPill(
              label: 'Chase',
              value:
                  '${provider.target} target - ${provider.requiredRuns ?? 0} needed from ${provider.requiredBalls ?? 0} balls',
              color: _D.live,
              fullWidth: true,
            ),
          ],
          if (provider.resultMessage != null) ...[
            const SizedBox(height: 10),
            _InfoPill(
              label: 'Result',
              value: provider.resultMessage!,
              color: _D.green,
              fullWidth: true,
            ),
          ],
          if (provider.playerOfMatchName != null) ...[
            const SizedBox(height: 10),
            _InfoPill(
              label: 'Player of the Match',
              value: provider.playerOfMatchName!,
              color: _D.gold,
              fullWidth: true,
            ),
          ],
          if (provider.appreciations.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...provider.appreciations
                .take(3)
                .map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _InfoPill(
                      label: 'Appreciation',
                      value: text,
                      color: _D.purple,
                      fullWidth: true,
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;
  const _InfoPill({
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(_D.rMD),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: _D.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchActionBar extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _MatchActionBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final canEnd = provider.currentStatus == 'live';
    final isFinalInnings = provider.inningsNumber >= 2;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canEnd
            ? () => _confirmEnd(context, isFinalInnings)
            : provider.startMatch,
        icon: Icon(
          canEnd
              ? (isFinalInnings
                    ? Icons.emoji_events_rounded
                    : Icons.flag_circle_rounded)
              : Icons.play_arrow_rounded,
        ),
        label: Text(
          canEnd
              ? (isFinalInnings ? 'Finish Match' : 'End 1st Innings')
              : 'Go Live',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canEnd ? _D.live : _D.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_D.rMD),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmEnd(BuildContext context, bool isFinalInnings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFinalInnings ? 'Finish Match?' : 'End 1st Innings?'),
        content: Text(
          isFinalInnings
              ? 'Second innings complete karke result public scorecard par publish karna hai?'
              : 'First innings complete karke second innings start karna hai?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isFinalInnings ? 'Finish' : 'End Innings'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.endInnings();
    }
  }
}

class _MiniScorecardPreview extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _MiniScorecardPreview({required this.provider});

  @override
  Widget build(BuildContext context) {
    final strikerStat = provider.currentStriker == null
        ? null
        : provider.battingStatFor(provider.currentStriker);
    final nonStrikerStat = provider.currentNonStriker == null
        ? null
        : provider.battingStatFor(provider.currentNonStriker);
    final bowlerStat = provider.currentBowler == null
        ? null
        : provider.bowlingStatFor(provider.currentBowler);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.rXL),
        border: Border.all(color: _D.border),
        boxShadow: _D.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Scorecard Preview',
            icon: Icons.scoreboard_rounded,
            color: _D.teal,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ScorePreviewTile(
                  team: provider.battingTeamName,
                  value:
                      '${provider.currentScore.runs}/${provider.currentScore.wickets}',
                  sub:
                      '${provider.currentScore.overs} ov - RR ${provider.currentScore.runRate.toStringAsFixed(2)}',
                  color: _D.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScorePreviewTile(
                  team: provider.bowlingTeamName,
                  value: provider.currentBowler?.name ?? 'Bowling',
                  sub: provider.currentBowler == null
                      ? 'Set bowler'
                      : '${bowlerStat!.overs} ov - ${bowlerStat.runs}/${bowlerStat.wickets} - Eco ${bowlerStat.economy.toStringAsFixed(1)}',
                  color: _D.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TinyPlayerStat(
                  label: 'Striker',
                  value: provider.currentStriker == null
                      ? 'Not set'
                      : '${provider.currentStriker!.name} ${strikerStat!.runs}(${strikerStat.balls})',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TinyPlayerStat(
                  label: 'Non-striker',
                  value: provider.currentNonStriker == null
                      ? 'Not set'
                      : '${provider.currentNonStriker!.name} ${nonStrikerStat!.runs}(${nonStrikerStat.balls})',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveBallScorecardPreview extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _LiveBallScorecardPreview({required this.provider});

  @override
  Widget build(BuildContext context) {
    final strikerStat = provider.currentStriker == null
        ? null
        : provider.battingStatFor(provider.currentStriker);
    final nonStrikerStat = provider.currentNonStriker == null
        ? null
        : provider.battingStatFor(provider.currentNonStriker);
    final bowlerStat = provider.currentBowler == null
        ? null
        : provider.bowlingStatFor(provider.currentBowler);
    final balls = provider.currentOverBalls;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.rXL),
        border: Border.all(color: _D.border),
        boxShadow: _D.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Live Ball & Scorecard',
            icon: Icons.scoreboard_rounded,
            color: _D.teal,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ScorePreviewTile(
                  team: provider.battingTeamName,
                  value:
                      '${provider.currentScore.runs}/${provider.currentScore.wickets}',
                  sub:
                      '${provider.currentScore.overs} ov - RR ${provider.currentScore.runRate.toStringAsFixed(2)}',
                  color: _D.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScorePreviewTile(
                  team: provider.bowlingTeamName,
                  value: provider.currentBowler?.name ?? 'Set Bowler',
                  sub: provider.currentBowler == null
                      ? 'Bowler pending'
                      : '${bowlerStat!.overs} ov - ${bowlerStat.runs}/${bowlerStat.wickets} - Eco ${bowlerStat.economy.toStringAsFixed(1)}',
                  color: _D.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TinyPlayerStat(
                  label: 'Striker',
                  value: provider.currentStriker == null
                      ? 'Not set'
                      : '${provider.currentStriker!.name} ${strikerStat!.runs}(${strikerStat.balls})',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TinyPlayerStat(
                  label: 'Non-striker',
                  value: provider.currentNonStriker == null
                      ? 'Not set'
                      : '${provider.currentNonStriker!.name} ${nonStrikerStat!.runs}(${nonStrikerStat.balls})',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'This Over',
                  style: TextStyle(
                    color: _D.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                provider.currentScore.overs,
                style: const TextStyle(
                  color: _D.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (balls.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _D.surfaceAlt,
                borderRadius: BorderRadius.circular(_D.rMD),
              ),
              child: const Column(
                children: [
                  Icon(Icons.sports_cricket, size: 26, color: _D.textMuted),
                  SizedBox(height: 6),
                  Text(
                    'No balls yet',
                    style: TextStyle(
                      color: _D.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 66,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: balls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) =>
                    _OverBallPill(ball: balls[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverBallPill extends StatelessWidget {
  final Map<String, dynamic> ball;
  const _OverBallPill({required this.ball});

  @override
  Widget build(BuildContext context) {
    final runs = (ball['runs'] as num?)?.toInt() ?? 0;
    final isWicket = ball['wicket'] == true;
    final extra = ball['extra']?.toString();
    final wagonLabel = ball['wagonLabel']?.toString();
    final hasWagon = wagonLabel != null && wagonLabel.isNotEmpty;
    final color = isWicket
        ? _D.live
        : runs == 6
        ? _D.live
        : runs == 4
        ? _D.orange
        : hasWagon
        ? _D.green
        : extra != null
        ? _D.purple
        : _D.primary;

    return Container(
      width: hasWagon ? 74 : 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(_D.rMD),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isWicket ? 'W' : runs.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          if (extra != null)
            Text(
              extra,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w800,
              ),
            ),
          if (hasWagon)
            Text(
              wagonLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _ScorePreviewTile extends StatelessWidget {
  final String team;
  final String value;
  final String sub;
  final Color color;
  const _ScorePreviewTile({
    required this.team,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(_D.rMD),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            team,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: _D.textSecondary),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _D.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TinyPlayerStat extends StatelessWidget {
  final String label;
  final String value;
  const _TinyPlayerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _D.surfaceAlt,
        borderRadius: BorderRadius.circular(_D.rSM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _D.textMuted),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: _D.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
