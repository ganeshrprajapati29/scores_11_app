import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getChats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/chats');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to load chats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getChat(String userId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/chats/$userId');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to load chat: $e');
    }
  }

  Future<void> sendMessage(String userId, String message) async {
    try {
      await _apiClient.post(
        '${ApiConfig.baseUrl}/chats/$userId/messages',
        data: {'message': message},
      );
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}

