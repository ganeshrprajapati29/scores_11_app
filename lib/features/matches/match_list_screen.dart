import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../../core/widgets/match_status_badge.dart';
import '../../data/models/match_model.dart';
import '../../data/services/match_service.dart';
import 'package:shimmer/shimmer.dart';
import 'create_match_screen.dart';

class MatchListScreen extends StatefulWidget {
  final int initialTabIndex;
  final Match? initialMatch;

  const MatchListScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialMatch,
  });

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

  DateTime? _selectedDate;

  static const List<String> _liveStatuses = [
    'live',
    'in_progress',
    'paused',
    'innings_break',
    'duckworth_lewis',
  ];
  static const List<String> _upcomingStatuses = [
    'scheduled',
    'upcoming',
    'ready',
    'team_selecting',
    'toss_pending',
  ];
  static const List<String> _completedStatuses = [
    'completed',
    'finished',
    'tie',
    'tied',
    'draw',
    'washed_out',
    'abandoned',
    'cancelled',
    'no_result',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _loadMatches();
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

  PaginatedMatches _emptyPage(int page) => PaginatedMatches(
        matches: const [],
        page: page,
        limit: 20,
        total: 0,
        totalPages: page,
        hasMore: false,
      );

  List<Match> _dedupeMatches(Iterable<Match> matches) {
    final seen = <String>{};
    final unique = <Match>[];
    for (final match in matches) {
      final key = match.id.isNotEmpty
          ? match.id
          : '${match.team1Id}-${match.team2Id}-${match.scheduledDate.toIso8601String()}';
      if (seen.add(key)) unique.add(match);
    }
    return unique;
  }

  Future<List<PaginatedMatches>> _fetchStatusGroup({
    required List<String> statuses,
    required int page,
    required bool publicFeed,
    bool forceRefresh = false,
  }) {
    return Future.wait(
      statuses.map((status) async {
        try {
          return publicFeed
              ? await _matchService.getMatches(
                  page: page,
                  status: status,
                  forceRefresh: forceRefresh,
                )
              : await _matchService.getMyMatches(page: page, status: status);
        } catch (_) {
          return _emptyPage(page);
        }
      }),
    );
  }

  bool _hasMoreInGroup(List<PaginatedMatches> pages) {
    return pages.any((page) => page.hasMore);
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
      final groupedResults = await Future.wait([
        _fetchStatusGroup(
          statuses: _liveStatuses,
          page: 1,
          publicFeed: true,
          forceRefresh: refresh,
        ),
        _fetchStatusGroup(
          statuses: _upcomingStatuses,
          page: 1,
          publicFeed: false,
        ),
        _fetchStatusGroup(
          statuses: _completedStatuses,
          page: 1,
          publicFeed: false,
        ),
      ]);

      final livePages = groupedResults[0];
      final upcomingPages = groupedResults[1];
      final completedPages = groupedResults[2];
      final liveMatches = _dedupeMatches(
        livePages.expand((page) => page.matches).where((match) => match.isLive),
      );
      final upcomingMatches = _dedupeMatches(
        upcomingPages.expand((page) => page.matches).where(
              (match) => !match.isLive && !match.isCompleted,
            ),
      );
      final completedMatches = _dedupeMatches(
        completedPages
            .expand((page) => page.matches)
            .where((match) => match.isCompleted),
      );

      setState(() {
        // Sort matches appropriately for each tab
        _liveMatches = _sortMatches(liveMatches, 'live');
        _upcomingMatches = _sortMatches(upcomingMatches, 'upcoming');

        // Sort completed matches
        _completedMatches = _sortMatches(completedMatches, 'completed');

        // Update pagination flags
        _hasMoreLive = _hasMoreInGroup(livePages);
        _hasMoreUpcoming = _hasMoreInGroup(upcomingPages);
        _hasMoreCompleted = _hasMoreInGroup(completedPages);

        _isLoading = false;
      });
      _applyInitialMatch();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading matches: $e'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _applyInitialMatch() {
    final match = widget.initialMatch;
    if (match == null || !mounted) return;

    setState(() {
      _liveMatches.removeWhere((m) => m.id == match.id);
      _completedMatches.removeWhere((m) => m.id == match.id);
      _upcomingMatches.removeWhere((m) => m.id == match.id);

      if (match.isLive) {
        _liveMatches.insert(0, match);
        _liveMatches = _sortMatches(_liveMatches, 'live');
      } else if (match.isCompleted) {
        _completedMatches.insert(0, match);
        _completedMatches = _sortMatches(_completedMatches, 'completed');
      } else {
        _upcomingMatches.insert(0, match);
        _upcomingMatches = _sortMatches(_upcomingMatches, 'upcoming');
      }
    });
  }

  Future<void> _loadMoreLive() async {
    if (_isLoadingMoreLive || !_hasMoreLive) return;

    setState(() {
      _isLoadingMoreLive = true;
      _livePage++;
    });

    try {
      final pages = await _fetchStatusGroup(
        statuses: _liveStatuses,
        page: _livePage,
        publicFeed: true,
      );
      setState(() {
        _liveMatches = _sortMatches(
          _dedupeMatches(
              [..._liveMatches, ...pages.expand((page) => page.matches)]),
          'live',
        );
        _hasMoreLive = _hasMoreInGroup(pages);
        _isLoadingMoreLive = false;
      });
    } catch (e) {
      setState(() {
        _livePage--;
        _isLoadingMoreLive = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyError(e, fallback: 'More matches load nahi ho paaye.'),
            ),
          ),
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
      final pages = await _fetchStatusGroup(
        statuses: _upcomingStatuses,
        page: _upcomingPage,
        publicFeed: false,
      );
      setState(() {
        _upcomingMatches = _sortMatches(
          _dedupeMatches(
              [..._upcomingMatches, ...pages.expand((page) => page.matches)]),
          'upcoming',
        );
        _hasMoreUpcoming = _hasMoreInGroup(pages);
        _isLoadingMoreUpcoming = false;
      });
    } catch (e) {
      setState(() {
        _upcomingPage--;
        _isLoadingMoreUpcoming = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyError(e, fallback: 'More matches load nahi ho paaye.'),
            ),
          ),
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
      final pages = await _fetchStatusGroup(
        statuses: _completedStatuses,
        page: _completedPage,
        publicFeed: false,
      );
      setState(() {
        _completedMatches = _sortMatches(
          _dedupeMatches(
              [..._completedMatches, ...pages.expand((page) => page.matches)]),
          'completed',
        );
        _hasMoreCompleted = _hasMoreInGroup(pages);
        _isLoadingMoreCompleted = false;
      });
    } catch (e) {
      setState(() {
        _completedPage--;
        _isLoadingMoreCompleted = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyError(e, fallback: 'More matches load nahi ho paaye.'),
            ),
          ),
        );
      }
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  Future<void> _pickFilterDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: const Color(0xFF0D1117),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  List<Match> _applyDateFilter(List<Match> matches) {
    if (_selectedDate == null) return matches;
    return matches.where((match) {
      final date = match.scheduledDate;
      return date.year == _selectedDate!.year &&
          date.month == _selectedDate!.month &&
          date.day == _selectedDate!.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildShimmerLoading()
          : Column(
              children: [
                _buildMatchSummaryStrip(),
                _buildDateFilterBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _MatchList(
                        matches: _applyDateFilter(_liveMatches),
                        type: 'live',
                        isLoadingMore: _isLoadingMoreLive,
                        hasMore: _hasMoreLive,
                        loadMore: _loadMoreLive,
                        onRefresh: () => _loadMatches(refresh: true),
                      ),
                      _MatchList(
                        matches: _applyDateFilter(_upcomingMatches),
                        type: 'upcoming',
                        isLoadingMore: _isLoadingMoreUpcoming,
                        hasMore: _hasMoreUpcoming,
                        loadMore: _loadMoreUpcoming,
                        onRefresh: () => _loadMatches(refresh: true),
                      ),
                      _MatchList(
                        matches: _applyDateFilter(_completedMatches),
                        type: 'completed',
                        isLoadingMore: _isLoadingMoreCompleted,
                        hasMore: _hasMoreCompleted,
                        loadMore: _loadMoreCompleted,
                        onRefresh: () => _loadMatches(refresh: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildMatchSummaryStrip() {
    final filteredLive = _applyDateFilter(_liveMatches).length;
    final filteredUpcoming = _applyDateFilter(_upcomingMatches).length;
    final filteredCompleted = _applyDateFilter(_completedMatches).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              label: 'Live',
              count: filteredLive,
              icon: Icons.radio_button_checked_rounded,
              color: const Color(0xFFE53E3E),
              onTap: () => _tabController.animateTo(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryTile(
              label: 'Upcoming',
              count: filteredUpcoming,
              icon: Icons.event_available_rounded,
              color: AppColors.primary,
              onTap: () => _tabController.animateTo(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryTile(
              label: 'Results',
              count: filteredCompleted,
              icon: Icons.emoji_events_rounded,
              color: const Color(0xFF10B981),
              onTap: () => _tabController.animateTo(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar() {
    final label = _selectedDate == null
        ? 'All dates'
        : DateFormat('EEE, MMM d, yyyy').format(_selectedDate!);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Date: $label',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1117),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
            child: const Text('Today'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _pickFilterDate,
            child: const Text('Pick Date'),
          ),
          if (_selectedDate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.clear_rounded, size: 20),
              tooltip: 'Clear date filter',
            ),
          ],
        ],
      ),
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
              const Tab(text: 'Scheduled'),
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
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateMatchScreen()),
        );
        if (!mounted) return;
        // If a match was returned (newly created), add it to the correct list
        if (result != null && result is Match) {
          setState(() {
            _liveMatches.removeWhere((match) => match.id == result.id);
            _completedMatches.removeWhere((match) => match.id == result.id);
            _upcomingMatches.removeWhere((match) => match.id == result.id);

            if (result.isLive) {
              _liveMatches.insert(0, result);
              _liveMatches = _sortMatches(_liveMatches, 'live');
              _tabController.animateTo(0);
            } else if (result.isCompleted) {
              _completedMatches.insert(0, result);
              _completedMatches = _sortMatches(_completedMatches, 'completed');
              _tabController.animateTo(2);
            } else {
              _upcomingMatches.insert(0, result);
              _upcomingMatches = _sortMatches(_upcomingMatches, 'upcoming');
              _tabController.animateTo(1);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('New match added!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
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

class _SummaryTile extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const Spacer(),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0D1117),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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

    final items = _buildMatchItems();

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      color: AppColors.primary,
      strokeWidth: 2.5,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
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
          return items[index];
        },
      ),
    );
  }

  List<Widget> _buildMatchItems() {
    final items = <Widget>[];
    DateTime? currentSection;

    for (var index = 0; index < widget.matches.length; index++) {
      final match = widget.matches[index];
      final matchSection = DateTime(
        match.scheduledDate.year,
        match.scheduledDate.month,
        match.scheduledDate.day,
      );

      if (currentSection == null || currentSection != matchSection) {
        currentSection = matchSection;
        items.add(_MatchDateHeader(date: matchSection));
      }

      items.add(
        _MatchCard(match: match)
            .animate()
            .fadeIn(duration: 280.ms, delay: (index * 40).ms)
            .slideY(
                begin: 0.06, end: 0, duration: 280.ms, delay: (index * 40).ms),
      );
    }

    return items;
  }
}

// ---------------------------------------------------------------------------
// _EmptyState
// ---------------------------------------------------------------------------

class _MatchDateHeader extends StatelessWidget {
  final DateTime date;

  const _MatchDateHeader({required this.date});

  String _label() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final sectionDate = DateTime(date.year, date.month, date.day);

    if (sectionDate == normalizedToday) {
      return 'Today';
    }
    if (sectionDate == normalizedToday.add(const Duration(days: 1))) {
      return 'Tomorrow';
    }
    if (sectionDate == normalizedToday.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return DateFormat('EEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _label(),
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String type;
  const _EmptyState({required this.type});

  String _getMessage() {
    switch (type) {
      case 'live':
        return 'No live matches at the moment';
      case 'upcoming':
        return 'No scheduled matches found';
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

    final normalized = status.toLowerCase();
    if (match.isLive || match.isCompleted) {
      Navigator.pushNamed(context, '/scorecard', arguments: match.id);
    } else if (normalized == 'team_selecting' || normalized == 'ready') {
      Navigator.pushNamed(context, '/live-control', arguments: match.id);
    } else if (normalized == 'toss') {
      Navigator.pushNamed(context, '/toss', arguments: match.id);
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
    final isLive = match.isLive;
    final isCompleted = match.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? const Color(0xFFFFE0E0) : const Color(0xFFEEEFF2),
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
                    if (match.tournament != null &&
                        match.tournament!.isNotEmpty) ...[
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
                _TeamsRow(
                    match: match, isLive: isLive, isCompleted: isCompleted),
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
    if (displayFormat == 'T20')
      displayFormat = 'T20';
    else if (displayFormat == 'ODI')
      displayFormat = 'ODI';
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
          const Icon(Icons.emoji_events, size: 10, color: Color(0xFF10B981)),
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
                        if (match.score.team1.overs.isNotEmpty) ...[
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
                        if (match.score.team2.overs.isNotEmpty) ...[
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
    final isCompleted = match.isCompleted;

    String getFooterText() {
      if (isLive) {
        final overs = match.score.team1.overs;
        return 'Live • ${overs.isNotEmpty ? overs : '0.0'} overs • ${formatDate(match.scheduledDate)}';
      } else if (isCompleted) {
        // Fix: Access winner from match.result
        final message = match.result?.message ?? '';
        if (message.isNotEmpty) {
          return '🏆 $message • ${formatDate(match.scheduledDate)}';
        }
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
