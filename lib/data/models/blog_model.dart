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
      id: json['_id']?.toString() ?? '',

      title: json['title'] ?? 'Untitled',

      // ✅ FIX 2: author object handle
      author: json['author'] is Map
          ? json['author']['_id']?.toString()
          : json['author']?.toString(),

      excerpt: json['excerpt'],
      content: json['content'],

      // ✅ FIX 3: image fix
      imageUrl: json['image'] is Map
          ? json['image']['url']
          : json['image'] ?? json['imageUrl'],

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
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