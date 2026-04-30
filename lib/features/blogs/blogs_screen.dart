import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/custom_loader.dart';
import '../../../data/models/blog_model.dart';

// ─── Mock Data ────────────────────────────────────────────────────────────────

final List<Map<String, dynamic>> _mockBlogs = [
  {
    'id': '1',
    '_id': '1',
    'title': 'India vs Australia: Top 5 Moments from the Test Series',
    'author': 'Rahul Sharma',
    'excerpt':
        'The Border-Gavaskar Trophy delivered breathtaking cricket. Here are the five moments that defined the series and left fans speechless.',
    'category': 'Test Cricket',
    'readTime': '5 min read',
    'publishedAt': '2024-01-20',
    'tags': ['India', 'Australia', 'Test', 'BGT'],
    'coverColor': 0xFF1565C0,
  },
  {
    'id': '2',
    '_id': '2',
    'title': 'IPL 2024: Which Teams Are the Title Contenders This Season?',
    'author': 'Priya Mehta',
    'excerpt':
        'With mega auctions reshaping squads, we break down the strongest teams heading into IPL 2024 and who stands the best chance to lift the trophy.',
    'category': 'IPL',
    'readTime': '7 min read',
    'publishedAt': '2024-01-18',
    'tags': ['IPL', 'T20', 'Preview'],
    'coverColor': 0xFFE65100,
  },
  {
    'id': '3',
    '_id': '3',
    'title': 'Virat Kohli: The Art of Batting Under Pressure',
    'author': 'Scores11 Team',
    'excerpt':
        'Few batters in the history of cricket have thrived under pressure like Virat Kohli. We analyse the technique and mindset behind his chase masterclasses.',
    'category': 'Player Focus',
    'readTime': '6 min read',
    'publishedAt': '2024-01-15',
    'tags': ['Kohli', 'Batting', 'Analysis'],
    'coverColor': 0xFF2E7D32,
  },
  {
    'id': '4',
    '_id': '4',
    'title': 'How to Read a Cricket Pitch Before a Match',
    'author': 'Amit Verma',
    'excerpt':
        'Understanding pitch conditions is a skill that separates good players from great ones. Learn what to look for before your next match.',
    'category': 'Tips & Tricks',
    'readTime': '4 min read',
    'publishedAt': '2024-01-12',
    'tags': ['Tips', 'Pitch', 'Beginner'],
    'coverColor': 0xFF6A1B9A,
  },
  {
    'id': '5',
    '_id': '5',
    'title': "Women's Cricket: Rising Stars to Watch in 2024",
    'author': 'Sneha Patel',
    'excerpt':
        "Women's cricket is growing at an incredible pace. These young players have caught the attention of selectors and fans alike with standout performances.",
    'category': "Women's Cricket",
    'readTime': '5 min read',
    'publishedAt': '2024-01-10',
    'tags': ["Women's", 'Stars', '2024'],
    'coverColor': 0xFFC62828,
  },
  {
    'id': '6',
    '_id': '6',
    'title': 'The Science of Swing Bowling: A Deep Dive',
    'author': 'Deepak Nair',
    'excerpt':
        'What makes the ball swing? From seam position to atmospheric conditions, we explore the physics and craft behind one of cricket\'s most dangerous weapons.',
    'category': 'Bowling',
    'readTime': '8 min read',
    'publishedAt': '2024-01-08',
    'tags': ['Bowling', 'Swing', 'Science'],
    'coverColor': 0xFF00695C,
  },
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<BlogModel> blogs = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchBlogs();
  }

  Future<void> _fetchBlogs() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await _apiClient.executeWithRetry(
        () => _apiClient.get('${ApiConfig.blogs}/published'),
        maxRetries: 3,
      );

      dynamic rawBlogs = response;

      List<Map<String, dynamic>> parsedBlogs = [];

      if (rawBlogs is List<dynamic>) {
        parsedBlogs = rawBlogs.cast<Map<String, dynamic>>();
      } else if (rawBlogs is Map<String, dynamic>) {
        final data = rawBlogs['data'] ??
            rawBlogs['blogs'] ??
            rawBlogs['items'] ??
            (rawBlogs.values.firstOrNull is List
                ? rawBlogs.values.first
                : []);
        
        if (data is List<dynamic>) {
          parsedBlogs = data.cast<Map<String, dynamic>>();
        }
      }

      debugPrint('📊 Raw blogs count: ${parsedBlogs.length}');

      // Process each blog item for tag parsing
      for (final item in List<Map<String, dynamic>>.from(parsedBlogs)) {
        try {
          if (item['tags'] != null &&
              item['tags'] is List &&
              item['tags']!.isNotEmpty) {
            final firstTag = item['tags']![0];
            if (firstTag is String && firstTag.startsWith('[')) {
              item['tags'] = List<String>.from(jsonDecode(firstTag));
            }
          }
        } catch (e) {
          debugPrint('❌ Blog parse error: $e');
        }
      }

      // If API returns empty, fall back to mock data
      if (parsedBlogs.isEmpty) {
        parsedBlogs = _mockBlogs;
      }

      setState(() {
        blogs = parsedBlogs.map((map) => BlogModel.fromJson(map)).toList();
      });
    } catch (e) {
      debugPrint('❌ Blogs API error: $e — using mock data');
      // On error, show mock data instead of error state
      setState(() {
        blogs = _mockBlogs.map((map) => BlogModel.fromJson(map)).toList();
        error = null;
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Blogs',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchBlogs,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBlogs,
        color: AppColors.primary,
        child: isLoading
            ? const CustomLoader()
            : blogs.isEmpty
                ? (error != null
                    ? EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Load Failed',
                        subtitle: error!,
                      )
                    : const EmptyState(
                        icon: Icons.article_outlined,
                        title: 'No blogs yet',
                        subtitle: 'Cricket updates coming soon!',
                      ))
                : _BlogList(blogs: blogs),
      ),
    );
  }
}

// ─── Blog List ────────────────────────────────────────────────────────────────

class _BlogList extends StatelessWidget {
  final List<BlogModel> blogs;

  const _BlogList({required this.blogs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: blogs.length,
      itemBuilder: (context, index) {
        return _BlogCard(
          blog: blogs[index],
          mockMeta: index < _mockBlogs.length ? _mockBlogs[index] : null,
        );
      },
    );
  }
}

// ─── Blog Card ────────────────────────────────────────────────────────────────

class _BlogCard extends StatelessWidget {
  final BlogModel blog;
  final Map<String, dynamic>? mockMeta;

  const _BlogCard({required this.blog, this.mockMeta});

  @override
  Widget build(BuildContext context) {
    final category =
        mockMeta?['category'] as String? ?? 'Cricket';
    final readTime =
        mockMeta?['readTime'] as String? ?? '4 min read';
    final coverColorValue =
        mockMeta?['coverColor'] as int? ?? AppColors.primary.value;
    final coverColor = Color(coverColorValue);
    final tags = mockMeta?['tags'] as List? ?? [];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlogDetailScreen(blogId: blog.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover strip
            _CoverStrip(color: coverColor, category: category),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    blog.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.2,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Excerpt
                  Text(
                    blog.excerpt ?? 'Read full article...',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Tags
                  if (tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (tags as List)
                          .take(3)
                          .map((tag) => _Tag(label: tag.toString()))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Footer
                  _CardFooter(
                    author: blog.author ?? 'Scores11 Team',
                    readTime: readTime,
                    coverColor: coverColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cover Strip ─────────────────────────────────────────────────────────────

class _CoverStrip extends StatelessWidget {
  final Color color;
  final String category;

  const _CoverStrip({required this.color, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
    );
  }
}

// ─── Tag ──────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─── Card Footer ─────────────────────────────────────────────────────────────

class _CardFooter extends StatelessWidget {
  final String author;
  final String readTime;
  final Color coverColor;

  const _CardFooter({
    required this.author,
    required this.readTime,
    required this.coverColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Author avatar
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: coverColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              author.isNotEmpty ? author[0].toUpperCase() : 'S',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: coverColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            author,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            const Icon(Icons.schedule_rounded,
                size: 13, color: Color(0xFFAAAAAA)),
            const SizedBox(width: 4),
            Text(
              readTime,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFAAAAAA),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: coverColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.arrow_forward_rounded,
              size: 15, color: coverColor),
        ),
      ],
    );
  }
}

// ─── Blog Detail Screen ───────────────────────────────────────────────────────

class BlogDetailScreen extends StatelessWidget {
  final String blogId;

  const BlogDetailScreen({super.key, required this.blogId});

  @override
  Widget build(BuildContext context) {
    // Find mock data for this blog
    final meta = _mockBlogs.firstWhere(
      (m) => m['id'] == blogId,
      orElse: () => _mockBlogs.first,
    );
    final coverColor = Color(meta['coverColor'] as int);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Article',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon:
                Icon(Icons.share_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: coverColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                meta['category'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: coverColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Title
            Text(
              meta['title'] as String,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.4,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            // Author row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: coverColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (meta['author'] as String)[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: coverColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta['author'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          meta['publishedAt'] as String,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF999999)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.circle,
                            size: 3, color: Color(0xFFCCCCCC)),
                        const SizedBox(width: 8),
                        Text(
                          meta['readTime'] as String,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Divider strip
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: coverColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Content placeholder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                meta['excerpt'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF444444),
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: (meta['tags'] as List)
                  .map((tag) => _Tag(label: tag.toString()))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}