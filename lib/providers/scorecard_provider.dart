import 'package:flutter/foundation.dart';
import 'dart:async';
import '../data/services/match_service.dart';
import '../data/models/scorecard_model.dart';
import '../data/models/match_model.dart';
import '../core/services/cache_service.dart';
import '../../core/services/socket_service.dart';


class ScorecardProvider extends ChangeNotifier {
  final MatchService _matchService = MatchService();
  final CacheService _cacheService = CacheService();
  final SocketService _socketService = SocketService();
  Timer? _refreshTimer;
  FullScorecard? _scorecard;
  Match? _match;
  bool _isLoading = false;
  String? _error;
  bool _hasData = false;
  DateTime? _lastUpdated;
  List<dynamic> _recentBalls = [];
  List<dynamic> _commentary = [];
  bool _isLive = false;
  
  List<dynamic> get recentBalls => _recentBalls;
  List<dynamic> get commentary => _commentary;
  bool get isLive => _isLive;

  FullScorecard? get scorecard => _scorecard;
  Match? get match => _match;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _hasData;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> loadScorecard(String matchId, {bool forceRefresh = false}) async {
    if (matchId.isEmpty) {
      _error = 'Invalid match ID';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!forceRefresh) {
        final cached = _cacheService.getCachedScorecard(matchId);
        if (cached != null) {
          _scorecard = FullScorecard.fromJson(cached);
          if (_scorecard != null) {
            _match = _scorecard!.match;
          }
          _hasData = true;
          _lastUpdated = DateTime.now();
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      final match = await _matchService.getMatchById(matchId, forceRefresh: forceRefresh);
      final scorecardData = await _matchService.getFullScorecard(matchId, match: match);
      
      Map<String, dynamic> safeScorecardData;
      debugPrint('📊 Raw scorecardData: $scorecardData');
      if (scorecardData is Map<String, dynamic>) {
        safeScorecardData = scorecardData;
      } else if (scorecardData is List && scorecardData.isNotEmpty) {
        final firstItem = scorecardData[0];
        safeScorecardData = firstItem as Map<String, dynamic>;
      } else {
        safeScorecardData = <String, dynamic>{};
      }
      
      _match = match;
      _scorecard = FullScorecard.fromJson(safeScorecardData);
      debugPrint('📋 Parsed scorecard innings count: ${_scorecard?.innings.length ?? 0}');
      
      // LIVE FALLBACK: Create current innings from match.score if no innings data
      if (_scorecard != null && 
          _scorecard!.innings.isEmpty && 
          _match != null && 
          _match!.status == 'live' &&
          _match!.score.team1 != null && 
          _match!.score.team2 != null) {
        debugPrint('🔄 Live fallback: Creating current innings from match.score');
        String battingTeam;
        TeamScore battingScore;
        final team1OversDec = (_match!.score.team1.overs ?? '0.0').split('.').length > 1 
            ? (_match!.score.team1.oversInDecimal) 
            : 0.0;
        final team2OversDec = (_match!.score.team2.overs ?? '0.0').split('.').length > 1 
            ? (_match!.score.team2.oversInDecimal) 
            : 0.0;
        debugPrint('🔄 team1Overs: "${_match!.score.team1.overs}", team2Overs: "${_match!.score.team2.overs}"');
        if (team1OversDec > team2OversDec) {
          battingTeam = _match!.team1;
          battingScore = _match!.score.team1;
        } else {
          battingTeam = _match!.team2;
          battingScore = _match!.score.team2;
        }
        
        final runs = battingScore.runs;
        final wickets = battingScore.wickets;
      final oversStr = battingScore.overs ?? '0.0';
      debugPrint('🔄 Parsing overs: "$oversStr"');
      
      // Ultra-robust overs parsing
      List<String> parts = oversStr.split('.');
      if (parts.length > 2) parts = parts.sublist(0, 2); // Clamp to 2 parts
      final oversInt = int.tryParse(parts[0] ?? '0') ?? 0;
      // Fixed duplicate lines removed
      
      // Ultra-safe balls string extraction
      String ballsStr = '0';
      if (parts.length > 1) {
        final ballsPart = parts[1];
        if (ballsPart.isNotEmpty) {
          ballsStr = ballsPart.length >= 2 ? ballsPart.substring(0, 2) : ballsPart;
        }
      }
      final ballsIntRaw = int.tryParse(ballsStr) ?? 0;
      final ballsInt = ballsIntRaw.clamp(0, 5);
      final totalBalls = oversInt * 6 + ballsInt;
      
      debugPrint('📐 Parsed: overs=$oversInt.$ballsInt, totalBalls=$totalBalls');
        
        _scorecard = FullScorecard(
          match: _match!,
          innings: [
            Innings(
              inningsNumber: 1,
              battingTeam: battingTeam,
              bowlingTeam: battingTeam == _match!.team1 ? _match!.team2 : _match!.team1,
              totalRuns: runs,
              totalWickets: wickets,
              totalOvers: oversInt.toDouble(),
              totalBalls: totalBalls,
              extras: const Extras(),
              isCompleted: false,
            ),
          ],
          batting: [],
          bowling: [],
          fallOfWickets: [],
        );
      }
      
      _cacheService.cacheScorecard(matchId, safeScorecardData);
      _hasData = _match != null; // Always true if we have match
      _lastUpdated = DateTime.now();
      debugPrint('✅ Scorecard ready: hasData=$_hasData, innings=${_scorecard!.innings.length}');

      
      if (match != null && match.status == 'live') {
        _cancelRefreshTimer();
        _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
          refreshScorecard(matchId);
        });
      }
    } catch (e) {
      debugPrint('❌ Scorecard load error: $e');
      
      String errorMsg;
      if (e.toString().contains('404')) {
        errorMsg = 'Scorecard not available yet for this match. Try live score or check later.';
      } else if (e.toString().contains('SocketException')) {
        errorMsg = 'Network error. Check your connection and try again.';
      } else {
        final errStr = e.toString();
        errorMsg = 'Scorecard load failed: ${errStr.length > 100 ? errStr.substring(0, 100) : errStr}';
      }
      
      _error = errorMsg;
      _hasData = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshScorecard(String matchId) async {
    await loadScorecard(matchId, forceRefresh: true);
  }

  void _loadStaticFallback(String matchId) {
    try {
      final now = DateTime.now();
      
      _match = Match(
        id: matchId,
        team1: 'Mumbai Indians',
        team2: 'Royal Challengers Bangalore',
        venue: const Venue(name: 'Nassau County Stadium', city: 'New York'),
        scheduledDate: now,
        score: MatchScore(
          team1: const TeamScore(runs: 0, wickets: 0, overs: '0.0'),
          team2: const TeamScore(runs: 0, wickets: 0, overs: '0.0'),
        ),
        format: 'T20',
        matchType: 'LEAGUE',
        status: 'live',
        createdAt: now,
        updatedAt: now,
      );
      
      _scorecard = FullScorecard(
        match: _match!,
        innings: [
          Innings(
            inningsNumber: 1,
            battingTeam: 'Mumbai Indians',
            bowlingTeam: 'Royal Challengers Bangalore',
            totalRuns: 0,
            totalWickets: 0,
            totalOvers: 0.0,
            extras: const Extras(wides: 0, noBalls: 0, byes: 0, legByes: 0, total: 0),
            isCompleted: false,
          ),
        ],
        batting: [],
        bowling: [],
        fallOfWickets: [],
        partnerships: [],
      );
      
      _hasData = true;
      debugPrint('✅ Clean fallback loaded');
    } catch (e) {
      debugPrint('❌ Fallback error: $e');
      _hasData = false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _cancelRefreshTimer();
    super.dispose();
  }
}

