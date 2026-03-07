import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for local data storage using SharedPreferences
/// 
/// Supports:
/// - Match data caching
/// - Player stats caching
/// - Tournament data caching
/// - General API response caching
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
    return diff < (ttlMinutes * 60 * 1000); // Convert to milliseconds
  }

  /// Update cache timestamp
  void _updateCacheTime(String cacheTimeKey) {
    _prefs?.setInt(cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ==================== MATCH CACHE ====================

  /// Cache matches data
  Future<void> cacheMatches(List<Map<String, dynamic>> matches) async {
    await _prefs?.setString(matchesCacheKey, jsonEncode(matches));
    _updateCacheTime(matchesCacheTimeKey);
  }

  /// Get cached matches
  List<Map<String, dynamic>>? getCachedMatches({int ttlMinutes = 5}) {
    if (!_isCacheValid(matchesCacheTimeKey, ttlMinutes: ttlMinutes)) {
      return null;
    }
    final data = _prefs?.getString(matchesCacheKey);
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Cache live matches
  Future<void> cacheLiveMatches(List<Map<String, dynamic>> matches) async {
    await _prefs?.setString(liveMatchesCacheKey, jsonEncode(matches));
    _updateCacheTime('live_matches_cache_time');
  }

  /// Get cached live matches (shorter TTL for live data)
  List<Map<String, dynamic>>? getCachedLiveMatches({int ttlMinutes = 1}) {
    if (!_isCacheValid('live_matches_cache_time', ttlMinutes: ttlMinutes)) {
      return null;
    }
    final data = _prefs?.getString(liveMatchesCacheKey);
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Cache single match detail
  Future<void> cacheMatchDetail(String matchId, Map<String, dynamic> match) async {
    final key = 'match_detail_$matchId';
    await _prefs?.setString(key, jsonEncode(match));
    await _prefs?.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached match detail
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

  // ==================== PLAYER STATS CACHE ====================

  /// Cache player stats
  Future<void> cachePlayerStats(String playerId, Map<String, dynamic> stats) async {
    final key = '${playerStatsCacheKey}_$playerId';
    await _prefs?.setString(key, jsonEncode(stats));
    _updateCacheTime(playerStatsCacheTimeKey);
  }

  /// Get cached player stats
  Map<String, dynamic>? getCachedPlayerStats(String playerId, {int ttlMinutes = 30}) {
    final key = '${playerStatsCacheKey}_$playerId';
    if (!_isCacheValid(playerStatsCacheTimeKey, ttlMinutes: ttlMinutes)) {
      return null;
    }
    final data = _prefs?.getString(key);
    if (data == null) return null;
    return jsonDecode(data);
  }

  /// Cache player list
  Future<void> cachePlayers(List<Map<String, dynamic>> players) async {
    await _prefs?.setString('players_list_cache', jsonEncode(players));
    _updateCacheTime('players_list_cache_time');
  }

  /// Get cached players list
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

  /// Cache tournament data
  Future<void> cacheTournaments(List<Map<String, dynamic>> tournaments) async {
    await _prefs?.setString(tournamentCacheKey, jsonEncode(tournaments));
    _updateCacheTime(tournamentCacheTimeKey);
  }

  /// Get cached tournaments
  List<Map<String, dynamic>>? getCachedTournaments({int ttlMinutes = 30}) {
    if (!_isCacheValid(tournamentCacheTimeKey, ttlMinutes: ttlMinutes)) {
      return null;
    }
    final data = _prefs?.getString(tournamentCacheKey);
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Cache tournament detail
  Future<void> cacheTournamentDetail(String tournamentId, Map<String, dynamic> tournament) async {
    final key = 'tournament_detail_$tournamentId';
    await _prefs?.setString(key, jsonEncode(tournament));
    await _prefs?.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached tournament detail
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

  /// Cache teams
  Future<void> cacheTeams(List<Map<String, dynamic>> teams) async {
    await _prefs?.setString(teamsCacheKey, jsonEncode(teams));
    _updateCacheTime('teams_cache_time');
  }

  /// Get cached teams
  List<Map<String, dynamic>>? getCachedTeams({int ttlMinutes = 30}) {
    if (!_isCacheValid('teams_cache_time', ttlMinutes: ttlMinutes)) {
      return null;
    }
    final data = _prefs?.getString(teamsCacheKey);
    if (data == null) return null;
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Cache team detail
  Future<void> cacheTeamDetail(String teamId, Map<String, dynamic> team) async {
    final key = 'team_detail_$teamId';
    await _prefs?.setString(key, jsonEncode(team));
    await _prefs?.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached team detail
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

  // ==================== CACHE MANAGEMENT ====================

  /// Clear all cache
  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  /// Clear matches cache only
  Future<void> clearMatchesCache() async {
    await _prefs?.remove(matchesCacheKey);
    await _prefs?.remove(matchesCacheTimeKey);
    await _prefs?.remove(liveMatchesCacheKey);
  }

  /// Clear player stats cache only
  Future<void> clearPlayerStatsCache() async {
    await _prefs?.remove(playerStatsCacheKey);
    await _prefs?.remove(playerStatsCacheTimeKey);
  }

  /// Clear tournament cache only
  Future<void> clearTournamentCache() async {
    await _prefs?.remove(tournamentCacheKey);
    await _prefs?.remove(tournamentCacheTimeKey);
  }

  /// Get cache size (approximate)
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
}

