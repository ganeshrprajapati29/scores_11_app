import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/blog_model.dart';
import '../../data/services/blog_service.dart';

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  final BlogService _blogService = BlogService();
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
      final loadedBlogs = await _blogService.getBlogs(page: 1, limit: 20);
      if (!mounted) return;
      setState(() {
        blogs = loadedBlogs;
      });
    } catch (e) {
      debugPrint('Blogs API error: $e');
      if (!mounted) return;
      setState(() {
        blogs = [];
        error = 'Unable to load blogs';
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
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
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
                ? const EmptyState(
                    icon: Icons.article_outlined,
                    title: 'No blogs yet',
                    subtitle: 'Cricket updates coming soon!',
                  )
                : _BlogList(blogs: blogs),
      ),
    );
  }
}

class _BlogList extends StatelessWidget {
  final List<BlogModel> blogs;

  const _BlogList({required this.blogs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: blogs.length,
      itemBuilder: (context, index) {
        final accent = _blogAccent(index);
        return _BlogCard(blog: blogs[index], accent: accent);
      },
    );
  }
}

class _BlogCard extends StatelessWidget {
  final BlogModel blog;
  final Color accent;

  const _BlogCard({required this.blog, required this.accent});

  @override
  Widget build(BuildContext context) {
    final title = blog.title.trim().isEmpty ? 'Untitled Blog' : blog.title.trim();
    final excerpt = (blog.excerpt?.trim().isNotEmpty ?? false)
        ? blog.excerpt!.trim()
        : 'Read the latest cricket updates, stories, and analysis from Scores11.';
    final author = (blog.author?.trim().isNotEmpty ?? false) ? blog.author!.trim() : 'Scores11 Team';
    final date = _formatDate(blog.createdAt);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlogDetailScreen(blogId: blog.id, initialBlog: blog, accent: accent),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.10)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BlogCover(blog: blog, accent: accent, date: date),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    excerpt,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF667085),
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  _CardFooter(author: author, readTime: _readTime(blog), accent: accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogCover extends StatelessWidget {
  final BlogModel blog;
  final Color accent;
  final String date;

  const _BlogCover({required this.blog, required this.accent, required this.date});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if ((blog.imageUrl ?? '').trim().isNotEmpty)
            Image.network(
              blog.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _CoverFallback(accent: accent),
            )
          else
            _CoverFallback(accent: accent),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.60), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 12,
            child: _Chip(label: 'CRICKET BLOG', color: accent),
          ),
          if (date.isNotEmpty)
            Positioned(
              right: 14,
              bottom: 12,
              child: _Chip(label: date, color: Colors.white, dark: true),
            ),
        ],
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  final Color accent;

  const _CoverFallback({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.92), accent.withOpacity(0.56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.article_rounded, size: 44, color: Colors.white.withOpacity(0.94)),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool dark;

  const _Chip({required this.label, required this.color, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withOpacity(0.36) : Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: dark ? Colors.white.withOpacity(0.18) : Colors.transparent),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dark ? Colors.white : color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  final String author;
  final String readTime;
  final Color accent;

  const _CardFooter({
    required this.author,
    required this.readTime,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: accent.withOpacity(0.12), shape: BoxShape.circle),
          child: Center(
            child: Text(
              author.isNotEmpty ? author[0].toUpperCase() : 'S',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: accent),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            author,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475467)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF98A2B3)),
        const SizedBox(width: 4),
        Text(
          readTime,
          style: const TextStyle(fontSize: 11, color: Color(0xFF98A2B3), fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 10),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
        ),
      ],
    );
  }
}

class BlogDetailScreen extends StatefulWidget {
  final String blogId;
  final BlogModel? initialBlog;
  final Color? accent;

  const BlogDetailScreen({
    super.key,
    required this.blogId,
    this.initialBlog,
    this.accent,
  });

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final BlogService _blogService = BlogService();
  BlogModel? blog;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    blog = widget.initialBlog;
    if (!widget.blogId.startsWith('fallback')) {
      _loadBlog();
    }
  }

  Future<void> _loadBlog() async {
    setState(() => isLoading = blog == null);
    final loaded = await _blogService.getBlogById(widget.blogId);
    if (!mounted) return;
    setState(() {
      blog = loaded ?? blog;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? AppColors.primary;
    final currentBlog = blog;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Article',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: isLoading && currentBlog == null
          ? const CustomLoader()
          : currentBlog == null
              ? const EmptyState(
                  icon: Icons.article_outlined,
                  title: 'Blog not found',
                  subtitle: 'This article is not available right now.',
                )
              : _BlogDetailBody(blog: currentBlog, accent: accent),
    );
  }
}

class _BlogDetailBody extends StatelessWidget {
  final BlogModel blog;
  final Color accent;

  const _BlogDetailBody({required this.blog, required this.accent});

  @override
  Widget build(BuildContext context) {
    final author = (blog.author?.trim().isNotEmpty ?? false) ? blog.author!.trim() : 'Scores11 Team';
    final body = (blog.content?.trim().isNotEmpty ?? false)
        ? blog.content!.trim()
        : (blog.excerpt?.trim().isNotEmpty ?? false)
            ? blog.excerpt!.trim()
            : 'Full blog content will be available soon.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: _BlogCover(blog: blog, accent: accent, date: _formatDate(blog.createdAt)),
          ),
          const SizedBox(height: 18),
          Text(
            blog.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          _CardFooter(author: author, readTime: _readTime(blog), accent: accent),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF344054),
                height: 1.7,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _blogAccent(int index) {
  const colors = [
    Color(0xFF1565C0),
    Color(0xFFE65100),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFF00695C),
  ];
  return colors[index % colors.length];
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]}';
}

String _readTime(BlogModel blog) {
  final text = '${blog.content ?? ''} ${blog.excerpt ?? ''}'.trim();
  final words = text.isEmpty ? 700 : text.split(RegExp(r'\s+')).length;
  final minutes = (words / 180).ceil().clamp(3, 12);
  return '$minutes min read';
}
