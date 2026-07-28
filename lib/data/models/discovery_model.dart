class DiscoveryItem {
  final String id;
  final String type;
  final String name;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? image;
  final double rating;
  final bool isPro;
  final bool isVerified;
  final Map<String, dynamic> details;
  final Map<String, dynamic>? contact;
  final Map<String, dynamic>? socialLinks;
  final String? availability;
  final double? hourlyRate;
  final int views;
  final DateTime? createdAt;
  final double? distance;

  DiscoveryItem({
    required this.id,
    required this.type,
    required this.name,
    required this.location,
    this.latitude,
    this.longitude,
    this.image,
    required this.rating,
    required this.isPro,
    this.isVerified = false,
    required this.details,
    this.contact,
    this.socialLinks,
    this.availability,
    this.hourlyRate,
    this.views = 0,
    this.createdAt,
    this.distance,
  });

  factory DiscoveryItem.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int asInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    return DiscoveryItem(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
      image: json['image'],
      rating: asDouble(json['rating']) ?? 0,
      isPro: json['isPro'] ?? false,
      isVerified: json['isVerified'] ?? false,
      details: asMap(json['details']) ?? {},
      contact: asMap(json['contact']),
      socialLinks: asMap(json['socialLinks']),
      availability: json['availability'],
      hourlyRate: asDouble(json['hourlyRate']),
      views: asInt(json['views']),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      distance: asDouble(json['distance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'image': image,
      'rating': rating,
      'isPro': isPro,
      'isVerified': isVerified,
      'details': details,
      'contact': contact,
      'socialLinks': socialLinks,
      'availability': availability,
      'hourlyRate': hourlyRate,
      'views': views,
      'distance': distance,
    };
  }

  String get typeName {
    switch (type) {
      case 'umpire':
        return 'Umpire';
      case 'player':
        return 'Player';
      case 'commentator':
        return 'Commentator';
      case 'ground':
        return 'Ground';
      case 'opponentTeam':
        return 'Opponent Team';
      case 'tournamentTeam':
        return 'Tournament Team';
      case 'tournament':
        return 'Tournament';
      case 'scorer':
        return 'Scorer';
      default:
        return 'Unknown';
    }
  }

  String? get phone => contact?['phone'];
  String? get email => contact?['email'];
  String? get bio => details['bio'];

  String get distanceText {
    if (distance == null) return '';
    if (distance! < 1) {
      return '${(distance! * 1000).round()} m';
    } else if (distance! < 10) {
      return '${distance!.toStringAsFixed(1)} km';
    } else {
      return '${distance!.round()} km';
    }
  }
}
