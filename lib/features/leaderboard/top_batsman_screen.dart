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

  final List<Batsman> _batsmen = [
    Batsman(name: 'Virat Kohli', team: 'RCB', runs: 741, matches: 14, avg: 61.75, sr: 154.69, fours: 84, sixes: 38, image: 'https://picsum.photos/100/100', rank: 1, initials: 'VK'),
    Batsman(name: 'Rohit Sharma', team: 'MI', runs: 512, matches: 12, avg: 42.66, sr: 148.54, fours: 56, sixes: 24, image: 'https://picsum.photos/100/100', rank: 2, initials: 'RS'),
    Batsman(name: 'Shubman Gill', team: 'GT', runs: 489, matches: 11, avg: 44.45, sr: 151.16, fours: 52, sixes: 28, image: 'https://picsum.photos/100/100', rank: 3, initials: 'SG'),
    Batsman(name: 'Faf du Plessis', team: 'RCB', runs: 456, matches: 12, avg: 38.00, sr: 152.51, fours: 45, sixes: 22, image: 'https://picsum.photos/100/100', rank: 4, initials: 'FP'),
    Batsman(name: 'David Warner', team: 'DC', runs: 432, matches: 11, avg: 39.27, sr: 147.95, fours: 48, sixes: 18, image: 'https://picsum.photos/100/100', rank: 5, initials: 'DW'),
    Batsman(name: 'KL Rahul', team: 'LSG', runs: 421, matches: 12, avg: 35.08, sr: 144.52, fours: 42, sixes: 20, image: 'https://picsum.photos/100/100', rank: 6, initials: 'KR'),
    Batsman(name: 'Suryakumar Yadav', team: 'MI', runs: 398, matches: 10, avg: 39.80, sr: 160.48, fours: 38, sixes: 24, image: 'https://picsum.photos/100/100', rank: 7, initials: 'SY'),
    Batsman(name: 'Hardik Pandya', team: 'MI', runs: 345, matches: 11, avg: 31.36, sr: 138.80, fours: 32, sixes: 18, image: 'https://picsum.photos/100/100', rank: 8, initials: 'HP'),
  ];

  Color _teamBgColor(String team) {
    switch (team) {
      case 'RCB': return const Color(0xFFFFE5E5);
      case 'MI':  return const Color(0xFFDCEEFF);
      case 'GT':  return const Color(0xFFE0F4FF);
      case 'DC':  return const Color(0xFFEDE9FE);
      case 'LSG': return const Color(0xFFE6FAF0);
      default:    return const Color(0xFFF0F0F0);
    }
  }

  Color _teamTextColor(String team) {
    switch (team) {
      case 'RCB': return const Color(0xFF991B1B);
      case 'MI':  return const Color(0xFF1E3A8A);
      case 'GT':  return const Color(0xFF0369A1);
      case 'DC':  return const Color(0xFF6D28D9);
      case 'LSG': return const Color(0xFF15803D);
      default:    return const Color(0xFF374151);
    }
  }

  Color _rankColor(int index) {
    switch (index) {
      case 0: return const Color(0xFFFFD700);
      case 1: return const Color(0xFFC0C0C0);
      case 2: return const Color(0xFFCD7F32);
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() => _selectedTab = _tabController.index);
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
            expandedHeight: 340,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0A1628),
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 17),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            title: AnimatedOpacity(
              opacity: innerBoxIsScrolled ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Text(
                'TOP BATSMEN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628),
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08), width: 1),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFFFD700),
                  unselectedLabelColor: Colors.white38,
                  indicatorColor: const Color(0xFFFFD700),
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  tabs: const [
                    Tab(text: 'T20'),
                    Tab(text: 'ODI'),
                    Tab(text: 'TEST'),
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

  // ─── Podium Header ────────────────────────────────────────────────────────

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
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700).withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // Title
          Positioned(
            top: 56,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                        size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'TOP BATSMEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.emoji_events_rounded,
                        color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                        size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'IPL 2024 Season',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Podium players
          Padding(
            padding: const EdgeInsets.only(top: 96, bottom: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPodiumPlayer(top3[1], 1, 2),
                _buildPodiumPlayer(top3[0], 0, 1),
                _buildPodiumPlayer(top3[2], 2, 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlayer(Batsman player, int colorIndex, int position) {
    final isFirst = position == 1;
    final avatarSize = isFirst ? 74.0 : 58.0;
    final blockHeight = isFirst ? 54.0 : (position == 2 ? 38.0 : 26.0);
    final rankColor = _rankColor(colorIndex);
    final nameParts = player.name.split(' ');
    final lastName = nameParts.isNotEmpty ? nameParts.last : player.name;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown for 1st place
        if (isFirst)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Icon(Icons.workspace_premium_rounded,
                color: const Color(0xFFFFD700), size: 22),
          ),

        // Avatar
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: rankColor, width: isFirst ? 3 : 2.5),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withValues(alpha: 0.4),
                    blurRadius: isFirst ? 12 : 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  player.image,
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: Text(
                      player.initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: isFirst ? 20 : 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Rank badge
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
                  boxShadow: [
                    BoxShadow(
                        color: rankColor.withValues(alpha: 0.5),
                        blurRadius: 4),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$position',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_cricket_rounded,
                color: Colors.white.withValues(alpha: 0.5), size: 9),
            const SizedBox(width: 3),
            Text(
              '${player.runs} runs',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Podium block
        Container(
          width: isFirst ? 78 : 62,
          height: blockHeight,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                rankColor.withValues(alpha: 0.9),
                rankColor.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: rankColor.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            player.team,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Player List ──────────────────────────────────────────────────────────

  Widget _buildPlayerList() {
    return Column(
      children: [
        // Header row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
        Container(height: 1, color: const Color(0xFFEEF0F3)),

        // List
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _batsmen.length,
            separatorBuilder: (_, __) =>
                Container(height: 1, color: const Color(0xFFF3F4F6)),
            itemBuilder: (context, index) =>
                _buildPlayerRow(_batsmen[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(Batsman player, int index) {
    final isTop3 = index < 3;
    final rankColor = _rankColor(index);

    return Animate(
      effects: [
        FadeEffect(duration: 300.ms, delay: (index * 55).ms),
        SlideEffect(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
            duration: 280.ms,
            delay: (index * 55).ms),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: isTop3
              ? rankColor.withValues(alpha: 0.04)
              : Colors.white,
          border: isTop3
              ? Border(
                  left: BorderSide(
                      color: rankColor.withValues(alpha: 0.5), width: 3))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                          boxShadow: [
                            BoxShadow(
                              color: rankColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                          color: Color(0xFFBCC0CC),
                          fontWeight: FontWeight.w500,
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _teamBgColor(player.team),
                        border: Border.all(
                          color: _teamTextColor(player.team)
                              .withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          player.image,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
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
                          ),
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
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                              letterSpacing: -0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _teamBgColor(player.team),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              player.team,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _teamTextColor(player.team),
                                letterSpacing: 0.3,
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
                child: Container(
                  alignment: Alignment.center,
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

  // ─── Coming Soon ──────────────────────────────────────────────────────────

  Widget _buildComingSoon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sports_cricket_rounded,
                size: 52, color: Colors.grey[300]),
          ),
          const SizedBox(height: 20),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Data will be available soon',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _headerCell(String text,
      {int flex = 1, TextAlign align = TextAlign.center}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFADB5BD),
          letterSpacing: 0.5,
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
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}