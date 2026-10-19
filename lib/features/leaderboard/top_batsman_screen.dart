import 'package:flutter/material.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/services/leaderboard_service.dart';

const Color _rankPrimary = Color(0xFF1657CC);
const Color _rankBg = Color(0xFFF7F8FA);
const Color _rankBorder = Color(0xFFE4E7EC);
const Color _rankHeader = Color(0xFFF2F4F7);
const Color _rankText = Color(0xFF111827);
const Color _rankMuted = Color(0xFF667085);

class TopBatsmanScreen extends StatefulWidget {
  const TopBatsmanScreen({super.key});

  @override
  State<TopBatsmanScreen> createState() => _TopBatsmanScreenState();
}

class _TopBatsmanScreenState extends State<TopBatsmanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final LeaderboardService _service = LeaderboardService();
  final Map<_RankTab, List<Map<String, dynamic>>> _data = {};
  final Set<_RankTab> _loading = {};
  String? _error;

  static const _tabs = [
    _RankTab.batsmen,
    _RankTab.bowlers,
    _RankTab.mvp,
    _RankTab.teams,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _load(_tabs[_tabController.index]);
      }
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait(_tabs.map((tab) => _load(tab, force: true)));
  }

  Future<void> _load(_RankTab tab, {bool force = false}) async {
    if (!force && (_data[tab]?.isNotEmpty ?? false)) return;
    if (_loading.contains(tab)) return;
    setState(() {
      _loading.add(tab);
      _error = null;
    });
    try {
      final result = await _fetchRankings(tab);
      if (!mounted) return;
      setState(() => _data[tab] = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load rankings. Pull to refresh.');
    } finally {
      if (!mounted) return;
      setState(() => _loading.remove(tab));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRankings(_RankTab tab) async {
    final fallbackType = switch (tab) {
      _RankTab.batsmen => 'batsmen',
      _RankTab.bowlers => 'bowlers',
      _RankTab.mvp => 'mvp',
      _RankTab.teams => 'teams',
    };

    try {
      final result = switch (tab) {
        _RankTab.batsmen => (await _service.getTopBatsmen(limit: 30)).entries,
        _RankTab.bowlers => (await _service.getTopBowlers(limit: 30)).entries,
        _RankTab.mvp => await _service.getMVPRankings(limit: 30),
        _RankTab.teams => await _service.getTeamRankings(limit: 30),
      };
      if (result.isNotEmpty) return result;
    } catch (_) {
      // Try the generic endpoint below.
    }

    return _service.getAllRankings(type: fallbackType, limit: 30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _rankBg,
      appBar: const CustomAppBar(title: 'Rankings', showBackButton: true),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: _RankHero(data: _data),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _rankBorder),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: _rankMuted,
                indicator: BoxDecoration(
                  color: _rankPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                tabs: _tabs.map((tab) => Tab(text: tab.label, icon: Icon(tab.icon, size: 16))).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
            controller: _tabController,
            children: _tabs.map(_buildTab).toList(),
              ),
            ),
          ],
          ),
      ),
    );
  }

  Widget _buildTab(_RankTab tab) {
    final entries = _data[tab] ?? const <Map<String, dynamic>>[];
    final isLoading = _loading.contains(tab);

    return RefreshIndicator(
      onRefresh: () => _load(tab, force: true),
      color: _rankPrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StateBanner(message: _error!, isError: true),
            ),
          if (isLoading && entries.isEmpty)
            const SizedBox(
              height: 320,
              child: Center(child: CircularProgressIndicator(color: _rankPrimary)),
            )
          else if (entries.isEmpty)
            SizedBox(height: 320, child: _EmptyRankings(tab: tab))
          else
            ...List.generate(entries.length, (index) {
              final entry = _RankEntry.fromMap(entries[index], tab, index);
              return Padding(
                padding: EdgeInsets.only(bottom: index == entries.length - 1 ? 0 : 10),
                child: _RankingCard(entry: entry, tab: tab),
              );
            }),
        ],
      ),
    );
  }
}

enum _RankTab {
  batsmen('Batsmen', Icons.sports_cricket_rounded),
  bowlers('Bowlers', Icons.sports_baseball_rounded),
  mvp('MVP', Icons.workspace_premium_rounded),
  teams('Teams', Icons.groups_rounded);

  final String label;
  final IconData icon;
  const _RankTab(this.label, this.icon);
}

class _RankEntry {
  final int rank;
  final String id;
  final String name;
  final String team;
  final String role;
  final int matches;
  final int runs;
  final int wickets;
  final double average;
  final double strikeRate;
  final double economy;
  final int points;
  final int wins;
  final int losses;
  final int playersCount;
  final String? tournament;

  const _RankEntry({
    required this.rank,
    required this.id,
    required this.name,
    required this.team,
    required this.role,
    required this.matches,
    required this.runs,
    required this.wickets,
    required this.average,
    required this.strikeRate,
    required this.economy,
    required this.points,
    required this.wins,
    required this.losses,
    required this.playersCount,
    this.tournament,
  });

  factory _RankEntry.fromMap(Map<String, dynamic> json, _RankTab tab, int index) {
    final player = _map(json['player']) ?? _map(json['playerId']) ?? json;
    final teamMap = _map(json['team']) ?? _map(player['team']);
    final stats = _map(json['stats']) ?? json;
    return _RankEntry(
      rank: _int(json['rank'] ?? json['position']) ?? index + 1,
      id: _text(player['_id'] ?? player['id'] ?? teamMap?['_id'] ?? teamMap?['id'] ?? json['_id'] ?? json['id']),
      name: tab == _RankTab.teams
          ? _text(teamMap?['name'] ?? json['name'] ?? json['teamName'], fallback: 'Team')
          : _text(player['name'] ?? player['playerName'] ?? json['name'], fallback: 'Player'),
      team: _text(teamMap?['shortName'] ?? teamMap?['name'] ?? json['teamName'] ?? json['team']),
      role: _text(player['role'] ?? json['role'], fallback: tab.label),
      matches: _int(json['matches'] ?? json['matchesPlayed'] ?? stats['matches'] ?? stats['matchesPlayed'] ?? stats['totalMatches'] ?? stats['played']) ?? 0,
      runs: _int(stats['runs'] ?? stats['totalRuns'] ?? json['runs']) ?? 0,
      wickets: _int(stats['wickets'] ?? stats['totalWickets'] ?? json['wickets']) ?? 0,
      average: _double(stats['average'] ?? stats['avg']) ?? 0,
      strikeRate: _double(stats['strikeRate'] ?? stats['sr']) ?? 0,
      economy: _double(stats['economy'] ?? json['economy']) ?? 0,
      points: _int(json['points'] ?? stats['points'] ?? json['score']) ?? 0,
      wins: _int(json['matchesWon'] ?? json['wins'] ?? stats['matchesWon'] ?? stats['wins']) ?? 0,
      losses: _int(json['matchesLost'] ?? json['losses'] ?? stats['matchesLost'] ?? stats['losses']) ?? 0,
      playersCount: _int(json['playersCount'] ?? stats['players'] ?? stats['playersCount']) ?? 0,
      tournament: _textOrNull(_map(json['tournament'])?['name'] ?? json['tournamentName']),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static String? _textOrNull(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int? _int(dynamic value) => int.tryParse(value?.toString() ?? '');
  static double? _double(dynamic value) => double.tryParse(value?.toString() ?? '');
}

class _RankHero extends StatelessWidget {
  final Map<_RankTab, List<Map<String, dynamic>>> data;
  const _RankHero({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalPlayers = (data[_RankTab.batsmen]?.length ?? 0) + (data[_RankTab.bowlers]?.length ?? 0);
    final totalTeams = data[_RankTab.teams]?.length ?? 0;
    final totalMvp = data[_RankTab.mvp]?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _rankBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _rankPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.leaderboard_rounded, color: _rankPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Leaderboards',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _rankText, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Real players, teams and MVP rankings',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _rankMuted, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _HeroMetric(label: 'Players', value: '$totalPlayers')),
              const SizedBox(width: 9),
              Expanded(child: _HeroMetric(label: 'Teams', value: '$totalTeams')),
              const SizedBox(width: 9),
              Expanded(child: _HeroMetric(label: 'MVP', value: '$totalMvp')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _rankHeader,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _rankBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(color: _rankText, fontSize: 15, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _rankMuted, fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final _RankEntry entry;
  final _RankTab tab;
  const _RankingCard({required this.entry, required this.tab});

  @override
  Widget build(BuildContext context) {
    final accent = _rankColor(entry.rank);
    final metrics = _metricsFor(tab, entry);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: entry.id.isEmpty || tab == _RankTab.teams
            ? null
            : () => Navigator.pushNamed(context, '/player-profile/${entry.id}'),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _rankBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _RankBadge(rank: entry.rank, color: accent),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: accent.withOpacity(0.12),
                    child: Text(entry.initials, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _rankText)),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _SmallChip(text: entry.team.isEmpty ? entry.role : entry.team, color: _rankPrimary),
                            if (entry.tournament != null) _SmallChip(text: entry.tournament!, color: const Color(0xFFF59E0B)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(tab.icon, color: accent, size: 19),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    Expanded(child: _RankMetric(metric: metrics[i])),
                    if (i != metrics.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFF59E0B);
    if (rank == 2) return const Color(0xFF64748B);
    if (rank == 3) return const Color(0xFFB45309);
    return _rankPrimary;
  }

  static List<_MetricData> _metricsFor(_RankTab tab, _RankEntry entry) {
    return switch (tab) {
      _RankTab.batsmen => [
          _MetricData('Runs', '${entry.runs}'),
          _MetricData('Pts', '${entry.points}'),
          _MetricData('SR', entry.strikeRate > 0 ? entry.strikeRate.toStringAsFixed(0) : '-'),
        ],
      _RankTab.bowlers => [
          _MetricData('Wkts', '${entry.wickets}'),
          _MetricData('Pts', '${entry.points}'),
          _MetricData('Eco', entry.economy > 0 ? entry.economy.toStringAsFixed(1) : '-'),
        ],
      _RankTab.mvp => [
          _MetricData('Pts', '${entry.points}'),
          _MetricData('Runs', '${entry.runs}'),
          _MetricData('Wkts', '${entry.wickets}'),
        ],
      _RankTab.teams => [
          _MetricData('Pts', '${entry.points}'),
          _MetricData('W-L', '${entry.wins}-${entry.losses}'),
          _MetricData('Mat', '${entry.matches}'),
          _MetricData('Ply', entry.playersCount > 0 ? '${entry.playersCount}' : '-'),
        ],
    };
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;
  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text('#$rank', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String text;
  final Color color;
  const _SmallChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  const _MetricData(this.label, this.value);
}

class _RankMetric extends StatelessWidget {
  final _MetricData metric;
  const _RankMetric({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: _rankHeader, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(metric.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _rankText, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(metric.label, style: const TextStyle(color: _rankMuted, fontSize: 9, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StateBanner extends StatelessWidget {
  final String message;
  final bool isError;
  const _StateBanner({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFEF4444) : _rankPrimary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyRankings extends StatelessWidget {
  final _RankTab tab;
  const _EmptyRankings({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 56, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text('No ${tab.label.toLowerCase()} rankings yet', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _rankText)),
            const SizedBox(height: 6),
            const Text('Rankings will appear automatically after matches are scored.', textAlign: TextAlign.center, style: TextStyle(color: _rankMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
