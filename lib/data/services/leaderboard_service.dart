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
    final List<dynamic> data = response.data['data'] ?? [];
    final pagination = response.data['pagination'] ?? {};
    
    final entries = List<Map<String, dynamic>>.from(data);
    
    return PaginatedLeaderboard(
      entries: entries,
      page: pagination['page'] ?? page,
      limit: pagination['limit'] ?? limit,
      total: pagination['total'] ?? data.length,
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
    final List<dynamic> data = response.data['data'] ?? [];
    final pagination = response.data['pagination'] ?? {};
    
    final entries = List<Map<String, dynamic>>.from(data);
    
    return PaginatedLeaderboard(
      entries: entries,
      page: pagination['page'] ?? page,
      limit: pagination['limit'] ?? limit,
      total: pagination['total'] ?? data.length,
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
    final List<dynamic> data = response.data['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getTeamRankings({int limit = 20, String? tournamentId}) async {
    final queryParams = {
      'limit': limit.toString(),
      if (tournamentId != null) 'tournamentId': tournamentId,
    };
    final response = await _apiClient.get('/leaderboard/teams', queryParameters: queryParams);
    final List<dynamic> data = response.data['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
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
    final List<dynamic> data = response.data['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }
}

