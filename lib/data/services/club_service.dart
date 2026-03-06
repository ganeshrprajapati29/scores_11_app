import '../../core/services/api_client.dart';

class ClubService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getClubs({int page = 1, int limit = 20, String? search}) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null) 'search': search,
    };
    final response = await _apiClient.get('/clubs', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
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

