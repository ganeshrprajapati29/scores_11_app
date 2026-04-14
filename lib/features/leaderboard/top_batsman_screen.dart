import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import 'package:provider/provider.dart';
import '../../../providers/leaderboard_provider.dart';
import '../../../data/services/leaderboard_service.dart';

class Batsman {
  final String name;
  final String team;
  final int runs;
  final int matches;
  final double avg;
  final double sr;
  final int fours;
  final int sixes;
  final String image;
  final int rank;
  final String initials;

  Batsman({
    required this.name,
    required this.team,
    required this.runs,
    required this.matches,
    required this.avg,
    required this.sr,
    required this.fours,
    required this.sixes,
    required this.image,
    required this.rank,
    required this.initials,
  });
}

class TopBatsmanScreen extends StatefulWidget {
  const TopBatsmanScreen({super.key});

  @override
  State<TopBatsmanScreen> createState() => _TopBatsmanScreenState();
}

class _TopBatsmanScreenState extends State<TopBatsmanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  // Converted to Batsman objects instead of Map
  final List<Batsman> _batsmen = [
    Batsman(
      name: 'Virat Kohli',
      team: 'RCB',
      runs: 741,
      matches: 14,
      avg: 61.75,
      sr: 154.69,
      fours: 84,
      sixes: 38,
      image: 'https://picsum.photos/100/100',
      rank: 1,
      initials: 'VK',
    ),
    Batsman(
      name: 'Rohit Sharma',
      team: 'MI',
      runs: 512,
      matches: 12,
      avg: 42.66,
      sr: 148.54,
      fours: 56,
      sixes: 24,
      image: 'https://picsum.photos/100/100',
      rank: 2,
      initials: 'RS',
    ),
    Batsman(
      name: 'Shubman Gill',
      team: 'GT',
      runs: 489,
      matches: 11,
      avg: 44.45,
      sr: 151.16,
      fours: 52,
      sixes: 28,
      image: 'https://picsum.photos/100/100',
      rank: 3,
      initials: 'SG',
    ),
    Batsman(
      name: 'Faf du Plessis',
      team: 'RCB',
      runs: 456,
      matches: 12,
      avg: 38.00,
      sr: 152.51,
      fours: 45,
      sixes: 22,
      image: 'https://picsum.photos/100/100',
      rank: 4,
      initials: 'FP',
    ),
    Batsman(
      name: 'David Warner',
      team: 'DC',
      runs: 432,
      matches: 11,
      avg: 39.27,
      sr: 147.95,
      fours: 48,
      sixes: 18,
      image: 'https://picsum.photos/100/100',
      rank: 5,
      initials: 'DW',
    ),
    Batsman(
      name: 'KL Rahul',
      team: 'LSG',
      runs: 421,
      matches: 12,
      avg: 35.08,
      sr: 144.52,
      fours: 42,
      sixes: 20,
      image: 'https://picsum.photos/100/100',
      rank: 6,
      initials: 'KR',
    ),
    Batsman(
      name: 'Suryakumar Yadav',
      team: 'MI',
      runs: 398,
      matches: 10,
      avg: 39.80,
      sr: 160.48,
      fours: 38,
      sixes: 24,
      image: 'https://picsum.photos/100/100',
      rank: 7,
      initials: 'SY',
    ),
    Batsman(
      name: 'Hardik Pandya',
      team: 'MI',
      runs: 345,
      matches: 11,
      avg: 31.36,
      sr: 138.80,
      fours: 32,
      sixes: 18,
      image: 'https://picsum.photos/100/100',
      rank: 8,
      initials: 'HP',
    ),
  ];

  // Team badge colors
  Color _teamBgColor(String team) {
    switch (team) {
      case 'RCB':
        return const Color(0xFFFFE5E5);
      case 'MI':
        return const Color(0xFFDCEEFF);
      case 'GT':
        return const Color(0xFFE0F4FF);
      case 'DC':
        return const Color(0xFFEDE9FE);
      case 'LSG':
        return const Color(0xFFE6FAF0);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  Color _teamTextColor(String team) {
    switch (team) {
      case 'RCB':
        return const Color(0xFF991B1B);
      case 'MI':
        return const Color(0xFF1E3A8A);
      case 'GT':
        return const Color(0xFF0369A1);
      case 'DC':
        return const Color(0xFF6D28D9);
      case 'LSG':
        return const Color(0xFF15803D);
      default:
        return const Color(0xFF374151);
    }
  }

  Color _rankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFCD7F32);
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0A1628),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded,
                    color: Colors.white, size: 22),
                onPressed: () {},
              ),
            ],
            title: const Text(
              'TOP BATSMEN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: const Color(0xFF0A1628),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFFFD700),
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: const Color(0xFFFFD700),
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  tabs: const [
                    Tab(text: 'T20'),
                    Tab(text: 'ODI'),
                    Tab(text: 'Test'),
                  ],
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildPodiumHeader(),
            ),
          ),
        ],
        body: _selectedTab == 0 ? _buildPlayerList() : _buildComingSoon(),
      ),
    );
  }

  // ─── Podium Header ───────────────────────────────────────────────────────────

  Widget _buildPodiumHeader() {
    final top3 = _batsmen.take(3).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1628),
            Color(0xFF1A2F5E),
            Color(0xFF0D3B8A),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.only(top: 100, bottom: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPodiumPlayer(top3[1], 1, 2), // 2nd place
                _buildPodiumPlayer(top3[0], 0, 1), // 1st place
                _buildPodiumPlayer(top3[2], 2, 3), // 3rd place
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlayer(Batsman player, int colorIndex, int position) {
    final isFirst = position == 1;
    final avatarSize = isFirst ? 72.0 : 56.0;
    final blockHeight = isFirst ? 52.0 : (position == 2 ? 38.0 : 26.0);
    final rankColor = _rankColor(colorIndex);

    // Get last name safely
    final nameParts = player.name.split(' ');
    final lastName = nameParts.isNotEmpty ? nameParts.last : player.name;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: rankColor, width: 3),
                color: Colors.white.withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: ClipOval(
                child: Image.network(
                  player.image,
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white.withOpacity(0.1),
                      alignment: Alignment.center,
                      child: Text(
                        player.initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: isFirst ? 18 : 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rankColor,
                  border: Border.all(color: const Color(0xFF0A1628), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$position',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          lastName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: isFirst ? 13 : 11,
            letterSpacing: 0.2,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${player.runs} runs',
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        // Podium block
        Container(
          width: isFirst ? 76 : 60,
          height: blockHeight,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            color: rankColor.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  // ─── Player List ─────────────────────────────────────────────────────────────

  Widget _buildPlayerList() {
    return Column(
      children: [
        // Header row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _headerCell('#', flex: 1),
              _headerCell('Player', flex: 4, align: TextAlign.left),
              _headerCell('M', flex: 1),
              _headerCell('Runs', flex: 2),
              _headerCell('Avg', flex: 2),
              _headerCell('SR', flex: 2),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: _batsmen.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0F1F3)),
            itemBuilder: (context, index) {
              return _buildPlayerRow(_batsmen[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(Batsman player, int index) {
    final isTop3 = index < 3;
    final rankColor = _rankColor(index);

    return Animate(
      effects: [FadeEffect(duration: 300.ms, delay: (index * 50).ms)],
      child: Container(
        color: isTop3 ? rankColor.withOpacity(0.04) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 28,
                child: isTop3
                    ? Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rankColor,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
              ),

              // Player info
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _teamBgColor(player.team),
                      ),
                      alignment: Alignment.center,
                      child: ClipOval(
                        child: Image.network(
                          player.image,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: _teamBgColor(player.team),
                              alignment: Alignment.center,
                              child: Text(
                                player.initials,
                                style: TextStyle(
                                  color: _teamTextColor(player.team),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              color: _teamBgColor(player.team),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              player.team,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _teamTextColor(player.team),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // M
              _statCell(player.matches.toString()),

              // Runs (highlighted)
              Expanded(
                flex: 2,
                child: Text(
                  player.runs.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A5FB4),
                  ),
                ),
              ),

              // Avg
              _statCell(player.avg.toStringAsFixed(1)),

              // SR
              _statCell(player.sr.toStringAsFixed(1)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Coming Soon ─────────────────────────────────────────────────────────────

  Widget _buildComingSoon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_cricket_rounded,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Data coming soon',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _headerCell(String text,
      {int flex = 1, TextAlign align = TextAlign.center}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9CA3AF),
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _statCell(String text) {
    return Expanded(
      flex: 2,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}