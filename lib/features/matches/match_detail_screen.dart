import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/services/match_service.dart';
import '../../data/services/team_service.dart';
import '../../data/models/scorecard_model.dart';
import '../../data/models/match_model.dart';
import '../../data/models/team_model.dart';
import '../../data/models/player_model.dart';
import 'live_score_control_screen.dart';
import 'toss_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MatchService _matchService = MatchService();
  final TeamService _teamService = TeamService();
  bool _isLoading = true;
  String? _error;
  Match? _match;
  Map<String, dynamic>? _scorecardData;
  List<Map<String, dynamic>> _ballByBall = [];
  Timer? _liveRefreshTimer;

  List<BatsmanStats> _firstInningsBatting = [];
  List<BowlerStats> _firstInningsBowling = [];
  List<BatsmanStats> _secondInningsBatting = [];
  List<BowlerStats> _secondInningsBowling = [];

  List<Player> _team1Players = [];
  List<Player> _team2Players = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMatchData();
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _match?.isLive == true && !_isLoading) {
        _loadMatchData();
      }
    });
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final match = await _matchService.getMatchById(widget.matchId);

      if (!match.isScheduled) {
        await _loadScorecardData(match);
      }

      setState(() {
        _match = match;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadScorecardData(Match match) async {
    try {
      final scorecardData =
          await _matchService.getFullScorecard(widget.matchId, match: match);
      if (scorecardData.isNotEmpty) {
        var batting =
            scorecardData['batting'] ?? scorecardData['battingScorecard'] ?? [];
        var bowling =
            scorecardData['bowling'] ?? scorecardData['bowlingScorecard'] ?? [];
        final innings = scorecardData['innings'];
        if (innings is List && innings.isNotEmpty) {
          batting = batting is List && batting.isNotEmpty
              ? batting
              : innings.first['battingScorecard'] ?? [];
          bowling = bowling is List && bowling.isNotEmpty
              ? bowling
              : innings.first['bowlingScorecard'] ?? [];
        }
        if (batting is List && batting.isNotEmpty) {
          if (batting.first is List) {
            final allBatting = batting as List;
            if (allBatting.isNotEmpty) {
              _firstInningsBatting = (allBatting[0] as List)
                  .map((p) =>
                      BatsmanStats.fromJson(p as Map<String, dynamic>))
                  .toList();
            }
            if (allBatting.length > 1) {
              _secondInningsBatting = (allBatting[1] as List)
                  .map((p) =>
                      BatsmanStats.fromJson(p as Map<String, dynamic>))
                  .toList();
            }
          } else {
            _firstInningsBatting = batting
                .map((p) =>
                    BatsmanStats.fromJson(p as Map<String, dynamic>))
                .toList();
          }
        }

        if (bowling is List && bowling.isNotEmpty) {
          if (bowling.first is List) {
            final allBowling = bowling as List;
            if (allBowling.isNotEmpty) {
              _firstInningsBowling = (allBowling[0] as List)
                  .map((p) =>
                      BowlerStats.fromJson(p as Map<String, dynamic>))
                  .toList();
            }
            if (allBowling.length > 1) {
              _secondInningsBowling = (allBowling[1] as List)
                  .map((p) =>
                      BowlerStats.fromJson(p as Map<String, dynamic>))
                  .toList();
            }
          } else {
            _firstInningsBowling = bowling
                .map((p) =>
                    BowlerStats.fromJson(p as Map<String, dynamic>))
                .toList();
          }
        }

        setState(() {
          _scorecardData = scorecardData;
          final balls = scorecardData['ballByBall'] ?? scorecardData['balls'];
          _ballByBall = balls is List
              ? balls
                  .whereType<Map>()
                  .map((ball) => Map<String, dynamic>.from(ball))
                  .toList()
                  .reversed
                  .toList()
              : [];
        });
      }
    } catch (e) {
      debugPrint('Scorecard fetch error: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadMatchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Match Details',
        showBackButton: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.scoreboard_outlined, size: 19), text: 'Score'),
            Tab(
                icon: Icon(Icons.sports_cricket_outlined, size: 19),
                text: 'Batting'),
            Tab(
                icon: Icon(Icons.sports_baseball_outlined, size: 19),
                text: 'Bowling'),
            Tab(icon: Icon(Icons.info_outline, size: 19), text: 'Info'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _error != null
              ? _buildErrorState(_error!)
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppColors.primary,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildScoreTab(),
                      _buildBattingTab(),
                      _buildBowlingTab(),
                      _buildInfoTab(),
                    ],
                  ),
                ),
      floatingActionButton:
          _match?.isLive == true || _canStartLive() ? _buildFloatingButtons() : null,
    );
  }

  bool _canStartLive() {
    if (_match == null) return false;
    final status = _match!.status.toLowerCase();
    return status == 'scheduled' || status == 'team_selecting' || status == 'ready';
  }

  Widget _buildFloatingButtons() {
    final bool isLive = _match?.isLive == true;
    final bool canStart = _canStartLive();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'match_refresh',
          mini: true,
          backgroundColor: Colors.white,
          elevation: 1,
          onPressed: _refreshData,
          child: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(height: 12),
        if (canStart)
          FloatingActionButton.extended(
            heroTag: 'start_live',
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 2,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Live',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            onPressed: _showStartLiveDialog,
          ),
        if (canStart) const SizedBox(height: 12),
        if (isLive)
          FloatingActionButton.extended(
            heroTag: 'live_control',
            backgroundColor: const Color(0xFFB71C1C),
            foregroundColor: Colors.white,
            elevation: 2,
            icon: const Icon(Icons.sports_cricket_rounded),
            label: const Text('Live Control',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LiveScoreControlScreen(matchId: widget.matchId),
              ),
            ),
          ),
      ],
    );
  }

  void _showStartLiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start Live Match',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        content: Text(
            'Start live scoring for ${_match?.team1} vs ${_match?.team2}?',
            style: const TextStyle(fontSize: 14, color: Color(0xFF555555))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startLiveMatch();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Start',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _startLiveMatch() async {
    try {
      setState(() => _isLoading = true);

      if (_match?.toss?.winner == null || _match?.toss?.decision == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TossScreen(matchId: widget.matchId)),
          ).then((_) => _loadMatchData());
        }
        return;
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveScoreControlScreen(
              matchId: widget.matchId,
              match: _match,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFFB71C1C)),
        );
      }
    }
  }

  // ==================== SCORE TAB ====================
  Widget _buildScoreTab() {
    if (_match == null) {
      return const Center(child: Text('No match data available'));
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMatchHeader(),
          if (_match!.isScheduled || _match!.isTeamSelecting || _match!.isReady) ...[
            const SizedBox(height: 16),
            _buildStartFlowCard(),
          ],
          const SizedBox(height: 16),
          _buildScoreStats(),
          const SizedBox(height: 16),
          _buildBallByBallCard(),
          const SizedBox(height: 16),
          _buildFirstInningsCard(),
          const SizedBox(height: 16),
          _buildSecondInningsCard(),
          const SizedBox(height: 16),
          _buildMatchInfoCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStartFlowCard() {
    final tossDone =
        _match?.toss?.winner != null && _match?.toss?.decision != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tossDone ? 'Ready for live scoring' : 'Toss pending',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            tossDone
                ? 'Open live control to initialize batting order, set striker, non-striker and bowler.'
                : 'Complete the toss once, then start live control from this match.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: tossDone
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LiveScoreControlScreen(
                                matchId: widget.matchId, match: _match)),
                      )
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                TossScreen(matchId: widget.matchId)),
                      ).then((_) => _loadMatchData()),
              icon: Icon(
                  tossDone ? Icons.sports_cricket_rounded : Icons.flip_rounded,
                  size: 18),
              label: Text(tossDone ? 'Open Live Control' : 'Do Toss'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHeader() {
    final match = _match!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
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
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${match.score.team1.runs}/${match.score.team1.wickets}',
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '(${match.score.team1.overs} ov)',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: AppColors.primary,
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
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${match.score.team2.runs}/${match.score.team2.wickets}',
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '(${match.score.team2.overs} ov)',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMatchStatusChip(),
        ],
      ),
    );
  }

  Widget _buildMatchStatusChip() {
    final match = _match!;
    Color bgColor;
    Color textColor;
    String statusText;
    IconData icon;

    if (match.isLive) {
      bgColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFB71C1C);
      statusText = 'LIVE';
      icon = Icons.fiber_manual_record;
    } else if (match.isCompleted) {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      statusText = 'COMPLETED';
      icon = Icons.check_circle_outline;
    } else {
      bgColor = const Color(0xFFFFF8E1);
      textColor = const Color(0xFFE65100);
      statusText = match.status;
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 13),
          const SizedBox(width: 5),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('Run Rate', _getCurrentRunRate().toStringAsFixed(2)),
          _buildStatDivider(),
          _buildStatItem('Extras', _getExtrasTotal().toString()),
          _buildStatDivider(),
          _buildStatItem('CRR', _getCurrentRunRate().toStringAsFixed(2)),
          _buildStatDivider(),
          _buildStatItem('Target', _getTarget().toString()),
        ],
      ),
    );
  }

  Widget _buildBallByBallCard() {
    final balls = _ballByBall.take(18).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ball by Ball',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (_match?.isLive == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'AUTO',
                    style: TextStyle(
                      color: Color(0xFFB71C1C),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (balls.isEmpty)
            Text(
              'Scoring start hote hi ball-by-ball yahan live dikhega.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            )
          else
            Column(
              children: balls.map(_buildBallRow).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBallRow(Map<String, dynamic> ball) {
    final runs = (ball['runs'] as num?)?.toInt() ?? 0;
    final extras = (ball['extras'] as num?)?.toInt() ?? 0;
    final isWicket = ball['wicket'] == true || ball['isWicket'] == true;
    final isWide = ball['isWide'] == true;
    final isNoBall = ball['isNoBall'] == true;
    final extraLabel = isWide ? 'Wd' : isNoBall ? 'Nb' : extras > 0 ? '+$extras' : '';
    final batsman = _playerName(ball['batsman']);
    final bowler = _playerName(ball['bowler']);
    final wagon = ball['wagonLabel']?.toString();
    final ballText = '${ball['overNumber'] ?? 0}.${ball['ballNumber'] ?? 0}';
    final badgeText = isWicket ? 'W' : '$runs$extraLabel';
    final badgeColor = isWicket
        ? const Color(0xFFB71C1C)
        : runs == 6
            ? const Color(0xFF7C3AED)
            : runs == 4
                ? const Color(0xFFF97316)
                : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor.withOpacity(0.25)),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$ballText  $batsman vs $bowler',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isWicket
                      ? 'Wicket${ball['wicketType'] != null ? ' - ${ball['wicketType']}' : ''}'
                      : wagon != null && wagon.isNotEmpty
                          ? '$runs run${runs == 1 ? '' : 's'} through $wagon'
                          : '${runs + extras} run${runs + extras == 1 ? '' : 's'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _playerName(dynamic value) {
    if (value is Map) {
      return (value['playerName'] ?? value['name'] ?? 'Player').toString();
    }
    return 'Player';
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF999999),
                  letterSpacing: 0.3)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111))),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 0.5, height: 36, color: Colors.grey.shade200);
  }

  double _getCurrentRunRate() {
    final match = _match!;
    final currentInnings = match.currentInnings == 1
        ? match.innings.firstOrNull
        : (match.innings.length > 1 ? match.innings[1] : null);
    if (currentInnings != null) {
      return currentInnings.runRate;
    }
    return 0.0;
  }

  int _getExtrasTotal() {
    final match = _match!;
    final currentInnings = match.currentInnings == 1
        ? match.innings.firstOrNull
        : (match.innings.length > 1 ? match.innings[1] : null);
    if (currentInnings != null) {
      return currentInnings.extras.total;
    }
    return 0;
  }

  int _getTarget() {
    final match = _match!;
    if (match.score.team1.runs > 0 && match.score.team2.runs == 0) {
      return match.score.team1.runs + 1;
    }
    return 0;
  }

  Widget _buildFirstInningsCard() {
    final match = _match!;
    final firstInnings = match.innings.isNotEmpty ? match.innings[0] : null;
    if (firstInnings == null) return const SizedBox.shrink();

    return _buildInningsCard(firstInnings, 1, match.team1, match.team2);
  }

  Widget _buildSecondInningsCard() {
    final match = _match!;
    final secondInnings =
        match.innings.length > 1 ? match.innings[1] : null;
    if (secondInnings == null) return const SizedBox.shrink();

    return _buildInningsCard(secondInnings, 2, match.team2, match.team1);
  }

  Widget _buildInningsCard(
      Innings innings, int inningsNumber, String battingTeam, String bowlingTeam) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInningsTitle(innings, inningsNumber, battingTeam, bowlingTeam),
          _buildSimpleBattingTable(innings),
          _buildExtrasRow(innings.extras),
        ],
      ),
    );
  }

  Widget _buildInningsTitle(
      Innings innings, int inningsNumber, String battingTeam, String bowlingTeam) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Innings $inningsNumber',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                '$battingTeam vs $bowlingTeam',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${innings.totalRuns}/${innings.totalWickets} (${innings.oversDisplay})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBattingTable(Innings innings) {
    final isFirstInnings =
        innings.inningsNumber == 1 || _match?.innings.isEmpty == true;
    final battingData =
        isFirstInnings ? _firstInningsBatting : _secondInningsBatting;
    final displayBatting =
        battingData.isNotEmpty ? battingData : <BatsmanStats>[];

    if (displayBatting.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No batting data available',
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DataTable(
        columnSpacing: 18,
        horizontalMargin: 8,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 56,
        headingRowHeight: 36,
        headingRowColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => const Color(0xFFF8F8F8),
        ),
        dividerThickness: 0.5,
        columns: const [
          DataColumn(
              label: Text('Batsman',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('R',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('B',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('4s',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('6s',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('SR',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
        ],
        rows: displayBatting.map((bat) {
          return DataRow(cells: [
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bat.playerName.isNotEmpty && bat.playerName != 'Unknown'
                        ? bat.playerName
                        : (bat.playerId.isNotEmpty ? bat.playerId : 'Unknown'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xFF111111)),
                  ),
                  if (bat.howOut != null && bat.howOut != 'not out')
                    Text(
                      bat.howOut!,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFAAAAAA)),
                    ),
                ],
              ),
            ),
            DataCell(Text(bat.runs.toString(),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary))),
            DataCell(Text(bat.balls.toString(),
                style: const TextStyle(fontSize: 13, color: Color(0xFF333333)))),
            DataCell(Text(bat.fours.toString(),
                style: const TextStyle(fontSize: 13, color: Color(0xFF333333)))),
            DataCell(Text(bat.sixes.toString(),
                style: const TextStyle(fontSize: 13, color: Color(0xFF333333)))),
            DataCell(Text(bat.strikeRate.toStringAsFixed(1),
                style: const TextStyle(fontSize: 13, color: Color(0xFF333333)))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildExtrasRow(Extras extras) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Extras:',
            style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          if (extras.wides > 0) _extraBadge('wd ${extras.wides}'),
          if (extras.noBalls > 0) _extraBadge('nb ${extras.noBalls}'),
          if (extras.byes > 0) _extraBadge('b ${extras.byes}'),
          if (extras.legByes > 0) _extraBadge('lb ${extras.legByes}'),
          const Spacer(),
          Text(
            'Total: ${extras.total}',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  Widget _extraBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
    );
  }

  // ==================== BATTING TAB ====================
  Widget _buildBattingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Batting Statistics',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF111111)),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            _buildDetailedBattingTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBattingTable() {
    final allBatting = [..._firstInningsBatting, ..._secondInningsBatting];
    final displayBatting = allBatting.isNotEmpty ? allBatting : <BatsmanStats>[];

    if (displayBatting.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('No batting data available',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DataTable(
        columnSpacing: 16,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 60,
        headingRowHeight: 38,
        headingRowColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => const Color(0xFFF7F9FF),
        ),
        dividerThickness: 0.5,
        columns: const [
          DataColumn(
              label: Text('BATSMAN',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('RUNS',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('BALLS',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('4s',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('6s',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('SR',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
        ],
        rows: displayBatting.map((bat) {
          return DataRow(cells: [
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bat.playerName.isNotEmpty && bat.playerName != 'Unknown'
                        ? bat.playerName
                        : (bat.playerId.isNotEmpty ? bat.playerId : 'Unknown'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF111111)),
                  ),
                  if (bat.howOut != null && bat.howOut != 'not out')
                    Text(
                      bat.howOut!,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFCC3333)),
                    ),
                ],
              ),
            ),
            DataCell(Text(bat.runs.toString(),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary))),
            DataCell(Text(bat.balls.toString(),
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)))),
            DataCell(Text(bat.fours.toString(),
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)))),
            DataCell(Text(bat.sixes.toString(),
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)))),
            DataCell(Text(bat.strikeRate.toStringAsFixed(1),
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)))),
          ]);
        }).toList(),
      ),
    );
  }

  // ==================== BOWLING TAB ====================
  Widget _buildBowlingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Bowling Statistics',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF111111)),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            _buildDetailedBowlingTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBowlingTable() {
    final allBowling = [..._firstInningsBowling, ..._secondInningsBowling];
    final displayBowling = allBowling.isNotEmpty ? allBowling : <BowlerStats>[];

    if (displayBowling.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('No bowling data available',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DataTable(
        columnSpacing: 16,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 60,
        headingRowHeight: 38,
        headingRowColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => const Color(0xFFF7F9FF),
        ),
        dividerThickness: 0.5,
        columns: const [
          DataColumn(
              label: Text('BOWLER',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('O',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('M',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('R',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('W',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
          DataColumn(
              label: Text('ECON',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF888888)))),
        ],
        rows: displayBowling.map((bowl) {
          return DataRow(cells: [
            DataCell(Text(
              bowl.playerName.isNotEmpty && bowl.playerName != 'Unknown'
                  ? bowl.playerName
                  : (bowl.playerId.isNotEmpty ? bowl.playerId : 'Unknown'),
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF111111)),
            )),
            DataCell(Text(bowl.oversDisplay,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)))),
            DataCell(Text(bowl.maidens.toString(),
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)))),
            DataCell(Text(bowl.runs.toString(),
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)))),
            DataCell(Text(bowl.wickets.toString(),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary))),
            DataCell(Text(bowl.economy.toStringAsFixed(1),
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)))),
          ]);
        }).toList(),
      ),
    );
  }

  // ==================== INFO TAB ====================
  Widget _buildInfoTab() {
    if (_match == null) {
      return const Center(child: Text('Match information not available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildOfficialsCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final match = _match!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Information',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF111111)),
          ),
          const SizedBox(height: 14),
          _buildInfoTile(Icons.category_outlined, 'Format', match.format),
          _buildInfoTile(Icons.sports_cricket_outlined, 'Match Type', match.matchType),
          _buildInfoTile(
              Icons.location_on_outlined, 'Venue', match.venue?.name ?? 'TBD'),
          _buildInfoTile(Icons.calendar_today_outlined, 'Date',
              _formatDate(match.scheduledDate)),
          _buildInfoTile(
              Icons.access_time_outlined, 'Time', _formatTime(match.scheduledDate)),
          if (match.toss != null) ...[
            Divider(height: 24, color: Colors.grey.shade100),
            _buildInfoTile(Icons.swap_horiz_rounded, 'Toss',
                '${match.toss!.winner} won & chose to ${match.toss!.decision}'),
          ],
          if (match.result != null) ...[
            Divider(height: 24, color: Colors.grey.shade100),
            _buildInfoTile(Icons.emoji_events_outlined, 'Result',
                match.result!.winner ?? 'N/A'),
            if (match.result!.margin != null)
              _buildInfoTile(
                  Icons.trending_up_rounded, 'Margin', match.result!.margin!),
            if (match.result!.playerOfMatch != null)
              _buildInfoTile(Icons.star_outline_rounded, 'Player of Match',
                  match.result!.playerOfMatch!),
          ],
        ],
      ),
    );
  }

  Widget _buildOfficialsCard() {
    final match = _match!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Officials',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF111111)),
          ),
          const SizedBox(height: 14),
          _buildInfoTile(Icons.person_outline_rounded, 'Umpire 1',
              match.officials?.umpire1 ?? 'TBD'),
          _buildInfoTile(Icons.person_outline_rounded, 'Umpire 2',
              match.officials?.umpire2 ?? 'TBD'),
          _buildInfoTile(Icons.assignment_ind_outlined, 'Referee',
              match.officials?.referee ?? 'TBD'),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111111)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInfoCard() {
    final match = _match!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Venue Details',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF111111)),
          ),
          const SizedBox(height: 14),
          if (match.venue != null) ...[
            _buildInfoTile(Icons.location_on_outlined, 'Venue', match.venue!.name),
            if (match.venue!.city != null)
              _buildInfoTile(
                  Icons.location_city_outlined, 'City', match.venue!.city!),
            if (match.venue!.state != null)
              _buildInfoTile(Icons.map_outlined, 'State', match.venue!.state!),
            if (match.venue!.country != null)
              _buildInfoTile(
                  Icons.flag_outlined, 'Country', match.venue!.country!),
          ],
          const SizedBox(height: 14),
          const Text(
            'Weather & Pitch',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF333333)),
          ),
          const SizedBox(height: 8),
          if (match.weather != null) ...[
            _buildInfoTile(Icons.wb_sunny_outlined, 'Condition',
                match.weather!.condition ?? 'N/A'),
            if (match.weather!.temperature != null)
              _buildInfoTile(Icons.thermostat_outlined, 'Temperature',
                  '${match.weather!.temperature}°C'),
            if (match.weather!.humidity != null)
              _buildInfoTile(Icons.water_drop_outlined, 'Humidity',
                  '${match.weather!.humidity}%'),
          ],
          if (match.pitch != null) ...[
            _buildInfoTile(
                Icons.grass_outlined, 'Pitch Type', match.pitch!.type ?? 'N/A'),
            if (match.pitch!.batting != null)
              _buildInfoTile(Icons.sports_cricket_outlined, 'Batting',
                  match.pitch!.batting!),
            if (match.pitch!.dew != null)
              _buildInfoTile(Icons.water_outlined, 'Dew Factor',
                  match.pitch!.dew == true ? 'Yes' : 'No'),
          ],
        ],
      ),
    );
  }

  // ==================== LOADING & ERROR STATES ====================
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: index == 0 ? 160 : 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
          Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Unable to load match',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $ampm';
  }
}
