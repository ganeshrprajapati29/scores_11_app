import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/services/cache_service.dart';
import '../models/team_model.dart';

/// Pagination response wrapper for teams
class PaginatedTeams {
  final List<Team> teams;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  PaginatedTeams({
    required this.teams,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });
}

class TeamService {
  final ApiClient _apiClient = ApiClient();
  final CacheService _cacheService = CacheService();

  /// Get teams with pagination support
  Future<PaginatedTeams> getTeams({int page = 1, int limit = 20, String? search}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.teams}',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null) 'search': search,
        },
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final pagination = response.data['pagination'] ?? {};
        
        final teams = data.map((json) => Team.fromJson(json)).toList();
        
        return PaginatedTeams(
          teams: teams,
          page: pagination['page'] ?? page,
          limit: pagination['limit'] ?? limit,
          total: pagination['total'] ?? data.length,
          totalPages: pagination['pages'] ?? 1,
          hasMore: page < (pagination['pages'] ?? 1),
        );
      }
      throw Exception(response.data['message'] ?? 'Failed to get teams');
} on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Legacy method for backward compatibility
  Future<List<Team>> getTeamsList({int page = 1, int limit = 20}) async {
    final result = await getTeams(page: page, limit: limit);
    return result.teams;
  }

  /// Get team by ID
  Future<Team> getTeamById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.teams}/$id');
      if (response.statusCode == 200) {
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get team');
    } catch (e) {
      rethrow;
    }
  }

  /// Get public team info (less details)
  Future<Team> getTeamByIdPublic(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.teams}/public/$id');
      if (response.statusCode == 200) {
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get public team');
    } catch (e) {
      rethrow;
    }
  }

  /// Search teams
  Future<List<Team>> searchTeams(String query, {int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.teams}/search',
        queryParameters: {'q': query, 'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Team.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to search teams');
    } catch (e) {
      rethrow;
    }
  }

  /// Get team rankings
  Future<PaginatedTeams> getTeamRankings({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.teams}/rankings',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final pagination = response.data['pagination'] ?? {};
        
        final teams = data.map((json) => Team.fromJson(json)).toList();
        
        return PaginatedTeams(
          teams: teams,
          page: pagination['page'] ?? page,
          limit: pagination['limit'] ?? limit,
          total: pagination['total'] ?? data.length,
          totalPages: pagination['pages'] ?? 1,
          hasMore: page < (pagination['pages'] ?? 1),
        );
      }
      throw Exception(response.data['message'] ?? 'Failed to get rankings');
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new team
  Future<Team> createTeam({
    required String name,
    String? shortName,
    String? description,
    String? coach,
    String? homeGround,
    String? city,
    String? state,
    String? country,
    bool isPublic = true,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.teams}',
        data: {
          'name': name,
          if (shortName != null) 'shortName': shortName,
          if (description != null) 'description': description,
          if (coach != null) 'coach': coach,
          if (homeGround != null) 'homeGround': homeGround,
          if (city != null) 'city': city,
          if (state != null) 'state': state,
          if (country != null) 'country': country,
          'isPublic': isPublic,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create team');
    } catch (e) {
      rethrow;
    }
  }

  /// Update team
  Future<Team> updateTeam(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.teams}/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update team');
    } catch (e) {
      rethrow;
    }
  }

  /// Delete team
  Future<void> deleteTeam(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.teams}/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(response.data['message'] ?? 'Failed to delete team');
      }
      _cacheService.clearMatchesCache();
    } catch (e) {
      rethrow;
    }
  }

  /// Add player to team
  Future<Team> addPlayer(String teamId, String playerId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.teams}/$teamId/players',
        data: {'playerId': playerId},
      );
      if (response.statusCode == 200) {
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to add player');
    } catch (e) {
      rethrow;
    }
  }

  /// Remove player from team
  Future<Team> removePlayer(String teamId, String playerId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.teams}/$teamId/players/$playerId',
      );
      if (response.statusCode == 200) {
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to remove player');
    } catch (e) {
      rethrow;
    }
  }

  /// Get team matches
  Future<List<dynamic>> getTeamMatches(String teamId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.teams}/$teamId/matches',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data;
      }
      throw Exception(response.data['message'] ?? 'Failed to get team matches');
    } catch (e) {
      rethrow;
    }
  }

  /// Set team captain
  Future<Team> setCaptain(String teamId, String playerId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.teams}/$teamId/captain',
        data: {'playerId': playerId},
      );
      if (response.statusCode == 200) {
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to set captain');
    } catch (e) {
      rethrow;
    }
  }

  /// Set team vice-captain
  Future<Team> setViceCaptain(String teamId, String playerId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.teams}/$teamId/vice-captain',
        data: {'playerId': playerId},
      );
      if (response.statusCode == 200) {
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to set vice-captain');
    } catch (e) {
      rethrow;
    }
  }

  /// Upload team logo
  Future<Team> uploadLogo(String teamId, File file) async {
    try {
      final formData = FormData.fromMap({
        'logo': await MultipartFile.fromFile(file.path, filename: 'logo_${teamId}.jpg'),
      });
      final response = await _apiClient.uploadFile(
        '${ApiConfig.teams}/$teamId/logo',
        formData: formData,
      );
      if (response.statusCode == 200) {
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to upload logo');
    } catch (e) {
      rethrow;
    }
  }

  /// Transfer team ownership
  Future<Team> transferOwnership(String teamId, String newOwnerId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.teams}/$teamId/transfer',
        data: {'newOwnerId': newOwnerId},
      );
      if (response.statusCode == 200) {
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to transfer ownership');
    } catch (e) {
      rethrow;
    }
  }

  /// Get my teams
  Future<List<Team>> getMyTeams() async {
    try {
      final response = await _apiClient.get('${ApiConfig.teams}/my-teams');
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((json) => Team.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get my teams');
    } catch (e) {
      rethrow;
    }
  }
}
