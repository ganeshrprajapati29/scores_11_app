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
    final rawData = json['data'];
    final dataList = rawData is List
        ? rawData
        : rawData is Map && rawData['players'] is List
            ? rawData['players'] as List<dynamic>
            : json['players'] as List<dynamic>? ?? [];
    final rawPagination = rawData is Map && rawData['pagination'] is Map
        ? rawData['pagination']
        : json['pagination'];
    final pagination = rawPagination is Map
        ? Map<String, dynamic>.from(rawPagination)
        : <String, dynamic>{};
    final page = int.tryParse(pagination['page']?.toString() ?? '') ?? 1;
    final limit = int.tryParse(pagination['limit']?.toString() ?? '') ?? 20;
    final total = int.tryParse(pagination['total']?.toString() ?? '') ?? dataList.length;
    final totalPages = int.tryParse((pagination['pages'] ?? pagination['totalPages'])?.toString() ?? '') ?? 1;
    
    return PublicPlayersResponse(
      players: dataList
          .whereType<Map>()
          .map((p) => PublicPlayer.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasMore: page < totalPages,
    );
  }

  factory PublicPlayersResponse.merge(
    PublicPlayersResponse users,
    PublicPlayersResponse players, {
    required int page,
    required int limit,
  }) {
    final mergedByKey = <String, PublicPlayer>{};

    for (final player in [...users.players, ...players.players]) {
      final key = player.playerIdForTeam.isNotEmpty
          ? 'player:${player.playerIdForTeam}'
          : '${player.source}:${player.id}';
      mergedByKey[key] = player;
    }

    final mergedPlayers = mergedByKey.values.toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    final total = users.total + players.total;
    final totalPages = total == 0 ? 1 : (total / limit).ceil();

    return PublicPlayersResponse(
      players: mergedPlayers,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasMore: users.hasMore || players.hasMore,
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
  final String? teamName;
  final String? userId;
  final String source;
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
    this.teamName,
    this.userId,
    this.source = 'user',
    this.createdAt,
  });

  factory PublicPlayer.fromJson(Map<String, dynamic> json) {
    // Parse avatar
    Avatar? avatar;
    if (json['avatar'] is Map) {
      avatar = Avatar.fromJson(Map<String, dynamic>.from(json['avatar']));
    }
    if (avatar == null && json['profileImage'] is Map) {
      avatar = Avatar.fromJson(Map<String, dynamic>.from(json['profileImage']));
    }

    // Parse cricket profile
    CricketProfile? cricketProfile;
    if (json['cricketProfile'] is Map) {
      cricketProfile = CricketProfile.fromJson(Map<String, dynamic>.from(json['cricketProfile']));
    }

    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    if (cricketProfile == null && json['playerName'] != null) {
      cricketProfile = CricketProfile(
        playerId: id,
        playerType: json['role']?.toString() ?? 'batsman',
        battingStyle: json['battingStyle']?.toString(),
        bowlingStyle: json['bowlingStyle']?.toString(),
        matchesPlayed: json['stats'] is Map
            ? int.tryParse(json['stats']['matches']?.toString() ?? '')
            : null,
        totalRuns: json['stats'] is Map
            ? int.tryParse(json['stats']['runs']?.toString() ?? '')
            : null,
        totalWickets: json['stats'] is Map
            ? int.tryParse(json['stats']['wickets']?.toString() ?? '')
            : null,
        highestScore: json['stats'] is Map
            ? int.tryParse(json['stats']['highestScore']?.toString() ?? '')
            : null,
        battingAverage: json['stats'] is Map
            ? double.tryParse(json['stats']['average']?.toString() ?? '')
            : null,
      );
    }

    // Parse location
    Location? location;
    if (json['location'] is Map) {
      location = Location.fromJson(Map<String, dynamic>.from(json['location']));
    }

    // Parse stats
    Stats? stats;
    if (json['stats'] is Map) {
      stats = Stats.fromJson(Map<String, dynamic>.from(json['stats']));
    }

    return PublicPlayer(
      id: id,
      fullName: json['fullName']?.toString() ??
          json['playerName']?.toString() ??
          json['name']?.toString() ??
          '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'player',
      isPublicPlayer: json['isPublicPlayer'] == true || json['isPublicPlayer']?.toString() == 'true',
      isActive: json['isActive'] != false && json['isActive']?.toString() != 'false',
      avatar: avatar,
      cricketProfile: cricketProfile,
      location: location,
      stats: stats,
      teamName: json['teamName']?.toString() ??
          (json['team'] is Map
              ? (json['team']['name']?.toString() ??
                  json['team']['shortName']?.toString())
              : null),
      userId: _idFrom(json['user']) ??
          _idFrom(json['createdBy']) ??
          _idFrom(json['owner']) ??
          json['userId']?.toString(),
      source: json['source']?.toString() ??
          (json['playerName'] != null ? 'player' : 'user'),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) 
          : null,
    );
  }

  String get playerType => cricketProfile?.playerType ?? 'batsman';
  String get playerIdForTeam => cricketProfile?.playerId ?? id;
  String get connectionUserId => userId?.isNotEmpty == true ? userId! : id;
  String? get city => location?.city;
  String? get state => location?.state;

  static String? _idFrom(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return (value['_id'] ?? value['id'])?.toString();
    return value.toString();
  }
}

class CricketProfile {
  final String? playerId;
  final String? playerType;
  final String? battingStyle;
  final String? bowlingStyle;
  final int? matchesPlayed;
  final int? totalRuns;
  final int? totalWickets;
  final int? highestScore;
  final double? battingAverage;

  CricketProfile({
    this.playerId,
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
      playerId: json['playerId']?.toString(),
      playerType: json['playerType']?.toString(),
      battingStyle: json['battingStyle']?.toString(),
      bowlingStyle: json['bowlingStyle']?.toString(),
      matchesPlayed: int.tryParse(json['matchesPlayed']?.toString() ?? ''),
      totalRuns: int.tryParse(json['totalRuns']?.toString() ?? ''),
      totalWickets: int.tryParse(json['totalWickets']?.toString() ?? ''),
      highestScore: int.tryParse(json['highestScore']?.toString() ?? ''),
      battingAverage: double.tryParse(json['battingAverage']?.toString() ?? ''),
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
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
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
      matchesPlayed: int.tryParse(json['matchesPlayed']?.toString() ?? '') ?? 0,
      matchesWon: int.tryParse(json['matchesWon']?.toString() ?? '') ?? 0,
      matchesLost: int.tryParse(json['matchesLost']?.toString() ?? '') ?? 0,
    );
  }
}

class PublicPlayersService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch public players from API
  /// GET /api/user/players/public + optional /api/players/public
  /// Supports search by fullName or username
  /// Supports filtering by playerType
  Future<PublicPlayersResponse> getPublicPlayers({
    int page = 1,
    int limit = 20,
    String? search,
    String? playerType,
  }) async {
    try {
      final query = {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final usersResult = await _getFirstAvailable(
        paths: const [
          '/user/players/public',
          '/users/players/public',
          '/users/player/public',
        ],
        queryParameters: {
          ...query,
          if (playerType != null && playerType.isNotEmpty) 'playerType': playerType,
        },
      );

      final playerDocsResult = await _getOptional(
        path: '${ApiConfig.players}/public',
        queryParameters: {
          ...query,
          if (playerType != null && playerType.isNotEmpty) 'role': playerType,
        },
      );

      if (playerDocsResult == null) {
        return usersResult;
      }

      return PublicPlayersResponse.merge(
        usersResult,
        playerDocsResult,
        page: page,
        limit: limit,
      );
    } on DioException catch (e) {
      final message = _apiClient.parseDioError(e);
      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to load public players: $e');
    }
  }

  Future<PublicPlayersResponse> _getFirstAvailable({
    required List<String> paths,
    required Map<String, dynamic> queryParameters,
  }) async {
    DioException? lastError;

    for (final path in paths) {
      try {
        final response = await _apiClient.get(
          path,
          queryParameters: queryParameters,
        );
        if (response.statusCode == 200) {
          return PublicPlayersResponse.fromJson(response.data);
        }
      } on DioException catch (e) {
        lastError = e;
        if (e.response?.statusCode != 404) rethrow;
      }
    }

    if (lastError != null) throw lastError;
    throw Exception('Public players API route not found');
  }

  Future<PublicPlayersResponse?> _getOptional({
    required String path,
    required Map<String, dynamic> queryParameters,
  }) async {
    try {
      final response = await _apiClient.get(
        path,
        queryParameters: queryParameters,
      );
      if (response.statusCode == 200) {
        return PublicPlayersResponse.fromJson(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }
    return null;
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
