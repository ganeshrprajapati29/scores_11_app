import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:scores11/features/goLive/score_overlay.dart';

// Shape of GET /scoring/match/:id/live
Map<String, dynamic> liveJson({int innings = 1, int? target, int? required}) => {
      'match': {
        '_id': 'm1',
        'team1': {'_id': 't1', 'name': 'Mumbai Warriors', 'shortName': 'MW'},
        'team2': {'_id': 't2', 'name': 'Delhi Kings'},
        'currentInnings': innings,
        'overs': 20,
      },
      'battingTeam': innings == 1 ? 't1' : 't2',
      'scorecard': {
        'runs': 145,
        'wickets': 3,
        'overs': '16.2',
        'runRate': 8.87,
        'battingScorecard': [
          {'batsman': 'p1', 'playerName': 'Rohit Gurunath Sharma', 'runs': 45, 'balls': 30},
          {'batsman': 'p2', 'playerName': 'Virat', 'runs': 22, 'balls': 18},
        ],
        'bowlingScorecard': [
          {'bowler': 'b1', 'playerName': 'Jasprit Bumrah', 'overs': 3.2, 'runsConceded': 24, 'wickets': 2},
        ],
      },
      'currentStriker': 'p1',
      'currentNonStriker': {'_id': 'p2'},
      'currentBowler': 'b1',
      'target': target,
      'requiredRuns': required,
    };

void main() {
  test('first innings bar shows batting side, batters and bowler', () {
    final data = ScoreOverlayData.fromLive(liveJson())!;
    expect(data.battingTeam, 'MW');
    expect(data.bowlingTeam, 'DELHI KINGS');
    expect('${data.runs}/${data.wickets}', '145/3');
    expect(data.overs, '16.2');
    expect(data.runRate, '8.87');
    expect(data.striker, 'R. Sharma* 45(30)');
    expect(data.nonStriker, 'Virat 22(18)');
    expect(data.bowler, 'J. Bumrah 2-24 (3.2)');
    expect(data.equation, '');
  });

  test('chase shows runs needed off balls left', () {
    final data = ScoreOverlayData.fromLive(liveJson(innings: 2, target: 180, required: 35))!;
    expect(data.battingTeam, 'DELHI KINGS');
    expect(data.equation, 'NEED 35 OFF 22');
  });

  test('signature changes with the score', () {
    final a = ScoreOverlayData.fromLive(liveJson())!;
    final json = liveJson();
    (json['scorecard'] as Map)['runs'] = 149;
    final b = ScoreOverlayData.fromLive(json)!;
    expect(a.signature == b.signature, isFalse);
    expect(ScoreOverlayData.fromLive({}), isNull);
  });

  test('renders a 1280x96 PNG', () async {
    final png = await ScoreOverlayData.fromLive(liveJson(innings: 2, target: 180, required: 35))!
        .renderPng();
    expect(png.sublist(1, 4), [0x50, 0x4E, 0x47]); // "PNG"
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 1280);
    expect(frame.image.height, 96);
  });
}
