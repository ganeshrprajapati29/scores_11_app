import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/models/match_model.dart';
import '../../data/services/match_service.dart';

class ScheduledMatchesScreen extends StatefulWidget {
  final int initialTabIndex;

  const ScheduledMatchesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ScheduledMatchesScreen> createState() => _ScheduledMatchesScreenState();
}

class _ScheduledMatchesScreenState extends State<ScheduledMatchesScreen>
    with SingleTickerProviderStateMixin {
  final MatchService _matchService = MatchService();
  late final TabController _tabController;

  bool _isLoading = true;
  String? _error;
  List<Match> _scheduledMatches = [];
  List<Match> _completedMatches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1).toInt(),
    );
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _matchService.getMyMatches(status: 'scheduled'),
        _matchService.getMyMatches(status: 'completed'),
      ]);

      if (!mounted) return;
      setState(() {
        _scheduledMatches = results[0].matches
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
        _completedMatches = results[1].matches
          ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e, fallback: 'Matches load nahi ho paaye.');
        _isLoading = false;
      });
    }
  }

  Future<void> _openMatch(Match match) async {
    await Navigator.pushNamed(context, '/match-detail', arguments: match.id);
    if (mounted) _loadMatches();
  }

  Future<void> _initializeLive(Match match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialize Live Match?'),
        content: Text(
          '${match.team1} vs ${match.team2} ko live initialize karna hai?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.live_tv_rounded),
            label: const Text('Initialize'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _matchService.initializeMatch(match.id, const <Map<String, dynamic>>[]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${match.team1} vs ${match.team2} ab live matches me dikhega'),
        ),
      );
      await _loadMatches();
      if (mounted) {
        Navigator.pushNamed(context, '/live-matches');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e, fallback: 'Matches load nahi ho paaye.');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 4,
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE4E7EC)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 18),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.sports_cricket_rounded, color: AppColors.primary, size: 16),
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
                  'Scheduled Matches',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                Text(
                  'Your upcoming and completed matches',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w500),
                ),
              ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadMatches,
            icon: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE4E7EC)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 18),
            ),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadMatches)
              : Column(
                  children: [
                    _buildTabSwitcher(),
                    _buildStatStrip(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _MatchTab(
                            matches: _scheduledMatches,
                            sectionTitle: 'Your Scheduled Matches',
                            emptyText: 'No scheduled matches found',
                            onRefresh: _loadMatches,
                            onTap: _openMatch,
                            onInitializeLive: _initializeLive,
                          ),
                          _MatchTab(
                            matches: _completedMatches,
                            sectionTitle: 'Your Completed Matches',
                            emptyText: 'No completed matches found',
                            onRefresh: _loadMatches,
                            onTap: _openMatch,
                            onInitializeLive: _initializeLive,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Scheduled/Completed pill segments -- bound to the existing TabController.
  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: AnimatedBuilder(
        animation: _tabController.animation ?? _tabController,
        builder: (context, _) {
          final index = _tabController.index;
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    label: 'Scheduled',
                    selected: index == 0,
                    onTap: () => _tabController.animateTo(0),
                  ),
                ),
                Expanded(
                  child: _SegmentButton(
                    label: 'Completed',
                    selected: index == 1,
                    onTap: () => _tabController.animateTo(1),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Informational stat cards -- counts sourced from the exact same lists
  /// already loaded by [_loadMatches]. The "Live Ready" count is derived
  /// from the already-fetched scheduled list via the existing
  /// `Match.isReady` getter, so no extra fetch is introduced.
  Widget _buildStatStrip() {
    final readyCount = _scheduledMatches.where((m) => m.isReady).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              count: _scheduledMatches.length,
              label: 'Scheduled',
              subtitle: 'Upcoming',
              icon: Icons.calendar_month_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              count: readyCount,
              label: 'Live Ready',
              subtitle: 'Ready',
              icon: Icons.play_circle_fill_rounded,
              color: AppColors.live,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              count: _completedMatches.length,
              label: 'Completed',
              subtitle: 'Finished',
              icon: Icons.emoji_events_rounded,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.count,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101828),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(
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
    );
  }
}

class _MatchTab extends StatelessWidget {
  final List<Match> matches;
  final String sectionTitle;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final ValueChanged<Match> onTap;
  final ValueChanged<Match> onInitializeLive;

  const _MatchTab({
    required this.matches,
    required this.sectionTitle,
    required this.emptyText,
    required this.onRefresh,
    required this.onTap,
    required this.onInitializeLive,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Image.asset(
              'score 11/Empty States 2.png',
              width: 118,
              height: 118,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.sports_cricket_rounded, size: 58, color: Colors.grey[400]),
            ),
            const SizedBox(height: 12),
            Text(
              emptyText,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: matches.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sectionTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_vert_rounded,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Sort by: Date',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          final match = matches[index - 1];
          return _ScheduledMatchCard(
            match: match,
            onTap: () => onTap(match),
            onInitializeLive: () => onInitializeLive(match),
          );
        },
      ),
    );
  }
}

class _ScheduledMatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  final VoidCallback onInitializeLive;

  const _ScheduledMatchCard({
    required this.match,
    required this.onTap,
    required this.onInitializeLive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        image: const DecorationImage(
          image: AssetImage('score 11/Upcoming Match Card  1024 x 576 PNG.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          opacity: 0.045,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ScheduleStatusPill(match: match),
                  const Spacer(),
                  Text(
                    '${match.format.toUpperCase()} • ${DateFormat('dd MMM, hh:mm a').format(match.scheduledDate)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _TeamLogo(
                          name: match.team1,
                          color: AppColors.primary,
                          assetFallback: 'assets/images/teams/team1_logo.png',
                          logoUrl: match.team1Data is Map ? match.team1Data['logo']?.toString() : null,
                        ),
                        const SizedBox(height: 8),
                        _TeamName(name: match.team1),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TeamLogo(
                          name: match.team2,
                          color: const Color(0xFF3B82F6),
                          assetFallback: 'assets/images/teams/team2_logo.png',
                          logoUrl: match.team2Data is Map ? match.team2Data['logo']?.toString() : null,
                        ),
                        const SizedBox(height: 8),
                        _TeamName(name: match.team2),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 15, color: Colors.grey[500]),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      match.venue?.name ?? 'Venue TBD',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withOpacity(0.35)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onInitializeLive,
                      icon: const Icon(Icons.podcasts_rounded, size: 18),
                      label: const Text('Initialize Live'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blue outline "SCHEDULED" pill, or a red outline "READY" pill when the
/// match model already flags the match as ready-to-start (`match.isReady`).
class _ScheduleStatusPill extends StatelessWidget {
  final Match match;
  const _ScheduleStatusPill({required this.match});

  @override
  Widget build(BuildContext context) {
    final isReady = match.isReady;
    final color = isReady ? AppColors.live : AppColors.primary;
    final text = isReady ? 'READY' : 'SCHEDULED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String name;
  final Color color;
  final String assetFallback;
  final String? logoUrl;

  const _TeamLogo({
    required this.name,
    required this.color,
    required this.assetFallback,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
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
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
      ),
    );
  }
}

class _TeamName extends StatelessWidget {
  final String name;

  const _TeamName({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      maxLines: 2,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Matches load nahi ho paaye', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
