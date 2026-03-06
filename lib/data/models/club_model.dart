class Club {
  final String id;
  final String name;
  final String? description;
  final String? logo;
  final String? coverImage;
  final String ownerId;
  final String? associationId;
  final String? city;
  final String? state;
  final String? country;
  final int totalTeams;
  final int totalPlayers;
  final String status; // active, inactive, suspended
  final DateTime createdAt;
  final DateTime updatedAt;

  Club({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    this.coverImage,
    required this.ownerId,
    this.associationId,
    this.city,
    this.state,
    this.country,
    this.totalTeams = 0,
    this.totalPlayers = 0,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logo: json['logo'],
      coverImage: json['coverImage'],
      ownerId: json['ownerId'] ?? json['owner'] ?? '',
      associationId: json['associationId'] ?? json['association'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      totalTeams: json['totalTeams'] ?? 0,
      totalPlayers: json['totalPlayers'] ?? 0,
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo': logo,
      'coverImage': coverImage,
      'ownerId': ownerId,
      'associationId': associationId,
      'city': city,
      'state': state,
      'country': country,
      'totalTeams': totalTeams,
      'totalPlayers': totalPlayers,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Association {
  final String id;
  final String name;
  final String? description;
  final String? logo;
  final String? coverImage;
  final String ownerId;
  final String? region;
  final String? city;
  final String? state;
  final String? country;
  final int totalClubs;
  final int totalTournaments;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Association({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    this.coverImage,
    required this.ownerId,
    this.region,
    this.city,
    this.state,
    this.country,
    this.totalClubs = 0,
    this.totalTournaments = 0,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Association.fromJson(Map<String, dynamic> json) {
    return Association(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logo: json['logo'],
      coverImage: json['coverImage'],
      ownerId: json['ownerId'] ?? json['owner'] ?? '',
      region: json['region'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      totalClubs: json['totalClubs'] ?? 0,
      totalTournaments: json['totalTournaments'] ?? 0,
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo': logo,
      'coverImage': coverImage,
      'ownerId': ownerId,
      'region': region,
      'city': city,
      'state': state,
      'country': country,
      'totalClubs': totalClubs,
      'totalTournaments': totalTournaments,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

