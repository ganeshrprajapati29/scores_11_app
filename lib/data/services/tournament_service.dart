import 'dart:math' as math;
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../models/tournament_model.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
// import 'dart:developer';

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
    final Map<String, String> statusMap = {
      'LIVE': 'in_progress',
      'UPCOMING': 'published',
      'COMPLETED': 'completed',
    };
    final String? backendStatus = status != null ? statusMap[status] ?? status.toLowerCase() : null;

    try {
        final response = await _apiClient.get(ApiConfig.tournaments, queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (backendStatus != null) 'status': backendStatus,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? {};
        final List<dynamic> tournamentJson = data['tournaments'] ?? [];
        final List<Tournament> tournaments = tournamentJson
            .map((json) => Tournament.fromJson(json))
            .toList();
        final Map<String, dynamic> pagination = data['pagination'] ?? {};

        return PaginatedTournaments(
          tournaments: tournaments,
          page: page,
          limit: limit,
          total: pagination['total'] ?? tournaments.length,
          totalPages: pagination['pages'] ?? 1,
          hasMore: page < (pagination['pages'] ?? 1),
        );
      }
      // Fallback to mock data on API failure
      return _getMockTournaments(page, limit);
    } catch (e) {
      debugPrint('Tournament service error (fallback): $e');
      return PaginatedTournaments(
        tournaments: [],
        page: page,
        limit: limit,
        total: 0,
        totalPages: 0,
        hasMore: false,
      );
    }
  }


PaginatedTournaments _getMockTournaments(int page, int limit) {
    final mockData = [
      Tournament(
        id: 'mock1',
        name: 'IPL 2024',
        shortName: 'IPL',
        organizer: 'Mock Cricket League',
        format: 'T20',
        type: 'LEAGUE',
        status: 'LIVE',
        totalTeams: 10,
        entryFee: 100,
        prizeMoney: 100000,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 60)),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        venue: 'Wankhede Stadium',
        isPaid: true,
      ),
      Tournament(
        id: 'mock2',
        name: 'T20 Blast 2024',
        shortName: 'Blast',
        organizer: 'Mock County Cricket',
        format: 'T20',
        type: 'LEAGUE',
        status: 'UPCOMING',
        totalTeams: 18,
        entryFee: 50,
        prizeMoney: 50000,
        startDate: DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 90)),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
        venue: 'Edgbaston',
        isPaid: false,
      ),
      Tournament(
        id: 'mock3',
        name: 'Local League 2024',
        shortName: 'Local',
        organizer: 'Local Cricket Association',
        format: 'ODI',
        type: 'LEAGUE',
        status: 'COMPLETED',
        totalTeams: 8,
        entryFee: 20,
        prizeMoney: 5000,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        venue: 'Local Ground',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now(),
        isPaid: true,
      ),
      // Add more mock data for pagination testing
      Tournament(
        id: 'mock4',
        name: 'International T20 Series',
        shortName: 'INTL',
        organizer: 'International Cricket Council',
        format: 'T20',
        type: 'LEAGUE',
        status: 'LIVE',
        totalTeams: 2,
        entryFee: 0,
        prizeMoney: 1000000,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
        venue: 'M Chinnaswamy Stadium',
        isPaid: false,
      ),
      Tournament(
        id: 'mock5',

        name: "Women's Premier League",
        shortName: 'WPL',
        organizer: 'Mock Women Cricket',
        format: 'T20',

        type: 'LEAGUE',
        status: 'UPCOMING',
        totalTeams: 5,
        entryFee: 75,
        prizeMoney: 20000,
        startDate: DateTime.now().add(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 45)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
        venue: 'Arun Jaitley Stadium',
        isPaid: true,
      ),
    ];

    // ✅ FIXED: Safe pagination for String page/limit params
    final int safePage = int.tryParse(page?.toString() ?? '1') ?? 1;
    final int safeLimit = int.tryParse(limit?.toString() ?? '20') ?? 20;
    final int startIndex = math.max(0, (safePage - 1) * safeLimit);
    final int endIndex = math.min(startIndex + safeLimit, mockData.length);
    
    final List<Tournament> pageData = startIndex < mockData.length 
        ? mockData.sublist(startIndex, math.min(endIndex, mockData.length))
        : [];
    
    return PaginatedTournaments(
      tournaments: pageData,
      page: page,
      limit: limit,
      total: mockData.length,
      totalPages: (mockData.length / limit).ceil(),
      hasMore: endIndex < mockData.length,
    );
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
    required String format,
    String type = 'LEAGUE',
    required DateTime startDate,
    required DateTime endDate,
    String? venue,
    int totalTeams = 10,
    double? entryFee,
    double? prizeMoney,
  }) async {
    // Use current user ID from auth token (ApiClient handles automatically)
    // For now use mock organizer ID - replace with real user ID extraction later
    const String organizer = 'current_user_mock_id';

    if (startDate == null) throw Exception('Start date required');
    if (endDate == null) throw Exception('End date required');
    try {
        final Map<String, dynamic> venueObj = {
          'name': venue ?? 'Default Stadium',
          'city': 'Delhi',
          'state': 'Delhi', 
          'country': 'India',
        };

        final response = await _apiClient.post(
          ApiConfig.tournaments,
          data: {
            'name': name,
            if (shortName != null) 'shortName': shortName,
            if (description != null) 'description': description,
            'organizer': organizer,
            'format': format,
            'type': type,
            'startDate': startDate.toIso8601String(),
            'endDate': endDate.toIso8601String(),
            'venue': venueObj,
            'maxTeams': totalTeams,
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

  /// Get points table (TODO: implement PointsTable model)
  /*
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
  */

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
