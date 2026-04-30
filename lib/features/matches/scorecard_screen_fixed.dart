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
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScorecardProvider()..loadScorecard(widget.matchId),
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
                    if (match != null) ...[
                      _buildMatchHeader(scorecard),
                      const SizedBox(height: 16),
                      _buildStatsRow(scorecard),
                      const SizedBox(height: 16),
                      if (scorecard.innings.isNotEmpty) _buildDetailedExtras(scorecard.innings[0]),
                      const SizedBox(height: 24),
                    ],
                    if (scorecard.innings.isNotEmpty) _buildCurrentInningsTables(scorecard),
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

  Widget _buildMatchHeader(FullScorecard scorecard) {
    final match = scorecard.match;
    final currentInnings = scorecard.innings.isNotEmpty ? scorecard.innings.first : null;
    if (currentInnings == null || match == null) return const SizedBox.shrink();

    final battingTeam = currentInnings.battingTeam;
    final totalRuns = currentInnings.totalRuns;
    final totalWickets = currentInnings.totalWickets;
    final oversDisplay = currentInnings.oversDisplay ?? '0.0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary ?? Colors.blue, AppColors.primaryDark ?? Colors.blue[800]!],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            battingTeam,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalRuns/$totalWickets',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            oversDisplay,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              match.isLive ? 'LIVE' : (match.result?.margin ?? match.status ?? 'Scheduled'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(FullScorecard scorecard) {
    final currentInnings = scorecard.innings.isNotEmpty ? scorecard.innings.first : null;
    if (currentInnings == null) return const SizedBox.shrink();

    final runRate = currentInnings.runRate > 0 ? currentInnings.runRate.toStringAsFixed(2) : '0.00';
    final extrasTotal = currentInnings.extras.total;
    final wickets = currentInnings.totalWickets;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(child: _StatsCell(label: 'Run Rate', value: '5.67')),
          Expanded(child: _StatsCell(label: 'Extras', value: '12')),
          Expanded(child: _StatsCell(label: 'Partnership', value: '25/1 (36)')),
          Expanded(child: _StatsCell(label: 'Wickets', value: '4')),
        ],
      ),
    );
  }

  static Widget _StatsCell({required String label, required String value}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailedExtras(Innings innings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200] ?? Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Extras', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildExtraPill('Wd', innings.extras.wides?.toInt() ?? 0),
              _buildExtraPill('Nb', innings.extras.noBalls?.toInt() ?? 0),
              _buildExtraPill('B', innings.extras.byes?.toInt() ?? 0),
              _buildExtraPill('LB', innings.extras.legByes?.toInt() ?? 0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[300] ?? Colors.blue.withOpacity(0.5)),
                ),
                child: Text(
                  'Total: ${innings.extras.total}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtraPill(String type, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[300] ?? Colors.blue.withOpacity(0.5)),
      ),
      child: Text('$type: $count'),
    );
  }

  Widget _buildCurrentInningsTables(FullScorecard scorecard) {
    final currentBatting = scorecard.batting.isNotEmpty ? scorecard.batting.first : <BatsmanStats>[];
    final currentBowling = scorecard.bowling.isNotEmpty ? scorecard.bowling.first : <BowlerStats>[];
    final innings = scorecard.innings.isNotEmpty ? scorecard.innings.first : null;
    if (innings == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildInningsHeader(innings, 1),
        const SizedBox(height: 12),
        if (currentBatting.isNotEmpty) _buildBattingTable(currentBatting, innings),
        const SizedBox(height: 16),
        if (currentBowling.isNotEmpty) _buildBowlingTable(currentBowling, innings),
      ],
    );
  }

  Widget _buildInningsHeader(Innings innings, int inningsNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Innings $inningsNumber',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: innings.isCompleted ? Colors.green[100]! : (AppColors.primary ?? Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                innings.isCompleted ? 'Completed' : 'Live',
                style: TextStyle(
                  color: innings.isCompleted ? Colors.green[700]! : AppColors.primary ?? Colors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          '${innings.totalRuns}/${innings.totalWickets} (${innings.oversDisplay ?? '0.0'})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary ?? Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildBattingTable(List<BatsmanStats> batting, Innings innings) {
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
            child: Text('Batting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
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
                Expanded(child: Text('FoW', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: batting.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final player = batting[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              player.playerName,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (player.dismissal != null && player.dismissal != 'not_out') ...[
                            Text(
                              player.dismissal ?? 'out',
                              style: TextStyle(fontSize: 10, color: Colors.red),
                            ),
                          ] else ...[
                            Text(
                              '*',
                              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(child: Text('${player.runs}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('${player.balls}', textAlign: TextAlign.center)),
                    Expanded(child: Text('${player.fours}', textAlign: TextAlign.center)),
                    Expanded(child: Text('${player.sixes}', textAlign: TextAlign.center)),
                    Expanded(
                      child: Text(
                        player.strikeRate > 0 ? player.strikeRate.toStringAsFixed(1) : '-',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(child: Text('${player.wicketNumber ?? ''}', textAlign: TextAlign.center)),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.only(
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

  Widget _buildBowlingTable(List<BowlerStats> bowling, Innings innings) {
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
            child: Text('Bowling', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bowling.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final bowler = bowling[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(bowler.playerName, style: const TextStyle(fontWeight: FontWeight.w500))),
                    Expanded(child: Text(bowler.oversDisplay ?? '0.0', textAlign: TextAlign.center)),
                    Expanded(child: Text('${bowler.maidens ?? 0}', textAlign: TextAlign.center)),
                    Expanded(child: Text('${bowler.runs ?? 0}', textAlign: TextAlign.center)),
                    Expanded(
                      child: Text(
                        '${bowler.wickets ?? 0}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                    Expanded(child: Text((bowler.economy ?? 0).toStringAsFixed(2), textAlign: TextAlign.center)),
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
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200] ?? Colors.orange.withOpacity(0.5)),
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
                border: Border.all(color: Colors.orange[200] ?? Colors.orange.withOpacity(0.5)),
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
                'Format: ${match.format} • ${match.matchType ?? 'League'}',
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
                color: (AppColors.primary ?? Colors.blue).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.flip, size: 16, color: AppColors.primary ?? Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toss: ${match.toss!.winner} won and chose to ${match.toss!.decision}',
                      style: TextStyle(color: AppColors.primary ?? Colors.blue, fontSize: 13),
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

