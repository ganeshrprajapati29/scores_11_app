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

  /// Clears cached scorecard data on logout so a different account signing
  /// in on the same app instance doesn't briefly see the previous state.
  void reset() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _scorecard = null;
    _match = null;
    _isLoading = false;
    _error = null;
    _hasData = false;
    _lastUpdated = null;
    _isLive = false;
    notifyListeners();
  }

  // ===============================
  // 🔥 MAIN FUNCTION
  // ===============================
  Future<void> loadScorecard(
    String matchId, {
    bool forceRefresh = false,
    bool showLoading = true,
  }) async {
    if (matchId.isEmpty) {
      _error = 'Invalid match ID';
      notifyListeners();
      return;
    }

    if (showLoading) _isLoading = true;
    _error = null;
    if (showLoading) notifyListeners();

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
      _match = fullScorecard.match;
      _hasData = true;
      _isLive = _isLiveStatus(_match?.status ?? match.status);

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
      final displayMatch = _matchWithApiResult(match, data);
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
      
      // If innings array exists in data, build a complete professional
      // scorecard for every innings.
      if (data['innings'] != null && data['innings'] is List && (data['innings'] as List).isNotEmpty) {
        final rawInnings = data['innings'] as List;
        final inningsList = <Innings>[];
        final battingByInnings = <List<BatsmanStats>>[];
        final bowlingByInnings = <List<BowlerStats>>[];
        final fieldingByInnings = <List<FieldingStats>>[];
        final fallOfWickets = <FallOfWicket>[];
        final fallOfWicketsByInnings = <List<FallOfWicket>>[];

        for (final raw in rawInnings.whereType<Map>()) {
          final inningsMap = Map<String, dynamic>.from(raw);
          inningsList.add(Innings.fromJson(inningsMap));

          final battingRaw = inningsMap['battingScorecard'];
          battingByInnings.add(battingRaw is List
              ? battingRaw
                  .whereType<Map>()
                  .map((b) => BatsmanStats.fromJson(Map<String, dynamic>.from(b)))
                  .toList()
              : <BatsmanStats>[]);

          final bowlingRaw = inningsMap['bowlingScorecard'];
          bowlingByInnings.add(bowlingRaw is List
              ? bowlingRaw
                  .whereType<Map>()
                  .map((b) => BowlerStats.fromJson(Map<String, dynamic>.from(b)))
                  .toList()
              : <BowlerStats>[]);

          final fieldingRaw = inningsMap['fieldingScorecard'];
          fieldingByInnings.add(fieldingRaw is List
              ? fieldingRaw
                  .whereType<Map>()
                  .map((f) => FieldingStats.fromJson(Map<String, dynamic>.from(f)))
                  .toList()
              : <FieldingStats>[]);

          final fowRaw = inningsMap['fallOfWickets'];
          final inningsWickets = <FallOfWicket>[];
          if (fowRaw is List) {
            inningsWickets.addAll(fowRaw
                .whereType<Map>()
                .map((w) => FallOfWicket.fromJson(Map<String, dynamic>.from(w))));
            fallOfWickets.addAll(inningsWickets);
          }
          fallOfWicketsByInnings.add(inningsWickets);
        }

        return FullScorecard(
          match: displayMatch,
          innings: inningsList,
          batting: battingByInnings,
          bowling: bowlingByInnings,
          fielding: fieldingByInnings,
          fallOfWickets: fallOfWickets,
          fallOfWicketsByInnings: fallOfWicketsByInnings,
          partnerships: List<Map<String, dynamic>>.from(data['partnerships'] ?? []),
        );
      }

      // Build innings from flat API data
      final inningsList = <Innings>[
        Innings(
          inningsNumber: 1,
          battingTeam: match.team1,
          bowlingTeam: match.team2,
          totalRuns: _parseInt(runs),
          totalWickets: _parseInt(wickets),
          totalOvers: _parseOvers(overs),
          totalBalls: (_parseOvers(overs) * 6).toInt(),
          extras: _parseExtras(extras),
          isCompleted: match.status != 'live',
        )
      ];

      final battingList = <BatsmanStats>[];
      if (battingScorecard is List) {
        for (var b in battingScorecard) {
          if (b is Map) {
            battingList.add(BatsmanStats.fromJson(Map<String, dynamic>.from(b)));
          }
        }
      }

      // Parse bowling data  
      final bowlingList = <BowlerStats>[];
      if (bowlingScorecard is List) {
        for (var b in bowlingScorecard) {
          if (b is Map) {
            bowlingList.add(BowlerStats.fromJson(Map<String, dynamic>.from(b)));
          }
        }
      }

      return FullScorecard(
        match: displayMatch,
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

  bool _isLiveStatus(String status) {
    const liveStatuses = {'live', 'started', 'in_progress', 'ongoing'};
    return liveStatuses.contains(status.toLowerCase());
  }

  Match _matchWithApiResult(Match match, Map<String, dynamic> data) {
    final apiMatch = data['match'];
    if (apiMatch is! Map) return match;

    final merged = Map<String, dynamic>.from(match.toJson());
    merged.addAll(Map<String, dynamic>.from(apiMatch));

    if (apiMatch['result'] is Map) {
      final result = Map<String, dynamic>.from(apiMatch['result'] as Map);
      final winnerName = result['winner'] is Map
          ? (result['winner']['name'] ?? result['winner']['shortName'])?.toString()
          : result['winner']?.toString();
      final margin = result['margin']?.toString();

      if ((result['message'] == null || result['message'].toString().isEmpty) &&
          winnerName != null &&
          winnerName.isNotEmpty &&
          margin != null &&
          margin.isNotEmpty) {
        result['message'] = '$winnerName won by $margin';
      }
      if (winnerName != null && winnerName.isNotEmpty) {
        result['winner'] = winnerName;
      }
      merged['result'] = result;
    }

    return Match.fromJson(merged);
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
        if (_match != null && _isLiveStatus(_match!.status)) {
          loadScorecard(matchId, forceRefresh: true, showLoading: false);
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
