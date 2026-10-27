import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/models/match_model.dart';
import '../../data/services/match_service.dart';
import 'package:shimmer/shimmer.dart';
import 'create_match_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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
  String _searchQuery = '';

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
            content: Text(friendlyError(e, fallback: 'Could not load matches.')),
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
              friendlyError(e, fallback: 'Could not load more matches.'),
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
              friendlyError(e, fallback: 'Could not load more matches.'),
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
              friendlyError(e, fallback: 'Could not load more matches.'),
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

  /// Date filter plus the team/venue search from the app bar.
  List<Match> _applyDateFilter(List<Match> matches) {
    final query = _searchQuery.trim().toLowerCase();
    return matches.where((match) {
      if (_selectedDate != null) {
        final date = match.scheduledDate;
        final sameDay = date.year == _selectedDate!.year &&
            date.month == _selectedDate!.month &&
            date.day == _selectedDate!.day;
        if (!sameDay) return false;
      }
      if (query.isEmpty) return true;
      final haystack = [
        match.team1,
        match.team2,
        match.venue?.name ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _openSearch() async {
    final controller = TextEditingController(text: _searchQuery);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search matches'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Team or venue',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            TextButton(onPressed: () => Navigator.pop(ctx, ''), child: const Text('Clear')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && mounted) setState(() => _searchQuery = value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildShimmerLoading()
          : Column(
              children: [
                _buildTopTabBar(),
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

  // ---------------------------------------------------------------------
  // Underline tab row: LIVE / SCHEDULED / COMPLETED
  // ---------------------------------------------------------------------
  Widget _buildTopTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.live,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.live,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
        unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        tabs: const [
          Tab(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.circle, size: 9),
              SizedBox(width: 6),
              Text('LIVE'),
            ]),
          ),
          Tab(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.calendar_month_rounded, size: 16),
              SizedBox(width: 6),
              Text('SCHEDULED'),
            ]),
          ),
          Tab(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.emoji_events_rounded, size: 16),
              SizedBox(width: 6),
              Text('COMPLETED'),
            ]),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Stat pill strip -- doubles as the tab switcher (tap-to-switch preserved)
  // ---------------------------------------------------------------------
  Widget _buildMatchSummaryStrip() {
    final filteredLive = _applyDateFilter(_liveMatches).length;
    final filteredUpcoming = _applyDateFilter(_upcomingMatches).length;
    final filteredCompleted = _applyDateFilter(_completedMatches).length;

    return AnimatedBuilder(
      animation: _tabController.animation ?? _tabController,
      builder: (context, _) {
        final activeIndex = _tabController.index;
        return Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Live Matches',
                  subtitle: 'Now Live',
                  count: filteredLive,
                  icon: Icons.circle,
                  color: AppColors.live,
                  selected: activeIndex == 0,
                  onTap: () => _tabController.animateTo(0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Scheduled',
                  subtitle: 'Upcoming',
                  count: filteredUpcoming,
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  selected: activeIndex == 1,
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Completed',
                  subtitle: 'Finished',
                  count: filteredCompleted,
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.completed,
                  selected: activeIndex == 2,
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Date filter row -- callbacks unchanged
  // ---------------------------------------------------------------------
  Widget _buildDateFilterBar() {
    final label = _selectedDate == null
        ? 'All dates'
        : DateFormat('EEE, MMM d, yyyy').format(_selectedDate!);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_note_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Date: $label',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _DateChipButton(
            label: 'Today',
            onTap: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
          ),
          const SizedBox(width: 8),
          _DateChipButton(
            label: 'Pick Date',
            icon: Icons.calendar_today_rounded,
            filled: true,
            onTap: _pickFilterDate,
          ),
          if (_selectedDate != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: _clearDateFilter,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.filter_alt_off_rounded,
                    size: 16, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 68,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.sports_cricket_rounded, color: AppColors.primary, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Matches',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'All your cricket matches',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _openSearch,
          icon: Icon(Icons.search_rounded,
              color: _searchQuery.isEmpty ? AppColors.textSecondary : AppColors.primary),
          tooltip: 'Search',
        ),
        IconButton(
          onPressed: _pickFilterDate,
          icon: const Icon(Icons.calendar_today_outlined,
              color: AppColors.textSecondary, size: 20),
          tooltip: 'Pick date',
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
          icon: const Icon(Icons.notifications_none_rounded,
              color: AppColors.textSecondary),
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
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
            borderRadius: BorderRadius.circular(16),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
class _DateChipButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback onTap;

  const _DateChipButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: filled ? Colors.white : AppColors.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.label,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color.withOpacity(0.55) : AppColors.divider,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x14101828),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: icon == Icons.circle ? 12 : 18),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
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
            width: 120,
            height: 120,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'score 11/Empty States 2.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.sports_cricket_rounded,
                size: 48,
                color: Color(0xFFB0B8CC),
              ),
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
          const Text(
            'Check back later for updates',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
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
    final auth = context.read<AuthProvider>();
    // The match creator scores it from Live Score Control; everyone else
    // watches the scorecard / match centre.
    final isScorer = match.canBeScoredBy(auth.user?.id, role: auth.userRole);

    final normalized = status.toLowerCase();
    if (match.isCompleted) {
      Navigator.pushNamed(context, '/scorecard', arguments: match.id);
    } else if (match.isLive) {
      Navigator.pushNamed(context, isScorer ? '/live-control' : '/scorecard', arguments: match.id);
    } else if (normalized == 'team_selecting' || normalized == 'ready') {
      Navigator.pushNamed(context, isScorer ? '/live-control' : '/match-detail', arguments: match.id);
    } else if (normalized == 'toss') {
      Navigator.pushNamed(context, isScorer ? '/toss' : '/match-detail', arguments: match.id);
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

  /// Pure display heuristic: whichever team has bowled more overs so far is
  /// the team currently batting (used only to label the live chase banner).
  bool _team2IsBatting() {
    return match.score.team2.oversInDecimal >= match.score.team1.oversInDecimal &&
        match.score.team2.oversInDecimal > 0;
  }

  String _formatCrr() {
    final battingScore =
        _team2IsBatting() ? match.score.team2 : match.score.team1;
    final overs = battingScore.oversInDecimal;
    if (overs <= 0) return '0.00';
    return (battingScore.runs / overs).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;
    final isCompleted = match.isCompleted;
    final bgAsset = isLive
        ? 'score 11/Live Match Card 1024 x 576 PNG.png'
        : 'score 11/Upcoming Match Card  1024 x 576 PNG.png';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          image: AssetImage(bgAsset),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          opacity: isLive ? 0.18 : 0.13,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLive ? AppColors.live.withOpacity(0.25) : AppColors.divider,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101828),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _handleMatchTap(context),
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.primary.withOpacity(0.04),
          highlightColor: AppColors.primary.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: status badge + format/overs + venue
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusPill(match: match),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${match.format.toUpperCase()} • ${match.overs} overs',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        _VenueLabel(venue: match.venue?.name),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Teams row
                _TeamsRow(
                    match: match, isLive: isLive, isCompleted: isCompleted),
                if (isLive) ...[
                  const SizedBox(height: 12),
                  _LiveChaseBanner(
                    match: match,
                    battingTeamName:
                        _team2IsBatting() ? match.team2 : match.team1,
                  ),
                ],
                const SizedBox(height: 14),
                // Footer / CTA
                if (isLive)
                  _LiveFooter(crr: _formatCrr())
                else if (isCompleted)
                  _CompletedFooter(
                    match: match,
                    onTap: () => _handleMatchTap(context),
                  )
                else
                  _ScheduledFooter(
                    dateLabel: _formatMatchDate(match.scheduledDate),
                    onTap: () => _handleMatchTap(context),
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
// Status pill (LIVE / SCHEDULED / COMPLETED / READY)
// ---------------------------------------------------------------------------

class _StatusPill extends StatelessWidget {
  final Match match;
  const _StatusPill({required this.match});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String text;
    final isLive = match.isLive;

    if (isLive) {
      color = AppColors.live;
      text = 'LIVE';
    } else if (match.isCompleted) {
      color = AppColors.completed;
      text = 'COMPLETED';
    } else if (match.isReady) {
      color = AppColors.live;
      text = 'READY';
    } else {
      color = AppColors.scheduled;
      text = 'SCHEDULED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLive ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: isLive ? null : Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            const Icon(Icons.circle, size: 7, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: isLive ? Colors.white : color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Live chase banner: "TEAM need X runs in Y balls"
// ---------------------------------------------------------------------------

class _LiveChaseBanner extends StatelessWidget {
  final Match match;
  final String battingTeamName;

  const _LiveChaseBanner({required this.match, required this.battingTeamName});

  @override
  Widget build(BuildContext context) {
    final requiredRuns = match.result?.requiredRuns;
    final requiredBalls = match.result?.requiredBalls;
    if (requiredRuns == null || requiredBalls == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.live.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.live.withOpacity(0.18)),
      ),
      child: Text(
        '$battingTeamName need $requiredRuns runs in $requiredBalls balls',
        style: const TextStyle(
          color: AppColors.live,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footers per match state
// ---------------------------------------------------------------------------

class _LiveFooter extends StatelessWidget {
  final String crr;
  const _LiveFooter({required this.crr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'CRR: $crr',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Live Score',
              style: TextStyle(
                color: AppColors.live,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.live),
          ],
        ),
      ],
    );
  }
}

class _CompletedFooter extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  const _CompletedFooter({required this.match, required this.onTap});

  String _resultText() {
    final message = match.result?.message ?? '';
    if (message.isNotEmpty) return message;
    final winner = match.result?.winner ?? 'Match completed';
    final margin = match.result?.margin ?? '';
    if (margin.isNotEmpty) return '$winner won by $margin';
    return winner;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_resultText()} — Full Time',
          style: const TextStyle(
            color: AppColors.completed,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.bar_chart_rounded, size: 16),
            label: const Text('View Scorecard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.completed,
              side: BorderSide(color: AppColors.completed.withOpacity(0.35)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduledFooter extends StatelessWidget {
  final String dateLabel;
  final VoidCallback onTap;
  const _ScheduledFooter({required this.dateLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              dateLabel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('View Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withOpacity(0.35)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

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

class _TeamAvatar extends StatelessWidget {
  final String name;
  final Color bgColor;
  final Color textColor;
  final String? logoUrl;
  final String assetFallback;

  const _TeamAvatar({
    required this.name,
    required this.bgColor,
    required this.textColor,
    required this.assetFallback,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      clipBehavior: Clip.antiAlias,
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
      child: (logoUrl != null && logoUrl!.trim().isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: logoUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _fallback(),
            )
          : Image.asset(
              assetFallback,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'T',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: textColor,
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
                  assetFallback: 'assets/images/teams/team1_logo.png',
                  logoUrl: match.team1Data is Map ? match.team1Data['logo']?.toString() : null,
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
                      if (isLive &&
                          match.score.team2.oversInDecimal == 0 &&
                          match.result?.target != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Target ${match.result!.target}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ] else if (isLive || isCompleted) ...[
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
                  assetFallback: 'assets/images/teams/team2_logo.png',
                  logoUrl: match.team2Data is Map ? match.team2Data['logo']?.toString() : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

