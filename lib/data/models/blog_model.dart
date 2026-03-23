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
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled',
      author: json['author']?.toString(),
      excerpt: json['excerpt'],
      content: json['content'],
      imageUrl: json['image'] ?? json['imageUrl'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
  List<Object?> get props => [id, title, author, excerpt, content, imageUrl, createdAt, updatedAt];
}
