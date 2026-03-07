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
  /// 
  /// Algorithm:
  /// int page = 1;
  /// loadMore(){
  ///   page++;
  ///   fetchMatches(page);
  /// }
  /// 
  /// Cache Strategy:
  /// - First page requests: Check cache first, then API if cache expired
  /// - Subsequent pages: Always fetch from API (no pagination cache)
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
          final matchesJson = matches.map((m) => m.toJson()).toList();
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
        final cachedData = _cacheService.getCachedMatches(ttlMinutes: 60); // Longer TTL for offline
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

  /// Get live matches with short cache duration
  Future<List<Match>> getLiveMatches({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedData = _cacheService.getCachedLiveMatches(ttlMinutes: 1);
      if (cachedData != null) {
        return cachedData.map((json) => Match.fromJson(json)).toList();
      }
    }

    try {
      final result = await getMatches(status: 'LIVE');
      
      // Cache live matches with shorter TTL
      final matchesJson = result.matches.map((m) => m.toJson()).toList();
      _cacheService.cacheLiveMatches(matchesJson);
      
      return result.matches;
    } catch (e) {
      final cachedData = _cacheService.getCachedLiveMatches(ttlMinutes: 5);
      if (cachedData != null) {
        return cachedData.map((json) => Match.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<List<Match>> getUpcomingMatches({int limit = 10}) async {
    final result = await getMatches(status: 'SCHEDULED', limit: limit);
    return result.matches;
  }

  Future<List<Match>> getCompletedMatches({int limit = 10}) async {
    final result = await getMatches(status: 'COMPLETED', limit: limit);
    return result.matches;
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
        // Clear matches cache after creating new match
        _cacheService.clearMatchesCache();
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
        // Clear cache after update
        _cacheService.clearMatchesCache();
        _cacheService.cacheMatchDetail(id, response.data['data']);
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
      // Clear cache after delete
      _cacheService.clearMatchesCache();
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
        // Clear cache after status update
        _cacheService.clearMatchesCache();
        _cacheService.cacheMatchDetail(id, response.data['data']);
        return Match.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Failed to update status');
    } catch (e) {
      rethrow;
    }
  }
}

