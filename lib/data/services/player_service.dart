import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/services/cache_service.dart';
import '../../data/models/player_model.dart';

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

factory PaginatedPlayers.fromJson(Map<String, dynamic> json) {
    // FIXED: Handle both List and Map responses
    List<dynamic> dataList = [];
    if (json['data'] is List) {
      dataList = json['data'] as List<dynamic>;
    } else if (json['data'] is Map<String, dynamic>) {
      // Single player object - wrap in list
      dataList = [json['data']];
    }
    final pagination = json['pagination'] ?? <String, dynamic>{};
    return PaginatedPlayers(
      players: dataList.map((p) => Player.fromJson(p as Map<String, dynamic>)).toList(),
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 10,
      total: pagination['total'] ?? 0,
      totalPages: pagination['pages'] ?? 1,
      hasMore: (pagination['page'] ?? 1) < (pagination['pages'] ?? 1),
    );
  }
}

/// PlayerSearchResult class for player search results with pagination
class PlayerSearchResult {
  final List<Player> players;
  final bool hasMore;
  final int total;
  
  PlayerSearchResult({
    required this.players,
    required this.hasMore,
    required this.total,
  });
  
  factory PlayerSearchResult.fromJson(Map<String, dynamic> json) {
    return PlayerSearchResult(
      players: (json['players'] as List<dynamic>?)
          ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      hasMore: json['hasMore'] ?? false,
      total: json['total'] ?? 0,
    );
  }
}

class PlayerService {
  final ApiClient _apiClient = ApiClient();
  final CacheService _cacheService = CacheService();

/// Search only MY players (created by logged in user)
  /// Requires authentication - returns only players created by the current user
  Future<List<Player>> searchMyPlayers(String query, {int limit = 20}) async {
    try {
      // Use authenticated endpoint - returns only the current user's players
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/players/my/search',
        queryParameters: {'q': query, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final players = data.map((json) => Player.fromJson(json)).toList();
        return players;
      }
      throw Exception(response.data['message'] ?? 'Search failed');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

/// Get all MY players (created by logged in user) - paginated
  /// 🔥 FIX: This uses authenticated endpoint - backend gets userId from auth token
  /// Returns players where user: req.user.userId (via player.user field)
  Future<PaginatedPlayers> getMyPlayers({int page = 1, int limit = 20}) async {
    try {
      // 🔥 FIXED: Use the authenticated /my endpoint which gets userId from JWT token
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/players/my',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        return PaginatedPlayers.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to load my players');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

/// Search all public players (all users' players)
  Future<List<Player>> searchPlayers(String query, {int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/players/search',
        queryParameters: {'q': query, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final players = data.map((json) => Player.fromJson(json)).toList();
        return players;
      }
      throw Exception(response.data['message'] ?? 'Search failed');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get public players (all users' players) - paginated with search and filter
  Future<PlayerSearchResult> getPublicPlayers({
    required int page,
    String? search,
    String? filter,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (filter != null && filter != 'all') 'role': filter,
      };
      
final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/public/players',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<Player> players = (data['players'] as List)
            .map((json) => Player.fromJson(json))
            .toList();
        
        return PlayerSearchResult(
          players: players,
          hasMore: data['hasMore'] ?? false,
          total: data['total'] ?? 0,
        );
      } else {
        throw Exception('Failed to load public players');
      }
    } catch (e) {
      throw Exception('Error fetching public players: $e');
    }
  }

  /// Updated getPlayers method with filter parameter
  Future<PlayerSearchResult> getPlayers({
    required int page,
    String? search,
    String? filter,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (filter != null && filter != 'all') 'role': filter,
      };
      
final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/players',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<Player> players = (data['players'] as List)
            .map((json) => Player.fromJson(json))
            .toList();
        
        return PlayerSearchResult(
          players: players,
          hasMore: data['hasMore'] ?? false,
          total: data['total'] ?? 0,
        );
      } else {
        throw Exception('Failed to load players');
      }
    } catch (e) {
      throw Exception('Error fetching players: $e');
    }
  }

  Future<List<Player>> getPlayersByTeam(String teamId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/players/team/$teamId',
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final players = data.map((json) => Player.fromJson(json)).toList();
        return players;
      }
      throw Exception(response.data['message'] ?? 'Failed to load team players');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Player> getPlayerById(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/players/public/$id',
      );

      if (response.statusCode == 200) {
        final player = Player.fromJson(response.data['data']);
        return player;
      }
      throw Exception(response.data['message'] ?? 'Player not found');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<Player>> getTrendingPlayers({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/players/trending',
        queryParameters: {'limit': limit},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
return data.map((json) => Player.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  void clearCache() {
    _cacheService.clearAll();
  }

/// Create new player - FIXED: Use auth endpoint when logged in to associate with user
  Future<Player> createPlayer({
    required String name,
    String? role,
    String? battingStyle,
    String? bowlingStyle,
    String? team,
    int? jerseyNumber,
    String? phone,
    String? dateOfBirth,
    String? nationality,
    Map<String, dynamic>? stats,
  }) async {
    try {
      // FIXED: Transform UI values (lowercase) to backend expected format
      // UI passes: 'batsman', 'bowler', 'all-rounder', 'wicket-keeper'
      // Backend accepts: 'batsman', 'bowler', 'all-rounder', 'wicket-keeper'
      final roleMap = {
        'batsman': 'batsman',
        'bowler': 'bowler',
        'all-rounder': 'all-rounder',
        'wicket-keeper': 'wicket-keeper',
      };

      // Transform batting style - UI passes these exact values
      final battingStyleMap = {
        'right-hand bat': 'right-hand bat',
        'left-hand bat': 'left-hand bat',
      };

      // Transform bowling style - UI passes these exact values
      final bowlingStyleMap = {
        'right-arm fast': 'right-arm fast',
        'right-arm medium': 'right-arm medium',
        'left-arm fast': 'left-arm fast',
        'left-arm medium': 'left-arm medium',
        'off-spin': 'off-spin',
        'leg-spin': 'leg-spin',
        'none': 'none',
      };

      final transformedData = {
        'playerName': name,
        'role': roleMap[role] ?? role ?? 'batsman',
        'battingStyle': battingStyleMap[battingStyle] ?? battingStyle ?? 'right-hand bat',
        'bowlingStyle': bowlingStyleMap[bowlingStyle] ?? bowlingStyle ?? 'none',
        if (team != null) 'team': team,
        if (jerseyNumber != null) 'jerseyNumber': jerseyNumber,
        if (phone != null) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (nationality != null) 'nationality': nationality,
        if (stats != null) 'stats': stats,
      };

      // IMPORTANT: Use protected endpoint with auth to associate player with user
      // This will link the player to the logged-in user for "my players" search
      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/players',  // Uses auth header internally
        data: transformedData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _cacheService.clearAll();
        // FIXED: Handle response structure - may be directly in 'data' or nested
        final playerData = response.data['data'] ?? response.data;
        if (playerData is Map<String, dynamic>) {
          return Player.fromJson(playerData);
        }
        throw Exception('Invalid player data format');
      }
      throw Exception(response.data['message'] ?? 'Failed to create player');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to create player: $e');
    }
  }
}
