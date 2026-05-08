import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for local data storage using SharedPreferences
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  // Cache keys
  static const String matchesCacheKey = 'matches_cache';
  static const String liveMatchesCacheKey = 'live_matches_cache';
  static const String playerStatsCacheKey = 'player_stats_cache';
  static const String tournamentCacheKey = 'tournament_cache';
  static const String teamsCacheKey = 'teams_cache';

  // Cache timestamps
  static const String matchesCacheTimeKey = 'matches_cache_time';
  static const String playerStatsCacheTimeKey = 'player_stats_cache_time';
  static const String tournamentCacheTimeKey = 'tournament_cache_time';

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if cache is valid (within TTL)
  bool _isCacheValid(String cacheTimeKey, {int ttlMinutes = 5}) {
    if (_prefs == null) return false;
    final cacheTime = _prefs!.getInt(cacheTimeKey);
    if (cacheTime == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - cacheTime;
    return diff < (ttlMinutes * 60 * 1000);
  }

  /// Update cache timestamp
  void _updateCacheTime(String cacheTimeKey) {
    _prefs?.setInt(cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ==================== MATCH CACHE ====================

  Future<void> cacheMatches(List<Map<String, dynamic>> matches) async {
    await _prefs?.setString(matchesCacheKey, jsonEncode(matches));
    _updateCacheTime(matchesCacheTimeKey);
  }

  List<Map<String, dynamic>>? getCachedMatches({int ttlMinutes = 5}) {
    if (!_isCacheValid(matchesCacheTimeKey, ttlMinutes: ttlMinutes)) {
      return null;
    }
    final data = _prefs?.getString(matchesCacheKey);
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> cacheLiveMatches(List<Map<String, dynamic>> matches) async {
    await _prefs?.setString(liveMatchesCacheKey, jsonEncode(matches));
    _updateCacheTime('live_matches_cache_time');
  }

  List<Map<String, dynamic>>? getCachedLiveMatches({int ttlMinutes = 1}) {
    if (!_isCacheValid('live_matches_cache_time', ttlMinutes: ttlMinutes)) {
      return null;
    }
    final data = _prefs?.getString(liveMatchesCacheKey);
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> cacheMatchDetail(String matchId, Map<String, dynamic> match) async {
    final key = 'match_detail_$matchId';
    await _prefs?.setString(key, jsonEncode(match));
    await _prefs?.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, dynamic>? getCachedMatchDetail(String matchId, {int ttlMinutes = 5}) {
    final key = 'match_detail_$matchId';
    final cacheTime = _prefs?.getInt('${key}_time');
    if (cacheTime == null) return null;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - cacheTime;
    if (diff > (ttlMinutes * 60 * 1000)) return null;

    final data = _prefs?.getString(key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<void> clearMatchCache(String matchId) async {
    final key = 'match_detail_$matchId';
    await _prefs?.remove(key);
    await _prefs?.remove('${key}_time');
    await _prefs?.remove('live_score_$matchId');
    await _prefs?.remove('scorecard_$matchId');
  }

  // ==================== PLAYER STATS CACHE ====================

  Future<void> cachePlayerStats(String playerId, Map<String, dynamic> stats) async {
    final key = '${playerStatsCacheKey}_$playerId';
    await _prefs?.setString(key, jsonEncode(stats));
    _updateCacheTime(playerStatsCacheTimeKey);
  }

  Map<String, dynamic>? getCachedPlayerStats(String playerId, {int ttlMinutes = 30}) {
    final key = '${playerStatsCacheKey}_$playerId';
    if (!_isCacheValid(playerStatsCacheTimeKey, ttlMinutes: ttlMinutes)) {
      return null;
    }
    final data = _prefs?.getString(key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<void> cachePlayers(List<Map<String, dynamic>> players) async {
    await _prefs?.setString('players_list_cache', jsonEncode(players));
    _updateCacheTime('players_list_cache_time');
  }

  List<Map<String, dynamic>>? getCachedPlayers({int ttlMinutes = 15}) {
    if (!_isCacheValid('players_list_cache_time', ttlMinutes: ttlMinutes)) {
      return null;
    }
    final data = _prefs?.getString('players_list_cache');
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  // ==================== TOURNAMENT CACHE ====================

  Future<void> cacheTournaments(List<Map<String, dynamic>> tournaments) async {
    await _prefs?.setString(tournamentCacheKey, jsonEncode(tournaments));
    _updateCacheTime(tournamentCacheTimeKey);
  }

  List<Map<String, dynamic>>? getCachedTournaments({int ttlMinutes = 30}) {
    if (!_isCacheValid(tournamentCacheTimeKey, ttlMinutes: ttlMinutes)) {
      return null;
    }
    final data = _prefs?.getString(tournamentCacheKey);
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> cacheTournamentDetail(String tournamentId, Map<String, dynamic> tournament) async {
    final key = 'tournament_detail_$tournamentId';
    await _prefs?.setString(key, jsonEncode(tournament));
    await _prefs?.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, dynamic>? getCachedTournamentDetail(String tournamentId, {int ttlMinutes = 30}) {
    final key = 'tournament_detail_$tournamentId';
    final cacheTime = _prefs?.getInt('${key}_time');
    if (cacheTime == null) return null;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - cacheTime;
    if (diff > (ttlMinutes * 60 * 1000)) return null;

    final data = _prefs?.getString(key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  // ==================== TEAM CACHE ====================

  Future<void> cacheTeams(List<Map<String, dynamic>> teams) async {
    await _prefs?.setString(teamsCacheKey, jsonEncode(teams));
    _updateCacheTime('teams_cache_time');
  }

  List<Map<String, dynamic>>? getCachedTeams({int ttlMinutes = 30}) {
    if (!_isCacheValid('teams_cache_time', ttlMinutes: ttlMinutes)) {
      return null;
    }
    final data = _prefs?.getString(teamsCacheKey);
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> cacheTeamDetail(String teamId, Map<String, dynamic> team) async {
    final key = 'team_detail_$teamId';
    await _prefs?.setString(key, jsonEncode(team));
    await _prefs?.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, dynamic>? getCachedTeamDetail(String teamId, {int ttlMinutes = 30}) {
    final key = 'team_detail_$teamId';
    final cacheTime = _prefs?.getInt('${key}_time');
    if (cacheTime == null) return null;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - cacheTime;
    if (diff > (ttlMinutes * 60 * 1000)) return null;

    final data = _prefs?.getString(key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  // ==================== SCORE CACHE (Live Updates) ====================

  Future<void> cacheLiveScore(String matchId, Map<String, dynamic> score) async {
    final key = 'live_score_$matchId';
    await _prefs?.setString(key, jsonEncode(score));
    await _prefs?.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, dynamic>? getCachedLiveScore(String matchId, {int ttlMinutes = 1}) {
    final key = 'live_score_$matchId';
    final cacheTime = _prefs?.getInt('${key}_time');
    if (cacheTime == null) return null;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - cacheTime;
    if (diff > (ttlMinutes * 60 * 1000)) return null;

    final data = _prefs?.getString(key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  Future<void> cacheScorecard(String matchId, Map<String, dynamic> scorecard) async {
    final key = 'scorecard_$matchId';
    await _prefs?.setString(key, jsonEncode(scorecard));
    await _prefs?.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
  }

Map<String, dynamic>? getCachedScorecard(String matchId, {int ttlMinutes = 10}) {
    final key = 'scorecard_$matchId';
    final cacheTime = _prefs?.getInt('${key}_time');
    if (cacheTime == null) return null;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - cacheTime;
    if (diff > (ttlMinutes * 60 * 1000)) return null;

    final data = _prefs?.getString(key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  /// Clear scorecard cache for a specific match
  Future<void> clearScorecard(String matchId) async {
    final key = 'scorecard_$matchId';
    await _prefs?.remove(key);
    await _prefs?.remove('${key}_time');
  }

  // ==================== CACHE MANAGEMENT ====================

  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  Future<void> clearMatchesCache() async {
    await _prefs?.remove(matchesCacheKey);
    await _prefs?.remove(matchesCacheTimeKey);
    await _prefs?.remove(liveMatchesCacheKey);
    await _prefs?.remove('live_matches_cache_time');
  }

  Future<void> clearPlayerStatsCache() async {
    await _prefs?.remove(playerStatsCacheKey);
    await _prefs?.remove(playerStatsCacheTimeKey);
  }

  Future<void> clearTournamentCache() async {
    await _prefs?.remove(tournamentCacheKey);
    await _prefs?.remove(tournamentCacheTimeKey);
  }

  Future<void> clearTeamsCache() async {
    await _prefs?.remove(teamsCacheKey);
    await _prefs?.remove('teams_cache_time');
  }

  Future<void> clearAllMatchCaches() async {
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith('match_detail_') || 
          key.startsWith('live_score_') || 
          key.startsWith('scorecard_')) {
        await _prefs?.remove(key);
        await _prefs?.remove('${key}_time');
      }
    }
    await clearMatchesCache();
  }

  Future<int> getCacheSize() async {
    final keys = _prefs?.getKeys() ?? {};
    int size = 0;
    for (final key in keys) {
      final value = _prefs?.getString(key);
      if (value != null) {
        size += value.length;
      }
    }
    return size;
  }

  Future<Set<String>> getCacheKeys() async {
    return _prefs?.getKeys() ?? {};
  }

  bool get isInitialized => _prefs != null;
}