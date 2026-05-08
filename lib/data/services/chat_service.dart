import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getChats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/chat');
      return List<Map<String, dynamic>>.from(response.data ?? []);
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to load chats: $e');
    }
  }

  /// Get messages for specific chat by chatId
  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/chat/$chatId');
      return List<Map<String, dynamic>>.from(response.data ?? []);
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  /// Get chat ID by userId (finds or creates chat with that user)
  Future<Map<String, dynamic>> getChatByUserId(String receiverUserId) async {
    try {
      // Get all chats
      final chats = await getChats();
      
      // Find chat with this receiver
      final chat = chats.firstWhere(
        (chat) => chat['participants']?.any((p) => p['_id'] == receiverUserId || p['id'] == receiverUserId) ?? false,
orElse: () => {},
      );

      if (chat != null) {
        chat['chatId'] = chat['id'] ?? chat['_id'];
        return chat;
      }

      // Create new chat by sending first message (backend creates on send)
      // Return null chatId, will be created on first send
      return {'chatId': null, 'participants': [], 'otherUser': {'_id': receiverUserId}};
    } catch (e) {
      throw Exception('Failed to find/create chat: $e');
    }
  }

  Future<void> sendMessage(String receiverUserId, String text) async {
    try {
      await _apiClient.post(
        '${ApiConfig.baseUrl}/chat/$receiverUserId/messages',
        data: {'text': text},  // Backend expects 'text'
      );
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}

