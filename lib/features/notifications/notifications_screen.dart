import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/custom_loader.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final result = await _notificationService.getNotifications(limit: 50);
      setState(() {
        _notifications = result.notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
            .toList();
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((item) => item.copyWith(isRead: true)).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: 'Notifications',
        showBackButton: true,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: _isLoading
          ? const CustomLoader()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _buildNotificationItem(notification);
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final isRead = notification.isRead;
    final type = notification.type;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isRead ? const Color(0xFFE4E7EC) : AppColors.primary.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getNotificationColor(type).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getNotificationIcon(type),
            color: _getNotificationColor(type),
            size: 22,
          ),
        ),
        title: Text(
          notification.title.isEmpty ? 'Scores11 update' : notification.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
            fontSize: 13,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (!isRead) {
            _markAsRead(notification.id);
          }
          _openNotificationTarget(notification);
        },
      ),
    );
  }

  void _openNotificationTarget(NotificationModel notification) {
    final id = notification.referenceId?.trim() ?? '';
    final type = notification.type.toLowerCase();
    if (id.isNotEmpty && (type.contains('match') || type.contains('score'))) {
      Navigator.pushNamed(context, '/match/$id');
    } else if (id.isNotEmpty && type.contains('team')) {
      Navigator.pushNamed(context, '/team-detail', arguments: id);
    } else if (id.isNotEmpty && type.contains('tournament')) {
      Navigator.pushNamed(context, '/tournament/$id');
    } else if (id.isNotEmpty && (type.contains('post') || type.contains('comment') || type.contains('like'))) {
      Navigator.pushNamed(context, '/post-detail', arguments: id);
    } else if (id.isNotEmpty && (type.contains('chat'))) {
      Navigator.pushNamed(context, '/chats');
    }
  }

  Color _getNotificationColor(String type) {
    final value = type.toLowerCase();
    switch (value) {
      case 'match':
      case 'score':
        return AppColors.success;
      case 'team':
        return AppColors.primary;
      case 'tournament':
        return AppColors.warning;
      case 'wallet':
        return Colors.purple;
      case 'chat':
        return const Color(0xFF0891B2);
      case 'follow':
      case 'like':
      case 'comment':
      case 'post':
      case 'social':
        return const Color(0xFF7C3AED);
      case 'system':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  IconData _getNotificationIcon(String type) {
    final value = type.toLowerCase();
    switch (value) {
      case 'match':
      case 'score':
        return Icons.sports_cricket;
      case 'team':
        return Icons.groups;
      case 'tournament':
        return Icons.emoji_events;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'chat':
        return Icons.chat_bubble;
      case 'follow':
        return Icons.person_add_alt_1;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.mode_comment;
      case 'post':
      case 'social':
        return Icons.forum;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    try {
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes} min ago';
      } else if (diff.inDays < 1) {
        return '${diff.inHours} hours ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}


