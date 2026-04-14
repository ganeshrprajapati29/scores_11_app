import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../providers/scorecard_provider.dart';
import '../../data/services/match_service.dart';
import '../../data/models/scorecard_model.dart';
import '../../data/models/match_model.dart';
import '../matches/live_score_control_screen.dart';
import '../../providers/auth_provider.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ScorecardProvider>(context, listen: false);
      provider.loadScorecard(widget.matchId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider(
      create: (context) => ScorecardProvider(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Match Scorecard',
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Live Score'),
              Tab(text: 'Batting'),
              Tab(text: 'Bowling'),
              Tab(text: 'Extras'),
            ],
          ),
        ),
        body: Expanded(
          child: SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveScoreTab(),
                _buildBattingTab(),
                _buildBowlingTab(),
                _buildExtrasTab(),
              ],
            ),
          ),
        ),
        Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return Stack(
              children: [
                if (auth.userRole == 'admin' || auth.userRole == 'umpire')
                  Positioned(
                    right: 16,
                    bottom: 100,
                    child: FloatingActionButton.extended(
                      heroTag: 'liveControl',
                      backgroundColor: AppColors.live,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveScoreControlScreen(
                            matchId: widget.matchId,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.sports_cricket, color: Colors.white),
                      label: const Text(
                        'Live Control',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                FloatingActionButton(
                  heroTag: 'refresh',
                  onPressed: () => context.read<ScorecardProvider>().refreshScorecard(widget.matchId),
                  child: const Icon(Icons.refresh),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiveScoreTab() {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text('Failed to load scorecard'),
                Text(provider.error!),
                ElevatedButton(
                  onPressed: () => provider.refreshScorecard(widget.matchId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final scorecard = provider.scorecard;
        final match = scorecard?.match ?? provider.match;
        if (match == null || !provider.hasData) {
          return const Center(child: Text('No scorecard data'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshScorecard(widget.matchId),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildScoreHeader(match.score.team1, match.score.team2, match),
              const SizedBox(height: 24),
              if (scorecard!.fallOfWickets.isNotEmpty) ...[
                _buildFallOfWickets(scorecard.fallOfWickets),
                const SizedBox(height: 16),
              ],
              _buildMatchInfo(match),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBattingTab() {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        final scorecard = provider.scorecard;
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (scorecard == null) return const Center(child: Text('Loading batting...'));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: scorecard.innings.map((innings) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInningsHeader(innings),
              const SizedBox(height: 8),
              _buildBattingTable(innings),
              const SizedBox(height: 24),
            ],
          )).toList(),
        );
      },
    );
  }

  Widget _buildBowlingTab() {
    // Similar to batting, show bowling figures per innings
    return const Center(child: Text('Bowling figures coming soon'));
  }

  Widget _buildExtrasTab() {
    return const Center(child: Text('Extras, partnerships, stats'));
  }

  Widget _buildScoreHeader(TeamScore team1Score, TeamScore team2Score, Match match) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(
            '${match.team1} vs ${match.team2}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTeamScore(match.team1, team1Score)),
              const SizedBox(width: 32),
              Expanded(child: _buildTeamScore(match.team2, team2Score)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            match.result?.method ?? 'Live',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScore(String teamName, TeamScore score) {
    return Column(
      children: [
        Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('${score.runs}/${score.wickets} (${score.overs})', 
             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInningsHeader(Innings innings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Innings ${innings.inningsNumber} - ${innings.battingTeam ?? 'Team'}', 
             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('${innings.totalRuns}/${innings.totalWickets} (${innings.oversDisplay})'),
      ],
    );
  }

  Widget _buildBattingTable(Innings innings) {
    // In real, get batting for this innings from scorecard.batting[inningsNumber-1]
    final battingData = scorecard.batting.isNotEmpty ? scorecard.batting[0] : []; // fallback
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Batsman', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(child: Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(child: Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(child: Text('4s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(child: Text('6s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(child: Text('SR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          // Data rows - horizontal scroll for small screens
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 0, // Custom header already
                dataRowHeight: 48,
                columns: const [
                  DataColumn(label: SizedBox.shrink()), // Custom header
                  DataColumn(label: SizedBox.shrink()),
                  DataColumn(label: SizedBox.shrink()),
                  DataColumn(label: SizedBox.shrink()),
                  DataColumn(label: SizedBox.shrink()),
                  DataColumn(label: SizedBox.shrink()),
                ],
                rows: battingData.take(11).map((batsman) => DataRow(cells: [
                  DataCell(SizedBox(width: 160, child: Text(batsman.playerName, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis))),
                  DataCell(Text('${batsman.runs}')),
                  DataCell(Text('${batsman.balls}')),
                  DataCell(Text('${batsman.fours}')),
                  DataCell(Text('${batsman.sixes}')),
                  DataCell(Text('${batsman.strikeRate.toStringAsFixed(1)}')),
                ])).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallOfWickets(List<FallOfWicket> wickets) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fall of Wickets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ...wickets.map((w) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('${w.wicket}-${w.batsman} (${w.partnership}, ${w.runs})'),
          )),
        ],
      ),
    );
  }

  Widget _buildMatchInfo(Match match) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(match.venue?.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${match.format} • ${match.scheduledDate.day} ${_matchService._formatMonth(match.scheduledDate.month)}'),
            if (match.result?.playerOfMatch != null)
              Text('Player of the Match: ${match.result!.playerOfMatch}'),
          ],
        ),
      ),
    );
  }
}
