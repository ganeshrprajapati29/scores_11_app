// lib/presentation/screens/live_score_control_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

// ─────────────────────────────────────────────
//  Design Tokens — White Theme
// ─────────────────────────────────────────────
class _D {
  // Core
  static const primary      = Color(0xFF1A56DB);
  static const primaryDark  = Color(0xFF0D2147);
  static const primarySoft  = Color(0xFFEEF4FF);
  static const primaryMid   = Color(0xFFDEEBFF);

  // Surfaces
  static const bg           = Color(0xFFF5F7FF);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceAlt   = Color(0xFFF8FAFF);
  static const border       = Color(0xFFE8EEFF);

  // Status
  static const live         = Color(0xFFEF4444);
  static const liveSoft     = Color(0xFFFFF1F1);
  static const green        = Color(0xFF10B981);
  static const greenSoft    = Color(0xFFECFDF5);
  static const gold         = Color(0xFFF59E0B);
  static const goldSoft     = Color(0xFFFFFBEB);
  static const purple       = Color(0xFF7C3AED);
  static const purpleSoft   = Color(0xFFF5F3FF);
  static const teal         = Color(0xFF0891B2);
  static const tealSoft     = Color(0xFFECFEFF);
  static const orange       = Color(0xFFF97316);
  static const orangeSoft   = Color(0xFFFFF7ED);

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
  static const LinearGradient liveGrad = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
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
    BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> btnShadow(Color c) => [
    BoxShadow(color: c.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  // Radius
  static const double rXL  = 22;
  static const double rLG  = 16;
  static const double rMD  = 12;
  static const double rSM  = 8;
  static const double rXS  = 6;
}

// ─────────────────────────────────────────────
//  Main Screen
// ─────────────────────────────────────────────
class LiveScoreControlScreen extends StatefulWidget {
  final String matchId;
  final Match? match;

  const LiveScoreControlScreen({
    super.key,
    required this.matchId,
    this.match,
  });

  @override
  State<LiveScoreControlScreen> createState() => _LiveScoreControlScreenState();
}

class _LiveScoreControlScreenState extends State<LiveScoreControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveScoreControlProvider>()
        .initialize(widget.matchId, widget.match);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
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
                builder: (context, provider, _) => _LiveBanner(provider: provider),
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
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: _D.heroGrad),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Live Score Control',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
          ),
          Text(
            'Scorer Panel',
            style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(_D.rMD),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.55),
            indicator: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(_D.rSM),
            ),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(icon: Icon(Icons.flip, size: 18), text: 'Toss'),
              Tab(icon: Icon(Icons.groups, size: 18), text: 'Playing XI'),
              Tab(icon: Icon(Icons.sports_cricket, size: 18), text: 'Score'),
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
      onPressed: () => _showAddPlayerOptions(context),
      backgroundColor: _D.primary,
      elevation: 0,
      icon: const Icon(Icons.person_add_rounded, color: Colors.white),
      label: const Text('Add Player', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

// ── Player Options Bottom Sheet ────────────────────────
  void _showAddPlayerOptions(BuildContext context) {
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
              width: 40, height: 4,
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
            const SizedBox(height: 24),
            
            // Create New Player (Scores11 Style)
            _buildOptionTile(
              icon: Icons.person_add_rounded,
              title: 'Create New Player',
              subtitle: 'Add a new player to the system',
              color: _D.green,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/create-player');
              },
            ),
            const SizedBox(height: 12),
            
            // Create Team (NEW - Scores11 Style)
            _buildOptionTile(
              icon: Icons.groups_rounded,
              title: 'Create Team',
              subtitle: 'Create a new team with players',
              color: _D.primary,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/create-team');
              },
            ),
            const SizedBox(height: 12),
            
            // Open Player List
            _buildOptionTile(
              icon: Icons.people_rounded,
              title: 'Player List',
              subtitle: 'View and manage existing players',
              color: _D.purple,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/players');
              },
            ),
            const SizedBox(height: 12),
            
            // Team List (NEW)
            _buildOptionTile(
              icon: Icons.groups_outlined,
              title: 'Team List',
              subtitle: 'View and manage teams',
              color: _D.orange,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/teams');
              },
            ),
            const SizedBox(height: 12),
            
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
            const SizedBox(height: 24),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _D.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
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
                  borderRadius: BorderRadius.circular(_D.rXL),
                  boxShadow: [
                    BoxShadow(color: _D.primary.withOpacity(0.28), blurRadius: 28, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Toss Decision',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _TossTeamCard(name: provider.match?.team1 ?? 'Team 1'),
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flip, color: Colors.white, size: 24),
                        ),
                        _TossTeamCard(name: provider.match?.team2 ?? 'Team 2', isRight: true),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              if (!provider.tossDone) ...[
                // Select winner
                _SectionHeader(title: 'Who Won the Toss?', icon: Icons.emoji_events_rounded, color: _D.gold),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _D.goldSoft,
                      borderRadius: BorderRadius.circular(_D.rMD),
                      border: Border.all(color: _D.gold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: _D.gold, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${provider.tossWinnerName} won the toss',
                          style: const TextStyle(color: _D.gold, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(title: 'Elected to...', icon: Icons.sports_cricket, color: _D.primary),
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
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: _D.greenSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle_rounded, color: _D.green, size: 32),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Toss Completed!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _D.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _D.greenSoft,
                          borderRadius: BorderRadius.circular(_D.rMD),
                        ),
                        child: Text(
                          '${provider.tossWinnerName} elected to ${provider.tossDecision == 'bat' ? 'Bat First' : 'Bowl First'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _D.green, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
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
          onRefresh: () => provider.refreshLiveData(),
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
                          Text('Playing XI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _D.textPrimary)),
                          Text('Select 11 players per team', style: TextStyle(color: _D.textSecondary, fontSize: 13)),
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
                  color: _D.primary,
                ),
                const SizedBox(height: 28),

                // Team 2
                _buildTeamPlayersGrid(
                  provider.match?.team2 ?? 'Team 2',
                  provider.team2Players,
                  provider.selectedTeam2Players,
                  (player) => provider.toggleTeam2Player(player),
                  color: _D.purple,
                ),

                const SizedBox(height: 28),

                // Initialize button
                if (provider.selectedTeam1Players.length == 11 &&
                    provider.selectedTeam2Players.length == 11)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.canInitialize ? provider.initializeMatch : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _D.purple,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_D.rMD)),
                        shadowColor: Colors.transparent,
                      ),
                      icon: const Icon(Icons.sports_cricket, color: Colors.white),
                      label: const Text(
                        'Initialize Match',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
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
    Color color = _D.primary,
  }) {
    final selectedCount = selectedPlayers.length;
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
                width: 36, height: 36,
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
                    Text(teamName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                    Text('$selectedCount / 11 selected', style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
                  ],
                ),
              ),
              if (selectedCount == 11)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _D.greenSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 13, color: _D.green),
                      SizedBox(width: 4),
                      Text('Done', style: TextStyle(color: _D.green, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.07) : _D.surface,
                  borderRadius: BorderRadius.circular(_D.rMD),
                  border: Border.all(
                    color: isSelected ? color.withOpacity(0.4) : _D.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]
                      : _D.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.12) : _D.surfaceAlt,
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
                                style: TextStyle(fontSize: 11, color: isSelected ? color.withOpacity(0.7) : _D.textMuted),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle, size: 11, color: color),
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
              // Current Players Card
              _CurrentPlayersCard(
                provider: provider,
                onStrikerTap: () => _showPlayerSelector(provider, 'striker'),
                onNonStrikerTap: () => _showPlayerSelector(provider, 'nonStriker'),
                onBowlerTap: () => _showPlayerSelector(provider, 'bowler'),
              ),
              const SizedBox(height: 20),

              // Score Buttons
              _ScoreButtonsGrid(provider: provider),
              const SizedBox(height: 20),

              // Extras row
              _ExtrasCard(provider: provider),
              const SizedBox(height: 20),

              // Current over
              _CurrentOverCard(provider: provider),
            ],
          ),
        );
      },
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'batsman':    return Icons.sports_cricket;
      case 'bowler':     return Icons.sports_baseball;
      case 'allrounder': return Icons.all_inclusive;
      case 'wicketkeeper': return Icons.security;
      default:           return Icons.person_rounded;
    }
  }

  // ── Player Selector BottomSheet ────────────
  void _showPlayerSelector(LiveScoreControlProvider provider, String type) {
    final title = type == 'striker' ? 'Select Striker'
        : type == 'nonStriker' ? 'Select Non-Striker'
        : 'Select Bowler';
    
    // Get the correct players list based on selection type
    final players = type == 'bowler'
        ? provider.selectedTeam2Players // For bowling team (fielding team)
        : provider.selectedTeam1Players; // For batting team

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              width: 40, height: 4,
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
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: _D.primarySoft, borderRadius: BorderRadius.circular(_D.rSM)),
                    child: const Icon(Icons.person_search_rounded, color: _D.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _D.textPrimary)),
                ],
              ),
            ),
            Divider(color: _D.border, height: 1),
            Expanded(
              child: Consumer<LiveScoreControlProvider>(
                builder: (context, prov, _) => ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final isSelected = (type == 'striker' && prov.currentStriker?.id == player.id)
                        || (type == 'nonStriker' && prov.currentNonStriker?.id == player.id)
                        || (type == 'bowler' && prov.currentBowler?.id == player.id);

                    return GestureDetector(
                      onTap: () {
                        if (type == 'striker') prov.setStriker(player);
                        else if (type == 'nonStriker') prov.setNonStriker(player);
                        else if (type == 'bowler') prov.setBowler(player);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? _D.primarySoft : _D.surface,
                          borderRadius: BorderRadius.circular(_D.rMD),
                          border: Border.all(
                            color: isSelected ? _D.primary.withOpacity(0.3) : _D.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: isSelected ? _D.primaryMid : _D.surfaceAlt,
                                borderRadius: BorderRadius.circular(_D.rSM),
                              ),
                              child: Center(
                                child: Text(
                                  '${player.jerseyNumber ?? '?'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isSelected ? _D.primary : _D.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(player.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _D.textPrimary)),
                                  Text(player.role ?? '', style: const TextStyle(color: _D.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: _D.primaryMid, borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.check, color: _D.primary, size: 16),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Live Banner Widget
// ─────────────────────────────────────────────
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
              width: 20, height: 20,
              child: const CircularProgressIndicator(strokeWidth: 2, color: _D.gold),
            ),
            const SizedBox(width: 12),
            const Text('Initializing live control...', style: TextStyle(fontWeight: FontWeight.w600, color: _D.gold, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      decoration: const BoxDecoration(
        gradient: _D.heroGrad,
      ),
      child: Row(
        children: [
          // Live dot
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: _D.live, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${provider.currentScore.runs}/${provider.currentScore.wickets}',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              Text(
                '${provider.currentOver}.${provider.currentBall} overs',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
              ),
            ],
          ),

          const Spacer(),

          // RRR badge
          if (provider.requiredRR != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(_D.rSM),
              ),
              child: Text(
                'RRR: ${provider.requiredRR}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),

          IconButton(
            onPressed: provider.canRefresh ? () => provider.refreshLiveData() : null,
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white.withOpacity(provider.canRefresh ? 1.0 : 0.4),
              size: 20,
            ),
          ),
        ],
      ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _D.surfaceAlt,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _D.border),
            ),
            child: const Icon(Icons.sports_cricket, size: 26, color: _D.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _D.textPrimary),
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
  const _TossOptionButton({required this.label, required this.isSelected, required this.onTap});

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
          border: Border.all(color: isSelected ? _D.primary : _D.border, width: 1.5),
          boxShadow: isSelected ? _D.btnShadow(_D.primary) : _D.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded, size: 18, color: isSelected ? Colors.white : _D.textMuted),
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
  const _DecisionButton({required this.label, required this.icon, required this.isSelected, required this.color, required this.onTap});

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
    final done = count == 11;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: done ? _D.greenSoft : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(_D.rXS),
      ),
      child: Text(
        '$count/11',
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
  const _CurrentPlayersCard({
    required this.provider,
    required this.onStrikerTap,
    required this.onNonStrikerTap,
    required this.onBowlerTap,
  });

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
          const _SectionHeader(title: 'Current Players', icon: Icons.people_rounded, color: _D.primary),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PlayerChip(
                  name: provider.currentStriker?.name ?? 'Set Striker',
                  jersey: provider.currentStriker?.jerseyNumber,
                  label: 'Striker',
                  icon: Icons.person_rounded,
                  color: _D.green,
                  onTap: onStrikerTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlayerChip(
                  name: provider.currentNonStriker?.name ?? 'Non-Striker',
                  jersey: provider.currentNonStriker?.jerseyNumber,
                  label: 'Non-Striker',
                  icon: Icons.person_outline_rounded,
                  color: _D.orange,
                  onTap: onNonStrikerTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PlayerChip(
            name: provider.currentBowler?.name ?? 'Set Bowler',
            jersey: provider.currentBowler?.jerseyNumber,
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
  final String name;
  final int? jersey;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isFullWidth;
  const _PlayerChip({
    required this.name, required this.jersey, required this.label,
    required this.icon, required this.color, required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSet = jersey != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSet ? color.withOpacity(0.06) : _D.surfaceAlt,
          borderRadius: BorderRadius.circular(_D.rMD),
          border: Border.all(color: isSet ? color.withOpacity(0.25) : _D.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isSet ? color.withOpacity(0.12) : _D.border,
                borderRadius: BorderRadius.circular(_D.rSM),
              ),
              child: Icon(icon, color: isSet ? color : _D.textMuted, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isSet ? _D.textPrimary : _D.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(label, style: const TextStyle(fontSize: 10, color: _D.textMuted)),
                      if (jersey != null) ...[
                        const Text(' · ', style: TextStyle(fontSize: 10, color: _D.textMuted)),
                        Text('#$jersey', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: _D.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Score Buttons Grid
// ─────────────────────────────────────────────
class _ScoreButtonsGrid extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _ScoreButtonsGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _BtnData('0',   _D.textMuted,  () => provider.addRuns(0),          isRun: true),
      _BtnData('1',   const Color(0xFF3B82F6),  () => provider.addRuns(1), isRun: true),
      _BtnData('2',   const Color(0xFF1D4ED8),  () => provider.addRuns(2), isRun: true),
      _BtnData('3',   const Color(0xFF1E40AF),  () => provider.addRuns(3), isRun: true),
      _BtnData('4',   _D.orange,     () => provider.addRuns(4),           isRun: true,   isFour: true),
      _BtnData('6',   _D.live,       () => provider.addRuns(6),           isRun: true,   isSix: true),
      _BtnData('Wd',  _D.purple,     () => provider.addExtra('wide')),
      _BtnData('Nb',  _D.teal,       () => provider.addExtra('noBall')),
      _BtnData('LBW', _D.live,       () => provider.addWicket('lbw'),     isWicket: true),
      _BtnData('BW',  const Color(0xFFDC2626), () => provider.addWicket('bowled'),  isWicket: true),
      _BtnData('CT',  const Color(0xFFB91C1C), () => provider.addWicket('caught'),  isWicket: true),
      _BtnData('RO',  const Color(0xFF9B1C1C), () => provider.addWicket('runOut'),  isWicket: true),
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
          const _SectionHeader(title: 'Score Entry', icon: Icons.sports_cricket, color: _D.primary),
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
}

class _BtnData {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isRun;
  final bool isWicket;
  final bool isFour;
  final bool isSix;
  const _BtnData(this.label, this.color, this.onTap, {
    this.isRun = false, this.isWicket = false, this.isFour = false, this.isSix = false,
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
            color: data.isWicket ? data.color.withOpacity(0.3) : data.color.withOpacity(0.2),
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
              Text('FOUR', style: TextStyle(color: data.color.withOpacity(0.7), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            if (data.isSix)
              Text('SIX', style: TextStyle(color: data.color.withOpacity(0.7), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            if (data.isWicket)
              Icon(Icons.close_rounded, size: 11, color: data.color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Extras Card
// ─────────────────────────────────────────────
class _ExtrasCard extends StatelessWidget {
  final LiveScoreControlProvider provider;
  const _ExtrasCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final extras = [
      {'label': 'Wides',    'val': provider.extras['wides']   ?? 0, 'icon': Icons.width_full,       'color': _D.purple},
      {'label': 'No Balls', 'val': provider.extras['noBalls'] ?? 0, 'icon': Icons.error_outline,    'color': _D.teal},
      {'label': 'Byes',     'val': provider.extras['byes']    ?? 0, 'icon': Icons.run_circle,       'color': _D.gold},
      {'label': 'Leg Byes', 'val': provider.extras['legByes'] ?? 0, 'icon': Icons.sports_soccer,   'color': _D.orange},
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
          const _SectionHeader(title: 'Extras', icon: Icons.add_circle_outline, color: _D.textSecondary),
          const SizedBox(height: 14),
          Row(
            children: extras.map((e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: extras.indexOf(e) == 0 ? 0 : 8),
                child: _ExtraStatBox(
                  label: e['label'] as String,
                  value: (e['val'] as int).toString(),
                  icon: e['icon'] as IconData,
                  color: e['color'] as Color,
                ),
              ),
            )).toList(),
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
  const _ExtraStatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(_D.rMD),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, color: _D.textMuted, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Current Over Card
// ─────────────────────────────────────────────
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
          const _SectionHeader(title: 'This Over', icon: Icons.format_list_numbered_rounded, color: _D.primary),
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
                  Text('No balls yet', style: TextStyle(color: _D.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          else
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.currentOverBalls.length,
                itemBuilder: (context, index) {
                  final ball = provider.currentOverBalls[index];
                  final isWicket = ball['wicket'] ?? false;
                  final runs = ball['runs'] ?? 0;
                  final isExtra = ball['extra'] != null;

                  Color ballColor = isWicket ? _D.live
                      : runs == 6 ? _D.live
                      : runs == 4 ? _D.orange
                      : isExtra ? _D.purple
                      : _D.primary;

                  return Container(
                    width: 56, height: 56,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: ballColor.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(_D.rMD),
                      border: Border.all(color: ballColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isWicket ? 'W' : runs.toString(),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ballColor),
                        ),
                        if (isExtra)
                          Text(ball['extra'], style: TextStyle(fontSize: 8, color: ballColor.withOpacity(0.8), fontWeight: FontWeight.w700)),
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
}

// ─────────────────────────────────────────────
//  Section Header (reusable)
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_D.rSM),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _D.textPrimary),
        ),
      ],
    );
  }
}