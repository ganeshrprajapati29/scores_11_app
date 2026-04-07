import 'package:flutter/foundation.dart';
import 'dart:async';
import '../data/services/match_service.dart';
import '../data/models/scorecard_model.dart';
import '../data/models/match_model.dart';
import '../core/services/cache_service.dart';

class ScorecardProvider extends ChangeNotifier {
  final MatchService _matchService = MatchService();
  final CacheService _cacheService = CacheService();
  Timer? _refreshTimer;
  FullScorecard? _scorecard;
  Match? _match;
  bool _isLoading = false;
  String? _error;
  bool _hasData = false;
  DateTime? _lastUpdated;

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
      final scorecardData = await _matchService.getFullScorecard(matchId);
      
      Map<String, dynamic> safeScorecardData;
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
      
      _cacheService.cacheScorecard(matchId, scorecardData);
      _hasData = true;
      _lastUpdated = DateTime.now();
      
      if (match != null && match.status == 'live') {
        _cancelRefreshTimer();
        _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
          refreshScorecard(matchId);
        });
      }
    } catch (e) {
      debugPrint('❌ Scorecard load error: $e');
      _error = 'No scorecard data available. Check backend server. Error: ${e.toString()}';
      _hasData = false;
      // ✅ REMOVED FALLBACK - show real error to debug
      // _loadStaticFallback(matchId);
    } finally {
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

