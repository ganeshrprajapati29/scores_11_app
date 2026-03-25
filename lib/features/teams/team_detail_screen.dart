import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/enums.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_loader.dart';
import '../../data/models/team_model.dart';
import '../../data/services/team_service.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  final TeamService _teamService = TeamService();
  Team? _team;
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadTeam();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTeam() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final team = await _teamService.getTeamById(widget.teamId);
      setState(() {
        _team = team;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: _team?.name ?? 'Team Details',
      ),
      body: _isLoading
          ? const CustomLoader()
          : _error != null
              ? _buildErrorState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTeamHeader(),
                        const SizedBox(height: 24),
                        _buildInfoSection(),
                        const SizedBox(height: 24),
                        _buildPlayersSection(),
                        const SizedBox(height: 24),
                        _buildStatsSection(),
                        const SizedBox(height: 24),
                        _buildActionsSection(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ─── Error State ───────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: _loadTeam,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Team Header ───────────────────────────────────────────────────────────

  Widget _buildTeamHeader() {
    final initials = _team!.name.length >= 2
        ? _team!.name.substring(0, 2).toUpperCase()
        : _team!.name.substring(0, 1).toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _team!.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _team!.teamType ?? 'Cricket Team',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Section ──────────────────────────────────────────────────────────

  Widget _buildInfoSection() {
    return _buildSectionCard(
      title: 'Team Information',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _buildInfoRow(
              Icons.sports_cricket, 'Total Matches', '${_team!.matchesPlayed ?? 0}'),
          _buildDivider(),
          _buildInfoRow(Icons.emoji_events_outlined, 'Wins', '${_team!.wins ?? 0}',
              valueColor: Colors.green.shade600),
          _buildDivider(),
          _buildInfoRow(Icons.close_rounded, 'Losses', '${_team!.losses ?? 0}',
              valueColor: Colors.red.shade400),
          _buildDivider(),
          _buildInfoRow(Icons.remove_rounded, 'Ties', '${_team!.ties ?? 0}'),
          _buildDivider(),
          _buildInfoRow(
              Icons.star_outline_rounded, 'Captain', _team!.captainName ?? 'Not assigned'),
          _buildDivider(),
          _buildInfoRow(Icons.person_outline_rounded, 'Vice Captain',
              _team!.viceCaptainName ?? 'Not assigned'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: Colors.grey.shade100,
    );
  }

  // ─── Players Section ───────────────────────────────────────────────────────

  Widget _buildPlayersSection() {
    final players = _team!.players;

    return _buildSectionCard(
      title: 'Players',
      icon: Icons.people_outline_rounded,
      trailing: Text(
        '${players?.length ?? 0} players',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 13,
        ),
      ),
      child: players != null && players.isNotEmpty
          ? Column(
              children: List.generate(players.length, (index) {
                final player = players[index] as Map<String, dynamic>;
                final name = player['name'] as String? ?? 'Unknown';
                final role = player['role'] as String? ?? 'Player';
                final initial =
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P';

                return Container(
                  margin: EdgeInsets.only(
                      bottom: index < players.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                );
              }),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.person_off_outlined,
                        size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'No players in this team',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Stats Section ─────────────────────────────────────────────────────────

  Widget _buildStatsSection() {
    final matchesPlayed = _team!.matchesPlayed ?? 0;
    final wins = _team!.wins ?? 0;
    final losses = _team!.losses ?? 0;
    final ties = _team!.ties ?? 0;

    final winRate = matchesPlayed > 0
        ? (wins / matchesPlayed * 100).toStringAsFixed(1)
        : '0.0';

    return _buildSectionCard(
      title: 'Statistics',
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Win Rate',
                  '$winRate%',
                  Icons.trending_up_rounded,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Wins',
                  '$wins',
                  Icons.emoji_events_rounded,
                  Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Losses',
                  '$losses',
                  Icons.sentiment_dissatisfied_rounded,
                  Colors.red.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Ties',
                  '$ties',
                  Icons.handshake_outlined,
                  Colors.orange.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions Section ───────────────────────────────────────────────────────

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, size: 18),
            const SizedBox(width: 6),
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Edit Team',
                onPressed: () {
                  // Navigate to edit team
                },
                icon: Icons.edit_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Invite',
                onPressed: () {
                  // Show invite dialog
                },
                icon: Icons.person_add_rounded,
                variant: ButtonVariant.outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Reusable Section Card ─────────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (trailing != null) ...[
              const Spacer(),
              trailing,
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}