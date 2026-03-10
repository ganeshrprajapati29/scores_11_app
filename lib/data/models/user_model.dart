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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'USER',
      avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.tryParse(json['dateOfBirth']) 
          : null,
      gender: json['gender'],
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
      isEmailVerified: json['isEmailVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.tryParse(json['lastLogin']) 
          : null,
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

