import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/services/cache_service.dart';
import '../models/team_model.dart';
import '../models/player_model.dart';

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

  factory PaginatedTeams.fromJson(Map<String, dynamic> json) {
    List<dynamic> dataList = [];
    if (json['data'] is List) {
      dataList = json['data'] as List<dynamic>;
    } else if (json['data'] is Map<String, dynamic>) {
      dataList = [json['data']];
    }
    final pagination = json['pagination'] ?? <String, dynamic>{};
    return PaginatedTeams(
      teams: dataList.map((t) => Team.fromJson(t as Map<String, dynamic>)).toList(),
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 10,
      total: pagination['total'] ?? 0,
      totalPages: pagination['pages'] ?? 1,
      hasMore: (pagination['page'] ?? 1) < (pagination['pages'] ?? 1),
    );
  }
}

class TeamService {
  final ApiClient _apiClient = ApiClient();
  final CacheService _cacheService = CacheService();

  List<Player> _playersFromRaw(dynamic rawPlayers) {
    if (rawPlayers is! List) return const [];

    return rawPlayers
        .whereType<Map>()
        .map((json) => Player.fromJson(Map<String, dynamic>.from(json)))
        .where((player) => player.id.isNotEmpty)
        .toList();
  }

  /// Get all teams (both user's teams and public teams)
  Future<List<Team>> getAllTeams() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/teams',
        queryParameters: {
          'page': 1,
          'limit': 100,
        },
      );
      if (response.statusCode == 200) {
        dynamic rawData = response.data['data'];
        final List data = rawData is List ? rawData : (rawData is Map ? [rawData] : []);
        final teams = data.map((json) => Team.fromJson(json)).toList();
        
        try {
          final myTeams = await getMyTeams();
          final allTeamsMap = <String, Team>{};
          for (var team in teams) {
            allTeamsMap[team.id] = team;
          }
          for (var team in myTeams) {
            allTeamsMap[team.id] = team;
          }
          return allTeamsMap.values.toList();
        } catch (e) {
          return teams;
        }
      }
      throw Exception(response.data['message'] ?? 'Failed to get teams');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      try {
        return await getMyTeams();
      } catch (e2) {
        throw Exception(e.toString());
      }
    }
  }

  /// Get teams with pagination support
  Future<PaginatedTeams> getTeams({int page = 1, int limit = 20, String? search}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/teams',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null) 'search': search,
        },
      );
      if (response.statusCode == 200) {
        dynamic rawData = response.data['data'];
        final List data = rawData is List ? rawData : (rawData is Map ? [rawData] : []);
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

  /// Get teams list for backward compatibility
  Future<List<Team>> getTeamsList({int page = 1, int limit = 20}) async {
    final result = await getTeams(page: page, limit: limit);
    return result.teams;
  }

  /// Get team by ID
  Future<Team> getTeamById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/teams/$id');
      if (response.statusCode == 200) {
        final teamData = response.data['data'] ?? response.data;
        return Team.fromJson(teamData);
      }
      throw Exception(response.data['message'] ?? 'Failed to get team');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get team by ID with populated players details
  Future<Map<String, dynamic>> getTeamWithPlayers(String id) async {
    try {
      final teamResponse = await _apiClient.get('${ApiConfig.baseUrl}/teams/$id');
      
      if (teamResponse.statusCode == 200) {
        final teamData = teamResponse.data['data'] ?? teamResponse.data;
        final team = Team.fromJson(teamData);
        final embeddedPlayers = _playersFromRaw(
          teamData is Map ? teamData['players'] : null,
        );

        List<Player> players = const [];
        try {
          final playersResponse = await _apiClient.get('${ApiConfig.baseUrl}/players/team/$id');
          if (playersResponse.statusCode == 200) {
            final playersData = playersResponse.data['data'];
            players = _playersFromRaw(playersData is List
                ? playersData
                : playersData is Map
                    ? playersData['players']
                    : playersResponse.data['players']);
          }
        } catch (_) {
          players = const [];
        }

        return {
          'team': team,
          'players': players.isNotEmpty ? players : embeddedPlayers,
        };
      }
      throw Exception('Failed to load team with players');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get public team info (less details)
  Future<Team> getTeamByIdPublic(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/teams/public/$id');
      if (response.statusCode == 200) {
        final teamData = response.data['data'] ?? response.data;
        return Team.fromJson(teamData);
      }
      throw Exception(response.data['message'] ?? 'Failed to get public team');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Search teams
  Future<List<Team>> searchTeams(String query, {int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/teams/search',
        queryParameters: {'q': query, 'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        dynamic rawData = response.data['data'];
        final List data = rawData is List ? rawData : (rawData is Map ? [rawData] : []);
        return data.map((json) => Team.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to search teams');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get team rankings
  Future<PaginatedTeams> getTeamRankings({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/teams/rankings',
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
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// CREATE TEAM with players, captain, and vice-captain (ONE API CALL)
  Future<Team> createTeam({
    required String name,
    String? shortName,
    String? coach,
    String? description,
    String? city,
    String? state,
    String? country,
    String? homeGround,
    required List<String> players,
    required String captainId,
    required String viceCaptainId,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/teams',
        data: {
          'name': name,
          if (shortName != null && shortName.isNotEmpty) 'shortName': shortName,
          if (coach != null && coach.isNotEmpty) 'coach': coach,
          if (description != null && description.isNotEmpty) 'description': description,
          if (city != null && city.isNotEmpty) 'city': city,
          if (state != null && state.isNotEmpty) 'state': state,
          if (country != null && country.isNotEmpty) 'country': country,
          if (homeGround != null && homeGround.isNotEmpty) 'homeGround': homeGround,
          'players': players,
          'captainId': captainId,
          'viceCaptainId': viceCaptainId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        final teamData = response.data['data'] ?? response.data;
        return Team.fromJson(teamData);
      }
      throw Exception(response.data['message'] ?? 'Failed to create team');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  /// Update team
  Future<Team> updateTeam(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.baseUrl}/teams/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        final teamData = response.data['data'] ?? response.data;
        return Team.fromJson(teamData);
      }
      throw Exception(response.data['message'] ?? 'Failed to update team');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Delete team
  Future<void> deleteTeam(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.baseUrl}/teams/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(response.data['message'] ?? 'Failed to delete team');
      }
      _cacheService.clearMatchesCache();
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Add player to team (legacy method)
  Future<Team> addPlayer(String teamId, String playerId, {String? matchId}) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/teams/$teamId/players',
        data: {
          'playerId': playerId,
          if (matchId != null && matchId.isNotEmpty) 'matchId': matchId,
        },
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        final teamData = response.data['data'] ?? response.data;
        return Team.fromJson(teamData);
      }
      throw Exception(response.data['message'] ?? 'Failed to add player');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Remove player from team
  Future<Team> removePlayer(String teamId, String playerId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.baseUrl}/teams/$teamId/players/$playerId',
      );
      if (response.statusCode == 200) {
        final teamData = response.data['data'] ?? response.data;
        return Team.fromJson(teamData);
      }
      throw Exception(response.data['message'] ?? 'Failed to remove player');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get team matches
  Future<List<dynamic>> getTeamMatches(String teamId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/teams/$teamId/matches',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data;
      }
      throw Exception(response.data['message'] ?? 'Failed to get team matches');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Set team captain (legacy)
  Future<Team> setCaptain(String teamId, String playerId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/teams/$teamId/captain',
        data: {'playerId': playerId},
      );
      if (response.statusCode == 200) {
        final teamData = response.data['data'] ?? response.data;
        return Team.fromJson(teamData);
      }
      throw Exception(response.data['message'] ?? 'Failed to set captain');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Set team vice-captain (legacy)
  Future<Team> setViceCaptain(String teamId, String playerId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/teams/$teamId/vice-captain',
        data: {'playerId': playerId},
      );
      if (response.statusCode == 200) {
        final teamData = response.data['data'] ?? response.data;
        return Team.fromJson(teamData);
      }
      throw Exception(response.data['message'] ?? 'Failed to set vice-captain');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Upload team logo
  Future<Team> uploadLogo(String teamId, File file) async {
    try {
      final formData = FormData.fromMap({
        'logo': await MultipartFile.fromFile(file.path, filename: 'logo_${teamId}.jpg'),
      });
      final response = await _apiClient.uploadFile(
        '${ApiConfig.baseUrl}/teams/$teamId/logo',
        formData: formData,
      );
      if (response.statusCode == 200) {
        final teamData = response.data['data'] ?? response.data;
        return Team.fromJson(teamData);
      }
      throw Exception(response.data['message'] ?? 'Failed to upload logo');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Upload team logo (alternative method name for compatibility)
  Future<void> uploadTeamLogo(String teamId, File logoFile) async {
    try {
      final formData = FormData.fromMap({
        'logo': await MultipartFile.fromFile(logoFile.path),
      });
      
      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/teams/$teamId/logo',
        data: formData,
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload logo');
      }
      _cacheService.clearMatchesCache();
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    }
  }

  /// Transfer team ownership
  Future<Team> transferOwnership(String teamId, String newOwnerId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/teams/$teamId/transfer',
        data: {'newOwnerId': newOwnerId},
      );
      if (response.statusCode == 200) {
        final teamData = response.data['data'] ?? response.data;
        return Team.fromJson(teamData);
      }
      throw Exception(response.data['message'] ?? 'Failed to transfer ownership');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Get my teams (user's own teams)
  Future<List<Team>> getMyTeams() async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/teams/my-teams');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Team.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get my teams');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Clear all caches
  void clearCache() {
    _cacheService.clearAll();
  }
}
