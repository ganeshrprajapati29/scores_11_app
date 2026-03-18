import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/services/cache_service.dart';
import 'package:dio/dio.dart';
import '../models/player_model.dart';

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
    String? role,
    String? team,
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

    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
      if (role != null) 'role': role,
      if (team != null) 'team': team,
    };
    
    try {
      final response = await _apiClient.get('${ApiConfig.players}', queryParameters: queryParams);
      final List<dynamic> data = response.data['data'] ?? [];
      final pagination = response.data['pagination'] ?? {};
      
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
} on Exception catch (e) {
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
final message = _apiClient.parseDioError(e as DioException);
      throw Exception(message);
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
      throw Exception(e.toString());
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
    final response = await _apiClient.get('${ApiConfig.players}/$id');
    return Player.fromJson(response.data['data']);
  }

  /// Get player by ID with caching
  Future<Player> getPlayerByIdWithCache(String id, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedData = _cacheService.getCachedTeamDetail(id);
      if (cachedData != null) {
        return Player.fromJson(cachedData);
      }
    }

    try {
      final response = await _apiClient.get('${ApiConfig.players}/$id');
      final player = Player.fromJson(response.data['data']);
      
      _cacheService.cacheTeamDetail(id, player.toJson());
      
      return player;
    } catch (e) {
      rethrow;
    }
  }

  /// Get players by team
  Future<List<Player>> getPlayersByTeam(String teamId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.players}/team/$teamId');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Player.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get trending players
  Future<List<Player>> getTrendingPlayers({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.players}/trending', 
        queryParameters: {'limit': limit.toString()},
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Player.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Compare players
  Future<List<Player>> comparePlayers(String player1Id, String player2Id) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.players}/compare', 
        queryParameters: {
          'player1': player1Id,
          'player2': player2Id,
        },
      );
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Player.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

/// Get player stats
  Future<Map<String, dynamic>> getPlayerStats(String playerId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedStats = _cacheService.getCachedPlayerStats(playerId, ttlMinutes: 30);
      if (cachedStats != null) {
        return cachedStats;
      }
    }

    try {
      final response = await _apiClient.get('${ApiConfig.players}/$playerId/stats');
      final stats = response.data['data'] ?? {};
      
      _cacheService.cachePlayerStats(playerId, stats);
      
      return stats;
    } catch (e) {
      final cachedStats = _cacheService.getCachedPlayerStats(playerId, ttlMinutes: 60);
      if (cachedStats != null) {
        return cachedStats;
      }
      rethrow;
    }
  }

  /// Get player performance (stats + performances)
  Future<Map<String, dynamic>> getPlayerPerformance(String playerId, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.players}/$playerId/performance',
        queryParameters: queryParams,
      );
      return response.data['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new player
  Future<Player> createPlayer(Map<String, dynamic> playerData) async {
    final response = await _apiClient.post('${ApiConfig.players}', data: playerData);
    _cacheService.clearPlayerStatsCache();
    return Player.fromJson(response.data['data']);
  }

  /// Update a player
  Future<Player> updatePlayer(String id, Map<String, dynamic> playerData) async {
    final response = await _apiClient.put('${ApiConfig.players}/$id', data: playerData);
    _cacheService.clearPlayerStatsCache();
    return Player.fromJson(response.data['data']);
  }

  /// Delete a player
  Future<void> deletePlayer(String id) async {
    await _apiClient.delete('${ApiConfig.players}/$id');
    _cacheService.clearPlayerStatsCache();
  }

  /// Search players with debounce
  Future<List<Player>> searchPlayers(String query) async {
    final response = await _apiClient.get(
      '${ApiConfig.players}', 
      queryParameters: {'search': query},
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => Player.fromJson(json)).toList();
  }
}

