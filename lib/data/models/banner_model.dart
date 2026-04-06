class Banner {
  final String id;
  final String title;
  final String? description;
  final String image;
  final String? videoUrl;
  final String? gifUrl;
  final String? link;
  final String linkType;
  final String position;
  final int order;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final String targetAudience;
  final Map<String, dynamic> size;

  const Banner({
    required this.id,
    required this.title,
    this.description,
    required this.image,
    this.videoUrl,
    this.gifUrl,
    this.link,
    required this.linkType,
    required this.position,
    required this.order,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.targetAudience,
    required this.size,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      image: json['image'] ?? '',
      videoUrl: json['videoUrl'],
      gifUrl: json['gifUrl'],
      link: json['link'],
      linkType: json['linkType'] ?? 'none',
      position: json['position'] ?? 'general',
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? false,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      targetAudience: json['targetAudience'] ?? 'all',
      size: Map<String, dynamic>.from(json['size'] ?? {'width': 1920, 'height': 500}),
    );
  }
}
