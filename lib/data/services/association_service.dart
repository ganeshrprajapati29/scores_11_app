import '../../core/services/api_client.dart';

class AssociationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getAssociations({int page = 1, int limit = 20, String? search}) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null) 'search': search,
    };
    final response = await _apiClient.get('/associations', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getAssociationById(String id) async {
    final response = await _apiClient.get('/associations/$id');
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> createAssociation(Map<String, dynamic> associationData) async {
    final response = await _apiClient.post('/associations', associationData);
    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateAssociation(String id, Map<String, dynamic> associationData) async {
    final response = await _apiClient.put('/associations/$id', associationData);
    return response['data'] ?? {};
  }

  Future<void> deleteAssociation(String id) async {
    await _apiClient.delete('/associations/$id');
  }

  Future<List<Map<String, dynamic>>> getClubsUnderAssociation(String associationId, {int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/associations/$associationId/clubs', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getTournamentsUnderAssociation(String associationId, {int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/associations/$associationId/tournaments', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getRegionalTournaments({String? region, int page = 1, int limit = 20}) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (region != null) 'region': region,
    };
    final response = await _apiClient.get('/associations/regional-tournaments', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getMyAssociations() async {
    final response = await _apiClient.get('/associations/my-associations');
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }
}

