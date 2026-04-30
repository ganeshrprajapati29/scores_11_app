// DEPRECATED - Methods moved to match_detail_screen.dart
// This file can be safely deleted after verification

// Methods moved to match_detail_screen.dart - file deprecated
// Delete after verification

Widget _buildFallOfWickets(List<FallOfWicket> fallOfWickets) {
  return Container(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fall of Wickets', style: TextStyle(fontWeight: FontWeight.bold)),
        ...fallOfWickets.map((wicket) => Text('${wicket.wicket}/${wicket.runs} - ${wicket.batsman}')),
      ],
    ),
  );
}

Widget _buildMatchInfoCard(Match match) {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Match Info', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Venue: ${match.venue?.name ?? 'TBD'}'),
          Text('Status: ${match.status}'),
        ],
      ),
    ),
  );
}

Widget _buildInningsHeader(Innings innings, int index) {
  return Container(
    padding: EdgeInsets.all(12),
    color: Colors.blue[50],
    child: Text('Innings $index: ${innings.runs}/${innings.wickets}'),
  );
}

Widget _buildEnhancedBattingTable(List<BatsmanStats> batting, Innings innings) {
  return DataTable(
    columns: [
      DataColumn(label: Text('Batsman')),
      DataColumn(label: Text('R')),
      DataColumn(label: Text('B')),
      DataColumn(label: Text('4s')),
      DataColumn(label: Text('6s')),
      DataColumn(label: Text('SR')),
    ],
    rows: batting.map((bat) => DataRow(cells: [
      DataCell(Text(bat.name)),
      DataCell(Text(bat.runs.toString())),
      DataCell(Text(bat.balls.toString())),
      DataCell(Text(bat.fours.toString())),
      DataCell(Text(bat.sixes.toString())),
      DataCell(Text(bat.strikeRate.toString())),
    ])).toList(),
  );
}

Widget _buildEnhancedBowlingTable(List<BowlerStats> bowling) {
  return DataTable(
    columns: [
      DataColumn(label: Text('Bowler')),
      DataColumn(label: Text('O')),
      DataColumn(label: Text('M')),
      DataColumn(label: Text('R')),
      DataColumn(label: Text('W')),
      DataColumn(label: Text('ECON')),
    ],
    rows: bowling.map((bowl) => DataRow(cells: [
      DataCell(Text(bowl.name)),
      DataCell(Text(bowl.overs.toString())),
      DataCell(Text(bowl.maidens.toString())),
      DataCell(Text(bowl.runs.toString())),
      DataCell(Text(bowl.wickets.toString())),
      DataCell(Text(bowl.economy.toString())),
    ])).toList(),
  );
}

Widget _buildExtrasSummary(FullScorecard scorecard) {
  return Container(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Extras Summary'),
        Text('Wides: ${scorecard.extras.wides}'),
        Text('No Balls: ${scorecard.extras.noBalls}'),
        Text('Byes: ${scorecard.extras.by}'),
        Text('Leg Byes: ${scorecard.extras.legByes}'),
        Text('Penalties: ${scorecard.extras.penalties}'),
      ],
    ),
  );
}

