import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_appbar.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _posts = [
    {'id': '1', 'user': 'Cricket Fan', 'avatar': 'https://picsum.photos/50/50', 'content': 'Amazing match today! 🏏️ The way Rohit Sharma played was phenomenal. Best innings of the season!', 'time': '2h ago', 'likes': 245, 'comments': 32, 'shares': 12, 'images': ['https://picsum.photos/400/300']},
    {'id': '2', 'user': 'Sports Analyst', 'avatar': 'https://picsum.photos/50/50', 'content': 'Player performance review: Jasprit Bumrah has been the most consistent bowler this season with 28 wickets at an economy of just 6.5. Definitely a contender for the Purple Cap!', 'time': '4h ago', 'likes': 128, 'comments': 15, 'shares': 8, 'images': null},
    {'id': '3', 'user': 'Cricket Academy', 'avatar': 'https://picsum.photos/50/50', 'content': 'Join our coaching camp this weekend! Learn from former international players. Limited seats available.', 'time': '6h ago', 'likes': 89, 'comments': 45, 'shares': 20, 'images': ['https://picsum.photos/400/300', 'https://picsum.photos/400/300']},
    {'id': '4', 'user': 'Fantasy Expert', 'avatar': 'https://picsum.photos/50/50', 'content': 'Dream11 Tips for tonight\'s match: Go heavy on MI bowlers as they have a good record at Wankhede. Captain: Bumrah, Vice-Captain: SKY', 'time': '8h ago', 'likes': 312, 'comments': 89, 'shares': 45, 'images': null},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        title: 'Community',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedList(),
          _buildTrendingList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-post');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
    );
  }

  Widget _buildFeedList() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _buildPostCard(post, index);
        },
      ),
    );
  }

  Widget _buildTrendingList() {
    final trending = [
      {'tag': '#MIvsCSK', 'posts': '12.5K'},
      {'tag': '#Bumrah', 'posts': '8.2K'},
      {'tag': '#IPLFinal', 'posts': '6.8K'},
      {'tag': '#RohitSharma', 'posts': '5.4K'},
      {'tag': '#Wankhede', 'posts': '3.2K'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Trending Topics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...trending.asMap().entries.map((entry) {
          final index = entry.key;
          final topic = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic['tag'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${topic['posts']} posts',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.trending_up, color: AppColors.primary),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
        }),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(post['avatar']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['user'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        post['time'],
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
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              post['content'],
              style: const TextStyle(fontSize: 14),
            ),
          ),
          
          // Images
          if (post['images'] != null && (post['images'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            if ((post['images'] as List).length == 1)
              Image.network(
                post['images'][0],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              SizedBox(
                height: 200,
                child: Row(
                  children: (post['images'] as List).map((img) => Expanded(
                    child: Image.network(img, fit: BoxFit.cover),
                  )).toList(),
                ),
              ),
          ],
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildActionButton(Icons.thumb_up_outlined, '${post['likes']}'),
                _buildActionButton(Icons.comment_outlined, '${post['comments']}'),
                _buildActionButton(Icons.share_outlined, '${post['shares']}'),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

