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
    final List data = json['data'] ?? [];
    final pagination = json['pagination'] ?? {};
    return PaginatedPlayers(
      players: data.map((p) => Player.fromJson(p)).toList(),
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 10,
      total: pagination['total'] ?? 0,
      totalPages: pagination['pages'] ?? 1,
      hasMore: (pagination['page'] ?? 1) < (pagination['pages'] ?? 1),
    );
  }
}

class PlayerService {
  final ApiClient _apiClient = ApiClient();
  final CacheService _cacheService = CacheService();

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

  Future<PaginatedPlayers> getPlayers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? team,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/players',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null) 'search': search,
          if (role != null) 'role': role,
          if (team != null) 'team': team,
        },
      );
      if (response.statusCode == 200) {
        return PaginatedPlayers.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to load players');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
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

  /// Create new player
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
      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/players',
        data: {
          'name': name,
          if (role != null) 'role': role,
          if (battingStyle != null) 'battingStyle': battingStyle,
          if (bowlingStyle != null) 'bowlingStyle': bowlingStyle,
          if (team != null) 'team': team,
          if (jerseyNumber != null) 'jerseyNumber': jerseyNumber,
          if (phone != null) 'phone': phone,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (nationality != null) 'nationality': nationality,
          if (stats != null) 'stats': stats,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _cacheService.clearAll();
        return Player.fromJson(response.data['data']);
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

