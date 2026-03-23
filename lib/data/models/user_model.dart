import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final Avatar? avatar;
  final DateTime? dateOfBirth;
  final String? gender;
  final Address? address;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? cricketProfile;
  final String playingStyle;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.avatar,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.isEmailVerified = false,
    this.isActive = true,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    this.cricketProfile,
    required this.playingStyle,
  });

  factory UserModel.fromJson(dynamic json) {
    // Handle null or missing fields safely - accept any type for json parameter
    if (json == null) {
      return UserModel(
        id: '',
        name: '',
        email: '',
        role: 'USER',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        playingStyle: 'All Rounder',
      );
    }
    
    // Convert to Map<String, dynamic> if it's not already
    Map<String, dynamic> data;
    if (json is Map<String, dynamic>) {
      data = json;
    } else if (json is Map) {
      data = Map<String, dynamic>.from(json);
    } else {
      return UserModel(
        id: '',
        name: '',
        email: '',
        role: 'USER',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        playingStyle: 'All Rounder',
      );
    }
    
    final idValue = data['_id'] ?? data['id'];
    final nameValue = data['fullName'] ?? data['name'] ?? data['name'] ?? '';
    final emailValue = data['email'] ?? '';
    final roleValue = (data['role'] ?? 'USER').toString().toUpperCase();
    
    DateTime? parsedCreatedAt;
    DateTime? parsedUpdatedAt;
    
    try {
      if (data['createdAt'] != null) {
        parsedCreatedAt = data['createdAt'] is DateTime 
            ? data['createdAt'] 
            : DateTime.tryParse(data['createdAt'].toString());
      }
    } catch (e) {
      parsedCreatedAt = DateTime.now();
    }
    
    try {
      if (data['updatedAt'] != null) {
        parsedUpdatedAt = data['updatedAt'] is DateTime 
            ? data['updatedAt'] 
            : DateTime.tryParse(data['updatedAt'].toString());
      }
    } catch (e) {
      parsedUpdatedAt = DateTime.now();
    }

    // Safely parse avatar
    Avatar? avatar;
    try {
      if (data['avatar'] != null) {
        if (data['avatar'] is Map) {
          avatar = Avatar.fromJson(Map<String, dynamic>.from(data['avatar']));
        }
      }
    } catch (e) {
      avatar = null;
    }

    // Safely parse address
    Address? address;
    try {
      if (data['address'] != null) {
        if (data['address'] is Map) {
          address = Address.fromJson(Map<String, dynamic>.from(data['address']));
        }
      }
    } catch (e) {
      address = null;
    }

    return UserModel(
      id: idValue?.toString() ?? '',
      name: nameValue?.toString() ?? '',
      email: emailValue?.toString() ?? '',
      phone: data['phone']?.toString(),
      role: roleValue,
      avatar: avatar,
      dateOfBirth: data['dateOfBirth'] != null 
          ? DateTime.tryParse(data['dateOfBirth'].toString()) 
          : null,
      gender: data['gender']?.toString(),
      address: address,
      isEmailVerified: data['isEmailVerified'] == true || data['isEmailVerified'] == 'true',
      isActive: data['isActive'] != false && data['isActive'] != 'false',
      lastLogin: data['lastLogin'] != null 
          ? DateTime.tryParse(data['lastLogin'].toString()) 
          : null,
      createdAt: parsedCreatedAt ?? DateTime.now(),
      updatedAt: parsedUpdatedAt ?? DateTime.now(),
      playingStyle: data['playingStyle'] ?? data['cricketProfile']?['playingStyle'] ?? 'All Rounder',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'avatar': avatar?.toJson(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address?.toJson(),
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? role,
    Avatar? avatar,
    DateTime? dateOfBirth,
    String? gender,
    Address? address,
    bool? isEmailVerified,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? playingStyle,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      playingStyle: playingStyle ?? this.playingStyle,
    );
  }

@override
  List<Object?> get props => [
        id,
        email,
        name,
        phone,
        role,
        avatar,
        dateOfBirth,
        gender,
        address,
        isEmailVerified,
        isActive,
        lastLogin,
        createdAt,
        updatedAt,
        playingStyle,
      ];
}

class Avatar extends Equatable {
  final String? publicId;
  final String? url;

  const Avatar({this.publicId, this.url});

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      publicId: json['publicId'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'publicId': publicId,
      'url': url,
    };
  }

  @override
  List<Object?> get props => [publicId, url];
}

class Address extends Equatable {
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;

  const Address({
    this.street,
    this.city,
    this.state,
    this.country,
    this.pincode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
    };
  }

  String get fullAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    if (pincode != null && pincode!.isNotEmpty) parts.add(pincode!);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [street, city, state, country, pincode];
}

