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
  final String provider;
  final String? youtubeUrl;
  final String? youtubeVideoId;
  final String? youtubeEmbedUrl;
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
    this.provider = 'zenstream',
    this.youtubeUrl,
    this.youtubeVideoId,
    this.youtubeEmbedUrl,
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
      id: (json['_id'] ?? json['id'] ?? json['streamId'] ?? '').toString(),
      userId: json['userId'] is Map
          ? (json['userId']['_id'] ?? json['userId']['id'] ?? '').toString()
          : (json['userId'] ?? '').toString(),
      title: (json['title'] ?? 'Live Stream').toString(),
      description: json['description']?.toString(),
      streamType: (json['streamType'] ?? 'mobile').toString(),
      streamQuality: (json['streamQuality'] ?? '720p').toString(),
      thumbnail: json['thumbnail']?.toString(),
      streamKey: (json['streamKey'] ?? json['zenstreamStreamKey'] ?? json['key'] ?? json['streamId'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      streamUrl: (json['streamUrl'] ?? json['playbackUrl'] ?? json['zenstreamPlayerUrl'])?.toString(),
      rtmpUrl: (json['rtmpUrl'] ?? json['zenstreamRtmpUrl'])?.toString(),
      hlsUrl: (json['hlsUrl'] ?? json['hls_url'] ?? json['playbackUrl'])?.toString(),
      provider: (json['provider'] ?? (json['youtubeVideoId'] != null ? 'youtube' : 'zenstream')).toString(),
      youtubeUrl: json['youtubeUrl']?.toString(),
      youtubeVideoId: (json['youtubeVideoId'] ?? json['youtubeId'])?.toString(),
      youtubeEmbedUrl: json['youtubeEmbedUrl']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      viewerCount: int.tryParse((json['viewerCount'] ?? json['viewers'] ?? 0).toString()) ?? 0,
      likes: int.tryParse((json['likes'] ?? 0).toString()) ?? 0,
      category: (json['category'] ?? 'cricket').toString(),
      tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
      isPrivate: json['isPrivate'] == true,
      password: json['password']?.toString(),
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? ''),
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
      endedAt: DateTime.tryParse(json['endedAt']?.toString() ?? ''),
      duration: int.tryParse((json['duration'] ?? 0).toString()) ?? 0,
      location: json['location'] is Map ? LiveLocation.fromJson(Map<String, dynamic>.from(json['location'])) : null,
      pricing: json['pricing'] is Map ? Pricing.fromJson(Map<String, dynamic>.from(json['pricing'])) : null,
      equipment: json['equipment'] is Map ? Equipment.fromJson(Map<String, dynamic>.from(json['equipment'])) : null,
      lookingFor: json['lookingFor'] is List ? List<String>.from(json['lookingFor']) : [],
      requirements: json['requirements']?.toString(),
      isFeatured: json['isFeatured'] == true,
      isPremium: json['isPremium'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
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
      case 'youtube':
        return 'YouTube Live';
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
  bool get isYoutube => provider == 'youtube' || streamType == 'youtube' || youtubeVideoId != null;
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
          ? List<double>.from((json['coordinates'] as List).map((e) => (e is num ? e.toDouble() : double.tryParse(e.toString()) ?? 0.0)))
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
