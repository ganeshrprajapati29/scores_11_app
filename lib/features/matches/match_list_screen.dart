import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart' as MatchDateUtils;
import '../../../core/widgets/match_status_badge.dart';
import '../../data/models/match_model.dart';
import '../../data/services/match_service.dart';
import 'package:shimmer/shimmer.dart';

class MatchListScreen extends StatefulWidget {
  const MatchListScreen({super.key});

  @override
  State<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MatchService _matchService = MatchService();
  bool _returnFromCreate = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_returnFromCreate) {
      _returnFromCreate = false;
      _loadMatches(refresh: true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Sort matches based on type
  /// - LIVE: Newest (most recent start) first
  /// - UPCOMING: Soonest (closest to current date) first
  /// - COMPLETED: Newest first
  List<Match> _sortMatches(List<Match> matches, String type) {
    final sorted = List<Match>.from(matches);
    sorted.sort((a, b) {
      final dateA = a.scheduledDate;
      final dateB = b.scheduledDate;
      
      switch (type) {
        case 'live':
          // Live: newest (most recent start) first
          return dateB.compareTo(dateA);
        case 'upcoming':
          // Upcoming: soonest (closest to now) first
          return dateA.compareTo(dateB);
        case 'completed':
          // Completed: newest first
          return dateB.compareTo(dateA);
        default:
          return dateB.compareTo(dateA);
      }
    });
    return sorted;
  }

  /// Filter completed matches to show only those completed within last 30 days
  List<Match> _filterOldCompletedMatches(List<Match> matches) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return matches.where((match) {
      return match.scheduledDate.isAfter(thirtyDaysAgo);
    }).toList();
  }

  Future<void> _loadMatches({bool refresh = false}) async {
    if (refresh) {
      _livePage = 1;
      _upcomingPage = 1;
      _completedPage = 1;
      _hasMoreLive = true;
      _hasMoreUpcoming = true;
      _hasMoreCompleted = true;
      _liveMatches.clear();
      _upcomingMatches.clear();
      _completedMatches.clear();
    }

    setState(() => _isLoading = true);
    
    try {
      // Fetch all matches in parallel for better performance
      final results = await Future.wait([
        _matchService.getLiveMatches(forceRefresh: refresh),
        _matchService.getUpcomingMatches(),
        _matchService.getCompletedMatches(),
      ]);

      final liveMatches = results[0];
      final upcomingMatches = results[1];
      final completedMatches = results[2];

      setState(() {
        // Sort matches appropriately for each tab
        _liveMatches = _sortMatches(liveMatches, 'live');
        _upcomingMatches = _sortMatches(upcomingMatches, 'upcoming');
        
        // Filter and sort completed matches
        final filteredCompleted = _filterOldCompletedMatches(completedMatches);
        _completedMatches = _sortMatches(filteredCompleted, 'completed');

        // Update pagination flags
        _hasMoreLive = _liveMatches.length >= 20;
        _hasMoreUpcoming = _upcomingMatches.length >= 20;
        _hasMoreCompleted = _completedMatches.length >= 20;

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading matches: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreLive() async {
    if (_isLoadingMoreLive || !_hasMoreLive) return;
    
    setState(() {
      _isLoadingMoreLive = true;
      _livePage++;
    });
    
    try {
      final result = await _matchService.getMatches(page: _livePage, status: 'LIVE');
      setState(() {
        final newMatches = _sortMatches(result.matches, 'live');
        _liveMatches.addAll(newMatches);
        _hasMoreLive = result.hasMore;
        _isLoadingMoreLive = false;
      });
    } catch (e) {
      setState(() {
        _livePage--;
        _isLoadingMoreLive = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreUpcoming() async {
    if (_isLoadingMoreUpcoming || !_hasMoreUpcoming) return;
    
    setState(() {
      _isLoadingMoreUpcoming = true;
      _upcomingPage++;
    });
    
    try {
      final result = await _matchService.getMatches(page: _upcomingPage, status: 'SCHEDULED');
      setState(() {
        final newMatches = _sortMatches(result.matches, 'upcoming');
        _upcomingMatches.addAll(newMatches);
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

  Future<void> _loadMoreCompleted() async {
    if (_isLoadingMoreCompleted || !_hasMoreCompleted) return;
    
    setState(() {
      _isLoadingMoreCompleted = true;
      _completedPage++;
    });
    
    try {
      final result = await _matchService.getMatches(page: _completedPage, status: 'COMPLETED');
      setState(() {
        final filteredMatches = _filterOldCompletedMatches(result.matches);
        final newMatches = _sortMatches(filteredMatches, 'completed');
        _completedMatches.addAll(newMatches);
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildShimmerLoading()
          : TabBarView(
              controller: _tabController,
              children: [
                _MatchList(
                  matches: _liveMatches,
                  type: 'live',
                  isLoadingMore: _isLoadingMoreLive,
                  hasMore: _hasMoreLive,
                  loadMore: _loadMoreLive,
                  onRefresh: () => _loadMatches(refresh: true),
                ),
                _MatchList(
                  matches: _upcomingMatches,
                  type: 'upcoming',
                  isLoadingMore: _isLoadingMoreUpcoming,
                  hasMore: _hasMoreUpcoming,
                  loadMore: _loadMoreUpcoming,
                  onRefresh: () => _loadMatches(refresh: true),
                ),
                _MatchList(
                  matches: _completedMatches,
                  type: 'completed',
                  isLoadingMore: _isLoadingMoreCompleted,
                  hasMore: _hasMoreCompleted,
                  loadMore: _loadMoreCompleted,
                  onRefresh: () => _loadMatches(refresh: true),
                ),
              ],
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.sports_cricket_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Matches',
            style: TextStyle(
              color: Color(0xFF0D1117),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEEEFF2), width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: const Color(0xFF8B92A5),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2.5,
              ),
              insets: const EdgeInsets.symmetric(horizontal: 16),
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53E3E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Live'),
                  ],
                ),
              ),
              const Tab(text: 'Upcoming'),
              const Tab(text: 'Completed'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEFF2),
      highlightColor: const Color(0xFFF8F9FA),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      heroTag: 'match_list_create',
      onPressed: () {
        setState(() => _returnFromCreate = true);
        Navigator.pushReplacementNamed(context, '/create-match');
      },
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text(
        'Create Match',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

// ---------------------------------------------------------------------------
// _MatchList
// ---------------------------------------------------------------------------

class _MatchList extends StatefulWidget {
  final List<Match> matches;
  final String type;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback loadMore;
  final Future<void> Function()? onRefresh;

  const _MatchList({
    required this.matches,
    required this.type,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadMore,
    this.onRefresh,
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matches.isEmpty) {
      return _EmptyState(type: widget.type);
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      color: AppColors.primary,
      strokeWidth: 2.5,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: widget.matches.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.matches.length) {
            return widget.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          return _MatchCard(match: widget.matches[index])
              .animate()
              .fadeIn(duration: 280.ms, delay: (index * 40).ms)
              .slideY(begin: 0.06, end: 0, duration: 280.ms, delay: (index * 40).ms);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyState
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final String type;
  const _EmptyState({required this.type});

  String _getMessage() {
    switch (type) {
      case 'live':
        return 'No live matches at the moment';
      case 'upcoming':
        return 'No upcoming matches scheduled';
      case 'completed':
        return 'No completed matches';
      default:
        return 'No matches found';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.sports_cricket_rounded,
              size: 38,
              color: const Color(0xFFB0B8CC),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _getMessage(),
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back later for updates',
            style: TextStyle(
              color: const Color(0xFF9CA3AF),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MatchCard
// ---------------------------------------------------------------------------

class _MatchCard extends StatelessWidget {
  final Match match;

  const _MatchCard({required this.match});

  void _handleMatchTap(BuildContext context) {
    final status = match.status;
    
    if (status == 'LIVE') {
      Navigator.pushNamed(context, '/live-control', arguments: match.id);
    } else if (status == 'SCHEDULED') {
      Navigator.pushNamed(context, '/team-select', arguments: match.id);
    } else if (status == 'TOSS') {
      Navigator.pushNamed(context, '/toss', arguments: match.id);
    } else if (status == 'COMPLETED') {
      Navigator.pushNamed(context, '/scorecard', arguments: match.id);
    } else {
      Navigator.pushNamed(context, '/match-detail', arguments: match.id);
    }
  }

  /// Format date for display
  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDate = DateTime(date.year, date.month, date.day);
    
    if (matchDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (matchDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else if (matchDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == 'LIVE';
    final isCompleted = match.status == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? const Color(0xFFFFE0E0)
              : const Color(0xFFEEEFF2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _handleMatchTap(context),
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withOpacity(0.04),
          highlightColor: AppColors.primary.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: badge + format + venue
                Row(
                  children: [
                    MatchStatusBadge(status: match.status),
                    if (match.matchNumber != null) ...[
                      const SizedBox(width: 8),
                      _MatchNumberChip(matchNumber: match.matchNumber!),
                    ],
                    const Spacer(),
                    if (match.tournament != null && match.tournament!.isNotEmpty) ...[
                      _TournamentBadge(tournament: match.tournament),
                      const SizedBox(width: 8),
                    ],
                    _MatchTypeChip(matchType: match.matchType),
                    const SizedBox(width: 8),
                    _FormatChip(format: match.format),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _VenueLabel(venue: match.venue?.name),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Teams row
                _TeamsRow(match: match, isLive: isLive, isCompleted: isCompleted),
                const SizedBox(height: 14),
                // Footer with date/time
                _MatchFooter(
                  match: match, 
                  isLive: isLive,
                  formatDate: _formatMatchDate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _FormatChip extends StatelessWidget {
  final String format;
  const _FormatChip({required this.format});

  @override
  Widget build(BuildContext context) {
    String displayFormat = format.toUpperCase();
    if (displayFormat == 'T20') displayFormat = 'T20';
    else if (displayFormat == 'ODI') displayFormat = 'ODI';
    else if (displayFormat == 'TEST') displayFormat = 'TEST';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        displayFormat,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _VenueLabel extends StatelessWidget {
  final String? venue;
  const _VenueLabel({this.venue});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on_outlined,
            size: 12, color: Color(0xFFB0B8CC)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            venue ?? 'TBD',
            style: const TextStyle(
              color: Color(0xFF8B92A5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MatchNumberChip extends StatelessWidget {
  final int matchNumber;
  const _MatchNumberChip({required this.matchNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'M$matchNumber',
        style: const TextStyle(
          color: Color(0xFF6366F1),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TournamentBadge extends StatelessWidget {
  final String? tournament;
  const _TournamentBadge({this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events,
              size: 10, color: Color(0xFF10B981)),
          const SizedBox(width: 3),
          Text(
            (tournament?.length ?? 0) > 8 
                ? '${tournament?.substring(0, 8)}...' 
                : tournament ?? 'Tournament',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchTypeChip extends StatelessWidget {
  final String matchType;
  const _MatchTypeChip({required this.matchType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        matchType.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFF59E0B),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  final String name;
  final Color bgColor;
  final Color textColor;

  const _TeamAvatar({
    required this.name,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'T',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _TeamsRow extends StatelessWidget {
  final Match match;
  final bool isLive;
  final bool isCompleted;

  const _TeamsRow({
    required this.match,
    required this.isLive,
    required this.isCompleted,
  });

  String _truncate(String name) =>
      name.length > 15 ? '${name.substring(0, 12)}...' : name;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Team 1
          Expanded(
            child: Row(
              children: [
                _TeamAvatar(
                  name: match.team1,
                  bgColor: AppColors.primary.withOpacity(0.12),
                  textColor: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _truncate(match.team1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0D1117),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isLive || isCompleted) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${match.score.team1.runs}/${match.score.team1.wickets}',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isLive
                                ? AppColors.primary
                                : const Color(0xFF0D1117),
                            letterSpacing: -0.5,
                          ),
                        ),
                        if ((match.score.team1.overs ?? '').isNotEmpty)
                          Text(
                            '(${match.score.team1.overs} ov)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8B92A5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // VS divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: Color(0xFF8B92A5),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Team 2
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _truncate(match.team2),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0D1117),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                      if (isLive || isCompleted) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${match.score.team2.runs}/${match.score.team2.wickets}',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D1117),
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.end,
                        ),
                        if ((match.score.team2.overs ?? '').isNotEmpty)
                          Text(
                            '(${match.score.team2.overs} ov)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8B92A5),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.end,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _TeamAvatar(
                  name: match.team2,
                  bgColor: const Color(0xFF3B82F6).withOpacity(0.12),
                  textColor: const Color(0xFF3B82F6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchFooter extends StatelessWidget {
  final Match match;
  final bool isLive;
  final String Function(DateTime) formatDate;

  const _MatchFooter({
    required this.match,
    required this.isLive,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = match.status == 'COMPLETED';
    
    String getFooterText() {
      if (isLive) {
        final overs = match.score.team1.overs;
        return 'Live • ${overs.isNotEmpty ? overs : '0.0'} overs • ${formatDate(match.scheduledDate)}';
      } else if (isCompleted) {
        // Fix: Access winner from match.result
        final winner = match.result?.winner ?? 'Match completed';
        final margin = match.result?.margin ?? '';
        if (margin.isNotEmpty) {
          return '🏆 $winner won by $margin • ${formatDate(match.scheduledDate)}';
        }
        return '🏆 $winner • ${formatDate(match.scheduledDate)}';
      } else {
        return '📅 ${formatDate(match.scheduledDate)}';
      }
    }
    
    Color getFooterColor() {
      if (isLive) return const Color(0xFFE53E3E);
      if (isCompleted) return const Color(0xFF10B981);
      return const Color(0xFF6B7280);
    }
    
    IconData getFooterIcon() {
      if (isLive) return Icons.radio_button_on_rounded;
      if (isCompleted) return Icons.emoji_events_rounded;
      return Icons.access_time_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isLive
            ? const Color(0xFFFFF5F5)
            : isCompleted
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            getFooterIcon(),
            size: 14,
            color: getFooterColor(),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              getFooterText(),
              style: TextStyle(
                color: getFooterColor(),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: const Color(0xFFB0B8CC),
          ),
        ],
      ),
    );
  }
}