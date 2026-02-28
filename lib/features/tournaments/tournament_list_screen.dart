import 'package:flutter/material.dart';
import '../../core/config/theme_config.dart';
import '../../data/models/tournament_model.dart';
import '../../data/services/tournament_service.dart';
import 'tournament_detail_screen.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TournamentService _tournamentService = TournamentService();
  List<Tournament> _liveTournaments = [];
  List<Tournament> _upcomingTournaments = [];
  List<Tournament> _completedTournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTournaments() async {
    setState(() => _isLoading = true);
    try {
      final live = await _tournamentService.getLiveTournaments();
      final upcoming = await _tournamentService.getUpcomingTournaments();
      setState(() {
        _liveTournaments = live;
        _upcomingTournaments = upcoming;
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
        title: const Text('Tournaments'),
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
                _TournamentList(tournaments: _liveTournaments),
                _TournamentList(tournaments: _upcomingTournaments),
                _TournamentList(tournaments: _completedTournaments),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-tournament');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Tournament'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _TournamentList extends StatelessWidget {
  final List<Tournament> tournaments;

  const _TournamentList({required this.tournaments});

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text(
              'No tournaments found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        return _TournamentCard(tournament: tournaments[index]);
      },
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final isLive = tournament.status == 'LIVE';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentDetailScreen(
                tournamentId: tournament.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLive
                      ? [AppColors.live, AppColors.primary]
                      : [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.emoji_events,
                      size: 100,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle,
                                    color: AppColors.live, size: 8),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: AppColors.live,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          tournament.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.sports_cricket,
                        label: tournament.format,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.groups,
                        label: '${tournament.totalTeams} Teams',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        tournament.startDate != null
                            ? '${tournament.startDate!.day}/${tournament.startDate!.month}/${tournament.startDate!.year}'
                            : 'Date not set',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tournament.venue ?? 'Venue not set',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (tournament.isPaid) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_money,
                              size: 14, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            'Entry: \$${tournament.entryFee?.toStringAsFixed(0) ?? "0"}',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (tournament.prizeMoney != null) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.emoji_events,
                                size: 14, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'Prize: \$${tournament.prizeMoney?.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
