import '../../core/theme/app_colors.dart';
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
  
  // Pagination state for each tab
  List<Tournament> _liveTournaments = [];
  List<Tournament> _upcomingTournaments = [];
  List<Tournament> _completedTournaments = [];
  
  int _livePage = 1;
  int _upcomingPage = 1;
  int _completedPage = 1;
  
  bool _liveHasMore = true;
  bool _upcomingHasMore = true;
  bool _completedHasMore = true;
  
  bool _isLiveLoadingMore = false;
  bool _isUpcomingLoadingMore = false;
  bool _isCompletedLoadingMore = false;
  
  bool _isLoading = true;
  String? _error;

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
      final liveResult = await _tournamentService.getTournaments(status: 'IN_PROGRESS', page: 1);
      final upcomingResult = await _tournamentService.getTournaments(status: 'PUBLISHED', page: 1);
      final completedResult = await _tournamentService.getTournaments(status: 'COMPLETED', page: 1);
      
      setState(() {
        _liveTournaments = liveResult.tournaments;
        _upcomingTournaments = upcomingResult.tournaments;
        _completedTournaments = completedResult.tournaments;
        
        _liveHasMore = liveResult.hasMore;
        _upcomingHasMore = upcomingResult.hasMore;
        _completedHasMore = completedResult.hasMore;
        
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Load more live tournaments
  Future<void> _loadMoreLive() async {
    if (_isLiveLoadingMore || !_liveHasMore) return;
    
    setState(() => _isLiveLoadingMore = true);
    
    try {
      _livePage++;
      final result = await _tournamentService.getTournaments(status: 'LIVE', page: _livePage);
      setState(() {
        _liveTournaments.addAll(result.tournaments);
        _liveHasMore = result.hasMore;
        _isLiveLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _livePage--;
        _isLiveLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more: $e')),
        );
      }
    }
  }

  /// Load more upcoming tournaments
  Future<void> _loadMoreUpcoming() async {
    if (_isUpcomingLoadingMore || !_upcomingHasMore) return;
    
    setState(() => _isUpcomingLoadingMore = true);
    
    try {
      _upcomingPage++;
      final result = await _tournamentService.getTournaments(status: 'UPCOMING', page: _upcomingPage);
      setState(() {
        _upcomingTournaments.addAll(result.tournaments);
        _upcomingHasMore = result.hasMore;
        _isUpcomingLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _upcomingPage--;
        _isUpcomingLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more: $e')),
        );
      }
    }
  }

  /// Load more completed tournaments
  Future<void> _loadMoreCompleted() async {
    if (_isCompletedLoadingMore || !_completedHasMore) return;
    
    setState(() => _isCompletedLoadingMore = true);
    
    try {
      _completedPage++;
      final result = await _tournamentService.getTournaments(status: 'COMPLETED', page: _completedPage);
      setState(() {
        _completedTournaments.addAll(result.tournaments);
        _completedHasMore = result.hasMore;
        _isCompletedLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _completedPage--;
        _isCompletedLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tournaments'),
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
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _TournamentList(
                  tournaments: _liveTournaments,
                  isLoadingMore: _isLiveLoadingMore,
                  hasMore: _liveHasMore,
                  loadMore: _loadMoreLive,
                ),
                _TournamentList(
                  tournaments: _upcomingTournaments,
                  isLoadingMore: _isUpcomingLoadingMore,
                  hasMore: _upcomingHasMore,
                  loadMore: _loadMoreUpcoming,
                ),
                _TournamentList(
                  tournaments: _completedTournaments,
                  isLoadingMore: _isCompletedLoadingMore,
                  hasMore: _completedHasMore,
                  loadMore: _loadMoreCompleted,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tournament_list_create',
        onPressed: () {
          Navigator.pushNamed(context, '/create-tournament');
        },
        icon: Icon(Icons.add),
        label: Text('Create Tournament'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _TournamentList extends StatefulWidget {
  final List<Tournament> tournaments;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback loadMore;

  const _TournamentList({
    required this.tournaments,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadMore,
  });

  @override
  State<_TournamentList> createState() => _TournamentListState();
}

class _TournamentListState extends State<_TournamentList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Detect when user scrolls to bottom and load more
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      widget.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tournaments.isEmpty) {
      return Center(
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

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: widget.tournaments.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.tournaments.length) {
            return widget.isLoadingMore
                ? Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }
          return _TournamentCard(tournament: widget.tournaments[index]);
        },
      ),
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
                      ? AppColors.liveGradient
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
                            child: Row(
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
                      Icon(Icons.calendar_today,
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
                      Icon(Icons.location_on,
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
                          Icon(Icons.attach_money,
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
                            Icon(Icons.emoji_events,
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




