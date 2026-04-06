import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/scorecard_provider.dart';
import '../../../data/services/match_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../data/models/scorecard_model.dart';

class ScorecardScreen extends StatelessWidget {
  final String matchId;

  const ScorecardScreen({super.key, required this.matchId});

@override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScorecardProvider()..loadScorecard(matchId),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Scorecard',
          actions: [
            Consumer<ScorecardProvider>(
              builder: (context, provider, child) => IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : () => provider.refreshScorecard(matchId),
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
                      onPressed: provider.isLoading ? null : () => provider.refreshScorecard(matchId),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!provider.hasData || provider.scorecard == null) {
              return RefreshIndicator(
                onRefresh: () => provider.refreshScorecard(matchId),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  children: [
                    Icon(Icons.sports_scoreboard, size: 80, color: Colors.grey),
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
            return RefreshIndicator(
              onRefresh: () => provider.refreshScorecard(matchId),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMatchHeader(scorecard.match ?? Match(id: matchId)),
                    const SizedBox(height: 24),
                    _buildInningsSummary(scorecard),
                    const SizedBox(height: 24),
                    ...scorecard.innings.asMap().entries.map((entry) {
                      final inningsIndex = entry.key;
                      final innings = entry.value;
                      return _buildInningsSection(
                        innings, 
                        inningsIndex, 
                        scorecard.batting.length > inningsIndex ? scorecard.batting[inningsIndex] : [],
                      );
                    }).toList(),
                    if (scorecard.fallOfWickets.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildFallOfWickets(scorecard.fallOfWickets),
                    ],
                    const SizedBox(height: 24),
                    _buildPartnerships(scorecard),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.shade700],
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${match.team1Score ?? 0}/${match.team1Wickets ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'VS',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      match.team2,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${match.team2Score ?? 0}/${match.team2Wickets ?? 0}',
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
          const SizedBox(height: 12),
          Text(
            match.status ?? 'Match in Progress',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${match.venue ?? ''}, ${match.format}',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildInningsSummary(FullScorecard scorecard) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Innings Summary',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${innings.totalRuns}/${innings.totalWickets}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${innings.totalOvers.toStringAsFixed(1)} overs',
                      style: TextStyle(color: Colors.grey[600]),
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

  Widget _buildInningsSection(Innings innings, int inningsIndex, List<BatsmanStats> batting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Innings ${inningsIndex + 1}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: Text('Batsman', style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(child: Text('4s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(child: Text('6s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                    const Expanded(child: Text('SR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Players
              ...batting.map((player) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(player.playerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          if (player.dismissal != null)
                            Text(
                              player.dismissal!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                    Expanded(child: Text(player.runs.toString(), textAlign: TextAlign.center)),
                    Expanded(child: Text(player.balls.toString(), textAlign: TextAlign.center)),
                    Expanded(child: Text(player.fours.toString(), textAlign: TextAlign.center)),
                    Expanded(child: Text(player.sixes.toString(), textAlign: TextAlign.center)),
                    Expanded(
                      child: Text(
                        player.strikeRate > 0 ? '${player.strikeRate.toStringAsFixed(1)}' : '-',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Extras', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('${innings.extras ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFallOfWickets(List<FallOfWicket> wickets) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fall of Wickets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...wickets.map((wicket) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('${wicket.wicket} - ', style: const TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(wicket.batsman)),
                Text('${wicket.runs} (${wicket.partnership})'),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPartnerships(FullScorecard scorecard) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Partnership',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: Text('Batsmen: Rohit Sharma, Suryakumar Yadav')),
              Text('45 (4.2)'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: const Text('Run Rate')),
              const Text('11.25', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              Expanded(child: const Text('Required Rate')),
              const Text('12.5', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}

