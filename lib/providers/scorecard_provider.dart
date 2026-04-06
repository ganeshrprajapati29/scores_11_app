import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../data/services/match_service.dart';
import '../data/models/scorecard_model.dart';
import '../data/models/match_model.dart';
import '../core/services/cache_service.dart';

class ScorecardProvider extends ChangeNotifier {
  final MatchService _matchService = MatchService();
  final CacheService _cacheService = CacheService();

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
      
      _match = match;
      _scorecard = FullScorecard.fromJson(scorecardData);
      
      _cacheService.cacheScorecard(matchId, scorecardData);
      _hasData = true;
      _lastUpdated = DateTime.now();
    } catch (e) {
      debugPrint('❌ Scorecard load error: $e');
      _error = e.toString();
      _hasData = false;
      
      if (kDebugMode) {
        _loadStaticFallback(matchId);
      }
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
        team2: 'Chennai Super Kings',
        scheduledDate: now,
        score: const MatchScore(
          team1: TeamScore(runs: 185, wickets: 4, overs: '20.0'),
          team2: TeamScore(runs: 142, wickets: 7, overs: '19.3'),
        ),
        format: 'T20',
        matchType: 'LEAGUE',
        status: 'COMPLETED',
        createdAt: now,
        updatedAt: now,
      );
      
      _scorecard = FullScorecard(
        match: _match!,
        innings: [
          Innings(
            inningsNumber: 1,
            battingTeam: 'Mumbai Indians',
            bowlingTeam: 'Chennai Super Kings',
            totalRuns: 185,
            totalWickets: 4,
            totalOvers: 20.0,
            totalBalls: 120,
            extras: const Extras(wides: 8, noBalls: 2, byes: 4, legByes: 2, total: 16),
            isCompleted: true,
          ),
          Innings(
            inningsNumber: 2,
            battingTeam: 'Chennai Super Kings',
            bowlingTeam: 'Mumbai Indians',
            totalRuns: 142,
            totalWickets: 7,
            totalOvers: 19.3,
            totalBalls: 117,
            extras: const Extras(wides: 6, noBalls: 1, byes: 3, legByes: 1, total: 11),
            isCompleted: true,
          ),
        ],
        batting: [
          [
            BatsmanStats(
              playerId: '1',
              playerName: 'Rohit Sharma',
              runs: 72,
              balls: 45,
              fours: 8,
              sixes: 3,
              strikeRate: 160.0,
              dismissal: 'c Jadeja b Deshpande',
            ),
            BatsmanStats(
              playerId: '2',
              playerName: 'Ishan Kishan',
              runs: 45,
              balls: 30,
              fours: 6,
              sixes: 2,
              strikeRate: 150.0,
              dismissal: 'b Pathirana',
            ),
            BatsmanStats(
              playerId: '3',
              playerName: 'Hardik Pandya',
              runs: 35,
              balls: 20,
              fours: 3,
              sixes: 3,
              strikeRate: 175.0,
              dismissal: null,
            ),
          ],
          [
            BatsmanStats(
              playerId: '4',
              playerName: 'Ruturaj Gaikwad',
              runs: 52,
              balls: 38,
              fours: 5,
              sixes: 2,
              strikeRate: 136.8,
              dismissal: 'c Kishan b Bumrah',
            ),
            BatsmanStats(
              playerId: '5',
              playerName: 'MS Dhoni',
              runs: 28,
              balls: 15,
              fours: 2,
              sixes: 2,
              strikeRate: 186.7,
              dismissal: null,
            ),
          ],
        ],
        bowling: [
          [
            const BowlerStats(
              playerId: '6',
              playerName: 'Deepak Chahar',
              overs: 4.0,
              maidens: 0,
              runs: 32,
              wickets: 1,
              economy: 8.0,
            ),
            const BowlerStats(
              playerId: '7',
              playerName: 'Ravindra Jadeja',
              overs: 4.0,
              maidens: 0,
              runs: 38,
              wickets: 1,
              economy: 9.5,
            ),
          ],
          [
            const BowlerStats(
              playerId: '8',
              playerName: 'Jasprit Bumrah',
              overs: 4.0,
              maidens: 0,
              runs: 28,
              wickets: 3,
              economy: 7.0,
            ),
            const BowlerStats(
              playerId: '9',
              playerName: 'Hardik Pandya',
              overs: 3.3,
              maidens: 0,
              runs: 32,
              wickets: 1,
              economy: 9.14,
            ),
          ],
        ],
        fallOfWickets: [
          const FallOfWicket(wicket: 1, batsman: 'Ishan Kishan', runs: 85, overs: '10.2'),
          const FallOfWicket(wicket: 2, batsman: 'Rohit Sharma', runs: 120, overs: '14.3'),
          const FallOfWicket(wicket: 3, batsman: 'Ruturaj Gaikwad', runs: 52, overs: '8.3'),
          const FallOfWicket(wicket: 4, batsman: 'Shivam Dube', runs: 95, overs: '12.2'),
        ],
        partnerships: [],
      );
      
      _hasData = true;
      debugPrint('✅ Static fallback data loaded successfully');
    } catch (e) {
      debugPrint('❌ Static fallback error: $e');
      _hasData = false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}