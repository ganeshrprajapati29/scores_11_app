import '../../core/services/api_client.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/notifications', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final List<dynamic> data = response['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getNotificationById(String id) async {
    final response = await _apiClient.get('/notifications/$id');
    return response['data'] ?? {};
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.put('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.put('/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _apiClient.delete('/notifications/$id');
  }

  Future<void> deleteAllNotifications() async {
    await _apiClient.delete('/notifications');
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get('/notifications/unread-count');
    return response['count'] ?? 0;
  }

  Future<void> subscribeToTopic(String topic) async {
    await _apiClient.post('/notifications/subscribe', {'topic': topic});
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _apiClient.post('/notifications/unsubscribe', {'topic': topic});
  }

  // Admin functions
  Future<void> broadcastNotification(Map<String, dynamic> notificationData) async {
    await _apiClient.post('/notifications/broadcast', notificationData);
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    final response = await _apiClient.get('/notifications/settings');
    return response['data'] ?? {};
  }

  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    await _apiClient.put('/notifications/settings', settings);
  }
}

