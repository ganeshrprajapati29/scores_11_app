import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/services/cache_service.dart';
import '../../data/models/player_model.dart';
import '../../data/models/match_model.dart';

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
    List<dynamic> dataList = [];
    if (json['data'] is List) {
      dataList = json['data'] as List<dynamic>;
    } else if (json['data'] is Map<String, dynamic>) {
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

  List<dynamic> _extractPlayerList(dynamic responseData) {
    if (responseData is List) return responseData;
    if (responseData is! Map) return const [];

    final data = responseData['data'];
    if (data is List) return data;
    if (data is Map) {
      final nestedPlayers = data['players'];
      if (nestedPlayers is List) return nestedPlayers;
      final nestedData = data['data'];
      if (nestedData is List) return nestedData;
    }

    final players = responseData['players'];
    if (players is List) return players;
    return const [];
  }
  final CacheService _cacheService = CacheService();

  /// Search only MY players (created by logged in user)
  /// Requires authentication - returns only players created by the current user
  Future<List<Player>> searchMyPlayers(String query, {int limit = 20}) async {
    try {
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
  Future<PaginatedPlayers> getMyPlayers({int page = 1, int limit = 20}) async {
    try {
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
        if (filter != null && filter != 'all') 'playerType': filter,
      };
      
      final response = await _apiClient.get(
        '${ApiConfig.users}/players/public',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final rawData = data['data'];
        final rawPlayers = rawData is Map && rawData['players'] is List
            ? rawData['players']
            : data['players'] ?? rawData ?? [];
        final pagination = data['pagination'] ?? {};
        final List<Player> players = (rawPlayers as List)
            .map((json) => Player.fromJson(json))
            .toList();
        
        return PlayerSearchResult(
          players: players,
          hasMore: data['hasMore'] ?? ((pagination['page'] ?? page) < (pagination['pages'] ?? page)),
          total: data['total'] ?? pagination['total'] ?? players.length,
        );
      } else {
        throw Exception('Failed to load public players');
      }
    } catch (e) {
      throw Exception('Error fetching public players: $e');
    }
  }

  /// Get players with filter parameter
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
        final rawPlayers = data['players'] ?? data['data'] ?? [];
        final pagination = data['pagination'] ?? {};
        final List<Player> players = (rawPlayers as List)
            .map((json) => Player.fromJson(json))
            .toList();
        
        return PlayerSearchResult(
          players: players,
          hasMore: data['hasMore'] ?? ((pagination['page'] ?? page) < (pagination['pages'] ?? page)),
          total: data['total'] ?? pagination['total'] ?? players.length,
        );
      } else {
        throw Exception('Failed to load players');
      }
    } catch (e) {
      throw Exception('Error fetching players: $e');
    }
  }

  /// Get players by team ID
  Future<List<Player>> getPlayersByTeam(String teamId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/players/team/$teamId',
      );

      if (response.statusCode == 200) {
        final data = _extractPlayerList(response.data);
        final players = data
            .whereType<Map>()
            .map((json) => Player.fromJson(Map<String, dynamic>.from(json)))
            .where((player) => player.id.isNotEmpty)
            .toList();
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

  /// Get player by ID (public endpoint)
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

  Future<Map<String, dynamic>> getFullPlayerProfile(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/players/public/$id/full-profile',
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      throw Exception(response.data['message'] ?? 'Player profile not found');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get public player matches.
  Future<List<Match>> getPlayerMatches(String id, {int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/players/public/$id/matches',
        queryParameters: {'page': page, 'limit': limit, 'type': 'feed'},
      );

      if (response.statusCode == 200) {
        final raw = _extractPlayerList(response.data);
        return raw
            .whereType<Map>()
            .map((json) => Match.fromJson(Map<String, dynamic>.from(json)))
            .where((match) => match.id.isNotEmpty)
            .toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load player matches');
    } on DioException catch (e) {
      debugPrint('Player matches API error: ${_apiClient.parseDioError(e)}');
      return const [];
    } catch (e) {
      debugPrint('Player matches parse error: $e');
      return const [];
    }
  }

  Future<bool> optOutFromMatch(String playerId, String matchId) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.baseUrl}/players/public/$playerId/matches/$matchId/opt-out',
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get live stats for a player and tolerate different API wrappers.
  Future<PlayerStats?> getPlayerStats(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/players/$id/stats');
      if (response.statusCode == 200) {
        final raw = response.data is Map ? response.data['data'] ?? response.data : null;
        if (raw is Map) {
          final stats = raw['stats'] is Map ? raw['stats'] : raw;
          return PlayerStats.fromJson(Map<String, dynamic>.from(stats as Map));
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get trending players
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

  /// Create new player - associates with logged in user
  Future<Player> createPlayer({
    required String name,
    String? role,
    String? battingStyle,
    String? bowlingStyle,
    String? team,
    int? jerseyNumber,
    String? email,
    String? phone,
    String? dateOfBirth,
    String? nationality,
    Map<String, dynamic>? stats,
  }) async {
    try {
      // Transform UI values to backend expected format
      final roleMap = {
        'bat': 'batsman',
        'bowler': 'bowler',
        'ar': 'all-rounder',
        'wk': 'wicket-keeper',
        'batsman': 'batsman',
        'bowl': 'bowler',
        'bwl': 'bowler',
        'all-rounder': 'all-rounder',
        'wicket-keeper': 'wicket-keeper',
      };

      final battingStyleMap = {
        'rhb': 'right-hand bat',
        'lhb': 'left-hand bat',
        'right-hand bat': 'right-hand bat',
        'left-hand bat': 'left-hand bat',
      };

      final bowlingStyleMap = {
        'rfm': 'right-arm fast',
        'rwm': 'right-arm medium',
        'lfm': 'left-arm fast',
        'lwm': 'left-arm medium',
        'la': 'leg-spin',
        'oa': 'off-spin',
        'none': 'none',
      };

      final transformedData = {
        'playerName': name,
        'role': roleMap[role?.toLowerCase()] ?? role ?? 'batsman',
        'battingStyle': battingStyleMap[battingStyle?.toLowerCase()] ?? battingStyle ?? 'right-hand bat',
        'bowlingStyle': bowlingStyleMap[bowlingStyle?.toLowerCase()] ?? bowlingStyle ?? 'none',
        if (team != null && team.isNotEmpty) 'team': team,
        if (jerseyNumber != null) 'jerseyNumber': jerseyNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'dateOfBirth': dateOfBirth,
        if (nationality != null && nationality.isNotEmpty) 'nationality': nationality,
        if (stats != null) 'stats': stats,
      };

      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/players',
        data: transformedData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _cacheService.clearAll();
        final playerData = response.data['data'] ?? response.data;
        if (playerData is Map) {
          return Player.fromJson(Map<String, dynamic>.from(playerData));
        }
        throw Exception('Invalid player data format');
      }
      throw Exception(response.data['message'] ?? 'Failed to create player');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Update player
  Future<Player> updatePlayer(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.baseUrl}/players/$id',
        data: data,
      );

      if (response.statusCode == 200) {
        _cacheService.clearAll();
        final playerData = response.data['data'] ?? response.data;
        if (playerData is Map) {
          return Player.fromJson(Map<String, dynamic>.from(playerData));
        }
        throw Exception('Invalid player data format');
      }
      throw Exception(response.data['message'] ?? 'Failed to update player');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Delete player
  Future<void> deletePlayer(String id) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.baseUrl}/players/$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(response.data['message'] ?? 'Failed to delete player');
      }
      _cacheService.clearAll();
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to delete player: $e');
    }
  }

  /// Clear cache
  void clearCache() {
    _cacheService.clearAll();
  }
}
