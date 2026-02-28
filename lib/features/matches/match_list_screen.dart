import 'package:flutter/material.dart';
import '../../core/config/theme_config.dart';
import '../../data/models/match_model.dart';
import '../../data/services/match_service.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MatchService _matchService = MatchService();
  List<Match> _liveMatches = [];
  List<Match> _upcomingMatches = [];
  List<Match> _completedMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final live = await _matchService.getLiveMatches();
      final upcoming = await _matchService.getUpcomingMatches();
      final completed = await _matchService.getCompletedMatches();
      setState(() {
        _liveMatches = live;
        _upcomingMatches = upcoming;
        _completedMatches = completed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Live'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _MatchList(matches: _liveMatches, type: 'live'),
                _MatchList(matches: _upcomingMatches, type: 'upcoming'),
                _MatchList(matches: _completedMatches, type: 'completed'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-match');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Match'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  final List<Match> matches;
  final String type;

  const _MatchList({required this.matches, required this.type});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_cricket,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type} matches',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return _MatchCard(match: matches[index]);
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == 'LIVE';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/match-detail', arguments: match.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Row(
                children: [
                  if (isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.live,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.format,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    match.venue?.name ?? 'Stadium',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Teams and Score
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team 1',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (isLive)
                          Text(
                            '${match.score.team1.runs}/${match.score.team1.wickets}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Team 2',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (isLive)
                          Text(
                            '${match.score.team2.runs}/${match.score.team2.wickets}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Match Info
              if (isLive)
                Text(
                  'Overs: ${match.score.team1.overs}',
                  style: const TextStyle(color: AppColors.textSecondary),
                )
              else
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${match.scheduledDate.day}/${match.scheduledDate.month}/${match.scheduledDate.year}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (match.startTime != null) ...[
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match.startTime!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
