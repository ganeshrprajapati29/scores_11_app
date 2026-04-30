import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/user_service.dart';
import '../../providers/auth_provider.dart';

class CricketProfileScreen extends StatefulWidget {
  const CricketProfileScreen({super.key});

  @override
  State<CricketProfileScreen> createState() => _CricketProfileScreenState();
}

class _CricketProfileScreenState extends State<CricketProfileScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic>? _cricketStats;
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _matches = [];
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Matches', 'Tournaments', 'Practice'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final statsResult = await _userService.getCricketStats();
      if (statsResult['success']) {
        setState(() {
          _cricketStats = jsonDecode(statsResult['data']);
        });
      }

      final achievementsResult = await _userService.getAchievements();
      if (achievementsResult['success']) {
        final data = jsonDecode(achievementsResult['data']);
        setState(() {
          _achievements =
              List<Map<String, dynamic>>.from(data['achievements'] ?? []);
        });
      }

      _teams = [
        {'name': 'Delhi Strikers', 'role': 'Captain', 'logo': '🏏'},
        {'name': 'Mumbai Kings', 'role': 'Player', 'logo': '👑'},
      ];

      _matches = [
        {
          'id': '1',
          'opponent': 'Chennai Super',
          'date': '2024-01-15',
          'result': 'Won',
          'score': '145/2',
          'venue': 'Delhi',
        },
        {
          'id': '2',
          'opponent': 'Kolkata Knight',
          'date': '2024-01-10',
          'result': 'Lost',
          'score': '98/10',
          'venue': 'Kolkata',
        },
        {
          'id': '3',
          'opponent': 'Bangalore Royal',
          'date': '2024-01-05',
          'result': 'Won',
          'score': '167/5',
          'venue': 'Bangalore',
        },
      ];
    } catch (e) {
      debugPrint('Error loading cricket profile: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.5))
          : Column(
              children: [
                _ProfileHeader(
                  user: user,
                  cricketStats: _cricketStats,
                ),
                _FilterBar(
                  filters: _filters,
                  selected: _selectedFilter,
                  onSelected: (f) => setState(() => _selectedFilter = f),
                ),
                _TabBar(controller: _tabController),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _OverviewTab(
                        cricketStats: _cricketStats,
                        matches: _matches,
                        achievements: _achievements,
                        tabController: _tabController,
                      ),
                      _MatchesTab(matches: _matches),
                      _StatsTab(cricketStats: _cricketStats),
                      _TeamsTab(teams: _teams),
                      _AchievementsTab(achievements: _achievements),
                      const _InsightsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      title: const Text(
        'Cricket Profile',
        style: TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share_outlined, color: AppColors.primary),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.qr_code_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pushNamed(context, '/qr-code'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── Profile Header ──────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final Map<String, dynamic>? cricketStats;

  const _ProfileHeader({required this.user, required this.cricketStats});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          _Avatar(user: user),
          const SizedBox(width: 16),
          Expanded(child: _HeaderInfo(user: user, cricketStats: cricketStats)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final dynamic user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final hasImage = user?.avatar?.url != null;
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                user!.avatar!.url!,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(user: user),
              )
            : _AvatarFallback(user: user),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final dynamic user;

  const _AvatarFallback({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          user?.name?.substring(0, 1).toUpperCase() ?? 'U',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final dynamic user;
  final Map<String, dynamic>? cricketStats;

  const _HeaderInfo({required this.user, required this.cricketStats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user?.name ?? 'Player',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user?.cricketProfile?['playerType'] ?? 'All Rounder',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatPill(
              label: 'Matches',
              value: cricketStats?['matchesPlayed']?.toString() ?? '0',
            ),
            const SizedBox(width: 8),
            _StatPill(
              label: 'Runs',
              value: cricketStats?['totalRuns']?.toString() ?? '0',
            ),
            const SizedBox(width: 8),
            _StatPill(
              label: 'Wickets',
              value: cricketStats?['totalWickets']?.toString() ?? '0',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Tab Bar ─────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController controller;

  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.primary,
        unselectedLabelColor: const Color(0xFF999999),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Matches'),
          Tab(text: 'Stats'),
          Tab(text: 'Teams'),
          Tab(text: 'Achievements'),
          Tab(text: 'Insights'),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic>? cricketStats;
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> achievements;
  final TabController tabController;

  const _OverviewTab({
    required this.cricketStats,
    required this.matches,
    required this.achievements,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'Performance Summary'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PerformanceCard(
                  title: 'Batting',
                  icon: Icons.sports_cricket_rounded,
                  stats: [
                    {
                      'label': 'Avg',
                      'value': cricketStats?['battingAverage']?.toString() ??
                          '0.0'
                    },
                    {
                      'label': 'SR',
                      'value':
                          cricketStats?['strikeRate']?.toString() ?? '0.0'
                    },
                    {
                      'label': 'HS',
                      'value':
                          cricketStats?['highestScore']?.toString() ?? '0'
                    },
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PerformanceCard(
                  title: 'Bowling',
                  icon: Icons.rotate_right_rounded,
                  stats: [
                    {
                      'label': 'Avg',
                      'value': cricketStats?['bowlingAverage']?.toString() ??
                          '0.0'
                    },
                    {
                      'label': 'Eco',
                      'value':
                          cricketStats?['economy']?.toString() ?? '0.0'
                    },
                    {
                      'label': 'BB',
                      'value':
                          cricketStats?['bestBowling']?.toString() ?? '0/0'
                    },
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel(label: 'Recent Matches'),
              TextButton(
                onPressed: () => tabController.animateTo(1),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('See All',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...matches.take(3).map((m) => _MatchCard(match: m)),
          const SizedBox(height: 24),
          const _SectionLabel(label: 'Trophies & Awards'),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: achievements.isEmpty
                ? const Center(
                    child: Text('No achievements yet',
                        style: TextStyle(
                            color: Color(0xFF999999), fontSize: 13)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final a = achievements[index];
                      return _TrophyItem(name: a['name'] ?? 'Achievement');
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrophyItem extends StatelessWidget {
  final String name;

  const _TrophyItem({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.amber.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Colors.amber, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Matches Tab ─────────────────────────────────────────────────────────────

class _MatchesTab extends StatelessWidget {
  final List<Map<String, dynamic>> matches;

  const _MatchesTab({required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(
          child: Text('No matches found',
              style: TextStyle(color: Color(0xFF999999))));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: matches.length,
      itemBuilder: (context, index) => _MatchCard(match: matches[index]),
    );
  }
}

// ─── Match Card ───────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isWin = match['result'] == 'Won';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'vs ${match['opponent']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isWin
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  match['result'] ?? '',
                  style: TextStyle(
                    color: isWin
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MatchMeta(
                  icon: Icons.calendar_today_rounded,
                  text: match['date'] ?? ''),
              const SizedBox(width: 16),
              _MatchMeta(
                  icon: Icons.location_on_rounded,
                  text: match['venue'] ?? ''),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  match['score'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MatchMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFFAAAAAA)),
        const SizedBox(width: 3),
        Text(text,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Stats Tab ────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final Map<String, dynamic>? cricketStats;

  const _StatsTab({required this.cricketStats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'Batting Statistics'),
          const SizedBox(height: 12),
          _StatsTable(
            stats: [
              {
                'label': 'Matches',
                'value':
                    cricketStats?['matchesPlayed']?.toString() ?? '0'
              },
              {
                'label': 'Innings',
                'value': cricketStats?['innings']?.toString() ?? '0'
              },
              {
                'label': 'Runs',
                'value': cricketStats?['totalRuns']?.toString() ?? '0'
              },
              {
                'label': 'Average',
                'value':
                    cricketStats?['battingAverage']?.toString() ?? '0.0'
              },
              {
                'label': 'Strike Rate',
                'value':
                    cricketStats?['strikeRate']?.toString() ?? '0.0'
              },
              {
                'label': 'Highest Score',
                'value':
                    cricketStats?['highestScore']?.toString() ?? '0'
              },
              {
                'label': 'Centuries',
                'value': cricketStats?['centuries']?.toString() ?? '0'
              },
              {
                'label': 'Half Centuries',
                'value':
                    cricketStats?['halfCenturies']?.toString() ?? '0'
              },
              {
                'label': 'Fours',
                'value': cricketStats?['fours']?.toString() ?? '0'
              },
              {
                'label': 'Sixes',
                'value': cricketStats?['sixes']?.toString() ?? '0'
              },
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel(label: 'Bowling Statistics'),
          const SizedBox(height: 12),
          _StatsTable(
            stats: [
              {
                'label': 'Wickets',
                'value':
                    cricketStats?['totalWickets']?.toString() ?? '0'
              },
              {
                'label': 'Best Figures',
                'value':
                    cricketStats?['bestBowling']?.toString() ?? '0/0'
              },
              {
                'label': 'Economy',
                'value': cricketStats?['economy']?.toString() ?? '0.0'
              },
              {
                'label': 'Bowling Avg',
                'value':
                    cricketStats?['bowlingAverage']?.toString() ?? '0.0'
              },
              {
                'label': '5 Wicket Hauls',
                'value':
                    cricketStats?['fiveWicketHauls']?.toString() ?? '0'
              },
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsTable extends StatelessWidget {
  final List<Map<String, String>> stats;

  const _StatsTable({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: stats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            final isLast = index == stats.length - 1;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: index.isEven
                    ? Colors.white
                    : const Color(0xFFFAFBFD),
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(
                            color: Color(0xFFF0F0F0), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stat['label'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF777777),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    stat['value'] ?? '0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Performance Card ─────────────────────────────────────────────────────────

class _PerformanceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Map<String, String>> stats;

  const _PerformanceCard({
    required this.title,
    required this.icon,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...stats.map(
            (stat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stat['label'] ?? '',
                    style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    stat['value'] ?? '0',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Teams Tab ────────────────────────────────────────────────────────────────

class _TeamsTab extends StatelessWidget {
  final List<Map<String, dynamic>> teams;

  const _TeamsTab({required this.teams});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  team['logo'] ?? '🏏',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            title: Text(
              team['name'] ?? 'Team',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1A1A2E),
              ),
            ),
            subtitle: Text(
              team['role'] ?? 'Player',
              style: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chevron_right_rounded,
                  color: AppColors.primary, size: 18),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
}

// ─── Achievements Tab ─────────────────────────────────────────────────────────

class _AchievementsTab extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;

  const _AchievementsTab({required this.achievements});

  static const List<Map<String, dynamic>> _mockAchievements = [
    {
      'icon': Icons.star_rounded,
      'color': Color(0xFF1565C0),
      'title': 'First Match'
    },
    {
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFC62828),
      'title': 'Hot Streak'
    },
    {
      'icon': Icons.military_tech_rounded,
      'color': Color(0xFF6A1B9A),
      'title': 'Champion'
    },
    {
      'icon': Icons.bolt_rounded,
      'color': Color(0xFFE65100),
      'title': 'Quick 50'
    },
    {
      'icon': Icons.shield_rounded,
      'color': Color(0xFF2E7D32),
      'title': 'Best Defense'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final total = achievements.length + _mockAchievements.length;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: total,
      itemBuilder: (context, index) {
        if (index < achievements.length) {
          final a = achievements[index];
          return _AchievementCard(
            icon: Icons.emoji_events_rounded,
            color: Colors.amber,
            title: a['name'] ?? 'Achievement',
            description: a['description'] ?? '',
          );
        }
        final mock = _mockAchievements[index - achievements.length];
        return _AchievementCard(
          icon: mock['icon'] as IconData,
          color: mock['color'] as Color,
          title: mock['title'] as String,
          description: '',
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _AchievementCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              description,
              style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Insights Tab ─────────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  const _InsightsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Placeholder
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart_rounded,
                    size: 40, color: AppColors.primary.withOpacity(0.3)),
                const SizedBox(height: 8),
                const Text(
                  'Performance Trend',
                  style: TextStyle(
                    color: Color(0xFFBBBBBB),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel(label: 'Insights'),
          const SizedBox(height: 12),
          _InsightCard(
            title: 'Best Performance',
            description: 'Your best performance was on Sunday matches',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF2E7D32),
          ),
          _InsightCard(
            title: 'Consistency',
            description: 'You maintain a 75% win rate in tournaments',
            icon: Icons.analytics_rounded,
            color: const Color(0xFF1565C0),
          ),
          _InsightCard(
            title: 'Most Runs',
            description: 'You score most of your runs in overs 10-20',
            icon: Icons.timer_rounded,
            color: const Color(0xFFE65100),
          ),
          const SizedBox(height: 24),
          const _SectionLabel(label: 'Reports'),
          const SizedBox(height: 12),
          _ReportTile(
            icon: Icons.picture_as_pdf_rounded,
            iconColor: const Color(0xFFC62828),
            title: 'Download Performance Report',
            subtitle: 'Get detailed PDF report',
            trailing: Icons.download_rounded,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _ReportTile(
            icon: Icons.share_rounded,
            iconColor: AppColors.primary,
            title: 'Share Profile',
            subtitle: 'Share your cricket profile',
            trailing: Icons.share_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _InsightCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback onTap;

  const _ReportTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            Icon(trailing, color: const Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }
}