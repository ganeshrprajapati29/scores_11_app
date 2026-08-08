import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/theme_config.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/services/tournament_service.dart';
import '../../data/models/tournament_model.dart';
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
      final liveResult =
          await _tournamentService.getTournaments(status: 'LIVE');
      final upcomingResult =
          await _tournamentService.getTournaments(status: 'UPCOMING');
      final completedResult =
          await _tournamentService.getTournaments(status: 'COMPLETED');

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
        _error = _cleanError(e);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tournaments: $_error'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  String _cleanError(Object error) {
    return friendlyError(
      error,
      fallback: 'Tournaments load nahi ho paaye. Please retry.',
    );
  }

  Future<void> _loadMoreLive() async {
    if (_isLiveLoadingMore || !_liveHasMore) return;
    setState(() => _isLiveLoadingMore = true);
    try {
      _livePage++;
      final result = await _tournamentService.getTournaments(
          status: 'LIVE', page: _livePage);
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
          SnackBar(
            content: Text(
              friendlyError(e, fallback: 'More tournaments load nahi ho paaye.'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreUpcoming() async {
    if (_isUpcomingLoadingMore || !_upcomingHasMore) return;
    setState(() => _isUpcomingLoadingMore = true);
    try {
      _upcomingPage++;
      final result = await _tournamentService.getTournaments(
          status: 'UPCOMING', page: _upcomingPage);
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
          SnackBar(
            content: Text(
              friendlyError(e, fallback: 'More tournaments load nahi ho paaye.'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreCompleted() async {
    if (_isCompletedLoadingMore || !_completedHasMore) return;
    setState(() => _isCompletedLoadingMore = true);
    try {
      _completedPage++;
      final result = await _tournamentService.getTournaments(
          status: 'COMPLETED', page: _completedPage);
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
          SnackBar(
            content: Text(
              friendlyError(e, fallback: 'More tournaments load nahi ho paaye.'),
            ),
          ),
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
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _TournamentList(
                      tournaments: _liveTournaments,
                      isLoadingMore: _isLiveLoadingMore,
                      hasMore: _liveHasMore,
                      loadMore: _loadMoreLive,
                      onRefresh: _loadTournaments,
                    ),
                    _TournamentList(
                      tournaments: _upcomingTournaments,
                      isLoadingMore: _isUpcomingLoadingMore,
                      hasMore: _upcomingHasMore,
                      loadMore: _loadMoreUpcoming,
                      onRefresh: _loadTournaments,
                    ),
                    _TournamentList(
                      tournaments: _completedTournaments,
                      isLoadingMore: _isCompletedLoadingMore,
                      hasMore: _completedHasMore,
                      loadMore: _loadMoreCompleted,
                      onRefresh: _loadTournaments,
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
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Tournaments',
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
              borderSide: BorderSide(color: AppColors.primary, width: 2.5),
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
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 34, color: Color(0xFFE53E3E)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Color(0xFF0D1117),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              style: const TextStyle(color: Color(0xFF8B92A5), fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadTournaments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      heroTag: 'tournament_list_create',
      onPressed: () async {
        final created = await Navigator.pushNamed(context, '/create-tournament');
        if (created == true) _loadTournaments();
      },
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text(
        'Create Tournament',
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
// _TournamentList
// ---------------------------------------------------------------------------

class _TournamentList extends StatefulWidget {
  final List<Tournament> tournaments;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback loadMore;
  final Future<void> Function()? onRefresh;

  const _TournamentList({
    required this.tournaments,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadMore,
    this.onRefresh,
  });

  @override
  State<_TournamentList> createState() => _TournamentListState();
}

class _TournamentListState extends State<_TournamentList> {
  late final ScrollController _scrollController;

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
    if (widget.tournaments.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () => Future.value(),
      color: AppColors.primary,
      strokeWidth: 2.5,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: widget.tournaments.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.tournaments.length) {
            return widget.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          return _TournamentCard(tournament: widget.tournaments[index])
              .animate()
              .fadeIn(duration: 280.ms, delay: (index * 45).ms)
              .slideY(
                  begin: 0.06,
                  end: 0,
                  duration: 280.ms,
                  delay: (index * 45).ms);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyState
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            child: const Icon(
              Icons.emoji_events_outlined,
              size: 38,
              color: Color(0xFFB0B8CC),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No tournaments found',
            style: TextStyle(
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
// _TournamentCard
// ---------------------------------------------------------------------------

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;

  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final isLive = tournament.isLive;
    final isCompleted = tournament.status == 'COMPLETED';

    // Determine gradient colors
    final List<Color> gradientColors = isLive
        ? [const Color(0xFFE53E3E), const Color(0xFFC53030)]
        : isCompleted
            ? [const Color(0xFF6B7280), const Color(0xFF4B5563)]
            : [AppColors.primary, AppColors.primaryDark ?? AppColors.primary];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TournamentDetailScreen(tournamentId: tournament.id),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withOpacity(0.04),
          highlightColor: AppColors.primary.withOpacity(0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gradient Header ──────────────────────────────────────
              _CardHeader(
                tournament: tournament,
                isLive: isLive,
                gradientColors: gradientColors,
              ),

              // ── Details ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chips row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.sports_cricket_rounded,
                          label: tournament.format ?? 'T20',
                        ),
                        _InfoChip(
                          icon: Icons.groups_rounded,
                          label: '${tournament.totalTeams} Teams',
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Footer row: date + entry fee
                    _CardFooter(tournament: tournament),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CardHeader
// ---------------------------------------------------------------------------

class _CardHeader extends StatelessWidget {
  final Tournament tournament;
  final bool isLive;
  final List<Color> gradientColors;

  const _CardHeader({
    required this.tournament,
    required this.isLive,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Stack(
        children: [
          // Decorative icon watermark
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              Icons.emoji_events_rounded,
              size: 90,
              color: Colors.white.withOpacity(0.12),
            ),
          ),

          // Subtle top-right circle accent
          Positioned(
            right: 40,
            top: -24,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isLive) ...[
                  _LiveBadge(),
                  const SizedBox(height: 8),
                ],
                Text(
                  tournament.name ?? 'Unnamed Tournament',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LiveBadge
// ---------------------------------------------------------------------------

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFE53E3E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFFE53E3E),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CardFooter
// ---------------------------------------------------------------------------

class _CardFooter extends StatelessWidget {
  final Tournament tournament;

  const _CardFooter({required this.tournament});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date TBD';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 13, color: Color(0xFF8B92A5)),
          const SizedBox(width: 6),
          Text(
            _formatDate(tournament.startDate),
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (tournament.isPaid) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.paid_rounded,
                      size: 13, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    '\$${tournament.entryFee?.toStringAsFixed(0) ?? '0'}',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF9F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Free',
                style: TextStyle(
                  color: Color(0xFF2D7A3A),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: Color(0xFFB0B8CC)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _InfoChip
// ---------------------------------------------------------------------------

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
