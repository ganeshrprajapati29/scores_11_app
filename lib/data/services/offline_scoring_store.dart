import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// One scoring action made on this phone that the server may not have yet.
///
/// [type] is `ball`, `striker`, `nonStriker` or `bowler`. [payload] is the
/// exact API body; [local] holds what is needed to re-apply the action to the
/// on-screen score (after an app restart, or when the server state is
/// reloaded while the action is still queued).
class PendingScoreAction {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> local;
  final DateTime createdAt;

  /// `pending` (not yet accepted by the server), `sent` (accepted, but the
  /// saved server snapshot does not include it yet) or `rejected`.
  String status;
  String? error;

  PendingScoreAction({
    required this.id,
    required this.type,
    required this.payload,
    this.local = const {},
    DateTime? createdAt,
    this.status = 'pending',
    this.error,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isBall => type == 'ball';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isSent => status == 'sent';

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'local': local,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        if (error != null) 'error': error,
      };

  factory PendingScoreAction.fromJson(Map<String, dynamic> json) =>
      PendingScoreAction(
        id: json['id'].toString(),
        type: json['type'].toString(),
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
        local: Map<String, dynamic>.from(json['local'] as Map? ?? const {}),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        status: json['status']?.toString() ?? 'pending',
        error: json['error']?.toString(),
      );
}

/// Phone-side storage that keeps live scoring working without internet:
/// the queue of unsynced actions and the last score the server confirmed,
/// per match. Survives app restarts.
class OfflineScoringStore {
  static String _queueKey(String matchId) => 'offline_score_queue_$matchId';
  static String _snapshotKey(String matchId) => 'offline_score_snapshot_$matchId';

  static final Random _random = Random();

  /// Unique id for a scoring action; the backend uses it to ignore re-sends.
  static String newActionId() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = List.generate(8, (_) => _random.nextInt(36).toRadixString(36)).join();
    return 'b_${time}_$rand';
  }

  static Future<List<PendingScoreAction>> loadQueue(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey(matchId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => PendingScoreAction.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveQueue(String matchId, List<PendingScoreAction> queue) async {
    final prefs = await SharedPreferences.getInstance();
    if (queue.isEmpty) {
      await prefs.remove(_queueKey(matchId));
    } else {
      await prefs.setString(
        _queueKey(matchId),
        jsonEncode(queue.map((a) => a.toJson()).toList()),
      );
    }
  }

  /// Last server-confirmed state: match, live score and both squads.
  static Future<void> saveSnapshot(String matchId, Map<String, dynamic> snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _snapshotKey(matchId),
      jsonEncode({...snapshot, 'savedAt': DateTime.now().toIso8601String()}),
    );
  }

  static Future<Map<String, dynamic>?> loadSnapshot(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snapshotKey(matchId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (_) {
      return null;
    }
  }
}
