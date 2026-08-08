import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/services/tournament_service.dart';

class FixturesScreen extends StatefulWidget {
  final String tournamentId;

  const FixturesScreen({super.key, required this.tournamentId});

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  final TournamentService _service = TournamentService();
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    if (widget.tournamentId.isEmpty) {
      setState(() {
        _error = 'Tournament id missing';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final matches = await _service.getTournamentMatches(widget.tournamentId);
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e, fallback: 'Fixtures load nahi ho paaye.');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Fixtures',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadMatches,
            ),
          ],
        ),
        body: Column(
          children: [
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Completed'),
                Tab(text: 'Upcoming'),
              ],
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return _ErrorPanel(message: _error!, onRetry: _loadMatches);

    return TabBarView(
      children: [
        _MatchList(matches: _matches, onRefresh: _loadMatches),
        _MatchList(matches: _filterByStatus(['COMPLETED']), onRefresh: _loadMatches),
        _MatchList(matches: _filterByStatus(['SCHEDULED', 'UPCOMING']), onRefresh: _loadMatches),
      ],
    );
  }

  List<Map<String, dynamic>> _filterByStatus(List<String> statuses) {
    return _matches.where((match) {
      final status = match['status']?.toString().toUpperCase() ?? '';
      return statuses.contains(status);
    }).toList();
  }
}

class _MatchList extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final Future<void> Function() onRefresh;

  const _MatchList({required this.matches, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const _EmptyPanel(message: 'No fixtures available');
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) => _FixtureCard(match: matches[index]),
      ),
    );
  }
}

class _FixtureCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const _FixtureCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final team1 = _teamName(match['team1'], fallback: 'Team A');
    final team2 = _teamName(match['team2'], fallback: 'Team B');
    final status = match['status']?.toString().toUpperCase() ?? 'SCHEDULED';
    final date = DateTime.tryParse(match['scheduledDate']?.toString() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          final id = match['_id']?.toString() ?? match['id']?.toString();
          if (id != null && id.isNotEmpty) {
            Navigator.pushNamed(context, '/match-detail', arguments: id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateTime(date),
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ),
                  _Badge(label: status, color: _statusColor(status)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: Text(team1, style: const TextStyle(fontWeight: FontWeight.w800))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('VS', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Text(
                      team2,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              if ((match['venue']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match['venue'].toString(),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10)),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String message;
  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: const TextStyle(color: Color(0xFF64748B))));
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _teamName(dynamic team, {required String fallback}) {
  if (team is String && team.isNotEmpty) return team;
  if (team is Map) return team['name']?.toString() ?? team['shortName']?.toString() ?? fallback;
  return fallback;
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return const Color(0xFF16A34A);
    case 'LIVE':
    case 'IN_PROGRESS':
      return const Color(0xFFEF4444);
    default:
      return AppColors.primary;
  }
}

String _dateTime(DateTime? date) {
  if (date == null) return 'Schedule TBD';
  final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  $hour:${date.minute.toString().padLeft(2, '0')} $period';
}
