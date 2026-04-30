import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_appbar.dart';

// ─── Design tokens (matching community feed) ─────────────────────────────────
const _kBg = Color(0xFFF8F9FA);
const _kBorder = Color(0xFFEEEFF2);
const _kTextPrimary = Color(0xFF0D1117);
const _kTextSecondary = Color(0xFF6B7280);
const _kTextHint = Color(0xFF9CA3AF);
const _kShadow = Color(0x0A000000);
const _kCardRadius = 16.0;

class PointsTableScreen extends StatelessWidget {
  final String tournamentId;
  
  const PointsTableScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> teams = [
      {'name': 'Mumbai Indians', 'matches': 10, 'won': 7, 'lost': 3, 'tied': 0, 'nr': 0, 'points': 14, 'nrRate': 1.245, 'logo': 'https://picsum.photos/40/40', 'color': 0xFF004BA0},
      {'name': 'Chennai Super Kings', 'matches': 10, 'won': 6, 'lost': 4, 'tied': 0, 'nr': 0, 'points': 12, 'nrRate': 1.123, 'logo': 'https://picsum.photos/40/40', 'color': 0xFFFFC107},
      {'name': 'Delhi Capitals', 'matches': 10, 'won': 6, 'lost': 4, 'tied': 0, 'nr': 0, 'points': 12, 'nrRate': 0.987, 'logo': 'https://picsum.photos/40/40', 'color': 0xFF0078FF},
      {'name': 'Kolkata Knight Riders', 'matches': 10, 'won': 5, 'lost': 5, 'tied': 0, 'nr': 0, 'points': 10, 'nrRate': 1.056, 'logo': 'https://picsum.photos/40/40', 'color': 0xFF3A225D},
      {'name': 'Royal Challengers Bangalore', 'matches': 10, 'won': 4, 'lost': 6, 'tied': 0, 'nr': 0, 'points': 8, 'nrRate': 0.945, 'logo': 'https://picsum.photos/40/40', 'color': 0xFFD11D27},
      {'name': 'Punjab Kings', 'matches': 10, 'won': 3, 'lost': 7, 'tied': 0, 'nr': 0, 'points': 6, 'nrRate': 0.876, 'logo': 'https://picsum.photos/40/40', 'color': 0xFFE31B23},
      {'name': 'Rajasthan Royals', 'matches': 10, 'won': 5, 'lost': 5, 'tied': 0, 'nr': 0, 'points': 10, 'nrRate': 0.765, 'logo': 'https://picsum.photos/40/40', 'color': 0xFFE03A3A},
      {'name': 'Sunrisers Hyderabad', 'matches': 10, 'won': 4, 'lost': 6, 'tied': 0, 'nr': 0, 'points': 8, 'nrRate': -0.234, 'logo': 'https://picsum.photos/40/40', 'color': 0xFFF78C25},
    ];

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Tournament Info Card
          _buildTournamentInfoCard(),
          const SizedBox(height: 12),
          
          // Points Table Header
          _buildTableHeader(),
          
          // Points Table Body
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 800));
              },
              color: AppColors.primary,
              strokeWidth: 2.5,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  final isPlayoff = index < 4;
                  
                  return _buildTeamRow(team, index, isPlayoff);
                },
              ),
            ),
          ),
          
          // Legend
          _buildLegend(),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  // ─── AppBar (matching community feed style) ────────────────────────────────
  
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary, size: 16),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.leaderboard_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Points Table',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: _kTextSecondary, size: 22),
          onPressed: () => _showPointsExplanation(context),
        ),
      ],
    );
  }

  // ─── Tournament Info Card ───────────────────────────────────────────────────
  
  Widget _buildTournamentInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: const [
          BoxShadow(
            color: _kShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded, 
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IPL 2024',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '8 Teams • 14 Matches Each',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'League Stage',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  // ─── Table Header ──────────────────────────────────────────────────────────
  
  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#', 
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text('TEAM', 
                style: TextStyle(color: _kTextSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          _buildHeaderCell('M'),
          _buildHeaderCell('W'),
          _buildHeaderCell('L'),
          _buildHeaderCell('T'),
          _buildHeaderCell('NR'),
          _buildHeaderCell('PTS', isPrimary: true),
          _buildHeaderCell('NRR', isPrimary: true),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool isPrimary = false}) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isPrimary ? AppColors.primary : _kTextSecondary,
          fontSize: 11,
        ),
      ),
    );
  }

  // ─── Team Row ──────────────────────────────────────────────────────────────
  
  Widget _buildTeamRow(Map<String, dynamic> team, int index, bool isPlayoff) {
    final teamColor = Color(team['color'] ?? AppColors.primary.hashCode);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to team details
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isPlayoff 
                        ? AppColors.primary.withOpacity(0.1)
                        : _kBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPlayoff ? AppColors.primary : _kBorder,
                      width: isPlayoff ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isPlayoff ? AppColors.primary : _kTextSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                
                // Team Info
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: teamColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            team['name'].toString().substring(0, 1),
                            style: TextStyle(
                              color: teamColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          team['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _kTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stats
                _buildStatCell(team['matches'].toString()),
                _buildStatCell(team['won'].toString(), 
                    color: const Color(0xFF10B981)),
                _buildStatCell(team['lost'].toString(), 
                    color: const Color(0xFFEF4444)),
                _buildStatCell(team['tied'].toString()),
                _buildStatCell(team['nr'].toString()),
                _buildStatCell(team['points'].toString(), 
                    isBold: true, isPrimary: true),
                _buildStatCell(team['nrRate'].toStringAsFixed(3),
                    color: (team['nrRate'] as double) >= 0 
                        ? const Color(0xFF10B981) 
                        : const Color(0xFFEF4444)),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 260.ms, delay: (index * 40).ms)
      .slideX(begin: 0.02, end: 0, duration: 260.ms);
  }

  Widget _buildStatCell(String text, {Color? color, bool isBold = false, bool isPrimary = false}) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isPrimary ? AppColors.primary : (color ?? _kTextPrimary),
          fontWeight: isBold || isPrimary ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  // ─── Legend ─────────────────────────────────────────────────────────────────
  
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Qualified', AppColors.primary),
            const SizedBox(width: 24),
            _buildLegendItem('Playoffs Zone', AppColors.primary.withOpacity(0.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: _kTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── FAB ───────────────────────────────────────────────────────────────────
  
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'points_table_fab_${DateTime.now().millisecondsSinceEpoch}',
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share points table coming soon'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.share_rounded, size: 20),
      label: const Text('Share Table',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  // ─── Explanation Modal ─────────────────────────────────────────────────────
  
  void _showPointsExplanation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Points System',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildExplanationRow('Win', '2 Points', AppColors.primary),
            _buildExplanationRow('Tie / No Result', '1 Point', const Color(0xFFF59E0B)),
            _buildExplanationRow('Loss', '0 Points', const Color(0xFFEF4444)),
            const SizedBox(height: 20),
            const Divider(color: _kBorder),
            const SizedBox(height: 16),
            const Text(
              'Net Run Rate (NRR)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'NRR = (Runs scored / Overs faced) - (Runs conceded / Overs bowled)',
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Higher NRR is used as tie-breaker when teams have equal points',
                      style: TextStyle(
                        color: _kTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _kTextSecondary,
              fontSize: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}