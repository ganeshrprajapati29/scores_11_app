import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../providers/scorecard_provider.dart';
import '../../providers/auth_provider.dart';
import '../matches/live_score_control_screen.dart';
import '../../data/services/match_service.dart';
import '../../data/models/scorecard_model.dart';
import '../../data/models/match_model.dart';
import '../../../core/services/cache_service.dart';
import 'package:shimmer/shimmer.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final MatchService _matchService = MatchService();
  final CacheService _cacheService = CacheService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScorecardProvider>().loadScorecard(widget.matchId);
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
            Tab(icon: Icon(Icons.scoreboard), text: 'Score'),
            Tab(icon: Icon(Icons.sports_cricket), text: 'Batting'),
            Tab(icon: Icon(Icons.sports_baseball), text: 'Bowling'),
            Tab(icon: Icon(Icons.info_outline), text: 'Info'),
          ],
        ),
        actions: [
          Consumer<ScorecardProvider>(
            builder: (context, provider, child) => IconButton(
              icon: provider.isLoading 
                ? SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                  )
                : const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : () => provider.refreshScorecard(widget.matchId),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScoreTab(),
          _buildBattingTab(),
          _buildBowlingTab(),
          _buildInfoTab(),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'match_refresh',
              backgroundColor: Colors.blue,
              onPressed: () => context.read<ScorecardProvider>().refreshScorecard(widget.matchId),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'live_control',
              backgroundColor: AppColors.live ?? Colors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.sports_cricket),
              label: const Text('Live Control', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveScoreControlScreen(matchId: widget.matchId),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTab() {
    return Consumer2<ScorecardProvider, AuthProvider>(
      builder: (context, provider, authProvider, child) {
        if (provider.isLoading) return _buildShimmerLoading();
        
        if (provider.error != null) {
          return RefreshIndicator(
            onRefresh: () => provider.refreshScorecard(widget.matchId),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                Text(
                  'Scorecard Unavailable',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                if (provider.match != null) ...[
                  const Text(
                    'Showing live scores from match data:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildMatchScoreDirect(provider.match!),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.refreshScorecard(widget.matchId),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final scorecard = provider.scorecard;
        final match = scorecard?.match ?? provider.match;
        
        if (match == null) return const Center(child: Text('Match not found'));

        return RefreshIndicator(
          onRefresh: () => provider.refreshScorecard(widget.matchId),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTeamsHeader(scorecard, match),
              const SizedBox(height: 20),
              if (scorecard != null && scorecard.innings.isNotEmpty) ...[
                _buildStatsRow(scorecard.innings.first),
                const SizedBox(height: 20),
                _buildCurrentInningsSummary(scorecard.innings.first),
                const SizedBox(height: 16),
              ] else ...[
                _buildMatchScoreDirect(match),
                const SizedBox(height: 16),
              ],
              if (scorecard != null && scorecard.fallOfWickets.isNotEmpty) ...[
                _buildFallOfWickets(scorecard.fallOfWickets),
                const SizedBox(height: 24),
              ],
              _buildMatchInfoCard(match),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  // Direct match score display when scorecard is not available
  Widget _buildMatchScoreDirect(Match match) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.team1,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${match.score.team1.runs}/${match.score.team1.wickets}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '(${match.score.team1.overs})',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        match.team2,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${match.score.team2.runs}/${match.score.team2.wickets}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '(${match.score.team2.overs})',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: match.isLive ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (match.isLive) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('LIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ] else if (match.isCompleted) ...[
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text('COMPLETED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ] else ...[
                    const Icon(Icons.schedule, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(match.status ?? 'SCHEDULED', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            // Show target if second innings is batting
            if (_showTarget(match)) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Target: ${match.score.team1.runs + 1} runs',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            // Show required runs if live
            if (match.isLive && match.score.team2.runs > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.trending_up, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Need ${(match.score.team1.runs + 1) - match.score.team2.runs} runs in ${_remainingBalls(match)} balls',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _showTarget(Match match) {
    // Show target if second innings has started or completed
    return match.score.team2.runs > 0 || match.score.team2.wickets > 0;
  }

  String _remainingBalls(Match match) {
    final oversStr = match.score.team2.overs;
    final parts = oversStr.split('.');
    final oversCompleted = int.tryParse(parts[0]) ?? 0;
    final ballsCompleted = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final totalBalls = (match.overs * 6).toInt();
    final ballsDone = (oversCompleted * 6) + ballsCompleted;
    final remaining = totalBalls - ballsDone;
    final remainingOvers = remaining ~/ 6;
    final remainingBalls = remaining % 6;
    return remainingBalls > 0 ? '$remainingOvers.$remainingBalls' : '$remainingOvers';
  }

  Widget _buildBattingTab() {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return _buildShimmerLoading();
        final scorecard = provider.scorecard;
        if (scorecard == null || scorecard.innings.isEmpty) {
          return _buildEmptyState('No batting data available');
        }
        if (scorecard.batting.isEmpty || scorecard.batting.every((list) => list.isEmpty)) {
          return _buildEmptyState('Batting card not yet available');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scorecard.innings.length,
          itemBuilder: (context, index) {
            final innings = scorecard.innings[index];
            final batting = scorecard.batting.length > index 
              ? scorecard.batting[index]
              : <BatsmanStats>[];
            if (batting.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                _buildInningsHeader(innings, index + 1),
                const SizedBox(height: 16),
                _buildEnhancedBattingTable(batting, innings),
                if (index < scorecard.innings.length - 1) const SizedBox(height: 24),
              ],
            ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
          },
        );
      },
    );
  }

  Widget _buildBowlingTab() {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return _buildShimmerLoading();
        final scorecard = provider.scorecard;
        if (scorecard == null || scorecard.innings.isEmpty) {
          return _buildEmptyState('No bowling data available');
        }
        if (scorecard.bowling.isEmpty || scorecard.bowling.every((list) => list.isEmpty)) {
          return _buildEmptyState('Bowling card not yet available');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scorecard.innings.length,
          itemBuilder: (context, index) {
            final innings = scorecard.innings[index];
            final bowling = scorecard.bowling.length > index 
              ? scorecard.bowling[index]
              : <BowlerStats>[];
            if (bowling.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                _buildInningsHeader(innings, index + 1),
                const SizedBox(height: 16),
                _buildEnhancedBowlingTable(bowling),
                if (index < scorecard.innings.length - 1) const SizedBox(height: 24),
              ],
            ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
          },
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return _buildShimmerLoading();
        final scorecard = provider.scorecard;
        final match = scorecard?.match ?? provider.match;
        if (match == null) return _buildEmptyState('Match info unavailable');
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildMatchInfoCard(match),
            if (scorecard != null && scorecard.innings.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildExtrasSummary(scorecard.innings.first.extras),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTeamsHeader(FullScorecard? scorecard, Match match) {
    final team1Score = match.team1ScoreDisplay;
    final team2Score = match.team2ScoreDisplay;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary ?? Colors.blue, (AppColors.primaryDark ?? Colors.blue[800])!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.team1.length > 15 ? '${match.team1.substring(0, 12)}...' : match.team1,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(team1Score, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text('VS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      match.team2.length > 15 ? '${match.team2.substring(0, 12)}...' : match.team2,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(team2Score, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusBadge(match),
              if (match.venue != null) Text(
                match.venue!.name,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Match match) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            match.isLive ? Icons.fiber_manual_record : Icons.schedule,
            color: match.isLive ? Colors.green : Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            match.isLive ? 'LIVE' : match.status ?? 'Scheduled',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Innings innings) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('RR', innings.runRate.toStringAsFixed(2), Icons.speed)),
          Expanded(child: _buildStatItem('Extras', '${innings.extras.total}', Icons.add)),
          Expanded(child: _buildStatItem('WKTS', '${innings.totalWickets}', Icons.remove_circle)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<ScorecardProvider>().refreshScorecard(widget.matchId),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentInningsSummary(Innings innings) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Innings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('${innings.totalRuns}/${innings.totalWickets} (${innings.oversDisplay})'),
          Text('RR: ${innings.runRate.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildFallOfWickets(List<FallOfWicket> fallOfWickets) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fall of Wickets', style: TextStyle(fontWeight: FontWeight.bold)),
          ...fallOfWickets.map((wicket) => Text('${wicket.wicket}/${wicket.runs} - ${wicket.batsman} (${wicket.overs})')),
        ],
      ),
    );
  }

  Widget _buildMatchInfoCard(Match match) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Match Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _buildInfoRow('Format', match.format),
            _buildInfoRow('Match Type', match.matchType),
            _buildInfoRow('Venue', match.venue?.name ?? 'TBD'),
            _buildInfoRow('Date', '${match.scheduledDate.day}/${match.scheduledDate.month}/${match.scheduledDate.year}'),
            _buildInfoRow('Status', match.status ?? 'SCHEDULED'),
            if (match.toss != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Toss', '${match.toss!.winner} chose to ${match.toss!.decision}'),
            ],
            if (match.result != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Result', match.result!.winner ?? 'N/A'),
              if (match.result!.margin != null)
                _buildInfoRow('Margin', match.result!.margin!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildInningsHeader(Innings innings, int index) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Innings $index: ${innings.totalRuns}/${innings.totalWickets} (${innings.oversDisplay})',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEnhancedBattingTable(List<BatsmanStats> batting, Innings innings) {
    if (batting.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Batting card not available')),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        columns: const [
          DataColumn(label: Text('Batsman', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('B', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('4s', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('6s', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('SR', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: batting.map((bat) => DataRow(cells: [
          DataCell(Text(bat.playerName, style: const TextStyle(fontWeight: FontWeight.w500))),
          DataCell(Text(bat.runs.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(bat.balls.toString())),
          DataCell(Text(bat.fours.toString())),
          DataCell(Text(bat.sixes.toString())),
          DataCell(Text(bat.strikeRate.toStringAsFixed(2))),
        ])).toList(),
      ),
    );
  }

  Widget _buildEnhancedBowlingTable(List<BowlerStats> bowling) {
    if (bowling.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Bowling card not available')),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        columns: const [
          DataColumn(label: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('O', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('M', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('W', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ECON', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: bowling.map((bowl) => DataRow(cells: [
          DataCell(Text(bowl.playerName, style: const TextStyle(fontWeight: FontWeight.w500))),
          DataCell(Text(bowl.oversDisplay)),
          DataCell(Text(bowl.maidens.toString())),
          DataCell(Text(bowl.runs.toString())),
          DataCell(Text(bowl.wickets.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(bowl.economy.toStringAsFixed(2))),
        ])).toList(),
      ),
    );
  }

  Widget _buildExtrasSummary(Extras extras) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Extras Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _buildExtraItem('Wides', extras.wides),
              _buildExtraItem('No Balls', extras.noBalls),
              _buildExtraItem('Byes', extras.byes),
              _buildExtraItem('Leg Byes', extras.legByes),
              _buildExtraItem('Penalty', extras.penalty),
              _buildExtraItem('Total', extras.total, isTotal: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtraItem(String label, int value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: isTotal ? 24 : 18,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primary : Colors.black87,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}