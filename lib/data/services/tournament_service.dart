import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';
import '../../core/services/api_client.dart';
import '../models/tournament_model.dart';

class PaginatedTournaments {
  final List<Tournament> tournaments;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  const PaginatedTournaments({
    required this.tournaments,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });
}

class TournamentService {
  final ApiClient _apiClient = ApiClient();

  Future<PaginatedTournaments> getTournaments({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final normalizedStatus = status?.toUpperCase();
      if (normalizedStatus == 'LIVE') {
        final tournaments = await getOngoingTournaments(limit: limit);
        return PaginatedTournaments(
          tournaments: tournaments,
          page: page,
          limit: limit,
          total: tournaments.length,
          totalPages: 1,
          hasMore: false,
        );
      }
      if (normalizedStatus == 'UPCOMING') {
        final tournaments = await getUpcomingTournaments(limit: limit);
        return PaginatedTournaments(
          tournaments: tournaments,
          page: page,
          limit: limit,
          total: tournaments.length,
          totalPages: 1,
          hasMore: false,
        );
      }

      final response = await _apiClient.get(
        '${ApiConfig.tournaments}/list',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (status != null) 'status': _backendStatus(status),
        },
      );
      return _parsePaginatedTournaments(response.data, page: page, limit: limit);
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(
        e,
        defaultMessage: 'Could not load tournaments.',
      ));
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<List<Tournament>> getTournamentsList({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final result = await getTournaments(page: page, limit: limit, status: status);
    return result.tournaments;
  }

  Future<List<Tournament>> searchTournaments(String query, {int limit = 8}) async {
    final cleaned = query.trim();
    if (cleaned.length < 2) return [];

    try {
      final response = await _apiClient.get(
        '${ApiConfig.tournaments}/list',
        queryParameters: {
          'page': '1',
          'limit': limit.toString(),
          'search': cleaned,
          'q': cleaned,
        },
      );
      final results = _parsePaginatedTournaments(response.data, page: 1, limit: limit).tournaments;
      return _filterTournamentMatches(results, cleaned, limit: limit);
    } catch (_) {
      final results = await getTournamentsList(page: 1, limit: 50);
      return _filterTournamentMatches(results, cleaned, limit: limit);
    }
  }

  List<Tournament> _filterTournamentMatches(List<Tournament> tournaments, String query, {required int limit}) {
    final needle = query.toLowerCase();
    return tournaments.where((tournament) {
      final values = [
        tournament.name,
        tournament.shortName,
        tournament.description,
        tournament.format,
        tournament.type,
        tournament.status,
        tournament.venue,
        tournament.city,
      ];
      return values.any((value) => (value ?? '').toLowerCase().contains(needle));
    }).take(limit).toList();
  }

  Future<Tournament> getTournamentById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.tournaments}/public/$id');
      return Tournament.fromJson(_unwrapData(response.data));
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(
        e,
        defaultMessage: 'Could not open tournament.',
      ));
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<Tournament> getTournamentByIdPublic(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.tournaments}/public/$id');
      return Tournament.fromJson(_unwrapData(response.data));
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(
        e,
        defaultMessage: 'Could not open tournament.',
      ));
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<List<Tournament>> getOngoingTournaments({int limit = 10}) async {
    final response = await _apiClient.get(
      '${ApiConfig.tournaments}/ongoing',
      queryParameters: {'limit': limit.toString()},
    );
    return _parseTournamentList(_unwrapData(response.data));
  }

  Future<List<Tournament>> getUpcomingTournaments({int limit = 10}) async {
    final response = await _apiClient.get(
      '${ApiConfig.tournaments}/upcoming',
      queryParameters: {'limit': limit.toString()},
    );
    return _parseTournamentList(_unwrapData(response.data));
  }

  Future<List<Tournament>> getLiveTournaments() => getOngoingTournaments();

  Future<Tournament> createTournament({
    required String name,
    String? shortName,
    String? description,
    required String format,
    String type = 'LEAGUE',
    required DateTime startDate,
    required DateTime endDate,
    String? venue,
    int totalTeams = 10,
    double? entryFee,
    double? prizeMoney,
  }) async {
    try {
      final safeStartDate = startDate.isBefore(DateTime.now())
          ? DateTime.now().add(const Duration(hours: 1))
          : startDate;
      final safeEndDate = endDate.isBefore(safeStartDate)
          ? safeStartDate.add(const Duration(days: 1))
          : endDate;
      final response = await _apiClient.post(
        ApiConfig.tournaments,
        data: {
          'name': name,
          if (shortName != null && shortName.isNotEmpty) 'shortName': shortName,
          if (description != null && description.isNotEmpty)
            'description': description,
          'format': format.toLowerCase(),
          'type': type.toLowerCase(),
          'startDate': safeStartDate.toIso8601String(),
          'endDate': safeEndDate.toIso8601String(),
          'venue': {
            'name': venue?.isNotEmpty == true ? venue : 'Default Stadium',
            'city': '',
            'state': '',
            'country': 'India',
          },
          'maxTeams': totalTeams,
          'minTeams': 2,
          'entryFee': entryFee ?? 0,
          if (prizeMoney != null) 'prizeMoney': prizeMoney,
        },
      );
      return Tournament.fromJson(_unwrapData(response.data));
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(
        e,
        defaultMessage: 'Could not create tournament.',
      ));
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<Tournament> updateTournament(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('${ApiConfig.tournaments}/$id', data: data);
    return Tournament.fromJson(_unwrapData(response.data));
  }

  Future<void> deleteTournament(String id) async {
    await _apiClient.delete('${ApiConfig.tournaments}/$id');
  }

  Future<Tournament> registerTeam(String tournamentId, String teamId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.tournaments}/$tournamentId/register',
        data: {'teamId': teamId},
      );
      return Tournament.fromJson(_unwrapData(response.data));
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(
        e,
        defaultMessage: 'Could not register team.',
      ));
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<Tournament> unregisterTeam(String tournamentId, String teamId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.tournaments}/$tournamentId/register',
        data: {'teamId': teamId},
      );
      return Tournament.fromJson(_unwrapData(response.data));
    } on DioException catch (e) {
      throw Exception(_apiClient.parseDioError(
        e,
        defaultMessage: 'Could not unregister team.',
      ));
    } catch (e) {
      throw Exception(_cleanError(e));
    }
  }

  Future<Tournament> updateStatus(String tournamentId, String status) async {
    final response = await _apiClient.patch(
      '${ApiConfig.tournaments}/$tournamentId/status',
      data: {'status': _backendStatus(status)},
    );
    return Tournament.fromJson(_unwrapData(response.data));
  }

  Future<List<PointsTable>> getPointsTable(String tournamentId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.tournaments}/$tournamentId/points-table');
      final data = _unwrapData(response.data);
      final rawPoints = data is Map ? data['points'] : data;
      if (rawPoints is List) {
        return rawPoints.whereType<Map>().map((json) => PointsTable.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Points table load failed: ${e.message}');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTournamentMatches(
    String tournamentId, {
    String? status,
    String? matchType,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.tournaments}/$tournamentId/matches',
        queryParameters: {
          if (status != null && status != 'All') 'status': status,
          if (matchType != null && matchType != 'All') 'matchType': matchType,
        },
      );
      final data = _unwrapData(response.data);
      if (data is List) {
        return data.whereType<Map>().map((json) => Map<String, dynamic>.from(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Tournament matches load failed: ${e.message}');
      return [];
    }
  }

  Future<Map<String, dynamic>> generateLeagueMatches(String tournamentId) async {
    final response = await _apiClient.post('${ApiConfig.tournaments}/$tournamentId/generate/league');
    final data = _unwrapData(response.data);
    return data is Map ? Map<String, dynamic>.from(data) : {'matches': data};
  }

  Future<Map<String, dynamic>> generateKnockoutMatches(String tournamentId) async {
    final response = await _apiClient.post('${ApiConfig.tournaments}/$tournamentId/generate/knockout');
    final data = _unwrapData(response.data);
    return data is Map ? Map<String, dynamic>.from(data) : {'matches': data};
  }

  Future<Map<String, dynamic>> getTournamentStats(String tournamentId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.tournaments}/$tournamentId/stats');
      final data = _unwrapData(response.data);
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on DioException catch (e) {
      debugPrint('Tournament stats load failed: ${e.message}');
      return {};
    }
  }

  PaginatedTournaments _parsePaginatedTournaments(
    dynamic raw, {
    required int page,
    required int limit,
  }) {
    final data = _unwrapData(raw);
    final pagination = _readPagination(raw, data);
    final tournaments = _parseTournamentList(data);
    final total = _safeInt(pagination['total'], fallback: tournaments.length);
    final totalPages = _safeInt(
      pagination['pages'] ?? pagination['totalPages'],
      fallback: total == 0 ? 1 : (total / limit).ceil(),
    );

    return PaginatedTournaments(
      tournaments: tournaments,
      page: _safeInt(pagination['page'], fallback: page),
      limit: _safeInt(pagination['limit'], fallback: limit),
      total: total,
      totalPages: totalPages,
      hasMore: page < totalPages,
    );
  }

  List<Tournament> _parseTournamentList(dynamic data) {
    final rawList = data is Map
        ? (data['tournaments'] ?? data['items'] ?? data['docs'] ?? data['data'])
        : data;
    if (rawList is! List) return [];

    final tournaments = <Tournament>[];
    for (final item in rawList) {
      try {
        tournaments.add(Tournament.fromJson(item));
      } catch (e) {
        debugPrint('Skipping invalid tournament item: $e');
      }
    }
    return tournaments;
  }

  Map<String, dynamic> _readPagination(dynamic raw, dynamic data) {
    dynamic pagination;
    if (raw is Map) pagination = raw['pagination'];
    if (pagination == null && data is Map) pagination = data['pagination'];
    return pagination is Map ? Map<String, dynamic>.from(pagination) : {};
  }

  dynamic _unwrapData(dynamic raw) {
    if (raw is Map && raw.containsKey('data')) return raw['data'];
    return raw;
  }

  String _backendStatus(String status) {
    switch (status.toUpperCase()) {
      case 'LIVE':
        return 'in_progress';
      case 'UPCOMING':
        return 'draft';
      case 'COMPLETED':
        return 'completed';
      default:
        return status.toLowerCase();
    }
  }

  int _safeInt(dynamic value, {required int fallback}) {
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
