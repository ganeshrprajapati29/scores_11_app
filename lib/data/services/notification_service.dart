import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  /// Get all notifications
  Future<PaginatedNotifications> getNotifications({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get(
      '${ApiConfig.notifications}', 
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    final List<dynamic> data = response.data['data'] ?? [];
    final pagination = response.data['pagination'] ?? {};
    
    final notifications = data.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
    
    return PaginatedNotifications(
      notifications: notifications,
      page: pagination['page'] ?? page,
      limit: pagination['limit'] ?? limit,
      total: pagination['total'] ?? data.length,
      totalPages: pagination['pages'] ?? 1,
      hasMore: page < (pagination['pages'] ?? 1),
    );
  }

  /// Get notification by ID
  Future<NotificationModel> getNotificationById(String id) async {
    final response = await _apiClient.get('${ApiConfig.notifications}/$id');
    return NotificationModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    await _apiClient.put('${ApiConfig.notifications}/$id/read');
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await _apiClient.put('${ApiConfig.notifications}/read-all');
  }

  /// Delete a notification
  Future<void> deleteNotification(String id) async {
    await _apiClient.delete('${ApiConfig.notifications}/$id');
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    await _apiClient.delete('${ApiConfig.notifications}');
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('${ApiConfig.notifications}/unread-count');
      return response.data['count'] ?? 0;
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
      return 0;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _apiClient.post('${ApiConfig.notifications}/subscribe', data: {'topic': topic});
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _apiClient.post('${ApiConfig.notifications}/unsubscribe', data: {'topic': topic});
  }

  /// Broadcast notification (admin)
  Future<void> broadcastNotification(Map<String, dynamic> notificationData) async {
    await _apiClient.post('${ApiConfig.notifications}/broadcast', data: notificationData);
  }

  /// Get notification settings
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final response = await _apiClient.get('${ApiConfig.notifications}/settings');
    return response.data['data'] ?? {};
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    await _apiClient.put('${ApiConfig.notifications}/settings', data: settings);
  }
}

/// Pagination wrapper for notifications
class PaginatedNotifications {
  final List<NotificationModel> notifications;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  PaginatedNotifications({
    required this.notifications,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });
}

