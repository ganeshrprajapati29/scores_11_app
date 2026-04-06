import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../data/services/match_service.dart';
import '../data/models/scorecard_model.dart';
import '../data/models/match_model.dart';
import '../core/services/cache_service.dart';

class ScorecardProvider extends ChangeNotifier {
  final MatchService _matchService = MatchService();
  final CacheService _cacheService = CacheService();

  // State
  FullScorecard? _scorecard;
  Match? _match;
  bool _isLoading = false;
  String? _error;
  bool _hasData = false;
  DateTime? _lastUpdated;

  // Getters
  FullScorecard? get scorecard => _scorecard;
  Match? get match => _match;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _hasData;
  DateTime? get lastUpdated => _lastUpdated;

  // Static fallback data for "complete static" requirement
  static const Map<String, dynamic> _staticMatchData = {
    'team1': {'name': 'Mumbai Indians', 'shortName': 'MI', 'logo': 'https://via.placeholder.com/50?text=MI'},
    'team2': {'name': 'Chennai Super Kings', 'shortName': 'CSK', 'logo': 'https://via.placeholder.com/50?text=CSK'},
    'status': 'MI won by 43 runs',
    'venue': 'Wankhede Stadium, Mumbai',
    'date': '15 Mar 2024',
    'result': 'Mumbai Indians won by 43 runs',
    'playerOfMatch': 'Rohit Sharma',
  };

  static const List<Map<String, dynamic>> _staticBatting = [
    [
      {'name': 'Rohit Sharma', 'runs': 72, 'balls': 45, '4s': 8, '6s': 3, 'status': 'c Jadeja b Deshpande'},
      {'name': 'Ishan Kishan', 'runs': 45, 'balls': 30, '4s': 6, '6s': 2, 'status': 'b Pathirana'},
    ],
    [
      {'name': 'Ruturaj Gaikwad', 'runs': 52, 'balls': 38, '4s': 5, '6s': 2, 'status': 'not out'},
    ],
  ];

  Future<void> loadScorecard(String matchId, {bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String effectiveMatchId = matchId.trim();
      
      // Auto-select first live match if no specific ID
      if (effectiveMatchId.isEmpty) {
        final liveMatches = await _matchService.getLiveMatches(forceRefresh: forceRefresh);
        if (liveMatches.isNotEmpty) {
          effectiveMatchId = liveMatches.first.id;
          debugPrint('📱 Auto-selected live match: $effectiveMatchId');
        } else {
          effectiveMatchId = 'demo-match-1'; // static fallback ID
        }
      }

      // Try cache first
      if (!forceRefresh) {
        final cached = _cacheService.getCachedScorecard(effectiveMatchId);
        if (cached != null) {
          _scorecard = FullScorecard.fromJson(cached);
          _hasData = true;
          _lastUpdated = DateTime.now();
          notifyListeners();
          return;
        }
      }

      // Load match details
      final match = await _matchService.getMatchById(effectiveMatchId, forceRefresh: forceRefresh);
      _match = match;

      // Load full scorecard data
      final scorecardData = await _matchService.getFullScorecard(effectiveMatchId);
      _scorecard = FullScorecard.fromJson(scorecardData);
      
      // Cache the result
      _cacheService.cacheScorecard(effectiveMatchId, scorecardData);

      _hasData = true;
      _lastUpdated = DateTime.now();
    } catch (e) {
      debugPrint('❌ Scorecard load error: $e');
      _error = e.toString();
      _hasData = false;
      // Fallback to static data
      _loadStaticFallback();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshScorecard(String matchId) async {
    await loadScorecard(matchId, forceRefresh: true);
  }

  void _loadStaticFallback(String matchId) {
    // Create static FullScorecard for complete UI
    _match = Match(
      id: matchId,
      team1: _staticMatchData['team1']['name'],
      team2: _staticMatchData['team2']['name'],
      status: _staticMatchData['status'],
      // ... fill other fields
    );
    _scorecard = FullScorecard(
      match: _match!,
      innings: [
        Innings(totalRuns: 185, totalWickets: 4, totalOvers: 20.0),
        Innings(totalRuns: 142, totalWickets: 7, totalOvers: 19.3),
      ],
      batting: _staticBatting.map((innings) => innings.map<BatsmanStats>((p) {
        final sr = p['balls'] > 0 ? (p['runs'] / p['balls']) * 100 : 0.0;
        return BatsmanStats(
          playerId: '',
          playerName: p['name'],
          runs: p['runs'],
          balls: p['balls'],
          fours: p['4s'] ?? 0,
          sixes: p['6s'] ?? 0,
          strikeRate: sr,
          dismissal: p['status'],
        );
      }).toList()).toList(),
      fallOfWickets: [
        FallOfWicket(wicket: 1, batsman: 'Ishan Kishan', runs: 120, partnership: '12.3'),
      ],
    );
    _hasData = true;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
