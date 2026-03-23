import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/custom_loader.dart';

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Map<String, dynamic>> blogs = [];
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
      final response = await _apiClient.get(ApiConfig.blogs);
      if (response.statusCode == 200) {
        setState(() {
          blogs = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        });
      } else {
        setState(() => error = response.data['message'] ?? 'Failed to load blogs');
      }
    } catch (e) {
      setState(() => error = 'Network error: $e');
    } finally {
      setState(() => isLoading = false);
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
                ? EmptyState(
                    icon: Icons.article_outlined,
                    title: error ?? 'No blogs available',
                    subtitle: 'Check back later for cricket updates',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: blogs.length,
                    itemBuilder: (context, index) {
                      final blog = blogs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.article, color: AppColors.primary),
                          ),
                          title: Text(
                            blog['title'] ?? 'Untitled Blog',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                blog['author']?.toString() ?? 'Scores11 Team',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                blog['excerpt'] ?? 'Read full article...',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          isThreeLine: true,
                          onTap: () {
                            // Navigate to blog detail
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlogDetailScreen(blogId: blog['id'].toString()),
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
      body: const Center(
        child: Text('Blog detail screen (implement API call)'),
      ),
    );
  }
}

