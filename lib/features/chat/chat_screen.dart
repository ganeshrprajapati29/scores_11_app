import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../core/services/user_service.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  late String _chatId;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    _initUserId();
    _loadMessages();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initUserId() async {
    _currentUserId = await UserService.getUserId();
    if (mounted) setState(() {});
  }

  Future<void> _loadMessages() async {
    if (_chatId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      _messages = (await _chatService.getMessages(_chatId)).reversed.toList();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null || _isSending) return;

    final text = _messageController.text.trim();
    final receiverId = _receiverId;
    if (receiverId == null || receiverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to identify this player for chat')),
      );
      return;
    }
    _messageController.clear();
    setState(() => _isSending = true);

    try {
      final sent = await _chatService.sendMessage(receiverId, text);
      _chatId = _chatService.idFrom(sent['chat']) ?? _chatId;
      if (_chatId.isEmpty) {
        final chatInfo = await _chatService.getChatByUserId(receiverId);
        _chatId = chatInfo['chatId']?.toString() ?? '';
      }
      if (_chatId.isEmpty) {
        _messages.insert(0, {
          'text': text,
          'senderId': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        setState(() {});
        _scrollToBottom();
      } else {
        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
        _messageController.text = text; // Restore
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String? get _receiverId =>
      (widget.otherUser['_id'] ?? widget.otherUser['id'] ?? widget.otherUser['userId'])?.toString();

  String get _otherName {
    for (final key in const ['name', 'fullName', 'playerName', 'username']) {
      final value = widget.otherUser[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'unknown') return value;
    }
    return 'Player';
  }

  String? get _otherAvatarUrl {
    String? clean(String? value) {
      final url = value?.trim();
      if (url == null || url.isEmpty || url == 'default-avatar-url') return null;
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty)) {
        return null;
      }
      return url;
    }

    final avatar = widget.otherUser['avatar'];
    if (avatar is String) return clean(avatar);
    if (avatar is Map) return clean(avatar['url']?.toString());
    final profileImage = widget.otherUser['profileImage'];
    if (profileImage is String) return clean(profileImage);
    if (profileImage is Map) return clean(profileImage['url']?.toString());
    return clean(widget.otherUser['photo']?.toString());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _chatId.isNotEmpty && !_isSending) _loadMessages();
    });
  }

  bool _isMessageFromMe(Map<String, dynamic> message) {
    final sender = message['sender'];
    final senderId = sender is Map
        ? (sender['_id'] ?? sender['id'])?.toString()
        : (message['senderId'] ?? message['sender'])?.toString();
    return senderId != null && senderId == _currentUserId;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays > 0) {
      return '${time.day}/${time.month}/${time.year}';
    }
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final otherName = _otherName;
    final avatarUrl = _otherAvatarUrl;

    return Scaffold(
      appBar: CustomAppBar(
        title: otherName,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
              child: avatarUrl == null
                  ? Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : 'P',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                    )
                  : null,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Opacity(
                    opacity: 0.045,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_cricket_rounded, size: 92, color: AppColors.primary),
                        const SizedBox(height: 8),
                        Text(
                          'Scores11',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _isLoading && _messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              'Start the conversation!',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMe = _isMessageFromMe(msg);
                              final parsedTime = DateTime.tryParse(msg['timestamp']?.toString() ?? '');
                              final time = (parsedTime ?? DateTime.now()).toLocal();

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppColors.primary : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['text'] ?? '',
                                        style: TextStyle(
                                          color: isMe ? Colors.white : Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(time),
                                        style: TextStyle(
                                          color: isMe ? Colors.white70 : Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

