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
  bool _isLive = false;

  FullScorecard? get scorecard => _scorecard;
  Match? get match => _match;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _hasData;
  bool get isLive => _isLive;

  // ===============================
  // 🔥 MAIN FUNCTION
  // ===============================
  Future<void> loadScorecard(String matchId, {bool forceRefresh = false}) async {
    if (matchId.isEmpty) {
      _error = 'Invalid match ID';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ CACHE FIRST
      if (!forceRefresh) {
        final cached = _cacheService.getCachedScorecard(matchId);

        if (cached != null) {
          try {
            _scorecard = FullScorecard.fromJson(cached);
            _match = _scorecard?.match;
            _hasData = true;
            _isLoading = false;
            notifyListeners();
            return;
          } catch (e) {
            _cacheService.clearScorecard(matchId);
          }
        }
      }

      // ✅ FETCH MATCH
      final match = await _matchService.getMatchById(matchId);
      _match = match;

      FullScorecard? fullScorecard;

// ✅ FETCH SCORECARD - Use same endpoint as website
      // Don't throw error - just use fallback if API fails
      try {
        debugPrint('📡 Fetching scorecard from API...');
        final data = await _matchService.getFullScorecard(matchId, match: match);

        if (data != null && data.isNotEmpty) {
          debugPrint('✅ Scorecard API data received');
          
          // Handle website format directly - no transformation needed
          // The API returns: runs, wickets, overs, runRate, extras, battingScorecard, bowlingScorecard
          fullScorecard = _createScorecardFromApiData(data, match);
        }
      } catch (e) {
        debugPrint("⚠️ Scorecard API error (using fallback): $e");
        // Silently continue to fallback - don't show error
      }

      // ✅ FALLBACK (Using match data)
      if (fullScorecard == null || (fullScorecard.innings.isEmpty)) {
        debugPrint('🔄 Using fallback scorecard from match data');
        fullScorecard = _createFallbackScorecard(match);
      }

      _scorecard = fullScorecard;
      _hasData = true;
      _isLive = match.status == 'live';

      // ✅ CACHE SAVE SAFE
      try {
        _cacheService.cacheScorecard(matchId, _scorecard!.toJson());
      } catch (e) {
        debugPrint("Cache error: $e");
      }

// ✅ AUTO REFRESH for live matches
if (_isLive) {
        _startAutoRefresh(matchId);
      }

    } catch (e) {
      debugPrint('⚠️ Load scorecard error (using fallback): $e');
      // Don't show error to user - use fallback scorecard from match data
      // If we got the match, use it to create scorecard
      final matchData = _match;
      if (matchData != null) {
        _scorecard = _createFallbackScorecard(matchData);
        _hasData = true;
        _error = null; // Clear error - we have fallback data
      } else {
        // No match data either - show error
        _error = 'Failed to load scorecard';
        _hasData = false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// ===============================
  // 🔥 CREATE SCORECARD FROM API DATA
  // ===============================
  FullScorecard _createScorecardFromApiData(Map<String, dynamic> data, Match match) {
    try {
      // Handle multiple data formats from different endpoints
      // Website format: runs, wickets, overs, runRate, extras, battingScorecard, bowlingScorecard
      // API format: innings, batting, bowling
      dynamic runs = data['runs'];
      dynamic wickets = data['wickets'];
      dynamic overs = data['overs'];
      dynamic runRate = data['runRate'];
      dynamic extras = data['extras'] ?? {};
      dynamic battingScorecard = data['battingScorecard'] ?? data['batting'] ?? [];
      dynamic bowlingScorecard = data['bowlingScorecard'] ?? data['bowling'] ?? [];
      dynamic partnership = data['partnership'] ?? {};
      
      // If innings array exists in data, extract first innings data
      if (data['innings'] != null && data['innings'] is List && (data['innings'] as List).isNotEmpty) {
        final inningsData = (data['innings'] as List)[0];
        runs = runs ?? inningsData['totalRuns'];
        wickets = wickets ?? inningsData['totalWickets'];
        overs = overs ?? inningsData['totalOvers'];
        extras = extras ?? inningsData['extras'] ?? {};
      }
      
      // Build innings from API data
      List<Innings> inningsList = [];
      
      // First innings
      inningsList.add(Innings(
        inningsNumber: 1,
        battingTeam: match.team1,
        bowlingTeam: match.team2,
        totalRuns: _parseInt(runs),
        totalWickets: _parseInt(wickets),
        totalOvers: _parseOvers(overs),
        totalBalls: (_parseOvers(overs) * 6).toInt(),
        extras: _parseExtras(extras),
        isCompleted: match.status != 'live',
      ));

      // Second innings if needed
      if (match.score.team2.runs > 0) {
        inningsList.add(Innings(
          inningsNumber: 2,
          battingTeam: match.team2,
          bowlingTeam: match.team1,
          totalRuns: match.score.team2.runs,
          totalWickets: match.score.team2.wickets,
          totalOvers: match.score.team2.oversInDecimal,
          totalBalls: (match.score.team2.oversInDecimal * 6).toInt(),
          extras: const Extras(),
          isCompleted: match.status == 'completed',
        ));
      }

      // Parse batting data
      List<BatsmanStats> battingList = [];
      if (battingScorecard is List) {
        for (var b in battingScorecard) {
          if (b is Map) {
battingList.add(BatsmanStats(
              playerId: b['player']?['_id'] ?? b['player'] ?? '',
              playerName: b['playerName'] ?? b['player']?.toString() ?? 'Unknown',
              runs: b['runs'] ?? 0,
              balls: b['balls'] ?? 0,
              fours: b['fours'] ?? 0,
              sixes: b['sixes'] ?? 0,
              strikeRate: (b['strikeRate'] ?? 0).toDouble(),
              dismissal: b['dismissal'],
              notOut: b['notOut'] == true,
              wicketNumber: b['fallOfWickets']?['wicket'],
            ));
          }
        }
      }

      // Parse bowling data  
      List<BowlerStats> bowlingList = [];
      if (bowlingScorecard is List) {
        for (var b in bowlingScorecard) {
          if (b is Map) {
            bowlingList.add(BowlerStats(
              playerId: b['player']?['_id'] ?? b['player'] ?? '',
              playerName: b['playerName'] ?? b['player']?.toString() ?? 'Unknown',
              overs: _parseOvers(b['overs'] ?? '0.0'),
              maidens: b['maidens'] ?? 0,
              runs: b['runs'] ?? 0,
              wickets: b['wickets'] ?? 0,
              economy: (b['economy'] ?? 0).toDouble(),
            ));
          }
        }
      }

      return FullScorecard(
        match: match,
        innings: inningsList,
        batting: [battingList],
        bowling: [bowlingList],
        fallOfWickets: [],
        partnerships: [],
      );
    } catch (e) {
      debugPrint('Error creating scorecard: $e');
      return _createFallbackScorecard(match);
}
  }

  // ===============================
  // 🔥 PARSE HELPERS
  // ===============================
  double _parseOvers(dynamic overs) {
    if (overs is double) return overs;
    if (overs is int) return overs.toDouble();
    if (overs is String) {
      if (overs.contains('.')) {
        final parts = overs.split('.');
        final oversPart = int.tryParse(parts[0]) ?? 0;
        final ballsPart = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
        return oversPart + (ballsPart / 6);
      }
      return double.tryParse(overs) ?? 0;
    }
    return 0;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Extras _parseExtras(dynamic extras) {
    if (extras is! Map) return const Extras();
    return Extras(
      wides: _parseInt(extras['wides']),
      noBalls: _parseInt(extras['noBalls']),
      byes: _parseInt(extras['byes']),
      legByes: _parseInt(extras['legByes']),
    );
  }

  // ===============================
  // 🔥 FALLBACK FIX
  // ===============================
  FullScorecard _createFallbackScorecard(Match match) {
    List<Innings> innings = [];

    innings.add(
      Innings(
        inningsNumber: 1,
        battingTeam: match.team1,
        bowlingTeam: match.team2,
        totalRuns: match.score.team1.runs,
        totalWickets: match.score.team1.wickets,
        totalOvers: match.score.team1.oversInDecimal,
        totalBalls: (match.score.team1.oversInDecimal * 6).toInt(),
        extras: const Extras(),
        isCompleted: match.status != 'live',
      ),
    );

    if (match.score.team2.runs > 0 || match.status != 'upcoming') {
      innings.add(
        Innings(
          inningsNumber: 2,
          battingTeam: match.team2,
          bowlingTeam: match.team1,
          totalRuns: match.score.team2.runs,
          totalWickets: match.score.team2.wickets,
          totalOvers: match.score.team2.oversInDecimal,
          totalBalls: (match.score.team2.oversInDecimal * 6).toInt(),
          extras: const Extras(),
          isCompleted: match.status == 'completed',
        ),
      );
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

  // ===============================
  // 🔥 REFRESH SCORECARD
  // ===============================
  Future<void> refreshScorecard(String matchId) async {
    await loadScorecard(matchId, forceRefresh: true);
  }

  // ===============================
  // 🔥 AUTO REFRESH
  // ===============================
  void _startAutoRefresh(String matchId) {
    if (_refreshTimer != null) return;

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) {
        if (_match?.status == 'live') {
          loadScorecard(matchId, forceRefresh: true);
        } else {
          _stopTimer();
        }
      },
    );
  }

  void _stopTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
