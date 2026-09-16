import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class LiveMatchScreen extends StatefulWidget {
  final String matchId;

  const LiveMatchScreen({super.key, required this.matchId});

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  bool _isScoring = false;
  String _currentInnings = 'First Innings';

  final Map<String, dynamic> _matchData = {
    'team1': {
      'name': 'Mumbai Indians',
      'shortName': 'MI',
      'score': '145/3',
      'overs': '14.2',
      'logoAsset': 'assets/images/teams/team1_logo.png',
    },
    'team2': {
      'name': 'Chennai Super Kings',
      'shortName': 'CSK',
      'score': '0/0',
      'overs': '0',
      'logoAsset': 'assets/images/teams/team2_logo.png',
    },
    'target': '186',
    'required': '41 runs in 34 balls',
    'crR': '10.14',
    'extras': {'total': 8, 'wides': 3, 'noballs': 1, 'byes': 4, 'legByes': 0},
    'lastWicket': 'Ishan Kishan (45)',
    'currentOver': [1, 4, 0, 6, 1, 2],
    'batsmen': [
      {'name': 'Rohit Sharma', 'runs': 72, 'balls': 45, 'fours': 8, 'sixes': 3, 'strike': 160.0},
      {'name': 'Hardik Pandya', 'runs': 35, 'balls': 20, 'fours': 3, 'sixes': 3, 'strike': 175.0},
    ],
    'bowler': {
      'name': 'Deepak Chahar',
      'role': 'Right Arm Medium',
      'overs': '2.2',
      'runs': 18,
      'wickets': 1,
      'economy': 8.10,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeroHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: _buildScoreCard().animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                ),
                _buildCurrentOverCard().animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),
                _buildBattingCard().animate().fadeIn(delay: 180.ms),
                const SizedBox(height: 16),
                _buildExtrasRow().animate().fadeIn(delay: 240.ms),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // -------------------------------------------------------------------
  // Header: dark stadium-night hero — back button, logo, LIVE pill, share
  // -------------------------------------------------------------------
  Widget _buildHeroHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF061029), Color(0xFF0B2452), Color(0xFF123B7A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        image: DecorationImage(
          image: const AssetImage('score 11/Live Match Card 1024 x 576 PNG.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          opacity: 0.34,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: -6,
            child: Icon(Icons.grid_view_rounded,
                color: Colors.white.withValues(alpha: 0.18), size: 30),
          ),
          Positioned(
            right: 0,
            top: -6,
            child: Icon(Icons.grid_view_rounded,
                color: Colors.white.withValues(alpha: 0.18), size: 30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeroCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.sports_cricket_rounded, color: AppColors.primary),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.live,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 7),
                        SizedBox(width: 5),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeroCircleButton(icon: Icons.share_outlined, onTap: () {}),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Dark gradient score card
  // -------------------------------------------------------------------
  Widget _buildScoreCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('score 11/Live Match Card 1024 x 576 PNG.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                opacity: 0.24,
              ),
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildTeamScoreColumn(_matchData['team1'])),
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(child: _buildTeamScoreColumn(_matchData['team2'], alignRight: true)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MI chose to bat',
                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _buildLiveInfo('Target', _matchData['target'], AppColors.textPrimary)),
                Container(width: 1, height: 32, color: const Color(0xFFE4E7EC)),
                Expanded(child: _buildLiveInfo('Required', _matchData['required'], AppColors.error)),
                Container(width: 1, height: 32, color: const Color(0xFFE4E7EC)),
                Expanded(child: _buildLiveInfo('CRR', _matchData['crR'], const Color(0xFF16A34A))),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: AppColors.primary, size: 15),
                const SizedBox(width: 6),
                Text(
                  'Last Wicket: ',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                Text(
                  _matchData['lastWicket'],
                  style: const TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScoreColumn(Map<String, dynamic> team, {bool alignRight = false}) {
    final logo = Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Image.asset(
        team['logoAsset'],
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, color: AppColors.primary),
      ),
    );
    final texts = Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          team['shortName'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
        ),
        Text(
          team['score'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          '${team['overs']} overs',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
        ),
      ],
    );
    return Row(
      mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignRight
          ? [Flexible(child: texts), const SizedBox(width: 8), logo]
          : [logo, const SizedBox(width: 8), Flexible(child: texts)],
    );
  }

  Widget _buildLiveInfo(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Current Over ball-chips + bowler row
  // -------------------------------------------------------------------
  Widget _buildCurrentOverCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Over',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
              ),
              Text(
                '${_matchData['team1']['overs']} overs',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: (_matchData['currentOver'] as List).length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final over = _matchData['currentOver'] as List;
                if (index >= over.length) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE4E7EC), width: 1.4),
                    ),
                  );
                }
                final ball = over[index];
                final isWicket = ball == 'W';
                final isSix = ball == 6;
                final isFour = ball == 4;
                final isHighlighted = isWicket || isSix || isFour;
                final ballColor = isWicket
                    ? AppColors.error
                    : isSix
                        ? const Color(0xFF16A34A)
                        : isFour
                            ? AppColors.primary
                            : const Color(0xFF64748B);
                return Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isHighlighted ? ballColor : ballColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isHighlighted ? ballColor : ballColor.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    ball.toString(),
                    style: TextStyle(
                      color: isHighlighted ? Colors.white : ballColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE4E7EC)),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Color(0xFFF1F3F6), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bowler',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10.5),
                    ),
                    Text(
                      _matchData['bowler']['name'],
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    Text(
                      _matchData['bowler']['role'],
                      style: TextStyle(color: Colors.grey[500], fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              _bowlerStatCol('Overs', _matchData['bowler']['overs'].toString()),
              _bowlerStatCol('Runs', _matchData['bowler']['runs'].toString()),
              _bowlerStatCol('Wickets', _matchData['bowler']['wickets'].toString()),
              _bowlerStatCol(
                  'Economy', (_matchData['bowler']['economy'] as num).toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bowlerStatCol(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Batting card: striker highlighted, R / B / 4s / 6s / SR columns
  // -------------------------------------------------------------------
  Widget _buildBattingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Batting',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          ...(_matchData['batsmen'] as List).asMap().entries.map<Widget>((entry) {
            final batsman = entry.value;
            final isStriker = entry.key == 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: Color(0xFFF1F3F6), shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                      ),
                      if (isStriker)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batsman['name'],
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        if (isStriker) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'On Strike',
                              style: TextStyle(color: AppColors.primary, fontSize: 9.5, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _battingStatCol('Runs', '${batsman['runs']}'),
                  _battingStatCol('Balls', '${batsman['balls']}'),
                  _battingStatCol('4s', '${batsman['fours']}'),
                  _battingStatCol('6s', '${batsman['sixes']}'),
                  _battingStatCol(
                    'SR',
                    (batsman['strike'] as double).toStringAsFixed(2),
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _battingStatCol(String label, String value, {Color valueColor = AppColors.textPrimary}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: valueColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _columnHeader(String label) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _columnValue(String value) {
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Extras row
  // -------------------------------------------------------------------
  Widget _buildExtrasRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extras',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildExtraItem('Total', _matchData['extras']['total'].toString(), Icons.assignment_rounded, AppColors.primary),
              _buildExtraItem('Wides', _matchData['extras']['wides'].toString(), Icons.compare_arrows_rounded, const Color(0xFF7C3AED)),
              _buildExtraItem('No Balls', _matchData['extras']['noballs'].toString(), Icons.block_rounded, AppColors.error),
              _buildExtraItem('Byes', _matchData['extras']['byes'].toString(), Icons.directions_run_rounded, const Color(0xFF0891B2)),
              _buildExtraItem('Leg Byes', _matchData['extras']['legByes'].toString(), Icons.sports_cricket_rounded, const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtraItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14101828),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Bottom: static icon tab row + Scorecard / Add Ball action bar
  // -------------------------------------------------------------------
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bottomTabIcon(Icons.podcasts_rounded, 'Live', selected: true),
                  _bottomTabIcon(Icons.bar_chart_rounded, 'Scorecard'),
                  _bottomTabIcon(Icons.chat_bubble_outline_rounded, 'Commentary'),
                  _bottomTabIcon(Icons.insights_rounded, 'Stats'),
                  _bottomTabIcon(Icons.info_outline_rounded, 'Info'),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/scorecard', arguments: widget.matchId);
                      },
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: const Text('Scorecard'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/score-entry', arguments: widget.matchId);
                      },
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add Ball'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomTabIcon(IconData icon, String label, {bool selected = false}) {
    final color = selected ? AppColors.primary : Colors.grey[400];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

/// Circular translucent icon button used on the dark stadium hero header.
class _HeroCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeroCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.textPrimary, size: 19),
        ),
      ),
    );
  }
}
