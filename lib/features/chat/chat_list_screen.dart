import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_service.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../data/services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initUserId();
    _loadChats();
  }

  Future<void> _initUserId() async {
    _currentUserId = await UserService.getUserId();
    if (mounted) setState(() {});
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      _chats = await _chatService.getChats();
      // Filter to followers only (optional)
      // For now show all chats
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chats: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic>? _getOtherUser(Map<String, dynamic> chat) {
    if (_currentUserId == null) return null;
    final participants = chat['participants'] as List?;
    if (participants == null || participants.length != 2) return null;

    return participants.firstWhere(
      (p) => (p['_id'] ?? p['id'])?.toString() != _currentUserId,
      orElse: () => null,
    );
  }

  String? _getLastMessageText(Map<String, dynamic> chat) {
    final lastMsg = chat['lastMessage'];
    return lastMsg?['text'] ?? 'No messages yet';
  }

  int _getUnreadCount(Map<String, dynamic> chat) {
    final unreadCount = chat['unreadCount'];
    if (unreadCount is int) return unreadCount;
    if (unreadCount is Map && _currentUserId != null) {
      return unreadCount[_currentUserId] ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chats',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No chats yet'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/connections'),
                          child: const Text('View Connections'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final otherUser = _getOtherUser(chat);
                      if (otherUser == null) return const SizedBox.shrink();

                      final unread = _getUnreadCount(chat);
                      final lastMsgText = _getLastMessageText(chat);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: otherUser['avatar'] != null
                                ? NetworkImage(otherUser['avatar']['url'] ?? otherUser['avatar'])
                                : null,
                            child: otherUser['avatar'] == null
                                ? Text(
                                    (otherUser['name'] ?? otherUser['fullName'] ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          title: Text(
                            otherUser['name'] ?? otherUser['fullName'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
subtitle: Text(                            lastMsgText ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: unread > 0
                              ? Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$unread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chat['id'] ?? chat['_id'],
                                otherUser: otherUser,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/connections'),
        child: const Icon(Icons.people),
        tooltip: 'New Chat',
      ),
    );
  }
}

