import 'package:equatable/equatable.dart';

class BlogModel extends Equatable {
  final String id;
  final String title;
  final String? author;
  final String? excerpt;
  final String? content;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BlogModel({
    required this.id,
    required this.title,
    this.author,
    this.excerpt,
    this.content,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      // ✅ FIX 1: _id use karo
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',

      title: (json['title'] ?? json['name'] ?? 'Untitled Blog').toString(),

      // ✅ FIX 2: author object handle
      author: _readAuthor(json['author']),

      excerpt: json['excerpt']?.toString(),
      content: json['content']?.toString(),

      // ✅ FIX 3: image fix
      imageUrl: json['image'] is Map
          ? json['image']['url']?.toString()
          : (json['image'] ?? json['imageUrl'])?.toString(),

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  static String? _readAuthor(dynamic value) {
    if (value is Map) {
      final name = value['name'] ??
          value['fullName'] ??
          value['username'] ??
          value['displayName'] ??
          value['email'];
      final text = name?.toString().trim();
      return text == null || text.isEmpty ? null : text;
    }

    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    final looksLikeMongoId = RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(text);
    return looksLikeMongoId ? null : text;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id, // ✅ FIX
      'title': title,
      'author': author,
      'excerpt': excerpt,
      'content': content,
      'image': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, title, author, excerpt, content, imageUrl, createdAt, updatedAt];
}
