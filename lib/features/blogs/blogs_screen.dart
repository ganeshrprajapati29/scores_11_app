import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/custom_loader.dart';
import '../../../data/models/blog_model.dart';

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

      // ✅ FIXED: Safe response parsing - never assign Map directly to List
      List<dynamic> rawBlogs = [];

      if (response is List<dynamic>) {

      } else if (response is Map<String, dynamic>) {
        // Try common API patterns
        rawBlogs = response['data'] ?? 
                  response['blogs'] ?? 
                  response['items'] ?? 
                  (response.values.firstOrNull is List ? response.values.first : []);
      } 
      // No else - safe default to empty list

      debugPrint('📊 Raw blogs count: ${rawBlogs.length} (${response.runtimeType})');

      List<Map<String, dynamic>> parsedBlogs = [];

      for (final item in rawBlogs) {
        if (item is Map<String, dynamic>) {
          try {
            // Tags fix
            if (item['tags'] != null && item['tags'] is List && item['tags']!.isNotEmpty) {
              final firstTag = item['tags']![0];
              if (firstTag is String && firstTag.startsWith('[')) {
                item['tags'] = List<String>.from(jsonDecode(firstTag));
              }
            }
            parsedBlogs.add(item);
          } catch (e) {
            debugPrint('❌ Blog parse error: $e');
          }
        }
      }

      setState(() {
        blogs = parsedBlogs.map((map) => BlogModel.fromJson(map)).toList();
      });

    } catch (e) {
      debugPrint('❌ Blogs API error: $e');
      setState(() {
        error = e.toString();
        blogs = [];
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
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Blogs',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBlogs,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBlogs,
        child: isLoading
            ? const CustomLoader()
            : blogs.isEmpty
                ? (error != null
                    ? EmptyState(
                        icon: Icons.error_outline,
                        title: 'Load Failed',
                        subtitle: error!,
                      )
                    : const EmptyState(
                        icon: Icons.article_outlined,
                        title: 'No blogs yet',
                        subtitle: 'Cricket updates coming soon!',
                      ))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: blogs.length,
                    itemBuilder: (context, index) {
                      final blog = blogs[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),

                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.article,
                                color: AppColors.primary),
                          ),

                          title: Text(
                            blog.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),

                              // ✅ FIX 3: author safe handling
                              Text(
                                blog.author ?? 'Scores11 Team',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              Text(
                                blog.excerpt ?? 'Read full article...',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),

                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),

                          isThreeLine: true,

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlogDetailScreen(
                                  // ✅ FIX 4: correct id (_id)
                                  blogId: blog.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class BlogDetailScreen extends StatelessWidget {
  final String blogId;

  const BlogDetailScreen({super.key, required this.blogId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blog Detail')),
      body: Center(
        child: Text('Blog ID: $blogId'),
      ),
    );
  }
}