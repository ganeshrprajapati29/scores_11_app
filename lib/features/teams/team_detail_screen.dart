import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/enums.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_loader.dart';
import '../../data/models/team_model.dart';
import '../../data/models/player_model.dart';
import '../../data/services/team_service.dart';
import '../../data/services/player_service.dart';
import '../players/find_player_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  final TeamService _teamService = TeamService();
  final PlayerService _playerService = PlayerService();
  Team? _team;
  List<Player> _players = [];
  List<Player> _filteredPlayers = [];
  final TextEditingController _playerSearchController = TextEditingController();
  bool _isLoading = true;
  bool _isPlayersLoading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Color palette
  static const Color _primary = Color(0xFF1A1A2E);
  static const Color _accent = Color(0xFF4F8EF7);
  static const Color _success = Color(0xFF22C55E);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _bg = Color(0xFFF8F9FC);
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE8ECF4);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _playerSearchController.addListener(_filterPlayers);
    _loadTeam();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _playerSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeam() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final team = await _teamService.getTeamById(widget.teamId);
      setState(() => _team = team);

      setState(() => _isPlayersLoading = true);
      final players = await _playerService.getPlayersByTeam(widget.teamId);
      setState(() {
        _players = players;
        _filteredPlayers = players;
        _isLoading = false;
        _isPlayersLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isPlayersLoading = false;
      });
    }
  }

  void _filterPlayers() {
    final query = _playerSearchController.text.toLowerCase();
    setState(() {
      _filteredPlayers = _players.where((player) =>
        player.name.toLowerCase().contains(query) ||
        (player.role?.toLowerCase().contains(query) ?? false)
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: (_isLoading || _isPlayersLoading)
          ? const Center(child: CustomLoader())
          : _error != null
              ? _buildErrorState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadTeam,
                    color: _accent,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTeamHeader(),
                          const SizedBox(height: 20),
                          _buildStatsRow(),
                          const SizedBox(height: 20),
                          _buildInfoCard(),
                          const SizedBox(height: 20),
                          _buildPlayersSection(),
                          const SizedBox(height: 20),
                          _buildActionsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _cardBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        _team?.name ?? 'Team Details',
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _textPrimary),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  // ─── Error State ───────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 36, color: _danger),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to Load',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 140,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _loadTeam,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Team Header ───────────────────────────────────────────────────────────

  Widget _buildTeamHeader() {
    final name = _team!.name;
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.substring(0, 1).toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/pattern.png'),
          fit: BoxFit.cover,
          opacity: 0.04,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _team!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Text(
              _team!.teamType ?? 'Cricket Team',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Captain pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCaptainPill(
                Icons.military_tech_rounded,
                'C',
                _team!.captainName ?? 'TBA',
                _accent,
              ),
              const SizedBox(width: 10),
              _buildCaptainPill(
                Icons.star_rounded,
                'VC',
                _team!.viceCaptainName ?? 'TBA',
                _warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaptainPill(IconData icon, String badge, String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final matchesPlayed = _team!.matchesPlayed ?? 0;
    final wins = _team!.wins ?? 0;
    final losses = _team!.losses ?? 0;
    final ties = _team!.ties ?? 0;
    final winRate = matchesPlayed > 0
        ? (wins / matchesPlayed * 100).toStringAsFixed(0)
        : '0';

    return Row(
      children: [
        Expanded(child: _buildStatTile('$winRate%', 'Win Rate', _accent, Icons.trending_up_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatTile('$wins', 'Wins', _success, Icons.emoji_events_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatTile('$losses', 'Losses', _danger, Icons.close_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatTile('$ties', 'Ties', _warning, Icons.handshake_outlined)),
      ],
    );
  }

  Widget _buildStatTile(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Card ─────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return _buildCard(
      header: _buildCardHeader(Icons.info_outline_rounded, 'Team Info'),
      child: Column(
        children: [
          _buildInfoTile(Icons.sports_cricket_rounded, 'Matches Played', '${_team!.matchesPlayed ?? 0}'),
          _buildInfoTile(Icons.emoji_events_rounded, 'Wins', '${_team!.wins ?? 0}', valueColor: _success),
          _buildInfoTile(Icons.close_rounded, 'Losses', '${_team!.losses ?? 0}', valueColor: _danger),
          _buildInfoTile(Icons.remove_rounded, 'Ties', '${_team!.ties ?? 0}', valueColor: _warning),
          _buildInfoTile(Icons.military_tech_rounded, 'Captain', _team!.captainName ?? 'Not Assigned'),
          _buildInfoTile(Icons.star_rounded, 'Vice Captain', _team!.viceCaptainName ?? 'Not Assigned', isLast: true),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value,
      {Color? valueColor, bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: valueColor ?? _textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: _border.withOpacity(0.7)),
      ],
    );
  }

  // ─── Players Section ───────────────────────────────────────────────────────

  Widget _buildPlayersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCard(
          header: Row(
            children: [
              _buildCardHeader(Icons.people_alt_rounded, 'Players'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredPlayers.length} / ${_players.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: TextField(
                  controller: _playerSearchController,
                  style: const TextStyle(fontSize: 14, color: _textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by name or role...',
                    hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: _textSecondary, size: 18),
                    suffixIcon: _playerSearchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: _playerSearchController.clear,
                            child: const Icon(Icons.cancel_rounded, color: _textSecondary, size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // List
              _filteredPlayers.isNotEmpty
                  ? ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredPlayers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _buildPlayerTile(_filteredPlayers[index]),
                    )
                  : _buildEmptyPlayers(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildFullWidthButton(
          label: 'Find & Add Players',
          icon: Icons.person_add_alt_1_rounded,
          color: _accent,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FindPlayerScreen(teamId: widget.teamId),
              ),
            );
            if (result == true && mounted) _loadTeam();
          },
        ),
      ],
    );
  }

  Widget _buildPlayerTile(Player player) {
    final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P';
    return GestureDetector(
      onTap: () => _showPlayerDetails(player),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _accent.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (player.role != null)
                        _buildSmallBadge(player.role!, _accent),
                      if (player.teamName != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            player.teamName!,
                            style: const TextStyle(fontSize: 11, color: _textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.chevron_right_rounded, size: 18, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyPlayers() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _border,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_off_rounded, size: 28, color: _textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            _playerSearchController.text.isNotEmpty
                ? 'No matching players'
                : 'No players yet',
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_playerSearchController.text.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Add players to get started',
                style: TextStyle(color: Color(0xFFADB5BD), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showPlayerDetails(Player player) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FindPlayerScreen(teamId: widget.teamId),
        settings: RouteSettings(arguments: player),
      ),
    );
  }

  // ─── Actions Section ───────────────────────────────────────────────────────

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Edit Team',
                icon: Icons.edit_rounded,
                color: _primary,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                label: 'Invite',
                icon: Icons.person_add_rounded,
                color: _cardBg,
                textColor: _textPrimary,
                onTap: () {},
                isBordered: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Color? textColor,
    bool isBordered = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
          border: isBordered ? Border.all(color: _border, width: 1.5) : null,
          boxShadow: !isBordered
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: textColor ?? Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.82)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Reusable Card ─────────────────────────────────────────────────────────

  Widget _buildCard({required Widget header, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildCardHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: _accent),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}