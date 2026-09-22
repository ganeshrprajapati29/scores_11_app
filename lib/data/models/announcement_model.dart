class Announcement {
  final String id;
  final String message;
  final int order;

  const Announcement({
    required this.id,
    required this.message,
    required this.order,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['_id'] ?? '',
      message: json['message'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}
