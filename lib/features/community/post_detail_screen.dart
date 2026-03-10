import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_appbar.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final Map<String, dynamic> _post = {
    'user': 'Cricket Fan',
    'avatar': 'https://picsum.photos/50/50',
    'content': 'Amazing match today! 🏏️ The way Rohit Sharma played was phenomenal. Best innings of the season! He truly showed why he is one of the best captains in IPL history.',
    'time': '2 hours ago',
    'likes': 245,
    'comments': 32,
    'shares': 12,
    'images': ['https://picsum.photos/600/400'],
  };

  final List<Map<String, dynamic>> _comments = [
    {'user': 'Sports Lover', 'avatar': 'https://picsum.photos/50/50', 'content': 'Totally agree! Best knock of the season!', 'time': '1h ago', 'likes': 12},
    {'user': 'Cricket Expert', 'avatar': 'https://picsum.photos/50/50', 'content': 'His strike rate in the last 5 overs was incredible', 'time': '45m ago', 'likes': 8},
    {'user': 'MI Fan', 'avatar': 'https://picsum.photos/50/50', 'content': 'Captain Fantastic! 🔥', 'time': '30m ago', 'likes': 15},
  ];

  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Post',
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {},
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'save', child: Text('Save Post')),
              const PopupMenuItem(value: 'report', child: Text('Report')),
              const PopupMenuItem(value: 'copy', child: Text('Copy Link')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(_post['avatar']),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _post['user'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _post['time'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                  
                  // Post Content
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _post['content'],
                      style: const TextStyle(fontSize: 15),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  
                  // Post Image
                  if (_post['images'] != null && (_post['images'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Image.network(
                        _post['images'][0],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  
                  // Likes and Comments Count
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.thumb_up, color: Colors.white, size: 12),
                        ),
                        const SizedBox(width: 8),
                        Text('${_post['likes']} likes'),
                        const Spacer(),
                        Text('${_post['comments']} comments'),
                        const SizedBox(width: 16),
                        Text('${_post['shares']} shares'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  // Actions
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(Icons.thumb_up_outlined, 'Like'),
                        ),
                        Expanded(
                          child: _buildActionButton(Icons.comment_outlined, 'Comment'),
                        ),
                        Expanded(
                          child: _buildActionButton(Icons.share_outlined, 'Share'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 8),
                  
                  // Comments Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comments (${_comments.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._comments.asMap().entries.map((entry) {
                          final index = entry.key;
                          final comment = entry.value;
                          return _buildCommentCard(comment, index);
                        }),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
          
          // Comment Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: () {
                      if (_commentController.text.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comment posted!')),
                        );
                        _commentController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(comment['avatar']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['user'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(comment['content']),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      comment['time'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {},
                      child: Text(
                        'Like (${comment['likes']})',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {},
                      child: const Text(
                        'Reply',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 600 + (index * 100)));
  }
}

