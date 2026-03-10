import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/tournament_model.dart';

/// Pagination response wrapper for tournaments
class PaginatedTournaments {
  final List<Tournament> tournaments;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  PaginatedTournaments({
    required this.tournaments,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });
}

class TournamentService {
  final ApiClient _apiClient = ApiClient();

  /// Get tournaments with pagination support
  Future<PaginatedTournaments> getTournaments({
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
        final List data = response.data['data'] ?? [];
        final pagination = response.data['pagination'] ?? {};
        
        final tournaments = data.map((json) => Tournament.fromJson(json)).toList();
        
        return PaginatedTournaments(
          tournaments: tournaments,
          page: pagination['page'] ?? page,
          limit: pagination['limit'] ?? limit,
          total: pagination['total'] ?? data.length,
          totalPages: pagination['pages'] ?? 1,
          hasMore: page < (pagination['pages'] ?? 1),
        );
      }
      throw Exception(response.data['message'] ?? 'Failed to get tournaments');
    } catch (e) {
      rethrow;
    }
  }

  /// Legacy method for backward compatibility
  Future<List<Tournament>> getTournamentsList({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final result = await getTournaments(page: page, limit: limit, status: status);
    return result.tournaments;
  }

  /// Get tournament by ID
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

  /// Get public tournament info (less details)
  Future<Tournament> getTournamentByIdPublic(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.tournaments}/public/$id');
      if (response.statusCode == 200) {
        return Tournament.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get public tournament');
    } catch (e) {
      rethrow;
    }
  }

  /// Get ongoing tournaments
  Future<List<Tournament>> getOngoingTournaments({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.tournaments}/ongoing',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Tournament.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get ongoing tournaments');
    } catch (e) {
      rethrow;
    }
  }

  /// Get upcoming tournaments
  Future<List<Tournament>> getUpcomingTournaments({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.tournaments}/upcoming',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Tournament.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get upcoming tournaments');
    } catch (e) {
      rethrow;
    }
  }

  /// Get live tournaments
  Future<List<Tournament>> getLiveTournaments() async {
    try {
      final response = await _apiClient.get('${ApiConfig.tournaments}/ongoing');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Tournament.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get live tournaments');
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new tournament
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

  /// Update tournament
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

  /// Delete tournament
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

  /// Register team for tournament
  Future<Tournament> registerTeam(String tournamentId, String teamId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.tournaments}/$tournamentId/register',
        data: {'teamId': teamId},
      );
      if (response.statusCode == 200) {
        return Tournament.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to register team');
    } catch (e) {
      rethrow;
    }
  }

  /// Unregister team from tournament
  Future<Tournament> unregisterTeam(String tournamentId, String teamId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.tournaments}/$tournamentId/register',
        data: {'teamId': teamId},
      );
      if (response.statusCode == 200) {
        return Tournament.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to unregister team');
    } catch (e) {
      rethrow;
    }
  }

  /// Update tournament status
  Future<Tournament> updateStatus(String tournamentId, String status) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.tournaments}/$tournamentId/status',
        data: {'status': status},
      );
      if (response.statusCode == 200) {
        return Tournament.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update status');
    } catch (e) {
      rethrow;
    }
  }

  /// Get points table
  Future<List<PointsTable>> getPointsTable(String tournamentId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.tournaments}/$tournamentId/points-table',
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => PointsTable.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get points table');
    } catch (e) {
      rethrow;
    }
  }

  /// Add team to tournament
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

  /// Generate league matches
  Future<Map<String, dynamic>> generateLeagueMatches(String tournamentId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.tournaments}/$tournamentId/generate/league',
      );
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to generate league matches');
    } catch (e) {
      rethrow;
    }
  }

  /// Generate knockout matches
  Future<Map<String, dynamic>> generateKnockoutMatches(String tournamentId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.tournaments}/$tournamentId/generate/knockout',
      );
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to generate knockout matches');
    } catch (e) {
      rethrow;
    }
  }

  /// Get tournament stats
  Future<Map<String, dynamic>> getTournamentStats(String tournamentId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.tournaments}/$tournamentId/stats',
      );
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to get tournament stats');
    } catch (e) {
      rethrow;
    }
  }
}
