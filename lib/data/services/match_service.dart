import '../../core/config/api_config.dart';
import 'package:dio/dio.dart';
import '../models/match_model.dart';
import '../../core/services/api_client.dart';
import '../../core/services/cache_service.dart';
import 'package:flutter/foundation.dart';

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
  static bool get _preferFastMatchCache => false;

  /// Get matches with pagination support and caching
  Future<PaginatedMatches> getMatches({
    int page = 1,
    int limit = 20,
    String? status,
    String? tournament,
    bool forceRefresh = false,
  }) async {
    // Live/completed score state changes quickly; only use match-list cache when explicitly requested.
    if (_preferFastMatchCache &&
        page == 1 &&
        status == null &&
        tournament == null &&
        !forceRefresh) {
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
        final cachedData = _cacheService.getCachedMatches(ttlMinutes: 60);
        if (cachedData != null) {
          final matches = cachedData
              .map((json) => Match.fromJson(json))
              .toList();
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

  /// Get only matches created by the logged-in user.
  Future<PaginatedMatches> getMyMatches({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.matches}/my-matches',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
        },
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final pagination = response.data['pagination'] ?? {};
        final matches = data.map((json) => Match.fromJson(json)).toList();

        return PaginatedMatches(
          matches: matches,
          page: pagination['page'] ?? page,
          limit: pagination['limit'] ?? limit,
          total: pagination['total'] ?? data.length,
          totalPages: pagination['pages'] ?? 1,
          hasMore: page < (pagination['pages'] ?? 1),
        );
      }
      throw Exception(response.data['message'] ?? 'Failed to get your matches');
    } catch (e) {
      rethrow;
    }
  }

  /// Get match by ID with caching
  Future<Match> getMatchById(String id, {bool forceRefresh = false}) async {
    // Match score/status is live data, so prefer API and keep cache only as offline fallback.
    if (_preferFastMatchCache && !forceRefresh) {
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
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/scoring/match/$matchId/live',
      );
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to get live score');
    } catch (e) {
      rethrow;
    }
  }

  /// Get full scorecard - FIXED with proper 404 handling
  Future<Map<String, dynamic>> getFullScorecard(
    String matchId, {
    Match? match,
  }) async {
    debugPrint('🔍 Loading scorecard for matchId: $matchId');

    // Skip if match is scheduled
    if (match?.status == 'SCHEDULED' || match?.status == 'scheduled') {
      debugPrint('⏳ Match scheduled, returning basic scorecard');
      return _buildBasicScorecard(match!);
    }

    // Try different endpoints in order - same as website
    final List<String> endpoints = [
      '/scoring/match/$matchId/scorecard',
      '/scoring/match/$matchId/full-scorecard',
      '/matches/$matchId/scorecard',
    ];

    for (final endpoint in endpoints) {
      try {
        debugPrint('📡 Trying endpoint: $endpoint');
        // FIXED: Accept ALL responses (100-599) - Don't throw on 404!
        // This is the key fix - 404 should NOT cause DioException
        final response = await _apiClient.get(
          '${ApiConfig.scoring}$endpoint'.replaceFirst('/scoring', ''),
          options: Options(
            validateStatus: (status) => status != null && status >= 100,
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

        debugPrint('📊 Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          dynamic data = response.data['data'] ?? response.data;
          if (data is List && data.isNotEmpty) {
            data = data.first;
          }
          if (data != null && data is Map) {
            debugPrint('✅ Scorecard found at endpoint: $endpoint');
            return data as Map<String, dynamic>;
          }
        } else if (response.statusCode == 404) {
          debugPrint('⚠️ Endpoint $endpoint returned 404, trying next...');
          continue;
        }
      } catch (e) {
        debugPrint('⚠️ Error at endpoint $endpoint: $e');
        continue;
      }
    }

    // Fallback 1: Try live score endpoint
    try {
      debugPrint('🔄 Trying live score fallback...');
      final liveResponse = await _apiClient.get(
        '${ApiConfig.scoring}/match/$matchId/live',
        options: Options(
          validateStatus: (status) => status != null && status >= 100,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (liveResponse.statusCode == 200) {
        final liveData = liveResponse.data['data'] ?? liveResponse.data ?? {};
        if (liveData.isNotEmpty) {
          debugPrint('✅ Live score fallback loaded');
          return liveData as Map<String, dynamic>;
        }
      }
    } catch (liveError) {
      debugPrint('⚠️ Live score error: $liveError');
    }

    // Fallback 2: Use basic match score from match data
    if (match != null) {
      debugPrint('📊 Using basic match score fallback');
      return _buildBasicScorecard(match);
    }

    debugPrint('⚠️ No scorecard data available - returning empty');
    return {};
  }

  Map<String, dynamic> _buildBasicScorecard(Match match) {
    return {
      'match': match.toJson(),
      'innings': match.innings.map((i) => i.toJson()).toList(),
      'batting': [],
      'bowling': [],
      'fallOfWickets': [],
      'partnerships': [],
      'score': match.score.toJson(),
      'status': match.status,
      'live': match.isLive,
    };
  }

  /// Get live matches - uses dedicated endpoint with sorting (newest first)
  Future<List<Match>> getLiveMatches({
    bool forceRefresh = false,
    int limit = 25,
    String sort = 'updatedAt',
    String order = 'desc',
  }) async {
    if (!forceRefresh) {
      final cachedData = _cacheService.getCachedLiveMatches(ttlMinutes: 1);
      if (cachedData != null) {
        return cachedData.map((json) => Match.fromJson(json)).toList();
      }
    }

    try {
      final response = await _apiClient.get(
        '${ApiConfig.matches}/live',
        queryParameters: {
          'limit': limit.toString(),
          'sort': sort,
          'order': order,
          if (forceRefresh) 'forceRefresh': 'true',
        },
      );
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

  /// Get upcoming matches - uses dedicated endpoint with sorting (soonest first)
  Future<List<Match>> getUpcomingMatches({
    int limit = 10,
    String sort = 'scheduledDate',
    String order = 'asc',
    bool forceRefresh = false,
  }) async {
    // For force refresh, clear cache first
    if (forceRefresh) {
      _cacheService.clearMatchesCache();
    }

    try {
      final response = await _apiClient.get(
        '${ApiConfig.matches}/upcoming',
        queryParameters: {
          'limit': limit.toString(),
          'sort': sort,
          'order': order,
          if (forceRefresh) 'forceRefresh': 'true',
        },
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Match.fromJson(json)).toList();
      }
      throw Exception(
        response.data['message'] ?? 'Failed to get upcoming matches',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get completed matches - uses dedicated endpoint with sorting (newest first)
  Future<List<Match>> getCompletedMatches({
    int limit = 10,
    String sort = 'scheduledDate',
    String order = 'desc',
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.matches}/completed',
        queryParameters: {
          'limit': limit.toString(),
          'sort': sort,
          'order': order,
        },
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Match.fromJson(json)).toList();
      }
      throw Exception(
        response.data['message'] ?? 'Failed to get completed matches',
      );
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
      final response = await _apiClient.get(
        '${ApiConfig.matches}/tournament/$tournamentId',
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => Match.fromJson(json)).toList();
      }
      throw Exception(
        response.data['message'] ?? 'Failed to get tournament matches',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get matches by team
  Future<List<Match>> getTeamMatches(String teamId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.matches}/team/$teamId',
      );
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
      final response = await _apiClient.get(
        '${ApiConfig.matches}/$matchId/timeline',
      );
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(
        response.data['message'] ?? 'Failed to get match timeline',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Match> createMatchSimple({
    required String team1,
    required String team2,
    required Map<String, dynamic> venue,
    // Optional: when omitted, the backend schedules the match for now.
    DateTime? scheduledDate,
    String format = 't20',
    int overs = 20,
    String ballType = 'leather',
    String matchCategory = 'standard',
  }) async {
    final data = {
      'team1': team1,
      'team2': team2,
      'venue': venue,
      if (scheduledDate != null) ...{
        'scheduledDate': scheduledDate.toIso8601String(),
        'startTime':
            '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}',
      },
      'format': format,
      'overs': overs,
      'ballType': ballType,
      'matchCategory': matchCategory,
    };

    return await _createMatchPayload(data);
  }

  Future<Match> _createMatchPayload(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.matches}',
        data: data,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        final matchData = response.data['data'] ?? response.data;
        return Match.fromJson(matchData);
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
        data: {'status': status.toLowerCase()},
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
        data: {'winner': winner, 'decision': decision.toLowerCase()},
        options: Options(
          validateStatus: (status) => status != null && status >= 100,
        ),
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchesCache();
        return Match.fromJson(response.data['data']);
      }
      final data = response.data;
      final message = data is Map ? data['message']?.toString() : null;
      throw Exception(message ?? 'Failed to update toss');
    } on DioException catch (e) {
      throw Exception(
        _apiClient.parseDioError(
          e,
          defaultMessage: 'Toss update failed. Please try again.',
        ),
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      throw Exception(message);
    }
  }

  Future<Match> undoToss(String id) async {
    final response = await _apiClient.delete('${ApiConfig.matches}/$id/toss');
    if (response.statusCode == 200) {
      _cacheService.clearMatchCache(id);
      return Match.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Failed to undo toss');
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

  // ========== SCORING METHODS ==========

  /// Initialize match for scoring (set batting order)
  Future<void> initializeMatch(
    String matchId,
    List<Map<String, dynamic>> battingOrder,
  ) async {
    try {
      final response = await _apiClient.post(
        '/scoring/match/$matchId/initialize',
        data: {'battingOrder': battingOrder},
        options: Options(
          validateStatus: (status) => status != null && status >= 100,
        ),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        final data = response.data;
        final message = data is Map ? data['message']?.toString() : null;
        throw Exception(message ?? 'Failed to initialize match');
      }
      _cacheService.clearMatchCache(matchId);
    } on DioException catch (e) {
      throw Exception(
        _apiClient.parseDioError(
          e,
          defaultMessage: 'Match initialize failed. Please try again.',
        ),
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      throw Exception(message);
    }
  }

  /// Add a ball to the match (score update)
  Future<Map<String, dynamic>> addBall(
    String matchId,
    Map<String, dynamic> ballData,
  ) async {
    try {
      final response = await _apiClient.post(
        '/scoring/match/$matchId/ball',
        data: ballData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _cacheService.clearMatchCache(matchId);
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to add ball');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getScoringRulesCatalogue() async {
    try {
      final response = await _apiClient.get('/scoring/rules');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(
        response.data['message'] ?? 'Failed to get scoring rules',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> applyRainDls(
    String matchId,
    Map<String, dynamic> rainData,
  ) async {
    try {
      final response = await _apiClient.post(
        '/scoring/match/$matchId/rain-dls',
        data: rainData,
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchCache(matchId);
        return Map<String, dynamic>.from(response.data['data'] ?? {});
      }
      throw Exception(response.data['message'] ?? 'Failed to apply rain/DLS');
    } catch (e) {
      rethrow;
    }
  }

  /// Undo the latest scored ball for a live match.
  Future<Map<String, dynamic>> undoLastBall(String matchId) async {
    try {
      final response = await _apiClient.post(
        '/scoring/match/$matchId/undo-last-ball',
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchCache(matchId);
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to undo last ball');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> retireBatter(
    String matchId,
    Map<String, dynamic> retirement,
  ) async {
    final response = await _apiClient.post(
      '/scoring/match/$matchId/batter/retire',
      data: retirement,
    );
    if (response.statusCode == 200) {
      _cacheService.clearMatchCache(matchId);
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    }
    throw Exception(response.data['message'] ?? 'Failed to retire batter');
  }

  Future<Map<String, dynamic>> updateInningsContinuation(
    String matchId,
    Map<String, dynamic> continuation,
  ) async {
    final response = await _apiClient.patch(
      '/scoring/match/$matchId/innings/continuation',
      data: continuation,
    );
    if (response.statusCode == 200) {
      _cacheService.clearMatchCache(matchId);
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    }
    throw Exception(
      response.data['message'] ?? 'Failed to update innings continuation',
    );
  }

  /// Start a new innings
  Future<void> startInnings(String matchId, int inningsNumber) async {
    try {
      final response = await _apiClient.post(
        '/scoring/match/$matchId/innings/start',
        data: {'inningsNumber': inningsNumber},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'Failed to start innings');
      }
      _cacheService.clearMatchCache(matchId);
    } catch (e) {
      rethrow;
    }
  }

  /// End current innings
  /// [inningsNumber] is the innings the scorer means to end: the server
  /// ignores a repeated request once that innings is already over.
  Future<void> endInnings(String matchId, {int? inningsNumber}) async {
    try {
      final response = await _apiClient.post(
        '/scoring/match/$matchId/innings/end',
        data: {if (inningsNumber != null) 'inningsNumber': inningsNumber},
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'Failed to end innings');
      }
      _cacheService.clearMatchCache(matchId);
    } catch (e) {
      rethrow;
    }
  }

  /// End the match
  Future<void> endMatch(String matchId) async {
    try {
      final response = await _apiClient.post('/scoring/match/$matchId/end');
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'Failed to end match');
      }
      _cacheService.clearMatchCache(matchId);
    } catch (e) {
      rethrow;
    }
  }

  /// Set the striker (on-strike batsman)
  /// Offline-queue sender for striker / non-striker / bowler changes.
  /// Unlike [setStriker] & co. it lets the original [DioException] through,
  /// so the caller can tell "no internet" (retry later) from "rejected".
  Future<void> sendScoringRoleRaw(
    String matchId,
    String role,
    String playerId,
  ) async {
    final path = role == 'bowler'
        ? 'bowler'
        : role == 'nonStriker'
            ? 'non-striker'
            : 'striker';
    await _apiClient.patch(
      '/scoring/match/$matchId/$path',
      data: role == 'bowler' ? {'bowlerId': playerId} : {'batsmanId': playerId},
    );
    _cacheService.clearMatchCache(matchId);
  }

  Future<void> setStriker(String matchId, String batsmanId) async {
    try {
      final response = await _apiClient.patch(
        '/scoring/match/$matchId/striker',
        data: {'batsmanId': batsmanId},
        options: Options(
          validateStatus: (status) => status != null && status >= 100,
        ),
      );
      if (response.statusCode != 200) {
        final data = response.data;
        final message = data is Map ? data['message']?.toString() : null;
        throw Exception(message ?? 'Failed to set striker');
      }
      _cacheService.clearMatchCache(matchId);
    } on DioException catch (e) {
      throw Exception(
        _apiClient.parseDioError(
          e,
          defaultMessage: 'Failed to set striker. Please try again.',
        ),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Atomically swap the current striker and non-striker.
  Future<void> swapStrike(String matchId) async {
    try {
      final response = await _apiClient.patch(
        '/scoring/match/$matchId/swap-strike',
        options: Options(
          validateStatus: (status) => status != null && status >= 100,
        ),
      );
      if (response.statusCode != 200) {
        final data = response.data;
        final message = data is Map ? data['message']?.toString() : null;
        throw Exception(message ?? 'Failed to swap strike');
      }
      _cacheService.clearMatchCache(matchId);
    } on DioException catch (e) {
      throw Exception(
        _apiClient.parseDioError(
          e,
          defaultMessage: 'Failed to swap strike. Please try again.',
        ),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Set the non-striker
  Future<void> setNonStriker(String matchId, String batsmanId) async {
    try {
      final response = await _apiClient.patch(
        '/scoring/match/$matchId/non-striker',
        data: {'batsmanId': batsmanId},
        options: Options(
          validateStatus: (status) => status != null && status >= 100,
        ),
      );
      if (response.statusCode != 200) {
        final data = response.data;
        final message = data is Map ? data['message']?.toString() : null;
        throw Exception(message ?? 'Failed to set non-striker');
      }
      _cacheService.clearMatchCache(matchId);
    } on DioException catch (e) {
      throw Exception(
        _apiClient.parseDioError(
          e,
          defaultMessage: 'Failed to set non-striker. Please try again.',
        ),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Set the current bowler
  Future<void> setBowler(String matchId, String bowlerId) async {
    try {
      final response = await _apiClient.patch(
        '/scoring/match/$matchId/bowler',
        data: {'bowlerId': bowlerId},
        options: Options(
          validateStatus: (status) => status != null && status >= 100,
        ),
      );
      if (response.statusCode != 200) {
        final data = response.data;
        final message = data is Map ? data['message']?.toString() : null;
        throw Exception(message ?? 'Failed to set bowler');
      }
      _cacheService.clearMatchCache(matchId);
    } on DioException catch (e) {
      throw Exception(
        _apiClient.parseDioError(
          e,
          defaultMessage: 'Failed to set bowler. Please try again.',
        ),
      );
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Get partnership details
  Future<Map<String, dynamic>> getPartnership(String matchId) async {
    try {
      final response = await _apiClient.get(
        '/scoring/match/$matchId/partnership',
      );
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to get partnership');
    } catch (e) {
      rethrow;
    }
  }

  /// Get fall of wickets
  Future<List<dynamic>> getFallOfWickets(String matchId) async {
    try {
      final response = await _apiClient.get(
        '/scoring/match/$matchId/fall-of-wickets',
      );
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      throw Exception(
        response.data['message'] ?? 'Failed to get fall of wickets',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get over summary for a specific over
  Future<Map<String, dynamic>> getOverSummary(
    String matchId,
    int overNumber,
  ) async {
    try {
      final response = await _apiClient.get(
        '/scoring/match/$matchId/over-summary/$overNumber',
      );
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to get over summary');
    } catch (e) {
      rethrow;
    }
  }

  /// Over-by-over breakdown (runs/wickets per over) for the whole innings,
  /// used by the live-scoring "Over Summary" panel.
  Future<List<Map<String, dynamic>>> getOverSummaryData(String matchId) async {
    try {
      final response = await _apiClient.get(
        '/scoring/match/$matchId/over-summary',
      );
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
        }
      }
      return const [];
    } catch (e) {
      return const [];
    }
  }

  /// Update match result manually (scoring)
  Future<Map<String, dynamic>> updateMatchResult(
    String matchId,
    Map<String, dynamic> resultData,
  ) async {
    try {
      final response = await _apiClient.post(
        '/scoring/match/$matchId/result',
        data: resultData,
      );
      if (response.statusCode == 200) {
        _cacheService.clearMatchCache(matchId);
        return response.data['data'] ?? {};
      }
      throw Exception(response.data['message'] ?? 'Failed to update result');
    } catch (e) {
      rethrow;
    }
  }

  /// Get match scoring data with full details
  Future<Map<String, dynamic>> getMatchScoring(String matchId) async {
    try {
      final response = await _apiClient.get('/scoring/match/$matchId/scoring');
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(
        response.data['message'] ?? 'Failed to get match scoring',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get match timeline from scoring
  Future<Map<String, dynamic>> getScoringMatchTimeline(String matchId) async {
    try {
      final response = await _apiClient.get('/scoring/match/$matchId/timeline');
      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }
      throw Exception(
        response.data['message'] ?? 'Failed to get match timeline',
      );
    } catch (e) {
      rethrow;
    }
  }
}
