import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/services/socket_service.dart';
import '../../data/services/match_service.dart';
import '../../data/services/team_service.dart';
import '../../data/models/scorecard_model.dart';
import '../../data/models/match_model.dart';
import '../../data/models/team_model.dart';
import '../../data/models/player_model.dart';
import 'live_score_control_screen.dart';
import 'toss_screen.dart';
import '../highlights/match_highlights_section.dart';
import '../highlights/match_live_stream_banner.dart';

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
    _tabController = TabController(length: 5, vsync: this);
    _loadMatchData();
    // Polling is the fallback; the socket below makes updates near-instant.
    _liveRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _match?.isLive == true && !_isLoading) {
        _loadMatchData(silent: true);
      }
    });
    _subscribeLiveUpdates();
  }

  final SocketService _socketService = SocketService();
  Timer? _socketDebounce;

  Future<void> _subscribeLiveUpdates() async {
    try {
      await _socketService.connect();
      _socketService.joinMatch(widget.matchId);
      for (final event in _liveEvents) {
        _socketService.listen(event, _onLiveEvent);
      }
    } catch (e) {
      debugPrint('Match socket unavailable, polling only: $e');
    }
  }

  static const _liveEvents = [
    'liveScoreUpdate',
    'scoreUpdated',
    'tossUpdate',
    'matchStarted',
    'lineupsUpdate',
  ];

  void _onLiveEvent(dynamic data) {
    final id = data is Map ? (data['matchId'] ?? data['_id'])?.toString() : null;
    if (id != null && id != widget.matchId) return;
    // A wicket fires several events at once; refresh once.
    _socketDebounce?.cancel();
    _socketDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted && !_isLoading) _loadMatchData(silent: true);
    });
  }

  @override
  void dispose() {
    _socketDebounce?.cancel();
    for (final event in _liveEvents) {
      _socketService.unlisten(event, _onLiveEvent);
    }
    _socketService.leaveMatch(widget.matchId);
    _liveRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  /// [silent] = background refresh: no full-screen loader, and a failed
  /// refresh keeps the score already on screen.
  Future<void> _loadMatchData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final match = await _matchService.getMatchById(widget.matchId);

      if (!match.isScheduled) {
        await _loadScorecardData(match);
      }
      await _loadSquads(match);

      if (!mounted) return;
      setState(() {
        _match = match;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silent && _match != null) return;
      setState(() {
        _error = friendlyError(e, fallback: 'Could not load match details.');
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
            Tab(icon: Icon(Icons.groups_2_outlined, size: 19), text: 'Squads'),
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
                      _buildSquadsTab(),
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
    // Scoring controls are for signed-in users only (guests just watch).
    final auth = context.watch<AuthProvider>();
    final bool signedIn = auth.status == AuthStatus.authenticated &&
        (auth.user?.role ?? '').toUpperCase() != 'GUEST';
    // Only the match creator runs live scoring; others just watch.
    final bool isScorer = signedIn &&
        (_match?.canBeScoredBy(auth.user?.id, role: auth.userRole) ?? false);
    final bool isLive = isScorer && _match?.isLive == true;
    final bool canStart = isScorer && _canStartLive();

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
              content: Text(friendlyError(e, fallback: 'Something went wrong. Please try again.')),
              backgroundColor: const Color(0xFFB71C1C)),
        );
      }
    }
  }

  Future<void> _loadSquads(Match match) async {
    final team1Id = _teamId(match.team1Data) ?? _teamId(match.team1);
    final team2Id = _teamId(match.team2Data) ?? _teamId(match.team2);
    final results = await Future.wait<List<Player>>([
      _loadTeamPlayers(team1Id),
      _loadTeamPlayers(team2Id),
    ]);
    _team1Players = results[0];
    _team2Players = results[1];
  }

  Future<List<Player>> _loadTeamPlayers(String? teamId) async {
    if (teamId == null || teamId.isEmpty) return const [];
    try {
      final data = await _teamService.getTeamWithPlayers(teamId);
      final players = data['players'];
      return players is List<Player> ? players : const [];
    } catch (e) {
      debugPrint('Team players fetch error: $e');
      return const [];
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
          MatchLiveStreamBanner(
            key: ValueKey('stream-${_match!.id}'),
            matchId: _match!.id,
          ),
          if ((_match!.isScheduled || _match!.isTeamSelecting || _match!.isReady) &&
              _match!.canBeScoredBy(context.watch<AuthProvider>().user?.id,
                  role: context.watch<AuthProvider>().userRole)) ...[
            const SizedBox(height: 16),
            _buildStartFlowCard(),
          ],
          const SizedBox(height: 16),
          _buildScoreStats(),
          if (!_match!.isScheduled) ...[
            const SizedBox(height: 16),
            MatchHighlightsSection(
              key: ValueKey('highlights-${_match!.id}'),
              matchId: _match!.id,
              matchTitle: '${_match!.team1} vs ${_match!.team2}',
            ),
          ],
          const SizedBox(height: 16),
          _buildBallByBallCard(),
          const SizedBox(height: 16),
          _buildFirstInningsCard(),
          const SizedBox(height: 16),
          _buildSecondInningsCard(),
          const SizedBox(height: 16),
          _buildSquadPreviewCard(),
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
    final resultText = _matchResultText(match);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        image: const DecorationImage(
          image: AssetImage('score 11/Match Detail Header 1080 x 520.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          opacity: 0.075,
        ),
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
              _buildMatchStatusChip(),
              const Spacer(),
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                '${_formatDate(match.scheduledDate)}  ${_formatTime(match.scheduledDate)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _buildTeamScoreBlock(match.team1, match.score.team1)),
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
                child: _buildTeamScoreBlock(match.team2, match.score.team2,
                    alignEnd: true),
              ),
            ],
          ),
          if (resultText.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: match.isCompleted
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF7F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: match.isCompleted
                      ? const Color(0xFFC8E6C9)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    match.isCompleted
                        ? Icons.emoji_events_outlined
                        : Icons.info_outline_rounded,
                    color: match.isCompleted
                        ? const Color(0xFF2E7D32)
                        : AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      resultText,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamScoreBlock(String name, TeamScore score,
      {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          '${score.runs}/${score.wickets}',
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '(${score.overs} ov)',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
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
              'Ball-by-ball updates appear here once scoring starts.',
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
    final runs = _toInt(ball['runs']);
    final extras = _toInt(ball['extras']);
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
                      ? 'Wicket${ball['wicketType'] != null ? ' - ${ball['wicketType'].toString().replaceAll('_', ' ')}' : ''}'
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

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
    // A rain-revised (DLS) target from the server wins over the plain one.
    final revised = match.result?.target ?? 0;
    if (revised > 0) return revised;
    final first = match.score.team1.innings <= match.score.team2.innings
        ? match.score.team1
        : match.score.team2;
    final second = identical(first, match.score.team1)
        ? match.score.team2
        : match.score.team1;
    final chaseStarted = second.runs > 0 || second.wickets > 0 || second.overs != '0.0';
    if (first.runs > 0 && (chaseStarted || match.isCompleted)) return first.runs + 1;
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
                  Text(
                    bat.dismissalDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: bat.isOut
                          ? const Color(0xFFCC3333)
                          : const Color(0xFF2E7D32),
                    ),
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
                  Text(
                    bat.dismissalDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: bat.isOut
                          ? const Color(0xFFCC3333)
                          : const Color(0xFF2E7D32),
                    ),
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

  // ==================== SQUADS TAB ====================
  Widget _buildSquadsTab() {
    if (_match == null) {
      return const Center(child: Text('Squad information not available'));
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSquadCard(_match!.team1, _team1Players),
          const SizedBox(height: 16),
          _buildSquadCard(_match!.team2, _team2Players),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSquadPreviewCard() {
    return Container(
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
              Icon(Icons.groups_2_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Playing Squad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(3),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMiniSquad(_match!.team1, _team1Players),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 118,
                color: Colors.grey.shade100,
              ),
              Expanded(
                child: _buildMiniSquad(_match!.team2, _team2Players),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSquad(String teamName, List<Player> players) {
    final names = players.take(4).map((p) => p.name).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 8),
        if (names.isEmpty)
          Text(
            'Squad loading / not available',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          )
        else
          ...names.map(
            (name) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
          ),
        if (players.length > 4)
          Text(
            '+${players.length - 4} more',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildSquadCard(String teamName, List<Player> players) {
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
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _initials(teamName),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Text(
                  '${players.length} players',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Squads appear here once teams are selected.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            )
          else
            ...players.map((player) => _buildSquadPlayerRow(player)),
        ],
      ),
    );
  }

  Widget _buildSquadPlayerRow(Player player) {
    final subtitle = [
      player.playerRole ?? player.role,
      player.battingStyle,
      player.bowlingStyle,
    ]
        .where((value) => value != null && value.trim().isNotEmpty)
        .map((value) => value!)
        .join(' • ');
    final imageUrl = player.profileImage ?? player.photo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEFF6FF),
            backgroundImage:
                imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? Text(
                    _initials(player.name),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle.isEmpty ? 'Player' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (player.jerseyNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                '#${player.jerseyNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF374151),
                ),
              ),
            ),
        ],
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
                '${_tossWinnerName(match)} won & chose to ${match.toss!.decision ?? 'bat/bowl'}'),
          ],
          if (_hasMeaningfulResult(match.result)) ...[
            Divider(height: 24, color: Colors.grey.shade100),
            _buildInfoTile(Icons.emoji_events_outlined, 'Result',
                _matchResultText(match)),
            if (match.result!.margin != null)
              _buildInfoTile(
                  Icons.trending_up_rounded, 'Margin', match.result!.margin!),
            if (match.result!.playerOfMatch != null)
              _buildInfoTile(Icons.star_outline_rounded, 'Player of Match',
                  _safePlayerName(match.result!.playerOfMatch!)),
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

  bool _hasMeaningfulResult(MatchResult? result) {
    if (result == null) return false;
    return [
      result.winner,
      result.margin,
      result.method,
      result.message,
      result.playerOfMatch,
    ].any((value) => value != null && value.trim().isNotEmpty);
  }

  String _matchResultText(Match match) {
    final result = match.result;
    if (_hasMeaningfulResult(result)) {
      if (result!.message != null && result.message!.trim().isNotEmpty) {
        return result.message!.trim();
      }
      final winner = _safeTeamOrResultName(match, result.winner);
      final margin = result.margin?.trim();
      final method = result.method?.trim();
      final buffer = StringBuffer();
      if (winner.isNotEmpty) {
        buffer.write('$winner won');
      }
      if (margin != null && margin.isNotEmpty) {
        buffer.write(buffer.isEmpty ? margin : ' by $margin');
      }
      if (method != null && method.isNotEmpty) {
        buffer.write(buffer.isEmpty ? method : ' ($method)');
      }
      if (buffer.isNotEmpty) return buffer.toString();
    }
    if (match.isLive) {
      final battingTeam =
          match.currentInnings == 2 ? _teamName(match, 2) : _teamName(match, 1);
      return '$battingTeam batting now';
    }
    if (match.isScheduled || match.isTeamSelecting || match.isReady) {
      return 'Match scheduled on ${_formatDate(match.scheduledDate)} at ${_formatTime(match.scheduledDate)}';
    }
    return match.status.replaceAll('_', ' ');
  }

  String? _teamId(dynamic value) {
    if (value is Map) {
      final id = value['_id'] ?? value['id'] ?? value['teamId'];
      return _looksLikeId(id?.toString()) ? id.toString() : null;
    }
    if (value is String && _looksLikeId(value)) return value;
    return null;
  }

  bool _looksLikeId(String? value) {
    if (value == null) return false;
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value.trim());
  }

  String _teamName(Match match, int teamNumber) {
    final data = teamNumber == 1 ? match.team1Data : match.team2Data;
    final raw = teamNumber == 1 ? match.team1 : match.team2;
    if (data is Map) {
      final value = data['name'] ?? data['teamName'] ?? data['shortName'];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && !_looksLikeId(text)) return text;
    }
    final text = raw.trim();
    return text.isEmpty || _looksLikeId(text) ? 'Team $teamNumber' : text;
  }

  String _tossWinnerName(Match match) {
    final winner = match.toss?.winner?.trim() ?? '';
    if (winner.isEmpty) return 'Team';
    if (winner == match.team1Id || winner == match.team1) return _teamName(match, 1);
    if (winner == match.team2Id || winner == match.team2) return _teamName(match, 2);
    return _looksLikeId(winner) ? 'Team' : winner;
  }

  String _safeTeamOrResultName(Match match, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '';
    if (text == match.team1Id || text == match.team1) return _teamName(match, 1);
    if (text == match.team2Id || text == match.team2) return _teamName(match, 2);
    return _looksLikeId(text) ? '' : text;
  }

  String _safePlayerName(String value) {
    final text = value.trim();
    if (text.isEmpty || _looksLikeId(text)) return 'Player';
    return text;
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'T';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }
}
