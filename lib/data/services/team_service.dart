import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/team_model.dart';

class TeamService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Team>> getTeams({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.teams}',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((json) => Team.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get teams');
    } catch (e) {
      rethrow;
    }
  }

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

  Future<Team> createTeam({
    required String name,
    String? shortName,
    String? description,
    String? coach,
    String? homeGround,
    String? city,
    String? state,
    String? country,
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
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create team');
    } catch (e) {
      rethrow;
    }
  }

  Future<Team> updateTeam(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.teams}/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        return Team.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update team');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTeam(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.teams}/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(response.data['message'] ?? 'Failed to delete team');
      }
    } catch (e) {
      rethrow;
    }
  }

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
