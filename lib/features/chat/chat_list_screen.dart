import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      _chats = await _chatService.getChats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
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
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _chats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No chats yet'),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Find Players'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                final user = chat['user']; // Follower data
                final lastMsg = chat['lastMessage'];
                final unread = chat['unreadCount'] ?? 0;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user['name']?[0]?.toUpperCase() ?? '?'),
                  ),
                  title: Text(user['name'] ?? 'Player'),
                  subtitle: Text(lastMsg ?? 'No messages'),
                  trailing: unread > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      )
                    : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        userId: user['id'],
                        userName: user['name'],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/players'), // From followers
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}

