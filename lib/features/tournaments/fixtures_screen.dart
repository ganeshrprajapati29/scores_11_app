import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_appbar.dart';

class FixturesScreen extends StatelessWidget {
  final String tournamentId;
  
  const FixturesScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Fixtures',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Tournament Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.emoji_events, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IPL 2024',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '14 Matches • League Stage',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            
            // Tab Bar
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'All'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Upcoming'),
                ],
              ),
            ),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildMatchList('all'),
                  _buildMatchList('completed'),
                  _buildMatchList('upcoming'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchList(String filter) {
    final List<Map<String, dynamic>> matches = [
      {
        'id': '1',
        'team1': {'name': 'Mumbai Indians', 'short': 'MI', 'logo': 'https://picsum.photos/40/40', 'score': '185/4'},
        'team2': {'name': 'Chennai Super Kings', 'short': 'CSK', 'logo': 'https://picsum.photos/40/40', 'score': '142/3'},
        'date': '15 Mar 2024',
        'time': '19:30',
        'venue': 'Wankhede Stadium',
        'status': 'Completed',
        'result': 'MI won by 43 runs',
      },
      {
        'id': '2',
        'team1': {'name': 'Delhi Capitals', 'short': 'DC', 'logo': 'https://picsum.photos/40/40', 'score': null},
        'team2': {'name': 'Kolkata Knight Riders', 'short': 'KKR', 'logo': 'https://picsum.photos/40/40', 'score': null},
        'date': '16 Mar 2024',
        'time': '14:00',
        'venue': 'Arun Jaitley Stadium',
        'status': 'Upcoming',
        'result': null,
      },
      {
        'id': '3',
        'team1': {'name': 'Royal Challengers Bangalore', 'short': 'RCB', 'logo': 'https://picsum.photos/40/40', 'score': '178/6'},
        'team2': {'name': 'Punjab Kings', 'short': 'PBKS', 'logo': 'https://picsum.photos/40/40', 'score': '176/7'},
        'date': '16 Mar 2024',
        'time': '19:30',
        'venue': 'M. Chinnaswamy Stadium',
        'status': 'Completed',
        'result': 'RCB won by 2 wickets',
      },
      {
        'id': '4',
        'team1': {'name': 'Sunrisers Hyderabad', 'short': 'SRH', 'logo': 'https://picsum.photos/40/40', 'score': null},
        'team2': {'name': 'Rajasthan Royals', 'short': 'RR', 'logo': 'https://picsum.photos/40/40', 'score': null},
        'date': '17 Mar 2024',
        'time': '14:00',
        'venue': 'Rajiv Gandhi Stadium',
        'status': 'Upcoming',
        'result': null,
      },
      {
        'id': '5',
        'team1': {'name': 'Lucknow Super Giants', 'short': 'LSG', 'logo': 'https://picsum.photos/40/40', 'score': '160/8'},
        'team2': {'name': 'Gujarat Titans', 'short': 'GT', 'logo': 'https://picsum.photos/40/40', 'score': '161/4'},
        'date': '17 Mar 2024',
        'time': '19:30',
        'venue': 'Bharat Ratna Stadium',
        'status': 'Completed',
        'result': 'GT won by 6 wickets',
      },
    ];

    final filteredMatches = matches.where((m) {
      if (filter == 'all') return true;
      if (filter == 'completed') return m['status'] == 'Completed';
      if (filter == 'upcoming') return m['status'] == 'Upcoming';
      return true;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMatches.length,
      itemBuilder: (context, index) {
        final match = filteredMatches[index];
        final isCompleted = match['status'] == 'Completed';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/match-detail', arguments: match['id']);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${match['date']} • ${match['time']}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted ? AppColors.success.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            match['status'],
                            style: TextStyle(
                              color: isCompleted ? AppColors.success : AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Teams
                    Row(
                      children: [
                        Expanded(
                          child: _buildTeamColumn(
                            match['team1']['short'],
                            match['team1']['name'],
                            match['team1']['logo'],
                            match['team1']['score'],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            isCompleted ? 'VS' : 'VS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildTeamColumn(
                            match['team2']['short'],
                            match['team2']['name'],
                            match['team2']['logo'],
                            match['team2']['score'],
                            isRight: true,
                          ),
                        ),
                      ],
                    ),
                    
                    // Result
                    if (isCompleted && match['result'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          match['result'],
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    
                    // Venue
                    if (!isCompleted) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            match['venue'],
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
      },
    );
  }

  Widget _buildTeamColumn(String short, String name, String logo, String? score, {bool isRight = false}) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isRight) ...[
              CircleAvatar(radius: 15, backgroundImage: NetworkImage(logo)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (score != null)
                    Text(
                      score,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),
            if (isRight) ...[
              const SizedBox(width: 8),
              CircleAvatar(radius: 15, backgroundImage: NetworkImage(logo)),
            ],
          ],
        ),
      ],
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Matches',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('By Date'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.stadium),
              title: const Text('By Venue'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('By Team'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

