import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../providers/scorecard_provider.dart';
import '../../data/services/match_service.dart';
import '../../data/models/scorecard_model.dart';
import '../../data/models/match_model.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;  late TabController _tabController;  @override  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

  }

  @override  void dispose() {    _tabController.dispose();    super.dispose();  }  @override  void didChangeDependencies() {    super.didChangeDependencies();    context.read<ScorecardProvider>().loadScorecard(widget.matchId);  }  @override  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Match Scorecard',
        showBackButton: true,
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
      body: SafeArea(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<ScorecardProvider>().refreshScorecard(widget.matchId),
        child: const Icon(Icons.refresh),
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
              _buildScoreHeader(match),
              const SizedBox(height: 24),
              if (scorecard != null && scorecard.fallOfWickets.isNotEmpty) ...[
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
          children: scorecard.innings.asMap().entries.map((entry) {
            final index = entry.key;
            final innings = entry.value;
            // Fix type casting for batting
            final batting = scorecard.batting.length > index 
                ? scorecard.batting[index].cast<BatsmanStats>()
                : [] as List<BatsmanStats>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInningsHeader(innings, index + 1),
                const SizedBox(height: 8),
                _buildBattingTable(batting, innings),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBowlingTab() {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        final scorecard = provider.scorecard;
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (scorecard == null) return const Center(child: Text('Loading bowling...'));
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: scorecard.innings.asMap().entries.map((entry) {
            final index = entry.key;
            final innings = entry.value;
            // Fix type casting for bowling
            final bowling = scorecard.bowling.length > index 
                ? scorecard.bowling[index].cast<BowlerStats>()
                : [] as List<BowlerStats>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInningsHeader(innings, index + 1),
                const SizedBox(height: 8),
                _buildBowlingTable(bowling, innings),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildExtrasTab() {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        final scorecard = provider.scorecard;
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (scorecard == null) return const Center(child: Text('Loading extras...'));
        
        // Calculate total extras from all innings
        int totalByes = 0;
        int totalLegByes = 0;
        int totalWides = 0;
        int totalNoBalls = 0;
        int totalPenalty = 0;
        int grandTotal = 0;
        
        for (var innings in scorecard.innings) {
          totalByes += innings.extras.byes;
          totalLegByes += innings.extras.legByes;
          totalWides += innings.extras.wides;
          totalNoBalls += innings.extras.noBalls;
          grandTotal += innings.extras.total;
        }
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Extras Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildExtrasRow('Byes', totalByes),
                    _buildExtrasRow('Leg Byes', totalLegByes),
                    _buildExtrasRow('Wides', totalWides),
                    _buildExtrasRow('No Balls', totalNoBalls),
                    _buildExtrasRow('Penalty Runs', totalPenalty),
                    const Divider(),
                    _buildExtrasRow('Total Extras', grandTotal, isBold: true),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExtrasRow(String label, int value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value.toString(), style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildScoreHeader(Match match) {
    final team1Score = '${match.score.team1.runs}/${match.score.team1.wickets} (${match.score.team1.overs})';
    final team2Score = '${match.score.team2.runs}/${match.score.team2.wickets} (${match.score.team2.overs})';
    
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
            match.result?.margin ?? (match.isLive ? 'Live' : match.status),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScore(String teamName, String score) {
    return Column(
      children: [
        Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(score, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInningsHeader(Innings innings, int inningsNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Innings $inningsNumber - ${innings.battingTeam ?? 'Team'}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text('${innings.totalRuns}/${innings.totalWickets} (${innings.oversDisplay})'),
      ],
    );
  }

  Widget _buildBattingTable(List<BatsmanStats> batting, Innings innings) {
    if (batting.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No batting data available')));
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Batsman', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(child: Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('4s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('6s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('SR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: batting.length,
            itemBuilder: (context, index) {
              final batsman = batting[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(batsman.playerName, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    Expanded(child: Text(batsman.runs.toString(), textAlign: TextAlign.center)),
                    Expanded(child: Text(batsman.balls.toString(), textAlign: TextAlign.center)),
                    Expanded(child: Text(batsman.fours.toString(), textAlign: TextAlign.center)),
                    Expanded(child: Text(batsman.sixes.toString(), textAlign: TextAlign.center)),
                    Expanded(child: Text(batsman.strikeRate.toStringAsFixed(1), textAlign: TextAlign.center)),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Extras', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${innings.extras.total}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBowlingTable(List<BowlerStats> bowling, Innings innings) {
    if (bowling.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No bowling data available')));
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Bowler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(child: Text('O', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('W', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('Econ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bowling.length,
            itemBuilder: (context, index) {
              final bowler = bowling[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(bowler.playerName, style: const TextStyle(fontWeight: FontWeight.w500))),
                    // Use oversDisplay getter for proper overs format
                    Expanded(child: Text(bowler.oversDisplay, textAlign: TextAlign.center)),
                    Expanded(child: Text(bowler.maidens.toString(), textAlign: TextAlign.center)),
                    Expanded(child: Text(bowler.runs.toString(), textAlign: TextAlign.center)),
                    Expanded(child: Text(bowler.wickets.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text(bowler.economy.toStringAsFixed(2), textAlign: TextAlign.center)),
                  ],
                ),
              );
            },
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: wickets.map((w) => Chip(
              label: Text('${w.wicket}-${w.batsman} (${w.runs}, ${w.overs})'),
              backgroundColor: Colors.orange[100],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInfo(Match match) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (match.venue != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(match.venue!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (match.venue!.city != null) 
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(match.venue!.city!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.sports_cricket, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('${match.format} • ${_formatDate(match.scheduledDate)}'),
              ],
            ),
            if (match.result != null && match.result!.playerOfMatch != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text('Player of the Match: ${match.result!.playerOfMatch}'),
                ],
              ),
            ],
            if (match.toss != null) ...[
              const SizedBox(height: 8),
              Text('Toss: ${match.toss!.winner} won and chose to ${match.toss!.decision}'),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}