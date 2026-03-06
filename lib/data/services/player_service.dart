import '../models/player_model.dart';
import '../../core/services/api_client.dart';

class PlayerService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Player>> getPlayers({int page = 1, int limit = 20, String? search}) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null) 'search': search,
    };
    
    final response = await _apiClient.get('/players', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Player.fromJson(json)).toList();
  }

  Future<Player> getPlayerById(String id) async {
    final response = await _apiClient.get('/players/$id');
    return Player.fromJson(response['data']);
  }

  Future<Player> createPlayer(Map<String, dynamic> playerData) async {
    final response = await _apiClient.post('/players', playerData);
    return Player.fromJson(response['data']);
  }

  Future<Player> updatePlayer(String id, Map<String, dynamic> playerData) async {
    final response = await _apiClient.put('/players/$id', playerData);
    return Player.fromJson(response['data']);
  }

  Future<void> deletePlayer(String id) async {
    await _apiClient.delete('/players/$id');
  }

  Future<List<Player>> searchPlayers(String query) async {
    final response = await _apiClient.get('/players', queryParams: {'search': query});
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Player.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getPlayerStats(String playerId) async {
    final response = await _apiClient.get('/players/$playerId/stats');
    return response['data'] ?? {};
  }

  Future<List<Player>> getTrendingPlayers({int limit = 10}) async {
    final response = await _apiClient.get('/players/trending', queryParams: {'limit': limit.toString()});
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Player.fromJson(json)).toList();
  }

  Future<List<Player>> comparePlayers(String player1Id, String player2Id) async {
    final response = await _apiClient.get('/players/compare', queryParams: {
      'player1': player1Id,
      'player2': player2Id,
    });
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Player.fromJson(json)).toList();
  }
}

