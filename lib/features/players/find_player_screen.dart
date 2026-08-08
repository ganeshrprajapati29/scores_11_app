import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/custom_button.dart';
import '../../data/services/player_service.dart';
import '../../data/models/player_model.dart';
import '../../data/services/team_service.dart';
import '../../data/services/public_players_service.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/constants/enums.dart';
import 'create_player_screen.dart';

class FindPlayerScreen extends StatefulWidget {
  final String? teamId;
  final String? matchId;

  const FindPlayerScreen({super.key, this.teamId, this.matchId});

  @override
  State<FindPlayerScreen> createState() => _FindPlayerScreenState();
}

class _FindPlayerScreenState extends State<FindPlayerScreen> {
  final PlayerService _playerService = PlayerService();
  final TeamService _teamService = TeamService();
  final PublicPlayersService _publicPlayersService = PublicPlayersService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Player> _players = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _query = '';
  bool _isDetailLoading = false;
  String? _addingPlayerId;
  final Set<String> _addedPlayerIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocus.addListener(() => setState(() {}));
    _loadExistingTeamPlayers();
    _loadInitialPlayers();
  }

  Future<void> _loadExistingTeamPlayers() async {
    final teamId = widget.teamId;
    if (teamId == null || teamId.isEmpty) return;
    try {
      final data = await _teamService.getTeamWithPlayers(teamId);
      final players = data['players'];
      if (!mounted || players is! List) return;
      setState(() {
        _addedPlayerIds.addAll(
          players.whereType<Player>().map((player) => player.id),
        );
      });
    } catch (_) {
      // Search and add remain available if the initial membership lookup fails.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length > 1 && query != _query) {
      _performSearch(query);
    }
    if (query.isEmpty) {
      setState(() {
        _players.clear();
        _isSearching = false;
        _query = '';
      });
      _loadInitialPlayers();
    }
  }

  Future<void> _performSearch(String query) async {
    if (_isLoading) return;
    setState(() {
      _query = query;
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final players = await _searchAllPlayers(query);
      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Search error: $e', isError: true);
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInitialPlayers() async {
    if (_isLoading || _searchController.text.trim().isNotEmpty) return;
    setState(() => _isLoading = true);

    try {
      final publicResponse = await _publicPlayersService.getPublicPlayers(
        limit: 50,
      );
      final resultsById = <String, Player>{};
      for (final publicPlayer in publicResponse.players) {
        final player = _playerFromPublicPlayer(publicPlayer);
        if (player.id.isNotEmpty) resultsById[player.id] = player;
      }

      if (!mounted) return;
      setState(() {
        _players = resultsById.values.toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _isSearching = _players.isNotEmpty;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Player>> _searchAllPlayers(String query) async {
    final resultsById = <String, Player>{};

    try {
      final players = await _playerService.searchPlayers(query, limit: 30);
      for (final player in players) {
        if (player.id.isNotEmpty) resultsById[player.id] = player;
      }
    } catch (_) {
      // Public search below is the fallback for user-backed public players.
    }

    try {
      final publicResponse = await _publicPlayersService.getPublicPlayers(
        search: query,
        limit: 30,
      );
      for (final publicPlayer in publicResponse.players) {
        final player = _playerFromPublicPlayer(publicPlayer);
        if (player.id.isNotEmpty) resultsById[player.id] = player;
      }
    } catch (_) {
      // Keep player-doc results if public user search is unavailable.
    }

    return resultsById.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Player _playerFromPublicPlayer(PublicPlayer publicPlayer) {
    return Player(
      id: publicPlayer.playerIdForTeam,
      userId: publicPlayer.connectionUserId,
      name: publicPlayer.fullName,
      email: publicPlayer.email.isEmpty ? null : publicPlayer.email,
      role: publicPlayer.playerType,
      battingStyle: publicPlayer.cricketProfile?.battingStyle,
      bowlingStyle: publicPlayer.cricketProfile?.bowlingStyle,
      playerRole: publicPlayer.playerType,
      teamName: publicPlayer.teamName,
      stats: null,
      isActive: publicPlayer.isActive,
      createdAt: publicPlayer.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _addPlayerToTeam(Player player) async {
    if (widget.teamId == null) return;
    if (_addingPlayerId != null) return;
    setState(() => _addingPlayerId = player.id);
    try {
      await _teamService.addPlayerWithDetails(
        widget.teamId!,
        playerId: player.id,
        identifier: player.userId ?? player.id,
        name: player.name,
        email: player.email,
        phone: player.phone,
        role: player.role ?? player.playerRole,
        battingStyle: player.battingStyle,
        bowlingStyle: player.bowlingStyle,
        jerseyNumber: player.jerseyNumber,
        matchId: widget.matchId,
      );
      if (mounted) {
        _showSnackBar('${player.name} added to team!', isError: false);
        setState(() => _addedPlayerIds.add(player.id));
      }
    } catch (e) {
      final message = friendlyError(e, fallback: 'Player add nahi ho paaya.');
      final normalized = message.toLowerCase();
      if (normalized.contains('already') || normalized.contains('duplicate')) {
        if (mounted) {
          _showSnackBar('${player.name} is already in this team',
              isError: false);
          setState(() => _addedPlayerIds.add(player.id));
        }
      } else if (mounted) {
        _showSnackBar('Add error: $message', isError: true);
      }
    } finally {
      if (mounted) setState(() => _addingPlayerId = null);
    }
  }

  Future<void> _showPlayerDetails(Player player) async {
    setState(() => _isDetailLoading = true);
    try {
      final fullPlayer = await _playerService.getPlayerById(player.id);
      if (mounted) _showDetailsModal(fullPlayer);
    } catch (e) {
      if (mounted) _showSnackBar(friendlyError(e, fallback: 'Details load nahi ho paayi.'), isError: true);
    } finally {
      if (mounted) setState(() => _isDetailLoading = false);
    }
  }

  Future<void> _registerPlayer() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreatePlayerScreen(initialTeamId: widget.teamId),
      ),
    );
    if (created != true || !mounted) return;
    _showSnackBar(
      widget.teamId == null
          ? 'Player registered successfully'
          : 'Player registered and added to the team',
      isError: false,
    );
    await _loadInitialPlayers();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _players.clear();
      _isSearching = false;
      _query = '';
    });
  }

  void _showDetailsModal(Player player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _PlayerDetailSheet(
          player: player,
          scrollController: scrollController,
          teamId: widget.teamId,
          onAddToTeam: _addPlayerToTeam,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isTablet ? 680 : double.infinity),
          child: Column(
            children: [
              _SearchBar(
                controller: _searchController,
                focusNode: _searchFocus,
                isLoading: _isLoading,
                onSubmitted: _performSearch,
                onClear: _query.isNotEmpty ? _clearSearch : null,
              ),
              if (_players.isNotEmpty)
                _ResultsHeader(count: _players.length, query: _query),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: Color(0xFF1A1A2E)),
        ),
        onPressed: () => Navigator.of(context).pop(_addedPlayerIds.isNotEmpty),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Players',
            style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'Search by name',
            style: TextStyle(
              color: Color(0xFFADB5BD),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Register new player',
          onPressed: _registerPlayer,
          icon: const Icon(Icons.person_add_alt_1_rounded),
        ),
        if (_addedPlayerIds.isNotEmpty)
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text('Done (${_addedPlayerIds.length})'),
          ),
        if (_query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _clearSearch,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close_rounded,
                        size: 13, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching players...',
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_isSearching && _players.isEmpty && !_isLoading) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No players found',
        subtitle: 'Try a different search term',
      );
    }

    if (_players.isEmpty && !_isSearching) {
      return _EmptyState(
        icon: Icons.sports_cricket_rounded,
        title: 'Find your player',
        subtitle: 'Start typing to search players',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _players.length,
      itemBuilder: (context, index) => _PlayerCard(
        player: _players[index],
        index: index,
        teamId: widget.teamId,
        isDetailLoading: _isDetailLoading,
        isAdding: _addingPlayerId == _players[index].id,
        isAdded: _addedPlayerIds.contains(_players[index].id),
        onView: _showPlayerDetails,
        onAdd: _addPlayerToTeam,
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSubmitted,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: focusNode.hasFocus
                ? AppColors.primary.withOpacity(0.3)
                : const Color(0xFFE8EAF0),
            width: 1.2,
          ),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search players by name...',
            hintStyle: const TextStyle(
              color: Color(0xFFBCC0CC),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search_rounded,
                color:
                    focusNode.hasFocus ? AppColors.primary : Colors.grey[400],
                size: 20,
              ),
            ),
            suffixIcon: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : onClear != null
                    ? GestureDetector(
                        onTap: onClear,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EAF0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: Color(0xFF6B7280)),
                          ),
                        ),
                      )
                    : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          ),
        ),
      ),
    );
  }
}

// ─── Results Header ───────────────────────────────────────────────────────────

class _ResultsHeader extends StatelessWidget {
  final int count;
  final String query;

  const _ResultsHeader({required this.count, required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            '$count player${count != 1 ? 's' : ''} found',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '"$query"',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F8),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: const Color(0xFFCCCCCC)),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFAAAAAA),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Player Card ──────────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final Player player;
  final int index;
  final String? teamId;
  final bool isDetailLoading;
  final bool isAdding;
  final bool isAdded;
  final Future<void> Function(Player) onView;
  final Future<void> Function(Player) onAdd;

  const _PlayerCard({
    required this.player,
    required this.index,
    required this.teamId,
    required this.isDetailLoading,
    required this.isAdding,
    required this.isAdded,
    required this.onView,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onView(player),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _PlayerAvatar(player: player),
                const SizedBox(width: 14),
                Expanded(child: _PlayerInfo(player: player)),
                const SizedBox(width: 10),
                _PlayerActions(
                  player: player,
                  teamId: teamId,
                  isDetailLoading: isDetailLoading,
                  isAdding: isAdding,
                  isAdded: isAdded,
                  onView: onView,
                  onAdd: onAdd,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  final Player player;

  const _PlayerAvatar({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.08),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
  }
}

class _PlayerInfo extends StatelessWidget {
  final Player player;

  const _PlayerInfo({required this.player});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                player.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (player.jerseyNumber != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${player.jerseyNumber}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (player.role != null)
              _MiniChip(
                label: player.role!,
                textColor: AppColors.primary,
                bgColor: AppColors.primary.withOpacity(0.08),
              ),
            if (player.teamName != null)
              _MiniChip(
                label: player.teamName!,
                textColor: const Color(0xFF555555),
                bgColor: const Color(0xFFF0F0F0),
              ),
            if (player.battingStyle != null)
              _MiniChip(
                label: player.battingStyle!,
                textColor: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
              ),
          ],
        ),
      ],
    );
  }
}

class _PlayerActions extends StatelessWidget {
  final Player player;
  final String? teamId;
  final bool isDetailLoading;
  final bool isAdding;
  final bool isAdded;
  final Future<void> Function(Player) onView;
  final Future<void> Function(Player) onAdd;

  const _PlayerActions({
    required this.player,
    required this.teamId,
    required this.isDetailLoading,
    required this.isAdding,
    required this.isAdded,
    required this.onView,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconActionButton(
          onTap: () => onView(player),
          bgColor: const Color(0xFFF5F6FA),
          borderColor: const Color(0xFFE8EAF0),
          child: isDetailLoading
              ? SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              : const Icon(Icons.visibility_rounded,
                  size: 16, color: Color(0xFF777777)),
        ),
        if (teamId != null) ...[
          const SizedBox(height: 6),
          _IconActionButton(
            onTap: isAdding || isAdded ? () {} : () => onAdd(player),
            bgColor:
                (isAdded ? Colors.green : AppColors.primary).withOpacity(0.08),
            borderColor: AppColors.primary.withOpacity(0.2),
            child: isAdding
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    isAdded
                        ? Icons.check_circle_rounded
                        : Icons.person_add_rounded,
                    size: 16,
                    color: isAdded ? Colors.green : AppColors.primary,
                  ),
          ),
        ],
      ],
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color bgColor;
  final Color borderColor;
  final Widget child;

  const _IconActionButton({
    required this.onTap,
    required this.bgColor,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: child,
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _MiniChip({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Player Detail Bottom Sheet ───────────────────────────────────────────────

class _PlayerDetailSheet extends StatelessWidget {
  final Player player;
  final ScrollController scrollController;
  final String? teamId;
  final Future<void> Function(Player) onAddToTeam;

  const _PlayerDetailSheet({
    required this.player,
    required this.scrollController,
    required this.teamId,
    required this.onAddToTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                // Avatar
                Center(child: _SheetAvatar(player: player)),
                const SizedBox(height: 16),

                // Name
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Role & Team chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (player.role != null) ...[
                      _Chip(
                        label: player.role!,
                        textColor: AppColors.primary,
                        bgColor: AppColors.primary.withOpacity(0.08),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (player.teamName != null)
                      _Chip(
                        label: player.teamName!,
                        textColor: const Color(0xFF555555),
                        bgColor: const Color(0xFFF0F0F0),
                      ),
                  ],
                ),

                const SizedBox(height: 24),
                _SectionLabel(label: 'Player Info'),
                const SizedBox(height: 10),

                _InfoRow(
                    icon: Icons.flag_rounded,
                    label: 'Nationality',
                    value: player.nationality ?? 'N/A'),
                _InfoRow(
                    icon: Icons.cake_rounded,
                    label: 'Date of Birth',
                    value: player.dateOfBirth ?? 'N/A'),
                _InfoRow(
                    icon: Icons.sports_baseball_rounded,
                    label: 'Batting',
                    value: player.battingStyle ?? 'N/A'),
                _InfoRow(
                    icon: Icons.sports_cricket_rounded,
                    label: 'Bowling',
                    value: player.bowlingStyle ?? 'N/A'),
                if (player.teamName != null)
                  _InfoRow(
                      icon: Icons.group_rounded,
                      label: 'Team',
                      value: player.teamName!),

                if (player.stats != null) ...[
                  const SizedBox(height: 24),
                  _SectionLabel(label: 'Career Stats'),
                  const SizedBox(height: 10),
                  _StatsRow(
                      icon: Icons.bar_chart_rounded,
                      label: 'Matches',
                      value: player.stats!.matches.toString()),
                  _StatsRow(
                      icon: Icons.trending_up_rounded,
                      label: 'Runs',
                      value: player.stats!.runs.toString()),
                  _StatsRow(
                      icon: Icons.speed_rounded,
                      label: 'Average / SR',
                      value:
                          '${player.stats!.average.toStringAsFixed(1)} / ${player.stats!.strikeRate.toStringAsFixed(1)}'),
                  _StatsRow(
                      icon: Icons.local_fire_department_rounded,
                      label: '100s / 50s',
                      value:
                          '${player.stats!.hundreds} / ${player.stats!.fifties}'),
                  _StatsRow(
                      icon: Icons.remove_circle_outline_rounded,
                      label: 'Highest Score',
                      value: player.stats!.highestScore.toString()),
                  _StatsRow(
                      icon: Icons.sports_tennis_rounded,
                      label: 'Wickets',
                      value: player.stats!.wickets.toString()),
                  if (player.stats!.economy > 0)
                    _StatsRow(
                        icon: Icons.timer_outlined,
                        label: 'Economy',
                        value: player.stats!.economy.toStringAsFixed(1)),
                ],

                if (teamId != null) ...[
                  const SizedBox(height: 28),
                  CustomButton(
                    text: 'Add to Team',
                    onPressed: () {
                      Navigator.pop(context);
                      onAddToTeam(player);
                    },
                    icon: Icons.person_add_rounded,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAvatar extends StatelessWidget {
  final Player player;

  const _SheetAvatar({required this.player});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: AppColors.primary.withOpacity(0.2), width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: (player.profileImage != null || player.photo != null)
                ? Image.network(
                    player.profileImage ?? player.photo!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _AvatarFallback(player: player, size: 108),
                  )
                : _AvatarFallback(player: player, size: 108),
          ),
        ),
        if (player.jerseyNumber != null)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '#${player.jerseyNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final Player player;
  final double size;

  const _AvatarFallback({required this.player, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withOpacity(0.08),
      alignment: Alignment.center,
      child: Text(
        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}

// ─── Shared Sheet Widgets ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _Chip(
      {required this.label, required this.textColor, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 15),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatsRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
