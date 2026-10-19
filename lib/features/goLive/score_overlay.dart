import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Live score shown as a TV-style bar burned into the broadcast video, built
/// from GET /scoring/match/:id/live.
class ScoreOverlayData {
  final String battingTeam;
  final String bowlingTeam;
  final int runs;
  final int wickets;
  final String overs;
  final int maxOvers;
  final String runRate;
  final String striker;
  final String nonStriker;
  final String bowler;
  final String equation;

  const ScoreOverlayData({
    required this.battingTeam,
    required this.bowlingTeam,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.maxOvers,
    required this.runRate,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
    required this.equation,
  });

  /// Text that changes whenever the picture must be redrawn.
  String get signature =>
      '$battingTeam|$runs/$wickets|$overs|$striker|$nonStriker|$bowler|$equation';

  static int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  static String _id(dynamic v) {
    if (v == null) return '';
    if (v is Map) return (v['_id'] ?? v['id'] ?? '').toString();
    return v.toString();
  }

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static String _teamName(Map<String, dynamic> team, String fallback) {
    final short = (team['shortName'] ?? '').toString().trim();
    if (short.isNotEmpty) return short.toUpperCase();
    final name = (team['name'] ?? '').toString().trim();
    if (name.isEmpty) return fallback;
    return name.length <= 14 ? name.toUpperCase() : name.substring(0, 14).toUpperCase();
  }

  static String _shortPlayer(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    // "Rohit Gurunath Sharma" -> "R. Sharma"
    final short = '${parts.first[0]}. ${parts.last}';
    return short.length <= 16 ? short : short.substring(0, 16);
  }

  /// Bowling overs may be stored as 3.2 (overs.balls) or as a ball count.
  static String _bowlerOvers(Map<String, dynamic> b) {
    final overs = b['overs'];
    if (overs is num) {
      final whole = overs.floor();
      final balls = ((overs - whole) * 10).round();
      if (balls < 6) return balls == 0 ? '$whole' : '$whole.$balls';
    }
    final balls = _int(b['balls']);
    if (balls > 0) return balls % 6 == 0 ? '${balls ~/ 6}' : '${balls ~/ 6}.${balls % 6}';
    return overs?.toString() ?? '0';
  }

  static ScoreOverlayData? fromLive(Map<String, dynamic> live) {
    if (live.isEmpty) return null;
    final match = _map(live['match']);
    final team1 = _map(match['team1']);
    final team2 = _map(match['team2']);
    final card = _map(live['scorecard']);

    final battingId = _id(live['battingTeam']);
    final team1Bats = battingId.isEmpty
        ? (_int(match['currentInnings']) <= 1)
        : battingId == _id(team1);
    final batting = team1Bats ? team1 : team2;
    final bowling = team1Bats ? team2 : team1;

    final batters = (card['battingScorecard'] is List ? card['battingScorecard'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final bowlers = (card['bowlingScorecard'] is List ? card['bowlingScorecard'] as List : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    String batterLine(String id, {required bool onStrike}) {
      if (id.isEmpty) return '';
      final b = batters.firstWhere((e) => _id(e['batsman']) == id, orElse: () => {});
      if (b.isEmpty) return '';
      final name = _shortPlayer((b['playerName'] ?? '').toString());
      return '$name${onStrike ? '*' : ''} ${_int(b['runs'])}(${_int(b['balls'])})';
    }

    String bowlerLine(String id) {
      if (id.isEmpty) return '';
      final b = bowlers.firstWhere((e) => _id(e['bowler']) == id, orElse: () => {});
      if (b.isEmpty) return '';
      final name = _shortPlayer((b['playerName'] ?? '').toString());
      final runs = _int(b['runsConceded'] ?? b['runs']);
      return '$name ${_int(b['wickets'])}-$runs (${_bowlerOvers(b)})';
    }

    final target = _int(live['target']);
    final required = _int(live['requiredRuns']);
    final runs = _int(card['runs']);
    final overs = (card['overs'] ?? '0.0').toString();
    final maxOvers = _int(match['overs']);
    String equation = '';
    if (target > 0) {
      final need = required > 0 ? required : (target - runs).clamp(0, 9999);
      final parts = overs.split('.');
      final ballsBowled = (_int(parts.first) * 6) + (parts.length > 1 ? _int(parts[1]) : 0);
      final ballsLeft = maxOvers > 0 ? (maxOvers * 6 - ballsBowled).clamp(0, 9999) : 0;
      equation = need == 0
          ? 'TARGET $target'
          : (ballsLeft > 0 ? 'NEED $need OFF $ballsLeft' : 'TARGET $target');
    }

    final rr = card['runRate'];
    final runRate = rr is num ? rr.toStringAsFixed(2) : (rr?.toString() ?? '0.00');

    return ScoreOverlayData(
      battingTeam: _teamName(batting, 'BAT'),
      bowlingTeam: _teamName(bowling, 'BOWL'),
      runs: runs,
      wickets: _int(card['wickets']),
      overs: overs,
      maxOvers: maxOvers,
      runRate: runRate,
      striker: batterLine(_id(live['currentStriker']), onStrike: true),
      nonStriker: batterLine(_id(live['currentNonStriker']), onStrike: false),
      bowler: bowlerLine(_id(live['currentBowler'])),
      equation: equation,
    );
  }

  /// PNG of the score bar for a [width] x 96 overlay (1280-wide video).
  Future<Uint8List> renderPng({double width = 1280}) async {
    const height = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    const navy = Color(0xF20B1B3F);
    const brand = Color(0xFF1657CC);
    const red = Color(0xFFE53935);
    final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(24, 8, width - 48, height - 16), const Radius.circular(14));
    canvas.drawRRect(barRect, Paint()..color = navy);

    double x = 24;
    // Team + score block
    final scoreBlockWidth = 330.0;
    canvas.drawRRect(
      RRect.fromRectAndCorners(Rect.fromLTWH(x, 8, scoreBlockWidth, height - 16),
          topLeft: const Radius.circular(14), bottomLeft: const Radius.circular(14)),
      Paint()..color = brand,
    );
    _text(canvas, battingTeam, Offset(x + 18, 20), 22, FontWeight.w800, Colors.white70,
        maxWidth: 140);
    _text(canvas, '$runs/$wickets', Offset(x + 18, 42), 34, FontWeight.w900, Colors.white,
        maxWidth: 150);
    final oversLabel = maxOvers > 0 ? '$overs / $maxOvers ov' : '$overs ov';
    _text(canvas, oversLabel, Offset(x + 176, 28), 20, FontWeight.w700, Colors.white,
        maxWidth: 145);
    _text(canvas, 'RR $runRate', Offset(x + 176, 54), 18, FontWeight.w600, Colors.white70,
        maxWidth: 145);
    x += scoreBlockWidth + 22;

    // Batters
    final battersWidth = (width - 48 - scoreBlockWidth - 22) * 0.42;
    _text(canvas, striker.isEmpty ? '—' : striker, Offset(x, 22), 22, FontWeight.w700,
        Colors.white, maxWidth: battersWidth);
    _text(canvas, nonStriker, Offset(x, 52), 20, FontWeight.w500, Colors.white70,
        maxWidth: battersWidth);
    x += battersWidth + 18;

    // Bowler + equation
    final restWidth = width - 24 - x - 150;
    _text(canvas, bowler.isEmpty ? 'v $bowlingTeam' : bowler, Offset(x, 22), 22,
        FontWeight.w700, Colors.white, maxWidth: restWidth);
    if (equation.isNotEmpty) {
      _text(canvas, equation, Offset(x, 52), 20, FontWeight.w800, const Color(0xFFFFC94D),
          maxWidth: restWidth);
    } else {
      _text(canvas, 'v $bowlingTeam', Offset(x, 52), 20, FontWeight.w500, Colors.white70,
          maxWidth: restWidth);
    }

    // LIVE • SCORES11 tag
    final tagLeft = width - 24 - 138;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(tagLeft, 30, 54, 30), const Radius.circular(6)),
      Paint()..color = red,
    );
    _text(canvas, 'LIVE', Offset(tagLeft + 8, 34), 18, FontWeight.w900, Colors.white,
        maxWidth: 46);
    _text(canvas, 'SCORES11', Offset(tagLeft + 60, 36), 15, FontWeight.w800, Colors.white70,
        maxWidth: 80);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  static void _text(Canvas canvas, String text, Offset offset, double size,
      FontWeight weight, Color color,
      {required double maxWidth}) {
    if (text.isEmpty || maxWidth <= 0) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight, height: 1.0),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }
}
