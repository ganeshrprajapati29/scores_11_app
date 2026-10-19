import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/services/chat_service.dart';
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
  bool _searching = false;
  String _query = '';

  List<Map<String, dynamic>> get _visibleChats {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _chats;
    return _chats.where((chat) {
      final other = _getOtherUser(chat);
      return other != null && _displayName(other).toLowerCase().contains(q);
    }).toList();
  }
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
          SnackBar(
            content: Text(
              friendlyError(e, fallback: 'Could not load chats.'),
            ),
          ),
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

    final other = participants.firstWhere(
      (p) {
        if (p is! Map) return false;
        return (p['_id'] ?? p['id'])?.toString() != _currentUserId;
      },
      orElse: () => null,
    );
    return other is Map ? Map<String, dynamic>.from(other) : null;
  }

  String _displayName(Map<String, dynamic> user) {
    for (final key in const ['name', 'fullName', 'playerName', 'username']) {
      final value = user[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'unknown') {
        return value;
      }
    }
    return 'Player';
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

  String? _avatarUrl(Map<String, dynamic> user) {
    String? clean(String? value) {
      final url = value?.trim();
      if (url == null || url.isEmpty || url == 'default-avatar-url') return null;
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty)) {
        return null;
      }
      return url;
    }

    final avatar = user['avatar'];
    if (avatar is String) return clean(avatar);
    if (avatar is Map) {
      return clean(avatar['url']?.toString());
    }
    final profileImage = user['profileImage'];
    if (profileImage is String) return clean(profileImage);
    if (profileImage is Map) return clean(profileImage['url']?.toString());
    return clean(user['photo']?.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chats',
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: _searching ? 'Close search' : 'Search chats',
            onPressed: () => setState(() {
              _searching = !_searching;
              _query = '';
            }),
          ),
        ],
        bottom: _searching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    autofocus: true,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search by name',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _visibleChats.isEmpty && _query.isNotEmpty
                ? ListView(children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No chats match your search')),
                  ])
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
                    itemCount: _visibleChats.length,
                    itemBuilder: (context, index) {
                      final chat = _visibleChats[index];
                      final otherUser = _getOtherUser(chat);
                      if (otherUser == null) return const SizedBox.shrink();

                      final unread = _getUnreadCount(chat);
                      final lastMsgText = _getLastMessageText(chat);
                      final avatarUrl = _avatarUrl(otherUser);

                      final displayName = _displayName(otherUser);
                      final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.withOpacity(0.12)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withOpacity(0.10),
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Text(
                                    initial,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  )
                                : null,
                          ),
                          title: Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            lastMsgText ?? '',
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
                                chatId: (chat['id'] ?? chat['_id']).toString(),
                                otherUser: {...otherUser, 'name': displayName},
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

