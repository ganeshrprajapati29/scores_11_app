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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Match Scorecard',
        showBackButton: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.scoreboard_outlined), text: 'Score'),
            Tab(icon: Icon(Icons.sports_cricket_outlined), text: 'Batting'),
            Tab(icon: Icon(Icons.sports_baseball_outlined), text: 'Bowling'),
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
                : const Icon(Icons.refresh_rounded),
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
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'match_refresh',
          mini: true,
          backgroundColor: Colors.white,
          elevation: 2,
          onPressed: () => context.read<ScorecardProvider>().refreshScorecard(widget.matchId),
          child: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'live_control',
          backgroundColor: AppColors.live ?? Colors.red,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.sports_cricket_rounded),
          label: const Text('Live Control', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveScoreControlScreen(matchId: widget.matchId),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SCORE TAB ====================
  Widget _buildScoreTab() {
    return Consumer2<ScorecardProvider, AuthProvider>(
      builder: (context, provider, authProvider, child) {
        if (provider.isLoading) return _buildShimmerLoading();
        
        if (provider.error != null && provider.scorecard == null) {
          return _buildErrorState(provider.error!);
        }

        final scorecard = provider.scorecard;
        final match = scorecard?.match ?? provider.match;
        
        if (match == null) {
          return _buildEmptyState('Match not found');
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshScorecard(widget.matchId),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMatchHeader(scorecard, match),
                const SizedBox(height: 20),
                if (scorecard != null && scorecard.innings.isNotEmpty) ...[
                  _buildInningsScorecard(scorecard),
                  const SizedBox(height: 20),
                  if (scorecard.fallOfWickets.isNotEmpty)
                    _buildFallOfWicketsSection(scorecard.fallOfWickets),
                  const SizedBox(height: 20),
                  _buildMatchDetailsCard(match),
                ] else if (match != null) ...[
                  _buildDirectMatchScore(match),
                  const SizedBox(height: 20),
                  _buildMatchDetailsCard(match),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchHeader(FullScorecard? scorecard, Match match) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark ?? AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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
                      match.team1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getTeamScore(match, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getTeamOvers(match, 1),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      match.team2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getTeamScore(match, 2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getTeamOvers(match, 2),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMatchStatusChip(match),
        ],
      ),
    );
  }

  String _getTeamScore(Match match, int teamNumber) {
    if (teamNumber == 1) {
      return '${match.score.team1.runs}/${match.score.team1.wickets}';
    } else {
      return '${match.score.team2.runs}/${match.score.team2.wickets}';
    }
  }

  String _getTeamOvers(Match match, int teamNumber) {
    if (teamNumber == 1) {
      return '(${match.score.team1.overs} ov)';
    } else {
      return '(${match.score.team2.overs} ov)';
    }
  }

  Widget _buildMatchStatusChip(Match match) {
    Color bgColor;
    Color textColor;
    String statusText;
    IconData icon;

    if (match.isLive) {
      bgColor = Colors.red.withOpacity(0.2);
      textColor = Colors.white;
      statusText = 'LIVE';
      icon = Icons.fiber_manual_record;
    } else if (match.isCompleted) {
      bgColor = Colors.green.withOpacity(0.2);
      textColor = Colors.white;
      statusText = 'COMPLETED';
      icon = Icons.check_circle_outline;
    } else {
      bgColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.white;
      statusText = match.status ?? 'SCHEDULED';
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInningsScorecard(FullScorecard scorecard) {
    return Column(
      children: scorecard.innings.asMap().entries.map((entry) {
        final index = entry.key;
        final innings = entry.value;
final batting = scorecard.batting.length > index ? scorecard.batting[index] : <BatsmanStats>[];
        final bowling = scorecard.bowling.length > index ? scorecard.bowling[index] : <BowlerStats>[];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInningsTitle(innings, index + 1),
              if (batting.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildBattingTable(batting),
              ],
              if (bowling.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Bowling',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildBowlingTable(bowling),
              ],
              const SizedBox(height: 16),
              _buildExtrasRow(innings.extras),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInningsTitle(Innings innings, int inningsNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Innings $inningsNumber',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${innings.totalRuns}/${innings.totalWickets} (${innings.oversDisplay})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattingTable(List<BatsmanStats> batting) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 8,
        headingRowColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => Colors.grey[50],
        ),
        columns: const [
          DataColumn(label: Text('Batsman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('4s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('6s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('SR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: batting.map((bat) {
          return DataRow(cells: [
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bat.playerName,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  if (bat.howOut != null && bat.howOut!.isNotEmpty)
                    Text(
                      bat.howOut!,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            DataCell(Text(bat.runs.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            DataCell(Text(bat.balls.toString(), style: const TextStyle(fontSize: 13))),
            DataCell(Text(bat.fours.toString(), style: const TextStyle(fontSize: 13))),
            DataCell(Text(bat.sixes.toString(), style: const TextStyle(fontSize: 13))),
            DataCell(Text(bat.strikeRate.toStringAsFixed(1), style: const TextStyle(fontSize: 13))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildBowlingTable(List<BowlerStats> bowling) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 8,
        headingRowColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => Colors.grey[50],
        ),
        columns: const [
          DataColumn(label: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('O', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('M', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Econ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: bowling.map((bowl) {
          return DataRow(cells: [
            DataCell(Text(bowl.playerName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            DataCell(Text(bowl.oversDisplay, style: const TextStyle(fontSize: 13))),
            DataCell(Text(bowl.maidens.toString(), style: const TextStyle(fontSize: 13))),
            DataCell(Text(bowl.runs.toString(), style: const TextStyle(fontSize: 13))),
            DataCell(Text(bowl.wickets.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            DataCell(Text(bowl.economy.toStringAsFixed(2), style: const TextStyle(fontSize: 13))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildExtrasRow(Extras extras) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Extras:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(width: 8),
          if (extras.wides > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('wd $extras.wides', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          if (extras.noBalls > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('nb $extras.noBalls', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          if (extras.byes > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('b $extras.byes', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          if (extras.legByes > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('lb $extras.legByes', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          const Spacer(),
          Text(
            'Total: ${extras.total}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFallOfWicketsSection(List<FallOfWicket> fallOfWickets) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fall of Wickets',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: fallOfWickets.map((wicket) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${wicket.wicket}-${wicket.runs} (${wicket.batsman}, ${wicket.overs})',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectMatchScore(Match match) {
    final target = match.score.team1.runs + 1;
    final required = target - match.score.team2.runs;
    final isSecondInnings = match.score.team2.runs > 0 || match.score.team2.wickets > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTeamScoreCard(match.team1, match.score.team1.runs, match.score.team1.wickets, match.score.team1.overs),
              const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              _buildTeamScoreCard(match.team2, match.score.team2.runs, match.score.team2.wickets, match.score.team2.overs),
            ],
          ),
          if (match.isLive && isSecondInnings) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Target: $target runs',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Need $required runs in ${_getRemainingOvers(match)} overs',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamScoreCard(String team, int runs, int wickets, String overs) {
    return Column(
      children: [
        Text(
          team,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '$runs/$wickets',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        Text(
          '($overs)',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _getRemainingOvers(Match match) {
    final oversStr = match.score.team2.overs;
    final parts = oversStr.split('.');
    final completed = int.tryParse(parts[0]) ?? 0;
    final balls = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final totalBalls = match.overs * 6;
    final remaining = totalBalls - (completed * 6 + balls);
    final remainingOvers = remaining ~/ 6;
    final remainingBalls = remaining % 6;
    return remainingBalls > 0 ? '$remainingOvers.$remainingBalls' : '$remainingOvers';
  }

  // ==================== BATTING TAB ====================
  Widget _buildBattingTab() {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return _buildShimmerLoading();
        
        final scorecard = provider.scorecard;
        if (scorecard == null || scorecard.batting.isEmpty || scorecard.batting.every((list) => list.isEmpty)) {
          return _buildEmptyState('Batting card not available yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scorecard.innings.length,
          itemBuilder: (context, index) {
            final innings = scorecard.innings[index];
final batting = scorecard.batting.length > index ? scorecard.batting[index] : <BatsmanStats>[];
            if (batting.isEmpty) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInningsTitle(innings, index + 1),
                  const SizedBox(height: 12),
                  _buildDetailedBattingTable(batting),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailedBattingTable(List<BatsmanStats> batting) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => AppColors.primary.withOpacity(0.05),
        ),
        columns: const [
          DataColumn(label: Text('BATSMAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('RUNS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('BALLS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('4s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('6s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('SR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: batting.map((bat) {
          return DataRow(cells: [
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bat.playerName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (bat.howOut != null && bat.howOut!.isNotEmpty)
                    Text(
                      bat.howOut!,
                      style: TextStyle(fontSize: 10, color: Colors.red[400]),
                    ),
                ],
              ),
            ),
            DataCell(Text(bat.runs.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary))),
            DataCell(Text(bat.balls.toString(), style: const TextStyle(fontSize: 14))),
            DataCell(Text(bat.fours.toString(), style: const TextStyle(fontSize: 14))),
            DataCell(Text(bat.sixes.toString(), style: const TextStyle(fontSize: 14))),
            DataCell(Text(bat.strikeRate.toStringAsFixed(1), style: const TextStyle(fontSize: 14))),
          ]);
        }).toList(),
      ),
    );
  }

  // ==================== BOWLING TAB ====================
  Widget _buildBowlingTab() {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return _buildShimmerLoading();
        
        final scorecard = provider.scorecard;
        if (scorecard == null || scorecard.bowling.isEmpty || scorecard.bowling.every((list) => list.isEmpty)) {
          return _buildEmptyState('Bowling card not available yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scorecard.innings.length,
          itemBuilder: (context, index) {
            final innings = scorecard.innings[index];
final bowling = scorecard.bowling.length > index ? scorecard.bowling[index] : <BowlerStats>[];
            if (bowling.isEmpty) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInningsTitle(innings, index + 1),
                  const SizedBox(height: 12),
                  _buildDetailedBowlingTable(bowling),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailedBowlingTable(List<BowlerStats> bowling) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => AppColors.primary.withOpacity(0.05),
        ),
        columns: const [
          DataColumn(label: Text('BOWLER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('O', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('M', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('W', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('ECON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: bowling.map((bowl) {
          return DataRow(cells: [
            DataCell(Text(bowl.playerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
            DataCell(Text(bowl.oversDisplay, style: const TextStyle(fontSize: 14))),
            DataCell(Text(bowl.maidens.toString(), style: const TextStyle(fontSize: 14))),
            DataCell(Text(bowl.runs.toString(), style: const TextStyle(fontSize: 14))),
            DataCell(Text(bowl.wickets.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary))),
            DataCell(Text(bowl.economy.toStringAsFixed(2), style: const TextStyle(fontSize: 14))),
          ]);
        }).toList(),
      ),
    );
  }

  // ==================== INFO TAB ====================
  Widget _buildInfoTab() {
    return Consumer<ScorecardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return _buildShimmerLoading();
        
        final match = provider.scorecard?.match ?? provider.match;
        if (match == null) {
          return _buildEmptyState('Match information not available');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoCard(match),
              const SizedBox(height: 16),
              if (provider.scorecard != null && provider.scorecard!.innings.isNotEmpty)
                _buildExtrasDetailsCard(provider.scorecard!.innings.first.extras),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(Match match) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          _buildInfoTile(Icons.category, 'Format', match.format),
          _buildInfoTile(Icons.sports_cricket, 'Match Type', match.matchType),
          _buildInfoTile(Icons.location_on, 'Venue', match.venue?.name ?? 'TBD'),
          _buildInfoTile(Icons.calendar_today, 'Date', _formatDate(match.scheduledDate)),
          _buildInfoTile(Icons.access_time, 'Time', _formatTime(match.scheduledDate)),
          _buildInfoTile(Icons.info, 'Status', match.status ?? 'SCHEDULED'),
          if (match.toss != null) ...[
            const Divider(height: 24),
            _buildInfoTile(Icons.currency_bitcoin, 'Toss', '${match.toss!.winner} won the toss and chose to ${match.toss!.decision}'),
          ],
          if (match.result != null) ...[
            const Divider(height: 24),
            _buildInfoTile(Icons.emoji_events, 'Result', match.result!.winner ?? 'N/A'),
            if (match.result!.margin != null && match.result!.margin!.isNotEmpty)
              _buildInfoTile(Icons.trending_up, 'Margin', match.result!.margin!),
            if (match.result!.playerOfMatch != null && match.result!.playerOfMatch!.isNotEmpty)
              _buildInfoTile(Icons.star, 'Player of the Match', match.result!.playerOfMatch!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtrasDetailsCard(Extras extras) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extras Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _buildExtrasItem('Wides', extras.wides),
              _buildExtrasItem('No Balls', extras.noBalls),
              _buildExtrasItem('Byes', extras.byes),
              _buildExtrasItem('Leg Byes', extras.legByes),
              _buildExtrasItem('Penalty', extras.penalty),
              _buildExtrasItem('Total Extras', extras.total, isTotal: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtrasItem(String label, int value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: isTotal ? 22 : 18,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppColors.primary : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMatchDetailsCard(Match match) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          _buildDetailsRow('Format', match.format),
          _buildDetailsRow('Match Type', match.matchType),
          _buildDetailsRow('Venue', match.venue?.name ?? 'TBD'),
          _buildDetailsRow('Date', _formatDate(match.scheduledDate)),
          _buildDetailsRow('Time', _formatTime(match.scheduledDate)),
          if (match.toss != null) ...[
            const Divider(height: 24),
            _buildDetailsRow('Toss Winner', match.toss!.winner ?? 'N/A'),
            _buildDetailsRow('Toss Decision', match.toss!.decision ?? 'N/A'),
          ],
          if (match.result != null) ...[
            const Divider(height: 24),
            _buildDetailsRow('Winner', match.result!.winner ?? 'N/A'),
            if (match.result!.margin != null)
              _buildDetailsRow('Won By', match.result!.margin!),
            if (match.result!.playerOfMatch != null)
              _buildDetailsRow('Player of the Match', match.result!.playerOfMatch!),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== UTILITY WIDGETS ====================
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Unable to load scorecard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<ScorecardProvider>().refreshScorecard(widget.matchId),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_cricket_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<ScorecardProvider>().refreshScorecard(widget.matchId),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}