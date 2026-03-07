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
  
  // Pagination state for each tab
  int _livePage = 1;
  int _upcomingPage = 1;
  int _completedPage = 1;
  
  bool _hasMoreLive = true;
  bool _hasMoreUpcoming = true;
  bool _hasMoreCompleted = true;
  
  bool _isLoading = true;
  bool _isLoadingMoreLive = false;
  bool _isLoadingMoreUpcoming = false;
  bool _isLoadingMoreCompleted = false;
  
  List<Match> _liveMatches = [];
  List<Match> _upcomingMatches = [];
  List<Match> _completedMatches = [];

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

  /// Pagination Algorithm:
  /// int page = 1;
  /// loadMore(){
  ///   page++;
  ///   fetchMatches(page);
  /// }
  
  Future<void> _loadMatches({bool refresh = false}) async {
    if (refresh) {
      _livePage = 1;
      _upcomingPage = 1;
      _completedPage = 1;
      _hasMoreLive = true;
      _hasMoreUpcoming = true;
      _hasMoreCompleted = true;
    }
    
    setState(() => _isLoading = true);
    try {
      // Load first page (20 matches per page)
      final liveResult = await _matchService.getMatches(page: 1, status: 'LIVE');
      final upcomingResult = await _matchService.getMatches(page: 1, status: 'SCHEDULED');
      final completedResult = await _matchService.getMatches(page: 1, status: 'COMPLETED');
      
      setState(() {
        _liveMatches = liveResult.matches;
        _upcomingMatches = upcomingResult.matches;
        _completedMatches = completedResult.matches;
        
        _hasMoreLive = liveResult.hasMore;
        _hasMoreUpcoming = upcomingResult.hasMore;
        _hasMoreCompleted = completedResult.hasMore;
        
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

  /// Load more matches for Live tab
  Future<void> _loadMoreLive() async {
    if (_isLoadingMoreLive || !_hasMoreLive) return;
    
    setState(() {
      _isLoadingMoreLive = true;
      _livePage++; // Increment page
    });
    
    try {
      final result = await _matchService.getMatches(page: _livePage, status: 'LIVE');
      setState(() {
        _liveMatches.addAll(result.matches);
        _hasMoreLive = result.hasMore;
        _isLoadingMoreLive = false;
      });
    } catch (e) {
      setState(() {
        _livePage--; // Revert page on error
        _isLoadingMoreLive = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more: $e')),
        );
      }
    }
  }

  /// Load more matches for Upcoming tab
  Future<void> _loadMoreUpcoming() async {
    if (_isLoadingMoreUpcoming || !_hasMoreUpcoming) return;
    
    setState(() {
      _isLoadingMoreUpcoming = true;
      _upcomingPage++; // Increment page
    });
    
    try {
      final result = await _matchService.getMatches(page: _upcomingPage, status: 'SCHEDULED');
      setState(() {
        _upcomingMatches.addAll(result.matches);
        _hasMoreUpcoming = result.hasMore;
        _isLoadingMoreUpcoming = false;
      });
    } catch (e) {
      setState(() {
        _upcomingPage--;
        _isLoadingMoreUpcoming = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more: $e')),
        );
      }
    }
  }

  /// Load more matches for Completed tab
  Future<void> _loadMoreCompleted() async {
    if (_isLoadingMoreCompleted || !_hasMoreCompleted) return;
    
    setState(() {
      _isLoadingMoreCompleted = true;
      _completedPage++; // Increment page
    });
    
    try {
      final result = await _matchService.getMatches(page: _completedPage, status: 'COMPLETED');
      setState(() {
        _completedMatches.addAll(result.matches);
        _hasMoreCompleted = result.hasMore;
        _isLoadingMoreCompleted = false;
      });
    } catch (e) {
      setState(() {
        _completedPage--;
        _isLoadingMoreCompleted = false;
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
                _MatchList(
                  matches: _liveMatches, 
                  type: 'live',
                  isLoadingMore: _isLoadingMoreLive,
                  hasMore: _hasMoreLive,
                  loadMore: _loadMoreLive,
                ),
                _MatchList(
                  matches: _upcomingMatches, 
                  type: 'upcoming',
                  isLoadingMore: _isLoadingMoreUpcoming,
                  hasMore: _hasMoreUpcoming,
                  loadMore: _loadMoreUpcoming,
                ),
                _MatchList(
                  matches: _completedMatches, 
                  type: 'completed',
                  isLoadingMore: _isLoadingMoreCompleted,
                  hasMore: _hasMoreCompleted,
                  loadMore: _loadMoreCompleted,
                ),
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

class _MatchList extends StatefulWidget {
  final List<Match> matches;
  final String type;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback loadMore;

  const _MatchList({
    required this.matches,
    required this.type,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadMore,
  });

  @override
  State<_MatchList> createState() => _MatchListState();
}

class _MatchListState extends State<_MatchList> {
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
      // User is near bottom, load more matches
      widget.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matches.isEmpty) {
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
              'No ${widget.type} matches',
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
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: widget.matches.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at bottom when loading more
          if (index == widget.matches.length) {
            return widget.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }
          return _MatchCard(match: widget.matches[index]);
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
