import 'package:flutter/material.dart';
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

class LiveScoreControlScreen extends StatefulWidget {
  final String matchId;
  final Match? match;

  const LiveScoreControlScreen({
    super.key,
    required this.matchId,
    this.match = null,
  });

  @override
  State<LiveScoreControlScreen> createState() => _LiveScoreControlScreenState();
}

class _LiveScoreControlScreenState extends State<LiveScoreControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MatchService _matchService = MatchService();
  final TeamService _teamService = TeamService();
  final PlayerService _playerService = PlayerService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveScoreControlProvider>().initialize(widget.matchId, widget.match);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return ChangeNotifierProvider(
      create: (_) => LiveScoreControlProvider()
        ..setUserRole(context.read<AuthProvider>().userRole)
        ..initialize(widget.matchId, widget.match),
      child: Scaffold(

        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'Live Score Control',
          showBackButton: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.flip), text: 'Toss'),
              Tab(icon: Icon(Icons.groups), text: 'Playing XI'),
              Tab(icon: Icon(Icons.sports_cricket), text: 'Score'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Live Status Banner
            Consumer<LiveScoreControlProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange[50],
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Initializing live control...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.live, AppColors.error]),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: Colors.white.withOpacity(0.8), size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${provider.currentScore.runs}/${provider.currentScore.wickets}',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${provider.currentOver}.${provider.currentBall} overs',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (provider.requiredRR != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            'RRR: ${provider.requiredRR}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      IconButton(
                        onPressed: provider.canRefresh ? () => provider.refreshLiveData() : null,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
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
          builder: (context, provider, child) {
            if (provider.currentStatus == 'live') {
              return FloatingActionButton.extended(
                onPressed: provider.canEndInnings ? provider.endInnings : null,
                backgroundColor: Colors.red,
                icon: const Icon(Icons.stop, color: Colors.white),
                label: const Text('End Innings', style: TextStyle(color: Colors.white)),
              );
            }
            return FloatingActionButton.extended(
              onPressed: provider.canStartMatch ? provider.startMatch : null,
              backgroundColor: Colors.green,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Start Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTossTab() {
    return Consumer<LiveScoreControlProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      'Toss Decision',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTossTeamCard(provider.match?.team1 ?? 'Team 1'),
                        Icon(Icons.flip, color: Colors.white, size: 48),
                        _buildTossTeamCard(provider.match?.team2 ?? 'Team 2', isRight: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (!provider.tossDone)
                Column(
                  children: [
                    Text(
                      'Select Toss Winner',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => provider.setTossWinner('team1'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.sports_cricket),
                          label: Text(provider.match?.team1 ?? 'Team 1'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => provider.setTossWinner('team2'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.sports_cricket),
                          label: Text(provider.match?.team2 ?? 'Team 2'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (provider.tossWinnerKey != null)
                      Column(
                        children: [
                          Text('Winner: ${provider.tossWinnerName}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTossDecisionButton('Bat First', Icons.sports_cricket, () => provider.setTossDecision('bat')),
                              _buildTossDecisionButton('Bowl First', Icons.sports_baseball, () => provider.setTossDecision('bowl')),
                            ],
                          ),
                        ],
                      ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Toss Completed!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${provider.tossWinnerName} won and elected to ${provider.tossDecision == 'bat' ? 'Bat' : 'Bowl'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTossTeamCard(String teamName, {bool isRight = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.sports_cricket, size: 30, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('${isRight ? 'Team 2' : 'Team 1'}', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTossDecisionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[800])),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayingXiTab() {
    return Consumer<LiveScoreControlProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () => provider.refreshLiveData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Playing XI (11 players)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(20)),
                      child: Text('${provider.selectedTeam1Players.length}/11', style: TextStyle(color: Colors.green[800])),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Team 1 Players Grid
                _buildTeamPlayersGrid(
                  provider.match?.team1 ?? '',
                  provider.team1Players,
                  provider.team1Players.take(11).toList(),
                  (player) => provider.toggleTeam1Player(player),
                ),
                const SizedBox(height: 32),
                // Team 2 Players Grid  
                _buildTeamPlayersGrid(
                  provider.match?.team2 ?? '',
                  provider.team2Players,
                  provider.team2Players.take(11).toList(),
                  (player) => provider.toggleTeam2Player(player),
                ),

                const SizedBox(height: 24),
                if (provider.selectedTeam1Players.length == 11 && provider.selectedTeam2Players.length == 11)
                  ElevatedButton.icon(
                    onPressed: provider.canInitialize ? provider.initializeMatch : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    icon: const Icon(Icons.sports_cricket, color: Colors.white),
                    label: const Text('Initialize Match', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
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
    Function(Player) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.group, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(teamName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: availablePlayers.length,
          itemBuilder: (context, index) {
            final player = availablePlayers[index];
            final isSelected = selectedPlayers.any((p) => p.id == player.id);
            return GestureDetector(
              onTap: () => onToggle(player),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? Colors.green.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        _getRoleIcon(player.role ?? ''),
                        color: Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      player.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isSelected ? Colors.green[800] : Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '#${player.jerseyNumber ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('SELECTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                      ),
                  ],
                ),
              ).animate().scale(duration: const Duration(milliseconds: 150)),
            );
          },
        ),
      ],
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
        return Icons.person;
    }
  }

  Widget _buildScoreEntryTab() {
    return Consumer<LiveScoreControlProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Current Batsmen & Bowler
              _buildCurrentPlayersCard(provider),
              const SizedBox(height: 24),
              
              // Score Buttons Grid
              _buildScoreButtons(provider),
              
              const SizedBox(height: 24),
              
              // Wicket & Extras
              _buildWicketExtras(provider),
              
              const SizedBox(height: 24),
              
              // Current Over Balls
              _buildCurrentOver(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentPlayersCard(LiveScoreControlProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Players', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPlayerCard(
                  provider.currentStriker?.name ?? 'Set Striker',
                  provider.currentStriker?.jerseyNumber,
                  Icons.person,
                  Colors.green,
                  () => _showStrikerSelector(provider),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlayerCard(
                  provider.currentNonStriker?.name ?? 'Set Non-Striker',
                  provider.currentNonStriker?.jerseyNumber,
                  Icons.person_outline,
                  Colors.orange,
                  () => _showNonStrikerSelector(provider),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPlayerCard(
            provider.currentBowler?.name ?? 'Set Bowler',
            provider.currentBowler?.jerseyNumber,
            Icons.sports_baseball,
            Colors.red,
            () => _showBowlerSelector(provider),
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String name, int? jersey, IconData icon, Color color, VoidCallback onTap, {bool isExpanded = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  if (jersey != null) Text('#$jersey', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreButtons(LiveScoreControlProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Score Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _buildScoreButton('0', Colors.grey, () => provider.addRuns(0)),
            _buildScoreButton('1', Colors.blue[400]!, () => provider.addRuns(1)),
            _buildScoreButton('2', Colors.blue[500]!, () => provider.addRuns(2)),
            _buildScoreButton('3', Colors.blue[600]!, () => provider.addRuns(3)),
            _buildScoreButton('4', Colors.orange[400]!, () => provider.addRuns(4)),
            _buildScoreButton('6', Colors.red[400]!, () => provider.addRuns(6)),
            _buildScoreButton('Wd', Colors.purple, () => provider.addExtra('wide')),
            _buildScoreButton('Nb', Colors.teal, () => provider.addExtra('noBall')),
            _buildScoreButton('LBW', Colors.red[600]!, () => provider.addWicket('lbw')),
            _buildScoreButton('BW', Colors.red[500]!, () => provider.addWicket('bowled')),
            _buildScoreButton('CT', Colors.red[400]!, () => provider.addWicket('caught')),
            _buildScoreButton('RO', Colors.red[300]!, () => provider.addWicket('runOut')),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWicketExtras(LiveScoreControlProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Extras & More', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Wides', (provider.extras['wides'] ?? 0).toString(), Icons.width_full)),
                Expanded(child: _buildStatCard('No Balls', (provider.extras['noBalls'] ?? 0).toString(), Icons.error)),
                Expanded(child: _buildStatCard('Byes', (provider.extras['byes'] ?? 0).toString(), Icons.run_circle)),
                Expanded(child: _buildStatCard('LBW', (provider.extras['legByes'] ?? 0).toString(), Icons.sports_soccer)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentOver(LiveScoreControlProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Over Balls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (provider.currentOverBalls.isEmpty)
              const Center(child: Text('No balls yet. Start scoring!'))
            else
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.currentOverBalls.length,
                  itemBuilder: (context, index) {
                    final ball = provider.currentOverBalls[index];
                    return Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: (ball['wicket'] ?? false) ? Colors.red[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text((ball['runs'] ?? 0).toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          if (ball['wicket'] ?? false) const Icon(Icons.close, size: 16, color: Colors.red),
                        ],
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

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Player Selector Bottom Sheets
  void _showStrikerSelector(LiveScoreControlProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Striker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: Consumer<LiveScoreControlProvider>(
                  builder: (context, provider, child) => ListView.builder(
                    controller: scrollController,
                    itemCount: provider.battingTeamPlayers.length,
                    itemBuilder: (context, index) {
                      final player = provider.battingTeamPlayers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text('${player.jerseyNumber ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(player.name),
                        subtitle: Text(player.role ?? ''),
                        trailing: provider.currentStriker?.id == player.id
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () => provider.setStriker(player),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNonStrikerSelector(LiveScoreControlProvider provider) {
    // Similar implementation for non-striker
    _showStrikerSelector(provider); // Placeholder - implement similarly
  }

  void _showBowlerSelector(LiveScoreControlProvider provider) {
    // Similar implementation for bowler from bowling team
    _showStrikerSelector(provider); // Placeholder
  }
}


