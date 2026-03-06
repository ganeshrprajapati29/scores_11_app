import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_appbar.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;
  
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final Map<String, dynamic> _matchData = {
    'team1': {'name': 'Mumbai Indians', 'shortName': 'MI', 'logo': 'https://picsum.photos/50/50', 'score': '185/4', 'overs': '20'},
    'team2': {'name': 'Chennai Super Kings', 'shortName': 'CSK', 'logo': 'https://picsum.photos/50/50', 'score': '142/3', 'overs': '14.2'},
    'status': 'MI won',
    'venue': 'Wankhede Stadium, Mumbai',
    'date': '15 Mar 2024',
    'result': 'Mumbai Indians won by 43 runs',
    'playerOfMatch': 'Rohit Sharma',
    'toss': {'winner': 'MI', 'decision': 'Bat first'},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Match Details',
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Scorecard'),
            Tab(text: 'Commentary'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Match Score Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                // Match Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _matchData['status'],
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Team 1
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(_matchData['team1']['logo']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _matchData['team1']['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _matchData['team1']['shortName'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _matchData['team1']['score'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${_matchData['team1']['overs']} overs',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Team 2
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(_matchData['team2']['logo']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _matchData['team2']['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _matchData['team2']['shortName'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _matchData['team2']['score'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${_matchData['team2']['overs']} overs',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                // Match Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(Icons.location_on, _matchData['venue']),
                    _buildInfoItem(Icons.calendar_today, _matchData['date']),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _matchData['result'],
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_matchData['playerOfMatch'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Player of Match: ${_matchData['playerOfMatch']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildScorecardTab(),
                _buildCommentaryTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/live-match', arguments: widget.matchId);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Go Live'),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Match Highlights'),
          const SizedBox(height: 12),
          _buildHighlightCard('Great batting performance by top order', Icons.sports_cricket),
          _buildHighlightCard('Excellent bowling spell in death overs', Icons.sports_score),
          _buildHighlightCard('Fielding restrictions utilized well', Icons.person),
          const SizedBox(height: 24),
          _buildSectionTitle('Toss Info'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.flip, color: AppColors.primary),
                const SizedBox(width: 12),
                Text('${_matchData['toss']['winner']} won toss and chose to ${_matchData['toss']['decision']}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Batting'),
        _buildScorecardTeam('Mumbai Indians'),
        const SizedBox(height: 24),
        _buildSectionTitle('Bowling'),
        _buildScorecardTeam('Chennai Super Kings'),
      ],
    );
  }

  Widget _buildCommentaryTab() {
    final commentaries = [
      {'over': '19.5', 'text': 'OUT! Caught at long on', 'runs': 2},
      {'over': '19.4', 'text': 'Four! Straight down the ground', 'runs': 4},
      {'over': '19.3', 'text': 'Single to cover', 'runs': 1},
      {'over': '19.2', 'text': 'Six! Massive hit', 'runs': 6},
      {'over': '19.1', 'text': 'Dot ball', 'runs': 0},
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: commentaries.length,
      itemBuilder: (context, index) {
        final comment = commentaries[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  comment['over'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment['text']),
                    Text(
                      '${comment['runs']} runs',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
      },
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Player Stats'),
        const SizedBox(height: 12),
        _buildStatRow('Highest Individual Score', 'Rohit Sharma - 72'),
        _buildStatRow('Best Bowling Figures', 'Jasprit Bumrah - 4/20'),
        _buildStatRow('Most Sixes', 'Hardik Pandya - 5'),
        _buildStatRow('Most Fours', 'Ishan Kishan - 8'),
        _buildStatRow('Highest Partnership', 'Rohit & Surya - 89'),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildHighlightCard(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildScorecardTeam(String teamName) {
    final players = [
      {'name': 'Rohit Sharma', 'runs': 72, 'balls': 45, 'fours': 8, 'sixes': 3, 'status': 'out'},
      {'name': 'Ishan Kishan', 'runs': 45, 'balls': 30, 'fours': 6, 'sixes': 2, 'status': 'out'},
      {'name': 'Hardik Pandya', 'runs': 35, 'balls': 20, 'fours': 3, 'sixes': 3, 'status': 'not out'},
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              teamName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 1),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Batsman', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
                const SizedBox(width: 8),
                _buildScoreHeader('R'),
                _buildScoreHeader('B'),
                _buildScoreHeader('4s'),
                _buildScoreHeader('6s'),
                _buildScoreHeader('SR'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Players
          ...players.map((player) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        player['status'] == 'not out' ? 'Not Out' : 'c. sub b. player',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildScoreValue(player['runs'].toString()),
                _buildScoreValue(player['balls'].toString()),
                _buildScoreValue(player['fours'].toString()),
                _buildScoreValue(player['sixes'].toString()),
                _buildScoreValue(((player['runs'] / player['balls']) * 100).toStringAsFixed(1)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildScoreHeader(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildScoreValue(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

