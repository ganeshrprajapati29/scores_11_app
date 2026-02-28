import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/match_model.dart';

class MatchService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Match>> getMatches({
    int page = 1,
    int limit = 20,
    String? status,
    String? tournament,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.matches}',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
          if (tournament != null) 'tournament': tournament,
        },
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        return data.map((json) => Match.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get matches');
    } catch (e) {
      rethrow;
    }
  }

  Future<Match> getMatchById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.matches}/$id');
      if (response.statusCode == 200) {
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get match');
    } catch (e) {
      rethrow;
    }
  }

  Future<Match> createMatch({
    required String team1,
    required String team2,
    required DateTime scheduledDate,
    String? tournament,
    String format = 'T20',
    String matchType = 'LEAGUE',
    String? venueName,
    String? venueCity,
    int overs = 20,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.matches}',
        data: {
          'team1': team1,
          'team2': team2,
          'scheduledDate': scheduledDate.toIso8601String(),
          if (tournament != null) 'tournament': tournament,
          'format': format,
          'matchType': matchType,
          'venue': {
            'name': venueName ?? 'Stadium',
            'city': venueCity,
          },
          'overs': overs,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create match');
    } catch (e) {
      rethrow;
    }
  }

  Future<Match> updateMatch(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.matches}/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update match');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMatch(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.matches}/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(response.data['message'] ?? 'Failed to delete match');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Match> updateMatchStatus(String id, String status) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.matches}/$id/status',
        data: {'status': status},
      );
      if (response.statusCode == 200) {
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update status');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Match>> getLiveMatches() async {
    return getMatches(status: 'LIVE');
  }

  Future<List<Match>> getUpcomingMatches({int limit = 10}) async {
    return getMatches(status: 'SCHEDULED', limit: limit);
  }

  Future<List<Match>> getCompletedMatches({int limit = 10}) async {
    return getMatches(status: 'COMPLETED', limit: limit);
  }
}
