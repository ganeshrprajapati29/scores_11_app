import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/match_status_badge.dart';
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
        _error = e.toString().replaceFirst('Exception: ', '');
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
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: CustomAppBar(
        title: 'Scheduled Matches',
        showBackButton: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Scheduled'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadMatches)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _MatchTab(
                      matches: _scheduledMatches,
                      emptyText: 'No scheduled matches found',
                      onRefresh: _loadMatches,
                      onTap: _openMatch,
                      onInitializeLive: _initializeLive,
                    ),
                    _MatchTab(
                      matches: _completedMatches,
                      emptyText: 'No completed matches found',
                      onRefresh: _loadMatches,
                      onTap: _openMatch,
                      onInitializeLive: _initializeLive,
                    ),
                  ],
                ),
    );
  }
}

class _MatchTab extends StatelessWidget {
  final List<Match> matches;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final ValueChanged<Match> onTap;
  final ValueChanged<Match> onInitializeLive;

  const _MatchTab({
    required this.matches,
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
            Icon(Icons.sports_cricket_rounded, size: 58, color: Colors.grey[400]),
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
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
                  MatchStatusBadge(status: match.status),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(match.scheduledDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _TeamName(name: match.team1)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'VS',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Expanded(child: _TeamName(name: match.team2, alignRight: true)),
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
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onInitializeLive,
                      icon: const Icon(Icons.live_tv_rounded, size: 18),
                      label: const Text('Initialize Live'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
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

class _TeamName extends StatelessWidget {
  final String name;
  final bool alignRight;

  const _TeamName({required this.name, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 15,
        fontWeight: FontWeight.w900,
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
