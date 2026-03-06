import '../../core/services/api_client.dart';

class AwardService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getAwards({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/awards', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getAwardById(String id) async {
    final response = await _apiClient.get('/awards/$id');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> createAward(Map<String, dynamic> awardData) async {
    final response = await _apiClient.post('/awards', awardData);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateAward(String id, Map<String, dynamic> awardData) async {
    final response = await _apiClient.put('/awards/$id', awardData);
    return response['data'] ?? {};
  }

  Future<void> deleteAward(String id) async {
    await _apiClient.delete('/awards/$id');
  }

  Future<List<Map<String, dynamic>>> getNominations(String awardId, {int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/awards/$awardId/nominations', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> nominate(String awardId, Map<String, dynamic> nominationData) async {
    final response = await _apiClient.post('/awards/$awardId/nominate', nominationData);
    return response['data'] ?? {};
  }

  Future<void> vote(String awardId, String nomineeId) async {
    await _apiClient.post('/awards/$awardId/vote/$nomineeId');
  }

  Future<void> withdrawNomination(String awardId, String nominationId) async {
    await _apiClient.delete('/awards/$awardId/nominations/$nominationId');
  }

  Future<List<Map<String, dynamic>>> getMyNominations() async {
    final response = await _apiClient.get('/awards/my-nominations');
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getMyVotes() async {
    final response = await _apiClient.get('/awards/my-votes');
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }
}

