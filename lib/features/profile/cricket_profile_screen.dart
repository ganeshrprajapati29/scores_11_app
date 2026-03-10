import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/user_service.dart';
import '../../providers/auth_provider.dart';

class CricketProfileScreen extends StatefulWidget {
  const CricketProfileScreen({super.key});

  @override
  State<CricketProfileScreen> createState() => _CricketProfileScreenState();
}

class _CricketProfileScreenState extends State<CricketProfileScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  late TabController _tabController;
  bool _isLoading = true;
  
  Map<String, dynamic>? _cricketStats;
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _highlights = [];
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Matches',
    'Tournaments',
    'Practice',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load cricket stats
      final statsResult = await _userService.getCricketStats();
      if (statsResult['success']) {
        setState(() {
          _cricketStats = jsonDecode(statsResult['data']);
        });
      }

      // Load achievements
      final achievementsResult = await _userService.getAchievements();
      if (achievementsResult['success']) {
        final data = jsonDecode(achievementsResult['data']);
        setState(() {
          _achievements = List<Map<String, dynamic>>.from(data['achievements'] ?? []);
        });
      }

      // Mock teams data (in real app, fetch from API)
      _teams = [
        {'name': 'Delhi Strikers', 'role': 'Captain', 'logo': '🏏'},
        {'name': 'Mumbai Kings', 'role': 'Player', 'logo': '👑'},
      ];

      // Mock matches data
      _matches = [
        {
          'id': '1',
          'opponent': 'Chennai Super',
          'date': '2024-01-15',
          'result': 'Won',
          'score': '145/2',
          'venue': 'Delhi',
        },
        {
          'id': '2',
          'opponent': 'Kolkata Knight',
          'date': '2024-01-10',
          'result': 'Lost',
          'score': '98/10',
          'venue': 'Kolkata',
        },
        {
          'id': '3',
          'opponent': 'Bangalore Royal',
          'date': '2024-01-05',
          'result': 'Won',
          'score': '167/5',
          'venue': 'Bangalore',
        },
      ];

      // Mock highlights
      _highlights = [
        {
          'id': '1',
          'type': 'century',
          'title': 'First Century!',
          'description': 'Scored 102 runs against Chennai Super',
          'date': '2024-01-15',
          'image': null,
        },
        {
          'id': '2',
          'type': 'five_wickets',
          'title': '5 Wicket Haul',
          'description': 'Best bowling figures: 5/18',
          'date': '2024-01-10',
          'image': null,
        },
      ];
    } catch (e) {
      debugPrint('Error loading cricket profile: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricket Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              Navigator.pushNamed(context, '/qr-code');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Matches'),
            Tab(text: 'Stats'),
            Tab(text: 'Teams'),
            Tab(text: 'Achievements'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primary.withOpacity(0.1),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary,
                        child: user?.avatar?.url != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.avatar!.url!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Player',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.cricketProfile?['playerType'] ?? 'All Rounder',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _StatChip(
                                  label: 'Matches',
                                  value: _cricketStats?['matchesPlayed']?.toString() ?? '0',
                                ),
                                const SizedBox(width: 8),
                                _StatChip(
                                  label: 'Runs',
                                  value: _cricketStats?['totalRuns']?.toString() ?? '0',
                                ),
                                const SizedBox(width: 8),
                                _StatChip(
                                  label: 'Wickets',
                                  value: _cricketStats?['totalWickets']?.toString() ?? '0',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Filter chips
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                          },
                        ),
                      );
                    },
                  ),
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildMatchesTab(),
                      _buildStatsTab(),
                      _buildTeamsTab(),
                      _buildAchievementsTab(),
                      _buildInsightsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Summary
          const Text(
            'Performance Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PerformanceCard(
                  title: 'Batting',
                  stats: [
                    {'label': 'Avg', 'value': _cricketStats?['battingAverage']?.toString() ?? '0.0'},
                    {'label': 'SR', 'value': _cricketStats?['strikeRate']?.toString() ?? '0.0'},
                    {'label': 'HS', 'value': _cricketStats?['highestScore']?.toString() ?? '0'},
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PerformanceCard(
                  title: 'Bowling',
                  stats: [
                    {'label': 'Avg', 'value': _cricketStats?['bowlingAverage']?.toString() ?? '0.0'},
                    {'label': 'Eco', 'value': _cricketStats?['economy']?.toString() ?? '0.0'},
                    {'label': 'BB', 'value': _cricketStats?['bestBowling']?.toString() ?? '0/0'},
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Matches
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Matches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._matches.take(3).map((match) => _MatchCard(match: match)),
          
          const SizedBox(height: 24),
          
          // Trophies
          const Text(
            'Trophies & Awards',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                final achievement = _achievements[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        achievement['name'] ?? 'Achievement',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        return _MatchCard(match: _matches[index]);
      },
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batting Stats
          const Text(
            'Batting Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _StatsTable(
            stats: [
              {'label': 'Matches', 'value': _cricketStats?['matchesPlayed']?.toString() ?? '0'},
              {'label': 'Innings', 'value': _cricketStats?['innings']?.toString() ?? '0'},
              {'label': 'Runs', 'value': _cricketStats?['totalRuns']?.toString() ?? '0'},
              {'label': 'Average', 'value': _cricketStats?['battingAverage']?.toString() ?? '0.0'},
              {'label': 'Strike Rate', 'value': _cricketStats?['strikeRate']?.toString() ?? '0.0'},
              {'label': 'Highest Score', 'value': _cricketStats?['highestScore']?.toString() ?? '0'},
              {'label': 'Centuries', 'value': _cricketStats?['centuries']?.toString() ?? '0'},
              {'label': 'Half Centuries', 'value': _cricketStats?['halfCenturies']?.toString() ?? '0'},
              {'label': 'Fours', 'value': _cricketStats?['fours']?.toString() ?? '0'},
              {'label': 'Sixes', 'value': _cricketStats?['sixes']?.toString() ?? '0'},
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Bowling Stats
          const Text(
            'Bowling Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _StatsTable(
            stats: [
              {'label': 'Wickets', 'value': _cricketStats?['totalWickets']?.toString() ?? '0'},
              {'label': 'Best Figures', 'value': _cricketStats?['bestBowling']?.toString() ?? '0/0'},
              {'label': 'Economy', 'value': _cricketStats?['economy']?.toString() ?? '0.0'},
              {'label': 'Bowling Avg', 'value': _cricketStats?['bowlingAverage']?.toString() ?? '0.0'},
              {'label': '5 Wicket Hauls', 'value': _cricketStats?['fiveWicketHauls']?.toString() ?? '0'},
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                team['logo'] ?? '🏏',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            title: Text(
              team['name'] ?? 'Team',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(team['role'] ?? 'Player'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to team detail
            },
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _achievements.length + 5, // Adding some mock achievements
      itemBuilder: (context, index) {
        if (index < _achievements.length) {
          final achievement = _achievements[index];
          return _AchievementCard(
            icon: Icons.emoji_events,
            color: Colors.amber,
            title: achievement['name'] ?? 'Achievement',
            description: achievement['description'] ?? '',
          );
        }
        
        // Mock achievements for demo
        final List<Map<String, dynamic>> mockAchievements = [
          {'icon': Icons.star, 'color': Colors.blue, 'title': 'First Match'},
          {'icon': Icons.local_fire_department, 'color': Colors.red, 'title': 'Hot Streak'},
          {'icon': Icons.military_tech, 'color': Colors.purple, 'title': 'Champion'},
          {'icon': Icons.bolt, 'color': Colors.orange, 'title': 'Quick 50'},
          {'icon': Icons.shield, 'color': Colors.green, 'title': 'Best Defense'},
        ];
        final mock = mockAchievements[index - _achievements.length];
        return _AchievementCard(
          icon: mock['icon'] as IconData,
          color: mock['color'] as Color,
          title: mock['title'] as String,
          description: '',
        );
      },
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Chart Placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Performance Trend',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Insights
          const Text(
            'Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _InsightCard(
            title: 'Best Performance',
            description: 'Your best performance was on Sunday matches',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
          _InsightCard(
            title: 'Consistency',
            description: 'You maintain a 75% win rate in tournaments',
            icon: Icons.analytics,
            color: Colors.blue,
          ),
          _InsightCard(
            title: 'Most Runs',
            description: 'You score most of your runs in overs 10-20',
            icon: Icons.timer,
            color: Colors.orange,
          ),
          
          const SizedBox(height: 24),
          
          // Reports Section
          const Text(
            'Reports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Download Performance Report'),
              subtitle: const Text('Get detailed PDF report'),
              trailing: const Icon(Icons.download),
              onTap: () {
                // Download report
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.share, color: AppColors.primary),
              title: const Text('Share Profile'),
              subtitle: const Text('Share your cricket profile'),
              trailing: const Icon(Icons.share),
              onTap: () {
                // Share profile
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final String title;
  final List<Map<String, String>> stats;

  const _PerformanceCard({required this.title, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...stats.map((stat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stat['label'] ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    stat['value'] ?? '0',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isWin = match['result'] == 'Won';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'vs ${match['opponent']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isWin ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    match['result'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  match['date'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  match['venue'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${match['score']}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsTable extends StatelessWidget {
  final List<Map<String, String>> stats;

  const _StatsTable({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: stats.map((stat) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stat['label'] ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  stat['value'] ?? '0',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _AchievementCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _InsightCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
      ),
    );
  }
}
