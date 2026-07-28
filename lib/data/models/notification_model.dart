class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? referenceId;
  final Map<String, dynamic> data;
  final String sound;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    this.data = const {},
    this.sound = 'scores11',
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};
    final reference = json['referenceId'] ??
        data['referenceId'] ??
        data['matchId'] ??
        data['tournamentId'] ??
        data['teamId'] ??
        data['postId'] ??
        data['chatId'] ??
        data['userId'] ??
        data['senderId'];
    return NotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: (json['message'] ?? json['body'])?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      referenceId: reference?.toString(),
      data: data,
      sound: (json['sound'] ?? data['sound'] ?? 'scores11').toString(),
      isRead: json['isRead'] == true || json['isRead']?.toString() == 'true',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? referenceId,
    Map<String, dynamic>? data,
    String? sound,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      data: data ?? this.data,
      sound: sound ?? this.sound,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SubscriptionModel {
  final String id;
  final String userId;
  final String plan;
  final double amount;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isAutoRenew;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.plan,
    required this.amount,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.isAutoRenew,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      plan: json['plan'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isAutoRenew: json['isAutoRenew'] ?? false,
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stock;
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
    required this.isAvailable,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      stock: json['stock'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final String? imageUrl;
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.commentCount,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'],
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      likes: List<String>.from(json['likes'] ?? []),
      commentCount: json['commentCount'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class ClubModel {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String ownerId;
  final int memberCount;
  final bool isVerified;
  final DateTime createdAt;

  ClubModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    required this.ownerId,
    required this.memberCount,
    required this.isVerified,
    required this.createdAt,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logoUrl'],
      ownerId: json['ownerId'] ?? '',
      memberCount: json['memberCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
