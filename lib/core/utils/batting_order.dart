/// Works out which side batted first: 1 = team1, 2 = team2.
///
/// The first innings' batting team is the most reliable source; before that
/// innings exists the toss (winner + bat/bowl) decides. Team references can be
/// ids, names or short names, so each side is matched against all of them.
int firstBattingSideFor({
  String? firstInningsBattingTeam,
  String? tossWinner,
  String? tossDecision,
  required Iterable<String?> team1Refs,
  required Iterable<String?> team2Refs,
}) {
  final t1 = _refs(team1Refs);
  final t2 = _refs(team2Refs);

  final batting = _norm(firstInningsBattingTeam);
  if (batting.isNotEmpty) {
    if (t1.contains(batting)) return 1;
    if (t2.contains(batting)) return 2;
  }

  final winner = _norm(tossWinner);
  final decision = _norm(tossDecision);
  if (winner.isNotEmpty && (decision == 'bat' || decision == 'bowl')) {
    final winnerSide = t1.contains(winner)
        ? 1
        : t2.contains(winner)
            ? 2
            : 0;
    if (winnerSide != 0) {
      if (decision == 'bat') return winnerSide;
      return winnerSide == 1 ? 2 : 1;
    }
  }
  return 1;
}

/// Side batting in [inningsNumber] (1 or 2) given who batted first.
int battingSideForInnings(int firstSide, int inningsNumber) =>
    inningsNumber >= 2 ? (firstSide == 1 ? 2 : 1) : firstSide;

String _norm(String? value) => (value ?? '').trim().toLowerCase();

Set<String> _refs(Iterable<String?> values) =>
    values.map(_norm).where((v) => v.isNotEmpty).toSet();
