import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/scorecard_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../data/models/scorecard_model.dart';
import '../../../data/models/match_model.dart';

class ScorecardScreen extends StatefulWidget {
  final String matchId;

  const ScorecardScreen({super.key, required this.matchId});

@override
  _ScorecardScreenState createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  ScorecardProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = Provider.of<ScorecardProvider>(context, listen: false);
      if (_provider != null) {
        _provider!.loadScorecard(widget.matchId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Scorecard',
          showBackButton: true,
          actions: [
            Consumer<ScorecardProvider>(
              builder: (context, provider, child) => IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : () => provider.refreshScorecard(widget.matchId),
              ),
            ),
          ],
        ),
        body: Consumer<ScorecardProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading scorecard...'),
                  ],
                ),
              );
            }
            
            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : () => provider.refreshScorecard(widget.matchId),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!provider.hasData || provider.scorecard == null) {
              return RefreshIndicator(
                onRefresh: () => provider.refreshScorecard(widget.matchId),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  children: [
                    Icon(Icons.scoreboard, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No scorecard data available',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull to refresh or check back later',
                      style: TextStyle(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final scorecard = provider.scorecard!;
            final match = scorecard.match;
            
            return RefreshIndicator(
              onRefresh: () => provider.refreshScorecard(widget.matchId),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (match != null) _buildMatchHeader(match),
                    const SizedBox(height: 24),
                    _buildInningsSummary(scorecard),
                    const SizedBox(height: 24),
                    ..._buildInningsSections(scorecard),
                    if (scorecard.fallOfWickets.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildFallOfWickets(scorecard.fallOfWickets),
                    ],
                    const SizedBox(height: 24),
                    _buildMatchInfo(match),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMatchHeader(Match match) {
    // Safely get scores
    final team1Score = '${match.score.team1.runs}/${match.score.team1.wickets} (${match.score.team1.overs})';
    final team2Score = '${match.score.team2.runs}/${match.score.team2.wickets} (${match.score.team2.overs})';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team1Score,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team2Score,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: match.isLive ? AppColors.error : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              match.isLive ? 'LIVE' : (match.result?.margin ?? match.status),
              style: TextStyle(
                color: match.isLive ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${match.venue?.name ?? ''}, ${match.format}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInningsSummary(FullScorecard scorecard) {
    if (scorecard.innings.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Innings Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: scorecard.innings.asMap().entries.map((entry) {
              final innings = entry.value;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      'Innings ${entry.key + 1}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${innings.totalRuns}/${innings.totalWickets}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      innings.oversDisplay,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (innings.runRate > 0)
                      Text(
                        'RR: ${innings.runRate.toStringAsFixed(2)}',
                        style: TextStyle(color: AppColors.primary, fontSize: 11),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInningsSections(FullScorecard scorecard) {
    final List<Widget> sections = [];
    
    for (int i = 0; i < scorecard.innings.length; i++) {
      final innings = scorecard.innings[i];
      final batting = scorecard.batting.length > i ? scorecard.batting[i] : [];
      final bowling = scorecard.bowling.length > i ? scorecard.bowling[i] : [];
      
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInningsHeader(innings, i + 1),
            const SizedBox(height: 12),
            if (batting.isNotEmpty) _buildBattingTable(batting, innings),
            const SizedBox(height: 16),
            if (bowling.isNotEmpty) _buildBowlingTable(bowling, innings),
            const SizedBox(height: 24),
          ],
        ),
      );
    }
    
    return sections;
  }

  Widget _buildInningsHeader(Innings innings, int inningsNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Innings $inningsNumber',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: innings.isCompleted ? Colors.green[100] : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                innings.isCompleted ? 'Completed' : 'In Progress',
                style: TextStyle(
                  color: innings.isCompleted ? Colors.green[700] : AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          '${innings.totalRuns}/${innings.totalWickets} (${innings.oversDisplay})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildBattingTable(List<dynamic> batting, Innings innings) {
    final List<BatsmanStats> batsmanStats = batting.cast<BatsmanStats>(); // Safe cast
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Batting',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.grey[50],
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Batsman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('4s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('6s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('SR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          // Players List
          ...batting.map((player) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.playerName,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      if (player.dismissal != null && player.dismissal != 'not_out')
                        Text(
                          player.dismissal ?? 'out',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Expanded(child: Text(player.runs.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text(player.balls.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(player.fours.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(player.sixes.toString(), textAlign: TextAlign.center)),
                Expanded(
                  child: Text(
                    player.strikeRate > 0 ? player.strikeRate.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          )),
          // Extras Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Extras', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('${innings.extras.total}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBowlingTable(List<dynamic> bowling, Innings innings) {
    final List<BowlerStats> bowlerStats = bowling.cast<BowlerStats>(); // Safe cast
    if (bowlerStats.isEmpty) return const SizedBox.shrink();
    if (bowling.isEmpty) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Bowling',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.grey[50],
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('O', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('W', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('Econ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          // Bowlers List
          ...bowling.map((bowler) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(bowler.playerName, style: const TextStyle(fontWeight: FontWeight.w500))),
                Expanded(child: Text(bowler.oversDisplay, textAlign: TextAlign.center)),
                Expanded(child: Text(bowler.maidens.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(bowler.runs.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(bowler.wickets.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text(bowler.economy.toStringAsFixed(2), textAlign: TextAlign.center)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFallOfWickets(List<FallOfWicket> wickets) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 20, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Fall of Wickets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: wickets.map((wicket) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                '${wicket.wicket}-${wicket.batsman} (${wicket.runs}, ${wicket.overs})',
                style: const TextStyle(fontSize: 12),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInfo(Match? match) {
    if (match == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (match.venue != null) ...[
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${match.venue!.name}${match.venue!.city != null ? ', ${match.venue!.city}' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(Icons.sports_cricket, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Format: ${match.format} • ${match.matchType}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                _formatDate(match.scheduledDate),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          if (match.toss != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.flip, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toss: ${match.toss!.winner} won and chose to ${match.toss!.decision}',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (match.result != null && match.result!.playerOfMatch != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.emoji_events, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Player of the Match: ${match.result!.playerOfMatch}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}