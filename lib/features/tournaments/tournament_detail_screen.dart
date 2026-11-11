import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/models/tournament_model.dart';
import '../../data/models/team_model.dart';
import '../../data/services/team_service.dart';
import '../../data/services/tournament_service.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  final TournamentService _tournamentService = TournamentService();
  final TeamService _teamService = TeamService();
  late final TabController _tabController;

  Tournament? _tournament;
  List<Map<String, dynamic>> _matches = [];
  List<PointsTable> _pointsTable = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isRegistering = false;
  bool _isGeneratingFixtures = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTournament();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTournament() async {
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
      final results = await Future.wait<dynamic>([
        _tournamentService.getTournamentById(widget.tournamentId),
        _tournamentService.getTournamentMatches(widget.tournamentId),
        _tournamentService.getPointsTable(widget.tournamentId),
        _tournamentService.getTournamentStats(widget.tournamentId),
      ]);

      if (!mounted) return;
      setState(() {
        _tournament = results[0] as Tournament;
        _matches = (results[1] as List).whereType<Map<String, dynamic>>().toList();
        _pointsTable = (results[2] as List).whereType<PointsTable>().toList();
        _stats = results[3] is Map<String, dynamic> ? results[3] as Map<String, dynamic> : {};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(e);
        _isLoading = false;
      });
    }
  }

  String _cleanError(Object error) {
    final message = friendlyError(
      error,
      fallback: 'Could not open tournament. Please try again.',
    );
    if (message.contains('No token provided')) {
      return 'Showing public tournament details. Pull to refresh.';
    }
    return message;
  }

  Future<void> _participate() async {
    setState(() => _isRegistering = true);
    try {
      final teams = await _teamService.getMyTeams();
      if (!mounted) return;
      if (teams.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Create a team first to join this tournament.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final selectedTeam = await _showTeamPicker(teams);
      if (selectedTeam == null) return;

      final tournament = await _tournamentService.registerTeam(
        widget.tournamentId,
        selectedTeam.id,
      );
      if (!mounted) return;
      setState(() => _tournament = tournament);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedTeam.name} registered successfully.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadTournament();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<Team?> _showTeamPicker(List<Team> teams) {
    return showModalBottomSheet<Team>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Team',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: teams.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final alreadyJoined = _tournament?.teams.contains(team.id) == true ||
                          _tournament?.teams.contains(team.name) == true;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          team.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${team.players.length} players'),
                        trailing: alreadyJoined
                            ? const Text(
                                'Joined',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700),
                              )
                            : const Icon(Icons.chevron_right_rounded),
                        enabled: !alreadyJoined,
                        onTap: alreadyJoined ? null : () => Navigator.pop(context, team),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateFixtures(String type) async {
    if (_isGeneratingFixtures) return;
    setState(() => _isGeneratingFixtures = true);
    try {
      if (type == 'knockout') {
        await _tournamentService.generateKnockoutMatches(widget.tournamentId);
      } else {
        await _tournamentService.generateLeagueMatches(widget.tournamentId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(type == 'knockout'
              ? 'Knockout fixtures generated.'
              : 'League fixtures generated.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadTournament();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingFixtures = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadTournament)
              : _tournament == null
                  ? _ErrorState(message: 'Tournament not found', onRetry: _loadTournament)
                  : _buildContent(_tournament!),
      bottomNavigationBar: _tournament == null ? null : _buildBottomBar(_tournament!),
    );
  }

  Widget _buildContent(Tournament tournament) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          stretch: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _loadTournament,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text(
              tournament.name.isEmpty ? 'Tournament' : tournament.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            background: _HeroHeader(tournament: tournament),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Teams'),
                  Tab(text: 'Matches'),
                  Tab(text: 'Points'),
                  Tab(text: 'Prize'),
                ],
              ),
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(tournament: tournament, stats: _stats),
          _TeamsTab(tournament: tournament),
          _MatchesTab(
            matches: _matches,
            isGenerating: _isGeneratingFixtures,
            onGenerateLeague: () => _generateFixtures('league'),
            onGenerateKnockout: () => _generateFixtures('knockout'),
          ),
          _PointsTab(points: _pointsTable),
          _PrizeTab(tournament: tournament),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Tournament tournament) {
    final isClosed = tournament.isCompleted || tournament.status == 'CANCELLED';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Entry Fee', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  Text(
                    _money(tournament.entryFee),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isClosed || _isRegistering ? null : _participate,
                icon: _isRegistering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.group_add_rounded, size: 18),
                label: Text(isClosed ? 'Registration Closed' : 'Register Team'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final Tournament tournament;

  const _HeroHeader({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final imageUrl = tournament.bannerUrl ?? tournament.banner ?? tournament.logoUrl ?? tournament.logo;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackBackground(),
          )
        else
          _fallbackBackground(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.black.withOpacity(0.72),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 56,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(label: tournament.status, color: _statusColor(tournament.status)),
              _StatusChip(label: tournament.format, color: Colors.white),
              _StatusChip(label: tournament.type, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackBackground() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('score 11/Tournament Page banner.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isWhite = color == Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white.withOpacity(0.18) : color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isWhite ? Colors.white.withOpacity(0.28) : color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isWhite ? Colors.white : color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Tournament tournament;
  final Map<String, dynamic> stats;

  const _OverviewTab({required this.tournament, required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if ((tournament.description ?? '').isNotEmpty)
          _SectionCard(
            title: 'About',
            child: Text(
              tournament.description!,
              style: const TextStyle(color: Color(0xFF475569), height: 1.45),
            ),
          ),
        _SectionCard(
          title: 'Tournament Info',
          child: Column(
            children: [
              _InfoRow(icon: Icons.calendar_today_rounded, label: 'Start', value: _date(tournament.startDate)),
              _InfoRow(icon: Icons.event_available_rounded, label: 'End', value: _date(tournament.endDate)),
              _InfoRow(icon: Icons.location_on_rounded, label: 'Venue', value: tournament.displayLocation),
              _InfoRow(icon: Icons.person_rounded, label: 'Organizer', value: tournament.organizer.isEmpty ? 'Unknown' : tournament.organizer),
              _InfoRow(icon: Icons.groups_rounded, label: 'Teams', value: '${tournament.teamsCount}/${tournament.capacityTeams}'),
              _InfoRow(icon: Icons.sports_cricket_rounded, label: 'Overs', value: '${tournament.overs} overs'),
            ],
          ),
        ),
        _SectionCard(
          title: 'Live Summary',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatTile(label: 'Matches', value: _value(stats['totalMatches'] ?? tournament.totalMatches)),
              _StatTile(label: 'Completed', value: _value(stats['completedMatches'])),
              _StatTile(label: 'Upcoming', value: _value(stats['upcomingMatches'])),
              _StatTile(label: 'Teams', value: _value(tournament.teamsCount)),
            ],
          ),
        ),
        if ((tournament.rules ?? '').isNotEmpty)
          _SectionCard(
            title: 'Rules',
            child: Text(tournament.rules!, style: const TextStyle(color: Color(0xFF475569), height: 1.45)),
          ),
      ],
    );
  }
}

class _TeamsTab extends StatelessWidget {
  final Tournament tournament;

  const _TeamsTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    if (tournament.teams.isEmpty) {
      return const _EmptyPanel(message: 'No teams registered yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournament.teams.length,
      itemBuilder: (context, index) {
        final team = tournament.teams[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(team, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        );
      },
    );
  }
}

class _MatchesTab extends StatelessWidget {
  final List<Map<String, dynamic>> matches;
  final bool isGenerating;
  final VoidCallback onGenerateLeague;
  final VoidCallback onGenerateKnockout;

  const _MatchesTab({
    required this.matches,
    required this.isGenerating,
    required this.onGenerateLeague,
    required this.onGenerateKnockout,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Generate Fixtures',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create tournament schedule from registered teams.',
                  style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isGenerating ? null : onGenerateLeague,
                        icon: isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.calendar_month_rounded, size: 18),
                        label: const Text('League'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isGenerating ? null : onGenerateKnockout,
                        icon: const Icon(Icons.account_tree_rounded, size: 18),
                        label: const Text('Knockout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _EmptyPanel(message: 'Fixtures are not generated yet'),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) => _MatchCard(match: matches[index]),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final team1 = _teamName(match['team1'], fallback: 'Team A');
    final team2 = _teamName(match['team2'], fallback: 'Team B');
    final status = match['status']?.toString().toUpperCase() ?? 'SCHEDULED';
    final date = DateTime.tryParse(match['scheduledDate']?.toString() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(_dateTime(date), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                _MiniBadge(label: status, color: _statusColor(status)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _TeamName(name: team1)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('VS', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                ),
                Expanded(child: _TeamName(name: team2, alignEnd: true)),
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
    );
  }
}

class _PointsTab extends StatelessWidget {
  final List<PointsTable> points;

  const _PointsTab({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _EmptyPanel(message: 'Points table will appear after matches start');
    }
    final sorted = [...points]..sort((a, b) => b.points.compareTo(a.points));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PointsHeader(),
        ...sorted.asMap().entries.map((entry) => _PointsRow(rank: entry.key + 1, row: entry.value)),
      ],
    );
  }
}

class _PrizeTab extends StatelessWidget {
  final Tournament tournament;

  const _PrizeTab({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final prize = tournament.prizeMoney ?? 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'Prize Pool',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_money(prize), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const SizedBox(height: 6),
              const Text('Final prize distribution depends on organizer settings.', style: TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
        _SectionCard(
          title: 'Entry',
          child: _InfoRow(icon: Icons.payments_rounded, label: 'Entry Fee', value: _money(tournament.entryFee)),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF64748B)))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _TeamName extends StatelessWidget {
  final String name;
  final bool alignEnd;

  const _TeamName({required this.name, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w800),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _PointsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 34, child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text('Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          _TableHead('M'),
          _TableHead('W'),
          _TableHead('L'),
          _TableHead('Pts'),
          _TableHead('NRR'),
        ],
      ),
    );
  }
}

class _TableHead extends StatelessWidget {
  final String label;
  const _TableHead(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 42, child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
  }
}

class _PointsRow extends StatelessWidget {
  final int rank;
  final PointsTable row;

  const _PointsRow({required this.rank, required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(width: 34, child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(row.team, maxLines: 1, overflow: TextOverflow.ellipsis)),
          _TableCell('${row.matchesPlayed}'),
          _TableCell('${row.matchesWon}'),
          _TableCell('${row.matchesLost}'),
          _TableCell('${row.points}', bold: true),
          _TableCell("${row.netRunRate > 0 ? '+' : ''}${row.netRunRate.toStringAsFixed(3)}"),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String value;
  final bool bold;

  const _TableCell(this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String message;

  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 58, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 58, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF475569))),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _teamName(dynamic team, {required String fallback}) {
  if (team is String && team.isNotEmpty) return team;
  if (team is Map) {
    return team['name']?.toString() ??
        team['shortName']?.toString() ??
        team['_id']?.toString() ??
        team['id']?.toString() ??
        fallback;
  }
  return fallback;
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'LIVE':
    case 'IN_PROGRESS':
      return const Color(0xFFEF4444);
    case 'COMPLETED':
      return const Color(0xFF16A34A);
    case 'CANCELLED':
      return const Color(0xFF64748B);
    default:
      return AppColors.primary;
  }
}

String _date(DateTime? date) {
  if (date == null) return 'TBD';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _dateTime(DateTime? date) {
  if (date == null) return 'Schedule TBD';
  final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${_date(date)}  $hour:${date.minute.toString().padLeft(2, '0')} $period';
}

String _money(num? value) {
  final amount = value ?? 0;
  if (amount <= 0) return 'Free';
  return 'Rs ${amount.toStringAsFixed(0)}';
}

String _value(dynamic value) => int.tryParse(value?.toString() ?? '')?.toString() ?? '0';
