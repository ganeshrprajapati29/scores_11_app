import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/tournament_model.dart';

class TournamentService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Tournament>> getTournaments({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.tournaments}',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((json) => Tournament.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get tournaments');
    } catch (e) {
      rethrow;
    }
  }

  Future<Tournament> getTournamentById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.tournaments}/$id');
      if (response.statusCode == 200) {
        return Tournament.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get tournament');
    } catch (e) {
      rethrow;
    }
  }

  Future<Tournament> createTournament({
    required String name,
    String? shortName,
    String? description,
    required String organizer,
    String format = 'T20',
    String type = 'LEAGUE',
    DateTime? startDate,
    DateTime? endDate,
    String? venue,
    int totalTeams = 0,
    int overs = 20,
    bool isPaid = false,
    double? entryFee,
    double? prizeMoney,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.tournaments}',
        data: {
          'name': name,
          if (shortName != null) 'shortName': shortName,
          if (description != null) 'description': description,
          'organizer': organizer,
          'format': format,
          'type': type,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (venue != null) 'venue': venue,
          'totalTeams': totalTeams,
          'overs': overs,
          'isPaid': isPaid,
          if (entryFee != null) 'entryFee': entryFee,
          if (prizeMoney != null) 'prizeMoney': prizeMoney,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Tournament.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create tournament');
    } catch (e) {
      rethrow;
    }
  }

  Future<Tournament> updateTournament(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.tournaments}/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        return Tournament.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update tournament');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTournament(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.tournaments}/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(response.data['message'] ?? 'Failed to delete tournament');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PointsTable>> getPointsTable(String tournamentId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.tournaments}/$tournamentId/points-table',
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((json) => PointsTable.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get points table');
    } catch (e) {
      rethrow;
    }
  }

  Future<Tournament> addTeam(String tournamentId, String teamId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.tournaments}/$tournamentId/teams',
        data: {'teamId': teamId},
      );
      if (response.statusCode == 200) {
        return Tournament.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to add team');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Tournament>> getLiveTournaments() async {
    return getTournaments(status: 'LIVE');
  }

  Future<List<Tournament>> getUpcomingTournaments({int limit = 10}) async {
    return getTournaments(status: 'UPCOMING', limit: limit);
  }
}
