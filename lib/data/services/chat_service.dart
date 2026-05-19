import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();

  dynamic _unwrap(dynamic raw) {
    if (raw is Map) return raw['data'] ?? raw['chats'] ?? raw['messages'] ?? raw;
    return raw;
  }

  String? idFrom(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? value['userId'])?.toString();
    }
    return value.toString();
  }

  Future<List<Map<String, dynamic>>> getChats() async {
    try {
      final response = await _apiClient.get('/chat');
      final data = _unwrap(response.data);
      if (data is List) {
        return data.whereType<Map>().map((chat) => Map<String, dynamic>.from(chat)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to load chats: $e');
    }
  }

  /// Get messages for specific chat by chatId
  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      final response = await _apiClient.get('/chat/$chatId');
      final data = _unwrap(response.data);
      if (data is List) {
        return data.whereType<Map>().map((message) => Map<String, dynamic>.from(message)).toList();
      }
      return [];
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
        (chat) {
          final participants = chat['participants'];
          return participants is List &&
              participants.any((p) => idFrom(p) == receiverUserId);
        },
        orElse: () => {},
      );

      if (chat.isNotEmpty) {
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

  Future<Map<String, dynamic>> sendMessage(String receiverUserId, String text) async {
    try {
      final response = await _apiClient.post(
        '/chat/$receiverUserId/messages',
        data: {
          'receiverId': receiverUserId,
          'text': text,
        },
      );
      final data = _unwrap(response.data);
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(e));
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
}

