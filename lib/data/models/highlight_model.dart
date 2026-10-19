/// A match highlight: either a YouTube video (incl. auto-saved live replays)
/// or a clip uploaded from the phone. Mirrors backend highlight.model.js.
class HighlightModel {
  final String id;
  final String title;
  final String? description;
  final String source; // youtube | upload
  final String kind; // replay | clip
  final String? youtubeVideoId;
  final String? videoUrl;
  final String? thumbnail;
  final int? durationSeconds;
  final int views;
  final int likeCount;
  final bool isLiked;
  final String? matchId;
  final String matchTitle;
  final String uploaderId;
  final String uploaderName;
  final DateTime? createdAt;

  const HighlightModel({
    required this.id,
    required this.title,
    this.description,
    required this.source,
    required this.kind,
    this.youtubeVideoId,
    this.videoUrl,
    this.thumbnail,
    this.durationSeconds,
    this.views = 0,
    this.likeCount = 0,
    this.isLiked = false,
    this.matchId,
    this.matchTitle = '',
    this.uploaderId = '',
    this.uploaderName = '',
    this.createdAt,
  });

  bool get isYoutube => source == 'youtube' && (youtubeVideoId ?? '').isNotEmpty;
  bool get isReplay => kind == 'replay';

  HighlightModel copyWith({int? views, int? likeCount, bool? isLiked}) =>
      HighlightModel(
        id: id,
        title: title,
        description: description,
        source: source,
        kind: kind,
        youtubeVideoId: youtubeVideoId,
        videoUrl: videoUrl,
        thumbnail: thumbnail,
        durationSeconds: durationSeconds,
        views: views ?? this.views,
        likeCount: likeCount ?? this.likeCount,
        isLiked: isLiked ?? this.isLiked,
        matchId: matchId,
        matchTitle: matchTitle,
        uploaderId: uploaderId,
        uploaderName: uploaderName,
        createdAt: createdAt,
      );

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    final match = json['matchId'];
    final user = json['userId'];
    String teamName(dynamic team) {
      if (team is Map) {
        return (team['shortName'] ?? team['name'] ?? '').toString();
      }
      return '';
    }

    var matchTitle = '';
    String? matchId;
    if (match is Map) {
      matchId = match['_id']?.toString();
      final t1 = teamName(match['team1']);
      final t2 = teamName(match['team2']);
      if (t1.isNotEmpty || t2.isNotEmpty) matchTitle = '$t1 vs $t2';
    } else if (match != null) {
      matchId = match.toString();
    }

    return HighlightModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      source: (json['source'] ?? 'youtube').toString(),
      kind: (json['kind'] ?? 'clip').toString(),
      youtubeVideoId: json['youtubeVideoId']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      durationSeconds: (json['duration'] as num?)?.round(),
      views: (json['views'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] == true,
      matchId: matchId,
      matchTitle: matchTitle,
      uploaderId: user is Map ? (user['_id'] ?? '').toString() : (user ?? '').toString(),
      uploaderName: user is Map ? (user['name'] ?? '').toString() : '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
