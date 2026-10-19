import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/utils/friendly_error.dart';
import '../data/services/leaderboard_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  final LeaderboardService _leaderboardService = LeaderboardService();
  
  // Data
  List<Map<String, dynamic>> _topBatsmen = [];
  List<Map<String, dynamic>> _topBowlers = [];
  List<Map<String, dynamic>> _mvpRankings = [];
  List<Map<String, dynamic>> _teamRankings = [];
  Map<String, dynamic>? _playerRanking;
  Map<String, dynamic>? _teamRanking;
  
  // State
  bool _isLoadingBatsmen = false;
  bool _isLoadingBowlers = false;
  bool _isLoadingMoreBatsmen = false;
  String? _error;
  
  // Getters
  List<Map<String, dynamic>> get topBatsmen => _topBatsmen;
  List<Map<String, dynamic>> get topBowlers => _topBowlers;
  List<Map<String, dynamic>> get mvpRankings => _mvpRankings;
  List<Map<String, dynamic>> get teamRankings => _teamRankings;
  Map<String, dynamic>? get playerRanking => _playerRanking;
  Map<String, dynamic>? get teamRanking => _teamRanking;
  bool get isLoadingBatsmen => _isLoadingBatsmen;
  bool get isLoadingBowlers => _isLoadingBowlers;
  bool get isLoadingMoreBatsmen => _isLoadingMoreBatsmen;
  String? get error => _error;

  /// Clears cached leaderboard data on logout so a different account
  /// signing in on the same app instance doesn't briefly see stale data.
  void reset() {
    _topBatsmen = [];
    _topBowlers = [];
    _mvpRankings = [];
    _teamRankings = [];
    _playerRanking = null;
    _teamRanking = null;
    _isLoadingBatsmen = false;
    _isLoadingBowlers = false;
    _isLoadingMoreBatsmen = false;
    _error = null;
    notifyListeners();
  }

  /// Load top batsmen (T20 default)
  Future<void> loadTopBatsmen({String timeframe = 'T20', bool refresh = true, int page = 1, int limit = 20}) async {
    try {
      _isLoadingBatsmen = true;
      _error = null;
      notifyListeners();
      
      final result = await _leaderboardService.getTopBatsmen(
        page: page,
        limit: limit,
        timeframe: timeframe,
      );
      
      if (refresh) {
        _topBatsmen = result.entries;
      } else {
        _topBatsmen.addAll(result.entries);
      }
      
      _isLoadingMoreBatsmen = false;
    } catch (e) {
      _error = friendlyError(e, fallback: 'Could not load leaderboard.');
      debugPrint('LeaderboardProvider error: \$e');
    } finally {
      _isLoadingBatsmen = false;
      notifyListeners();
    }
  }
  
  /// Load top bowlers
  Future<void> loadTopBowlers({String? timeframe, int page = 1, int limit = 20}) async {
    try {
      _isLoadingBowlers = true;
      _error = null;
      notifyListeners();
      
      final result = await _leaderboardService.getTopBowlers(
        page: page,
        limit: limit,
        timeframe: timeframe,
      );
      
      _topBowlers = result.entries;
    } catch (e) {
      _error = friendlyError(e, fallback: 'Could not load leaderboard.');
    } finally {
      _isLoadingBowlers = false;
      notifyListeners();
    }
  }
  
  /// Load MVP rankings
  Future<void> loadMVPRankings({int limit = 20, String? timeframe}) async {
    try {
      _error = null;
      notifyListeners();
      
      _mvpRankings = await _leaderboardService.getMVPRankings(limit: limit, timeframe: timeframe);
    } catch (e) {
      _error = friendlyError(e, fallback: 'Could not load leaderboard.');
    } finally {
      notifyListeners();
    }
  }
  
  /// Load team rankings
  Future<void> loadTeamRankings({int limit = 20, String? tournamentId}) async {
    try {
      _error = null;
      notifyListeners();
      
      _teamRankings = await _leaderboardService.getTeamRankings(limit: limit, tournamentId: tournamentId);
    } catch (e) {
      _error = friendlyError(e, fallback: 'Could not load leaderboard.');
    } finally {
      notifyListeners();
    }
  }
  
  /// Get specific player ranking
  Future<void> loadPlayerRanking(String playerId) async {
    try {
      _error = null;
      notifyListeners();
      
      _playerRanking = await _leaderboardService.getPlayerRanking(playerId);
    } catch (e) {
      _error = friendlyError(e, fallback: 'Could not load ranking details.');
    } finally {
      notifyListeners();
    }
  }
  
  /// Get specific team ranking
  Future<void> loadTeamRanking(String teamId) async {
    try {
      _error = null;
      notifyListeners();
      
      _teamRanking = await _leaderboardService.getTeamRanking(teamId);
    } catch (e) {
      _error = friendlyError(e, fallback: 'Could not load ranking details.');
    } finally {
      notifyListeners();
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadTopBatsmen(refresh: true),
      loadTopBowlers(),
      loadMVPRankings(),
      loadTeamRankings(),
    ]);
  }
}

