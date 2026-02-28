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
    return DiscoveryItem(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      image: json['image'],
      rating: (json['rating'] ?? 0).toDouble(),
      isPro: json['isPro'] ?? false,
      isVerified: json['isVerified'] ?? false,
      details: json['details'] ?? {},
      contact: json['contact'],
      socialLinks: json['socialLinks'],
      availability: json['availability'],
      hourlyRate: json['hourlyRate']?.toDouble(),
      views: json['views'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      distance: json['distance']?.toDouble(),
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
