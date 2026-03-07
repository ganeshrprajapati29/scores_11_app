import '../models/player_model.dart';
import '../../core/services/api_client.dart';
import '../../core/services/cache_service.dart';

/// Pagination response wrapper for players
class PaginatedPlayers {
  final List<Player> players;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  PaginatedPlayers({
    required this.players,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });
}

class PlayerService {
  final ApiClient _apiClient = ApiClient();
  final CacheService _cacheService = CacheService();

  /// Get players with pagination support and caching
  Future<PaginatedPlayers> getPlayers({
    int page = 1,
    int limit = 20,
    String? search,
    bool forceRefresh = false,
  }) async {
    // For first page without search, try cache first
    if (page == 1 && search == null && !forceRefresh) {
      final cachedData = _cacheService.getCachedPlayers(ttlMinutes: 15);
      if (cachedData != null) {
        final players = cachedData.map((json) => Player.fromJson(json)).toList();
        return PaginatedPlayers(
          players: players,
          page: 1,
          limit: limit,
          total: players.length,
          totalPages: (players.length / limit).ceil(),
          hasMore: players.length >= limit,
        );
      }
    }

    final queryParams = {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
    };
    
    try {
      final response = await _apiClient.get('/players', queryParams: queryParams);
      final List<dynamic> data = response['data'] ?? [];
      final pagination = response['pagination'] ?? {};
      
      final players = data.map((json) => Player.fromJson(json)).toList();
      
      // Cache first page results
      if (page == 1 && search == null) {
        final playersJson = players.map((p) => p.toJson()).toList();
        _cacheService.cachePlayers(playersJson);
      }
      
      return PaginatedPlayers(
        players: players,
        page: pagination['page'] ?? page,
        limit: pagination['limit'] ?? limit,
        total: pagination['total'] ?? data.length,
        totalPages: pagination['pages'] ?? 1,
        hasMore: page < (pagination['pages'] ?? 1),
      );
    } catch (e) {
      // If API fails, return cached data
      if (page == 1 && search == null) {
        final cachedData = _cacheService.getCachedPlayers(ttlMinutes: 60);
        if (cachedData != null) {
          final players = cachedData.map((json) => Player.fromJson(json)).toList();
          return PaginatedPlayers(
            players: players,
            page: 1,
            limit: limit,
            total: players.length,
            totalPages: 1,
            hasMore: false,
          );
        }
      }
      rethrow;
    }
  }

  /// Legacy method for backward compatibility
  Future<List<Player>> getPlayersList({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final result = await getPlayers(page: page, limit: limit, search: search);
    return result.players;
  }

  /// Get player by ID
  Future<Player> getPlayerById(String id) async {
    final response = await _apiClient.get('/players/$id');
    return Player.fromJson(response['data']);
  }

  /// Get player by ID with caching
  Future<Player> getPlayerByIdWithCache(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedData = _cacheService.getCachedTeamDetail(id); // Reuse team cache for player
      if (cachedData != null) {
        return Player.fromJson(cachedData);
      }
    }

    try {
      final response = await _apiClient.get('/players/$id');
      final player = Player.fromJson(response['data']);
      
      // Cache the result
      _cacheService.cacheTeamDetail(id, player.toJson());
      
      return player;
    } catch (e) {
      rethrow;
    }
  }

  Future<Player> createPlayer(Map<String, dynamic> playerData) async {
    final response = await _apiClient.post('/players', playerData);
    // Clear players cache after creating new player
    _cacheService.clearPlayerStatsCache();
    return Player.fromJson(response['data']);
  }

  Future<Player> updatePlayer(String id, Map<String, dynamic> playerData) async {
    final response = await _apiClient.put('/players/$id', playerData);
    // Clear cache after update
    _cacheService.clearPlayerStatsCache();
    return Player.fromJson(response['data']);
  }

  Future<void> deletePlayer(String id) async {
    await _apiClient.delete('/players/$id');
    _cacheService.clearPlayerStatsCache();
  }

  /// Search players with debounce - caching handled in UI with debounce
  Future<List<Player>> searchPlayers(String query) async {
    final response = await _apiClient.get('/players', queryParams: {'search': query});
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Player.fromJson(json)).toList();
  }

  /// Get player stats with caching (longer TTL for stats)
  Future<Map<String, dynamic>> getPlayerStats(String playerId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedStats = _cacheService.getCachedPlayerStats(playerId, ttlMinutes: 30);
      if (cachedStats != null) {
        return cachedStats;
      }
    }

    try {
      final response = await _apiClient.get('/players/$playerId/stats');
      final stats = response['data'] ?? {};
      
      // Cache stats with longer TTL (30 mins)
      _cacheService.cachePlayerStats(playerId, stats);
      
      return stats;
    } catch (e) {
      // Try cache on error
      final cachedStats = _cacheService.getCachedPlayerStats(playerId, ttlMinutes: 60);
      if (cachedStats != null) {
        return cachedStats;
      }
      rethrow;
    }
  }

  Future<List<Player>> getTrendingPlayers({int limit = 10}) async {
    final response = await _apiClient.get('/players/trending', queryParams: {'limit': limit.toString()});
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Player.fromJson(json)).toList();
  }

  Future<List<Player>> comparePlayers(String player1Id, String player2Id) async {
    final response = await _apiClient.get('/players/compare', queryParams: {
      'player1': player1Id,
      'player2': player2Id,
    });
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Player.fromJson(json)).toList();
  }
}

