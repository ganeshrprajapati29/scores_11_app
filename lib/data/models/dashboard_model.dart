import 'package:flutter/material.dart';

class DashboardData {
  final List<DashboardTournament> tournaments;
  final List<DashboardMatch> matches;
  final List<DashboardNews> news;
  final List<DashboardVideo> videos;
  final Map<String, dynamic> stats;
  final List<DashboardMatch> liveMatches;
  final List<DashboardMatch> upcomingMatches;
  final List<TrendingPlayer> trendingPlayers;
  final List<DashboardTournament> latestTournaments;
  final QuickStats quickStats;

  DashboardData({
    required this.tournaments,
    required this.matches,
    required this.news,
    required this.videos,
    required this.stats,
    this.liveMatches = const [],
    this.upcomingMatches = const [],
    this.trendingPlayers = const [],
    this.latestTournaments = const [],
    QuickStats? quickStats,
  }) : quickStats = quickStats ?? const QuickStats(
    totalMatches: 0,
    totalTournaments: 0,
    totalTeams: 0,
    totalPlayers: 0,
    todayMatches: 0,
    weekMatches: 0,
    activeTournaments: 0,
    liveMatches: 0,
  );

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      tournaments: (json['tournaments'] as List? ?? [])
          .map<DashboardTournament>((e) => DashboardTournament.fromJson(e as Map<String, dynamic>))
          .toList(),
      matches: (json['matches'] as List? ?? [])
          .map<DashboardMatch>((e) => DashboardMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      news: (json['news'] as List? ?? [])
          .map<DashboardNews>((e) => DashboardNews.fromJson(e as Map<String, dynamic>))
          .toList(),
      videos: (json['videos'] as List? ?? [])
          .map<DashboardVideo>((e) => DashboardVideo.fromJson(e as Map<String, dynamic>))
          .toList(),
      stats: json['stats'] as Map<String, dynamic>? ?? {},
      liveMatches: (json['liveMatches'] as List? ?? [])
          .map<DashboardMatch>((e) => DashboardMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingMatches: (json['upcomingMatches'] as List? ?? [])
          .map<DashboardMatch>((e) => DashboardMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      trendingPlayers: (json['trendingPlayers'] as List? ?? [])
          .map<TrendingPlayer>((e) => TrendingPlayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      latestTournaments: (json['latestTournaments'] as List? ?? [])
          .map<DashboardTournament>((e) => DashboardTournament.fromJson(e as Map<String, dynamic>))
          .toList(),
      quickStats: QuickStats.fromJson(json['quickStats'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournaments': tournaments.map((e) => e.toJson()).toList(),
      'matches': matches.map((e) => e.toJson()).toList(),
      'news': news.map((e) => e.toJson()).toList(),
      'videos': videos.map((e) => e.toJson()).toList(),
      'stats': stats,
      'liveMatches': liveMatches.map((e) => e.toJson()).toList(),
      'upcomingMatches': upcomingMatches.map((e) => e.toJson()).toList(),
      'trendingPlayers': trendingPlayers.map((e) => e.toJson()).toList(),
      'latestTournaments': latestTournaments.map((e) => e.toJson()).toList(),
      'quickStats': quickStats.toJson(),
    };
  }
}

class QuickStats {
  final int totalMatches;
  final int totalTournaments;
  final int totalTeams;
  final int totalPlayers;
  final int todayMatches;
  final int weekMatches;
  final int activeTournaments;
  final int liveMatches;

  const QuickStats({
    required this.totalMatches,
    required this.totalTournaments,
    required this.totalTeams,
    required this.totalPlayers,
    required this.todayMatches,
    required this.weekMatches,
    required this.activeTournaments,
    required this.liveMatches,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      totalMatches: json['totalMatches'] ?? 0,
      totalTournaments: json['totalTournaments'] ?? 0,
      totalTeams: json['totalTeams'] ?? 0,
      totalPlayers: json['totalPlayers'] ?? 0,
      todayMatches: json['todayMatches'] ?? 0,
      weekMatches: json['weekMatches'] ?? 0,
      activeTournaments: json['activeTournaments'] ?? 0,
      liveMatches: json['liveMatches'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMatches': totalMatches,
      'totalTournaments': totalTournaments,
      'totalTeams': totalTeams,
      'totalPlayers': totalPlayers,
      'todayMatches': todayMatches,
      'weekMatches': weekMatches,
      'activeTournaments': activeTournaments,
      'liveMatches': liveMatches,
    };
  }
}

class TrendingPlayer {
  final int rank;
  final String id;
  final String name;
  final String role;
  final PlayerStats stats;

  TrendingPlayer({
    required this.rank,
    required this.id,
    required this.name,
    required this.role,
    required this.stats,
  });

  factory TrendingPlayer.fromJson(Map<String, dynamic> json) {
    return TrendingPlayer(
      rank: json['rank'] ?? 0,
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      stats: PlayerStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'id': id,
      'name': name,
      'role': role,
      'stats': stats.toJson(),
    };
  }
}

class PlayerStats {
  final int runs;
  final int wickets;
  final int matches;
  final double average;
  final double strikeRate;

  PlayerStats({
    required this.runs,
    required this.wickets,
    required this.matches,
    required this.average,
    required this.strikeRate,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      runs: json['runs'] ?? 0,
      wickets: json['wickets'] ?? 0,
      matches: json['matches'] ?? 0,
      average: (json['average'] ?? 0).toDouble(),
      strikeRate: (json['strikeRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'runs': runs,
      'wickets': wickets,
      'matches': matches,
      'average': average,
      'strikeRate': strikeRate,
    };
  }
}

class DashboardMatch {
  final DashboardTournament tournament;
  final String id;
  final String title;
  final String? subtitle;
  final String? time;
  final String? status;
  final String? team1;
  final String? team2;
  final String? team1ShortName;
  final String? team2ShortName;
  final String? team1Name;
  final String? team2Name;
  final String? scoreString;
  final DateTime? scheduledDate;
  final String? team1Logo;
  final String? team2Logo;
  final int? team1Score;
  final int? team2Score;
  final String? result;
  final String? format;

  DashboardMatch({
    required this.tournament,
    required this.id,
    required this.title,
    this.subtitle,
    this.time,
    this.status,
    this.team1,
    this.team2,
    this.team1ShortName,
    this.team2ShortName,
    this.team1Name,
    this.team2Name,
    this.scoreString,
    this.scheduledDate,
    this.team1Logo,
    this.team2Logo,
    this.team1Score,
    this.team2Score,
    this.result,
    this.format,
  });

  factory DashboardMatch.fromJson(Map<String, dynamic> json) {
    return DashboardMatch(
      tournament: DashboardTournament.fromJson(json['tournament'] ?? {}),
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      time: json['time'],
      status: json['status'],
      team1: json['team1'],
      team2: json['team2'],
      team1ShortName: json['team1ShortName'],
      team2ShortName: json['team2ShortName'],
      team1Name: json['team1Name'],
      team2Name: json['team2Name'],
      scoreString: json['scoreString'],
      scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']) : null,
      team1Logo: json['team1Logo'],
      team2Logo: json['team2Logo'],
      team1Score: json['team1Score'],
      team2Score: json['team2Score'],
      result: json['result'],
      format: json['format'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournament': tournament.toJson(),
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'time': time,
      'status': status,
      'team1': team1,
      'team2': team2,
      'team1ShortName': team1ShortName,
      'team2ShortName': team2ShortName,
      'team1Name': team1Name,
      'team2Name': team2Name,
      'scoreString': scoreString,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'team1Logo': team1Logo,
      'team2Logo': team2Logo,
      'team1Score': team1Score,
      'team2Score': team2Score,
      'result': result,
      'format': format,
    };
  }
}

class DashboardTournament {
  final String id;
  final String name;
  final String? logo;
  final String? category;
  final String? status;
  final String? startDate;
  final String? endDate;
  final int? teamCount;
  final int? matchCount;
  final int? totalTeams;
  final bool? isPaid;
  final double? entryFee;
  final String? prizeMoney;
  final String? format;

  DashboardTournament({
    required this.id,
    required this.name,
    this.logo,
    this.category,
    this.status,
    this.startDate,
    this.endDate,
    this.teamCount,
    this.matchCount,
    this.totalTeams,
    this.isPaid,
    this.entryFee,
    this.prizeMoney,
    this.format,
  });

  factory DashboardTournament.fromJson(Map<String, dynamic> json) {
    return DashboardTournament(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'],
      category: json['category'],
      status: json['status'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      teamCount: json['teamCount'],
      matchCount: json['matchCount'],
      totalTeams: json['totalTeams'],
      isPaid: json['isPaid'],
      entryFee: json['entryFee']?.toDouble(),
      prizeMoney: json['prizeMoney'],
      format: json['format'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'category': category,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
      'teamCount': teamCount,
      'matchCount': matchCount,
      'totalTeams': totalTeams,
      'isPaid': isPaid,
      'entryFee': entryFee,
      'prizeMoney': prizeMoney,
      'format': format,
    };
  }
}

class DashboardNews {
  final String id;
  final String title;
  final String? subtitle;
  final String? image;
  final String? source;
  final String? time;
  final String? url;

  DashboardNews({
    required this.id,
    required this.title,
    this.subtitle,
    this.image,
    this.source,
    this.time,
    this.url,
  });

  factory DashboardNews.fromJson(Map<String, dynamic> json) {
    return DashboardNews(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      image: json['image'],
      source: json['source'],
      time: json['time'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image': image,
      'source': source,
      'time': time,
      'url': url,
    };
  }
}

class DashboardVideo {
  final String id;
  final String title;
  final String? thumbnail;
  final String? duration;
  final String? views;
  final String? url;

  DashboardVideo({
    required this.id,
    required this.title,
    this.thumbnail,
    this.duration,
    this.views,
    this.url,
  });

  factory DashboardVideo.fromJson(Map<String, dynamic> json) {
    return DashboardVideo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'],
      duration: json['duration'],
      views: json['views'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnail': thumbnail,
      'duration': duration,
      'views': views,
      'url': url,
    };
  }
}
