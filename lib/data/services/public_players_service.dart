import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/user_model.dart';

class PublicPlayersResponse {
  final List<PublicPlayer> players;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  PublicPlayersResponse({
    required this.players,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });

  factory PublicPlayersResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    
    return PublicPlayersResponse(
      players: dataList.map((p) => PublicPlayer.fromJson(p as Map<String, dynamic>)).toList(),
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 20,
      total: pagination['total'] ?? 0,
      totalPages: pagination['pages'] ?? 1,
      hasMore: (pagination['page'] ?? 1) < (pagination['pages'] ?? 1),
    );
  }
}

class PublicPlayer {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String role;
  final bool isPublicPlayer;
  final bool isActive;
  final Avatar? avatar;
  final CricketProfile? cricketProfile;
  final Location? location;
  final Stats? stats;
  final DateTime? createdAt;

  PublicPlayer({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    required this.isPublicPlayer,
    required this.isActive,
    this.avatar,
    this.cricketProfile,
    this.location,
    this.stats,
    this.createdAt,
  });

  factory PublicPlayer.fromJson(Map<String, dynamic> json) {
    // Parse avatar
    Avatar? avatar;
    if (json['avatar'] != null) {
      avatar = Avatar.fromJson(Map<String, dynamic>.from(json['avatar']));
    }

    // Parse cricket profile
    CricketProfile? cricketProfile;
    if (json['cricketProfile'] != null) {
      cricketProfile = CricketProfile.fromJson(Map<String, dynamic>.from(json['cricketProfile']));
    }

    // Parse location
    Location? location;
    if (json['location'] != null) {
      location = Location.fromJson(Map<String, dynamic>.from(json['location']));
    }

    // Parse stats
    Stats? stats;
    if (json['stats'] != null) {
      stats = Stats.fromJson(Map<String, dynamic>.from(json['stats']));
    }

    return PublicPlayer(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'player',
      isPublicPlayer: json['isPublicPlayer'] ?? false,
      isActive: json['isActive'] ?? true,
      avatar: avatar,
      cricketProfile: cricketProfile,
      location: location,
      stats: stats,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) 
          : null,
    );
  }

  String get playerType => cricketProfile?.playerType ?? 'batsman';
  String? get city => location?.city;
  String? get state => location?.state;
}

class CricketProfile {
  final String? playerType;
  final String? battingStyle;
  final String? bowlingStyle;
  final int? matchesPlayed;
  final int? totalRuns;
  final int? totalWickets;
  final int? highestScore;
  final double? battingAverage;

  CricketProfile({
    this.playerType,
    this.battingStyle,
    this.bowlingStyle,
    this.matchesPlayed,
    this.totalRuns,
    this.totalWickets,
    this.highestScore,
    this.battingAverage,
  });

  factory CricketProfile.fromJson(Map<String, dynamic> json) {
    return CricketProfile(
      playerType: json['playerType'],
      battingStyle: json['battingStyle'],
      bowlingStyle: json['bowlingStyle'],
      matchesPlayed: json['matchesPlayed'],
      totalRuns: json['totalRuns'],
      totalWickets: json['totalWickets'],
      highestScore: json['highestScore'],
      battingAverage: json['battingAverage']?.toDouble(),
    );
  }
}

class Location {
  final String? city;
  final String? state;
  final String? country;

  Location({this.city, this.state, this.country});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      city: json['city'],
      state: json['state'],
      country: json['country'],
    );
  }
}

class Stats {
  final int? matchesPlayed;
  final int? matchesWon;
  final int? matchesLost;

  Stats({this.matchesPlayed, this.matchesWon, this.matchesLost});

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      matchesPlayed: json['matchesPlayed'] ?? 0,
      matchesWon: json['matchesWon'] ?? 0,
      matchesLost: json['matchesLost'] ?? 0,
    );
  }
}

class PublicPlayersService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch public players from API
  /// GET /api/users/players/public
  /// Supports search by fullName or username
  /// Supports filtering by playerType
  Future<PublicPlayersResponse> getPublicPlayers({
    int page = 1,
    int limit = 20,
    String? search,
    String? playerType,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/users/players/public',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (playerType != null && playerType.isNotEmpty) 'playerType': playerType,
        },
      );

      if (response.statusCode == 200) {
        return PublicPlayersResponse.fromJson(response.data);
      }
      throw Exception(response.data['message'] ?? 'Failed to load public players');
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to load public players: $e');
    }
  }

  /// Search public players by name
  Future<List<PublicPlayer>> searchPublicPlayers(String query) async {
    try {
      final response = await getPublicPlayers(
        search: query,
        limit: 20,
      );
      return response.players;
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  /// Get players filtered by type (batsman, bowler, all-rounder, wicket-keeper)
  Future<List<PublicPlayer>> getPlayersByType(String playerType) async {
    try {
      final response = await getPublicPlayers(
        playerType: playerType,
        limit: 20,
      );
      return response.players;
    } catch (e) {
      throw Exception('Failed to load players by type: $e');
    }
  }
}
