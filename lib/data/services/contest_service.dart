import '../../core/services/api_client.dart';

/// Pagination response wrapper for clubs
class PaginatedClubs {
  final List<Map<String, dynamic>> clubs;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  PaginatedClubs({
    required this.clubs,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });
}

class ClubService {
  final ApiClient _apiClient = ApiClient();

  /// Get clubs with pagination support
  Future<PaginatedClubs> getClubs({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParams = {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
    };
    final response = await _apiClient.get('/clubs', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    final pagination = response['pagination'] ?? {};
    
    final clubs = List<Map<String, dynamic>>.from(data);
    
    return PaginatedClubs(
      clubs: clubs,
      page: pagination['page'] ?? page,
      limit: pagination['limit'] ?? limit,
      total: pagination['total'] ?? data.length,
      totalPages: pagination['pages'] ?? 1,
      hasMore: page < (pagination['pages'] ?? 1),
    );
  }

  /// Legacy method for backward compatibility
  Future<List<Map<String, dynamic>>> getClubsList({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final result = await getClubs(page: page, limit: limit, search: search);
    return result.clubs;
  }

  Future<Map<String, dynamic>> getClubById(String id) async {
    final response = await _apiClient.get('/clubs/$id');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> createClub(Map<String, dynamic> clubData) async {
    final response = await _apiClient.post('/clubs', clubData);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateClub(String id, Map<String, dynamic> clubData) async {
    final response = await _apiClient.put('/clubs/$id', clubData);
    return response['data'] ?? {};
  }

  Future<void> deleteClub(String id) async {
    await _apiClient.delete('/clubs/$id');
  }

  Future<List<Map<String, dynamic>>> getClubTeams(String clubId, {int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/clubs/$clubId/teams', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getClubRankings({String? timeframe}) async {
    final queryParams = {
      if (timeframe != null) 'timeframe': timeframe,
    };
    final response = await _apiClient.get('/clubs/rankings', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> joinClub(String clubId) async {
    await _apiClient.post('/clubs/$clubId/join');
  }

  Future<void> leaveClub(String clubId) async {
    await _apiClient.post('/clubs/$clubId/leave');
  }

  Future<List<Map<String, dynamic>>> getMyClubs() async {
    final response = await _apiClient.get('/clubs/my-clubs');
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }
}
