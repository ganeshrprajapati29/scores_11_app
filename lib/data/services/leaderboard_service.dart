import '../../core/services/api_client.dart';

/// Pagination response wrapper for leaderboard entries
class PaginatedLeaderboard {
  final List<Map<String, dynamic>> entries;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  PaginatedLeaderboard({
    required this.entries,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });
}

class LeaderboardService {
  final ApiClient _apiClient = ApiClient();

  List<Map<String, dynamic>> _entries(dynamic raw) {
    dynamic findList(dynamic value) {
      if (value is List) return value;
      if (value is! Map) return const [];
      for (final key in const [
        'data',
        'players',
        'batsmen',
        'bowlers',
        'allRounders',
        'teams',
        'leaderboard',
        'items',
        'rankings',
        'results',
      ]) {
        final candidate = value[key];
        if (candidate is List) return candidate;
        if (candidate is Map) {
          final nested = findList(candidate);
          if (nested is List && nested.isNotEmpty) return nested;
        }
      }
      return const [];
    }

    final dynamic list = findList(raw);
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _pagination(dynamic raw) {
    if (raw is Map && raw['pagination'] is Map) {
      return Map<String, dynamic>.from(raw['pagination'] as Map);
    }
    if (raw is Map && raw['meta'] is Map) {
      return Map<String, dynamic>.from(raw['meta'] as Map);
    }
    return {};
  }

  /// Get top batsmen with pagination support
  Future<PaginatedLeaderboard> getTopBatsmen({
    int page = 1,
    int limit = 20,
    String? timeframe,
  }) async {
    final queryParams = {
      'page': page,
      'limit': limit,
      if (timeframe != null) 'timeframe': timeframe,
    };
    final response = await _apiClient.get('/leaderboard/batsmen', queryParameters: queryParams);
    final entries = _entries(response.data);
    final pagination = _pagination(response.data);

    return PaginatedLeaderboard(
      entries: entries,
      page: pagination['page'] ?? page,
      limit: pagination['limit'] ?? limit,
      total: pagination['total'] ?? entries.length,
      totalPages: pagination['pages'] ?? 1,
      hasMore: page < (pagination['pages'] ?? 1),
    );
  }

  /// Legacy method for backward compatibility
  Future<List<Map<String, dynamic>>> getTopBatsmenList({int limit = 20, String? timeframe}) async {
    final result = await getTopBatsmen(page: 1, limit: limit, timeframe: timeframe);
    return result.entries;
  }

  /// Get top bowlers with pagination support
  Future<PaginatedLeaderboard> getTopBowlers({
    int page = 1,
    int limit = 20,
    String? timeframe,
  }) async {
    final queryParams = {
      'page': page,
      'limit': limit,
      if (timeframe != null) 'timeframe': timeframe,
    };
    final response = await _apiClient.get('/leaderboard/bowlers', queryParameters: queryParams);
    final entries = _entries(response.data);
    final pagination = _pagination(response.data);

    return PaginatedLeaderboard(
      entries: entries,
      page: pagination['page'] ?? page,
      limit: pagination['limit'] ?? limit,
      total: pagination['total'] ?? entries.length,
      totalPages: pagination['pages'] ?? 1,
      hasMore: page < (pagination['pages'] ?? 1),
    );
  }

  /// Legacy method for backward compatibility
  Future<List<Map<String, dynamic>>> getTopBowlersList({int limit = 20, String? timeframe}) async {
    final result = await getTopBowlers(page: 1, limit: limit, timeframe: timeframe);
    return result.entries;
  }

  Future<List<Map<String, dynamic>>> getMVPRankings({int limit = 20, String? timeframe}) async {
    final queryParams = {
      'limit': limit.toString(),
      if (timeframe != null) 'timeframe': timeframe,
    };
    final response = await _apiClient.get('/leaderboard/mvp', queryParameters: queryParams);
    return _entries(response.data);
  }

  Future<List<Map<String, dynamic>>> getTeamRankings({int limit = 20, String? tournamentId}) async {
    final queryParams = {
      'limit': limit.toString(),
      if (tournamentId != null) 'tournamentId': tournamentId,
    };
    final response = await _apiClient.get('/leaderboard/teams', queryParameters: queryParams);
    return _entries(response.data);
  }

  Future<Map<String, dynamic>> getPlayerRanking(String playerId) async {
    final response = await _apiClient.get('/leaderboard/player/$playerId');
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> getTeamRanking(String teamId) async {
    final response = await _apiClient.get('/leaderboard/team/$teamId');
    return response.data['data'] ?? {};
  }

  Future<List<Map<String, dynamic>>> getAllRankings({String? type, int page = 1, int limit = 20}) async {
    final queryParams = {
      'type': type ?? 'batsmen',
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final response = await _apiClient.get('/leaderboard', queryParameters: queryParams);
    return _entries(response.data);
  }
}

