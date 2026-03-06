import '../../core/services/api_client.dart';

class LeaderboardService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getTopBatsmen({int limit = 20, String? timeframe}) async {
    final queryParams = {
      'limit': limit.toString(),
      if (timeframe != null) 'timeframe': timeframe,
    };
    final response = await _apiClient.get('/leaderboard/batsmen', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getTopBowlers({int limit = 20, String? timeframe}) async {
    final queryParams = {
      'limit': limit.toString(),
      if (timeframe != null) 'timeframe': timeframe,
    };
    final response = await _apiClient.get('/leaderboard/bowlers', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getMVPRankings({int limit = 20, String? timeframe}) async {
    final queryParams = {
      'limit': limit.toString(),
      if (timeframe != null) 'timeframe': timeframe,
    };
    final response = await _apiClient.get('/leaderboard/mvp', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getTeamRankings({int limit = 20, String? tournamentId}) async {
    final queryParams = {
      'limit': limit.toString(),
      if (tournamentId != null) 'tournamentId': tournamentId,
    };
    final response = await _apiClient.get('/leaderboard/teams', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getPlayerRanking(String playerId) async {
    final response = await _apiClient.get('/leaderboard/player/$playerId');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> getTeamRanking(String teamId) async {
    final response = await _apiClient.get('/leaderboard/team/$teamId');
    return response['data'] ?? {};
  }

  Future<List<Map<String, dynamic>>> getAllRankings({String? type, int page = 1, int limit = 20}) async {
    final queryParams = {
      'type': type ?? 'batsmen',
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final response = await _apiClient.get('/leaderboard', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }
}

