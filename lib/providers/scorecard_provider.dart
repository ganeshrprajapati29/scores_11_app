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
          try {
            _scorecard = FullScorecard.fromJson(cached);
            if (_scorecard != null) {
              _match = _scorecard!.match;
            }
            _hasData = true;
            _lastUpdated = DateTime.now();
            _isLoading = false;
            notifyListeners();
            return;
          } catch (e) {
            debugPrint('⚠️ Error parsing cached scorecard: $e');
          }
        }
      }

      final match = await _matchService.getMatchById(matchId, forceRefresh: forceRefresh);
      _match = match;
      
      FullScorecard? fullScorecard;
      try {
        final scorecardData = await _matchService.getFullScorecard(matchId, match: match);
        
        if (scorecardData != null) {
          Map<String, dynamic> safeScorecardData;
          if (scorecardData is Map<String, dynamic>) {
            safeScorecardData = scorecardData;
          } else if (scorecardData is List && scorecardData.isNotEmpty) {
            safeScorecardData = scorecardData[0] as Map<String, dynamic>;
          } else {
            safeScorecardData = _createScorecardFromMatch(match);
          }
          fullScorecard = FullScorecard.fromJson(safeScorecardData);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Scorecard API error: $e');
      }
      
      if (fullScorecard == null || fullScorecard.innings.isEmpty) {
        debugPrint('🔄 Creating scorecard from match data');
        fullScorecard = _createFullScorecardFromMatch(match);
      }
      
      _scorecard = fullScorecard;
      _match = match;
      
      // ✅ FIXED: Safe caching with error handling
      if (_scorecard != null) {
        try {
          final scorecardJson = _scorecard!.toJson();
          _cacheService.cacheScorecard(matchId, scorecardJson);
        } catch (e) {
          debugPrint('❌ Error caching scorecard: $e');
        }
      }
      
      _hasData = true;
      _lastUpdated = DateTime.now();
      _isLive = match.status == 'live';
      
      if (kDebugMode) debugPrint('✅ Scorecard ready: match=${match.team1} vs ${match.team2}, status=${match.status}, innings=${_scorecard?.innings.length ?? 0}');
      
      if (match.status == 'live') {
        _setupAutoRefresh(matchId);
      }
      
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Scorecard load error: $e');
      _error = 'Unable to load scorecard. Please check your connection.';
      _hasData = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  FullScorecard _createFullScorecardFromMatch(Match match) {
    List<Innings> innings = [];
    
    final team1Innings = Innings(
      inningsNumber: 1,
      battingTeam: match.team1,
      bowlingTeam: match.team2,
      totalRuns: match.score.team1.runs,
      totalWickets: match.score.team1.wickets,
      totalOvers: match.score.team1.oversInDecimal,
      totalBalls: (match.score.team1.oversInDecimal * 6).toInt(),
      extras: const Extras(),
      isCompleted: match.status == 'completed' || match.score.team2.runs > 0,
    );
    innings.add(team1Innings);
    
    if (match.score.team2.runs > 0 || match.status == 'live' || match.status == 'completed') {
      final team2Innings = Innings(
        inningsNumber: 2,
        battingTeam: match.team2,
        bowlingTeam: match.team1,
        totalRuns: match.score.team2.runs,
        totalWickets: match.score.team2.wickets,
        totalOvers: match.score.team2.oversInDecimal,
        totalBalls: (match.score.team2.oversInDecimal * 6).toInt(),
        extras: const Extras(),
        isCompleted: match.status == 'completed',
      );
      innings.add(team2Innings);
    }
    
    return FullScorecard(
      match: match,
      innings: innings,
      batting: [],
      bowling: [],
      fallOfWickets: [],
      partnerships: [],
    );
  }
  
  Map<String, dynamic> _createScorecardFromMatch(Match match) {
    return {
      'match': match.toJson(),
      'innings': [],
      'batting': [],
      'bowling': [],
      'fallOfWickets': [],
      'partnerships': [],
    };
  }
  
  void _setupAutoRefresh(String matchId) {
    _cancelRefreshTimer();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_match?.status == 'live') {
        refreshScorecard(matchId);
      } else {
        _cancelRefreshTimer();
      }
    });
  }

  Future<void> refreshScorecard(String matchId) async {
    await loadScorecard(matchId, forceRefresh: true);
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