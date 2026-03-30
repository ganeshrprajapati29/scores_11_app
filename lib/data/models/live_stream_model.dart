class LiveStreamModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String streamType;
  final String streamQuality;
  final String? thumbnail;
  final String streamKey;
  final String? streamUrl;
  final String? rtmpUrl;
  final String? hlsUrl;
  String status;
  int viewerCount;
  int likes;
  final String category;
  final List<String> tags;
  final bool isPrivate;
  final String? password;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int duration;
  final LiveLocation? location;
  final Pricing? pricing;
  final Equipment? equipment;
  final List<String> lookingFor;
  final String? requirements;
  final bool isFeatured;
  final bool isPremium;
  final DateTime createdAt;

  LiveStreamModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.streamType,
    required this.streamQuality,
    this.thumbnail,
    required this.streamKey,
    this.streamUrl,
    this.rtmpUrl,
    this.hlsUrl,
    required this.status,
    required this.viewerCount,
    required this.likes,
    required this.category,
    required this.tags,
    required this.isPrivate,
    this.password,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.duration,
    this.location,
    this.pricing,
    this.equipment,
    required this.lookingFor,
    this.requirements,
    required this.isFeatured,
    required this.isPremium,
    required this.createdAt,
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] : json['userId'],
      title: json['title'] ?? '',
      description: json['description'],
      streamType: json['streamType'] ?? 'mobile',
      streamQuality: json['streamQuality'] ?? '720p',
      thumbnail: json['thumbnail'],
      streamKey: json['streamKey'] ?? '',
      streamUrl: json['streamUrl'],
      rtmpUrl: json['rtmpUrl'],
      hlsUrl: json['hlsUrl'],
      status: json['status'] ?? 'pending',
      viewerCount: json['viewerCount'] ?? 0,
      likes: json['likes'] ?? 0,
      category: json['category'] ?? 'other',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isPrivate: json['isPrivate'] ?? false,
      password: json['password'],
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      duration: json['duration'] ?? 0,
      location: json['location'] != null ? LiveLocation.fromJson(json['location']) : null,
      pricing: json['pricing'] != null ? Pricing.fromJson(json['pricing']) : null,
      equipment: json['equipment'] != null ? Equipment.fromJson(json['equipment']) : null,
      lookingFor: json['lookingFor'] != null ? List<String>.from(json['lookingFor']) : [],
      requirements: json['requirements'],
      isFeatured: json['isFeatured'] ?? false,
      isPremium: json['isPremium'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  String get streamTypeDisplay {
    switch (streamType) {
      case 'mobile':
        return 'Mobile Camera';
      case 'professional':
        return 'Professional Camera';
      case 'session':
        return 'Live Session';
      case 'watch':
        return 'Watch Party';
      default:
        return streamType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'live':
        return 'LIVE';
      case 'scheduled':
        return 'Scheduled';
      case 'ended':
        return 'Ended';
      default:
        return 'Pending';
    }
  }

  bool get isLive => status == 'live';
  bool get isFree => pricing?.type == 'free' || pricing == null;
}

class LiveLocation {
  final String type;
  final List<double> coordinates;
  final String? address;

  LiveLocation({
    required this.type,
    required this.coordinates,
    this.address,
  });

  factory LiveLocation.fromJson(Map<String, dynamic> json) {
    return LiveLocation(
      type: json['type'] ?? 'Point',
      coordinates: json['coordinates'] != null 
          ? List<double>.from(json['coordinates'].map((e) => e.toDouble()))
          : [0, 0],
      address: json['address'],
    );
  }

  double get latitude => coordinates.isNotEmpty ? coordinates[0] : 0;
  double get longitude => coordinates.length > 1 ? coordinates[1] : 0;
}

class Pricing {
  final String type;
  final double amount;
  final String currency;

  Pricing({
    required this.type,
    required this.amount,
    required this.currency,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      type: json['type'] ?? 'free',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
    );
  }

  bool get isFree => type == 'free';
  String get displayPrice => isFree ? 'FREE' : '₹$amount';
}

class Equipment {
  final String? camera;
  final String? microphone;
  final String? lighting;
  final String? other;

  Equipment({
    this.camera,
    this.microphone,
    this.lighting,
    this.other,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      camera: json['camera'],
      microphone: json['microphone'],
      lighting: json['lighting'],
      other: json['other'],
    );
  }
}