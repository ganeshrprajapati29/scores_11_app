import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/services/cache_service.dart';
import '../models/match_model.dart';

/// Pagination response wrapper
class PaginatedMatches {
  final List<Match> matches;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  PaginatedMatches({
    required this.matches,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });
}

class MatchService {
  final ApiClient _apiClient = ApiClient();
  final CacheService _cacheService = CacheService();

  /// Get matches with pagination support and caching
  Future<PaginatedMatches> getMatches({
    int page = 1,
    int limit = 20,
    String? status,
    String? tournament,
    bool forceRefresh = false,
  }) async {
    // For first page with no filters, try cache first
    if (page == 1 && status == null && tournament == null && !forceRefresh) {
      final cachedData = _cacheService.getCachedMatches(ttlMinutes: 5);
      if (cachedData != null) {
        final matches = cachedData.map((json) => Match.fromJson(json)).toList();
        return PaginatedMatches(
          matches: matches,
          page: 1,
          limit: limit,
          total: matches.length,
          totalPages: (matches.length / limit).ceil(),
          hasMore: matches.length >= limit,
        );
      }
    }

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
        final List data = response.data['data'] ?? [];
        final pagination = response.data['pagination'] ?? {};
        
        final matches = data.map((json) => Match.fromJson(json)).toList();
        
        // Cache first page results
        if (page == 1 && status == null && tournament == null) {
          final matchesJson = matches.map((m) => m.toJson()).toList().cast<Map<String, dynamic>>();
          _cacheService.cacheMatches(matchesJson);
        }
        
        return PaginatedMatches(
          matches: matches,
          page: pagination['page'] ?? page,
          limit: pagination['limit'] ?? limit,
          total: pagination['total'] ?? data.length,
          totalPages: pagination['pages'] ?? 1,
          hasMore: page < (pagination['pages'] ?? 1),
        );
      }
      throw Exception(response.data['message'] ?? 'Failed to get matches');
    } catch (e) {
      // If API fails and we have cache, return cached data
      if (page == 1 && status == null && tournament == null) {
        final cachedData = _cacheService.getCachedMatches(ttlMinutes: 60);
        if (cachedData != null) {
          final matches = cachedData.map((json) => Match.fromJson(json)).toList();
          return PaginatedMatches(
            matches: matches,
            page: 1,
            limit: limit,
            total: matches.length,
            totalPages: 1,
            hasMore: false,
          );
        }
      }
      rethrow;
    }
  }

  /// Legacy method for backward compatibility - returns first page only
  Future<List<Match>> getMatchesList({
    int page = 1,
    int limit = 20,
    String? status,
    String? tournament,
  }) async {
    final result = await getMatches(
      page: page,
      limit: limit,
      status: status,
      tournament: tournament,
    );
    return result.matches;
  }

  /// Get match by ID with caching
  Future<Match> getMatchById(String id, {bool forceRefresh = false}) async {
    // Try cache first
    if (!forceRefresh) {
      final cachedData = _cacheService.getCachedMatchDetail(id, ttlMinutes: 5);
      if (cachedData != null) {
        return Match.fromJson(cachedData);
      }
    }

    try {
      final response = await _apiClient.get('${ApiConfig.matches}/$id');
      if (response.statusCode == 200) {
        final match = Match.fromJson(response.data['data']);
        
        // Cache the result
        _cacheService.cacheMatchDetail(id, match.toJson());
        
        return match;
      }
      throw Exception(response.data['message'] ?? 'Failed to get match');
    } catch (e) {
      // Try cache on error
      final cachedData = _cacheService.getCachedMatchDetail(id, ttlMinutes: 60);
      if (cachedData != null) {
        return Match.fromJson(cachedData);
      }
      rethrow;
    }
  }

  /// Get public match info (less details)
  Future<Match> getMatchByIdPublic(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.matches}/public/$id');
      if (response.statusCode == 200) {
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to get public match');
    } catch (e) {
      rethrow;
    }
  }

  /// Get live match score data
  Future<Map<String, dynamic>> getLiveScore(String matchId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/scoring/match/$matchId/live');
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to get live score');
    } catch (e) {
      rethrow;
    }
  }

  /// Get full scorecard
  Future<Map<String, dynamic>> getFullScorecard(String matchId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/scoring/match/$matchId/scorecard');
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to get scorecard');
    } catch (e) {
      rethrow;
    }
  }

  /// Get live matches - uses dedicated endpoint
  Future<List<Match>> getLiveMatches({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedData = _cacheService.getCachedLiveMatches(ttlMinutes: 1);
      if (cachedData != null) {
        return cachedData.map((json) => Match.fromJson(json)).toList();
      }
    }

    try {
      final response = await _apiClient.get('${ApiConfig.matches}/live');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final matches = data.map((json) => Match.fromJson(json)).toList();
        
        // Cache live matches with shorter TTL
        final matchesJson = matches.map((m) => m.toJson()).toList();
        _cacheService.cacheLiveMatches(matchesJson);
        
        return matches;
      }
      throw Exception(response.data['message'] ?? 'Failed to get live matches');
    } catch (e) {
      final cachedData = _cacheService.getCachedLiveMatches(ttlMinutes: 5);
      if (cachedData != null) {
        return cachedData.map((json) => Match.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  /// Get upcoming matches - uses dedicated endpoint
  Future<List<Match>> getUpcomingMatches({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.matches}/upcoming',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Match.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get upcoming matches');
    } catch (e) {
      rethrow;
    }
  }

  /// Get completed matches - uses dedicated endpoint
  Future<List<Match>> getCompletedMatches({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.matches}/completed',
        queryParameters: {'limit': limit.toString()},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Match.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get completed matches');
    } catch (e) {
      rethrow;
    }
  }

  /// Search matches
  Future<List<Match>> searchMatches(String query) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.matches}/search',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Match.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to search matches');
    } catch (e) {
      rethrow;
    }
  }

  /// Get matches by tournament
  Future<List<Match>> getTournamentMatches(String tournamentId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.matches}/tournament/$tournamentId');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Match.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get tournament matches');
    } catch (e) {
      rethrow;
    }
  }

  /// Get matches by team
  Future<List<Match>> getTeamMatches(String teamId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.matches}/team/$teamId');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Match.fromJson(json)).toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to get team matches');
    } catch (e) {
      rethrow;
    }
  }

  /// Get match timeline
  Future<Map<String, dynamic>> getMatchTimeline(String matchId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.matches}/$matchId/timeline');
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to get match timeline');
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new match
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
        _cacheService.clearMatchesCache();
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to create match');
    } catch (e) {
      rethrow;
    }
  }

  /// Update match
  Future<Match> updateMatch(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.matches}/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        _cacheService.cacheMatchDetail(id, response.data['data']);
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update match');
    } catch (e) {
      rethrow;
    }
  }

  /// Delete match
  Future<void> deleteMatch(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.matches}/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(response.data['message'] ?? 'Failed to delete match');
      }
      _cacheService.clearMatchesCache();
    } catch (e) {
      rethrow;
    }
  }

  /// Update match status
  Future<Match> updateMatchStatus(String id, String status) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.matches}/$id/status',
        data: {'status': status},
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        _cacheService.cacheMatchDetail(id, response.data['data']);
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update status');
    } catch (e) {
      rethrow;
    }
  }

  /// Schedule match
  Future<Match> scheduleMatch(String id, DateTime scheduledDate) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.matches}/$id/schedule',
        data: {'scheduledDate': scheduledDate.toIso8601String()},
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to schedule match');
    } catch (e) {
      rethrow;
    }
  }

  /// Update toss result
  Future<Match> updateToss(String id, String winner, String decision) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.matches}/$id/toss',
        data: {'tossWinner': winner, 'tossDecision': decision},
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update toss');
    } catch (e) {
      rethrow;
    }
  }

  /// Update match result
  Future<Match> updateResult(String id, Map<String, dynamic> result) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.matches}/$id/result',
        data: result,
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update result');
    } catch (e) {
      rethrow;
    }
  }

  /// Set match officials
  Future<Match> setOfficials(String id, Map<String, dynamic> officials) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.matches}/$id/officials',
        data: officials,
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to set officials');
    } catch (e) {
      rethrow;
    }
  }
}

