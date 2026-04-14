import 'package:flutter/material.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/player_service.dart';
import '../../../data/models/player_model.dart';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({super.key});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen>
    with TickerProviderStateMixin {
  final PlayerService _playerService = PlayerService();
  List<Player> _players = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedRole;

  AnimationController? _fadeController;
  Animation<double> _fadeAnimation = const AlwaysStoppedAnimation(1.0);

  final List<String> _roles = [
    'batsman',
    'bowler',
    'all-rounder',
    'wicket-keeper',
  ];

  // ── Fix: proper label formatting without callback-based replaceAll ──
  String _formatRoleLabel(String role) {
    return role
        .split('-')
        .map((w) => w.isNotEmpty
            ? w[0].toUpperCase() + w.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  // Role color mapping
  Color _roleColor(String? role) {
    switch (role) {
      case 'batsman':
        return const Color(0xFF4FC3F7);
      case 'bowler':
        return const Color(0xFF81C784);
      case 'all-rounder':
        return const Color(0xFFFFB74D);
      case 'wicket-keeper':
        return const Color(0xFFCE93D8);
      default:
        return Colors.grey;
    }
  }

  IconData _roleIcon(String? role) {
    switch (role) {
      case 'batsman':
        return Icons.sports_cricket;
      case 'bowler':
        return Icons.sports_baseball;
      case 'all-rounder':
        return Icons.stars;
      case 'wicket-keeper':
        return Icons.shield;
      default:
        return Icons.person;
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeIn,
    );
    _fadeController!.forward();

    _loadPlayers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadPlayers(loadMore: true);
      }
    }
  }

  Future<void> _loadPlayers({bool loadMore = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final paginated = await _playerService.getPlayers(
        page: loadMore ? _page + 1 : 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        role: _selectedRole,
      );

      setState(() {
        if (loadMore) {
          _players.addAll(paginated.players);
          _page = paginated.page;
        } else {
          _players = paginated.players;
          _page = paginated.page;
        }
        _hasMore = paginated.hasMore;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Load error: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchPlayers(String query) async {
    setState(() {
      _searchQuery = query;
      _page = 1;
    });
    await _loadPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Players',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_players.length} players found',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A3A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh,
                  color: Color(0xFF4FC3F7), size: 18),
            ),
            onPressed: () => _loadPlayers(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // ── Search & Filter Bar ──────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.06),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2A3A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.07), width: 1),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onSubmitted: _searchPlayers,
                      decoration: InputDecoration(
                        hintText: 'Search players...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14),
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF4FC3F7), size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close,
                                    color: Colors.grey.shade500, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchPlayers('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Role filter chips
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _roles.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildFilterChip(
                            label: 'All',
                            icon: Icons.people,
                            isSelected: _selectedRole == null,
                            color: const Color(0xFF4FC3F7),
                            onTap: () {
                              setState(() => _selectedRole = null);
                              _loadPlayers();
                            },
                          );
                        }
                        final role = _roles[index - 1];
                        return _buildFilterChip(
                          label: _formatRoleLabel(role),
                          icon: _roleIcon(role),
                          isSelected: _selectedRole == role,
                          color: _roleColor(role),
                          onTap: () {
                            setState(() => _selectedRole = role);
                            _loadPlayers();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Player List ──────────────────────────────────────────
            Expanded(
              child: _players.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _players.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _players.length) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4FC3F7),
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          );
                        }
                        return _buildPlayerCard(_players[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.15)
                : const Color(0xFF1E2A3A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isSelected ? color : Colors.white.withOpacity(0.07),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: isSelected ? color : Colors.grey.shade500),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Player player, int index) {
    final color = _roleColor(player.role);
    final initial =
        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index % 8) * 60),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          try {
            Navigator.pushNamed(
                context, '/player-profile/${player.id}');
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Navigation error: $e')),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF132030),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: color.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        initial,
                        style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (player.jerseyNumber != null)
                        Text(
                          '#${player.jerseyNumber}',
                          style: TextStyle(
                            color: color.withOpacity(0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name.isNotEmpty
                            ? player.name
                            : 'Unknown Player',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (player.role != null) ...[
                            Icon(_roleIcon(player.role),
                                size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              _formatRoleLabel(player.role!),
                              style: TextStyle(
                                  color: color, fontSize: 11),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (player.teamName != null)
                            Flexible(
                              child: Row(
                                children: [
                                  Icon(Icons.group,
                                      size: 12,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      player.teamName!,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (player.stats != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _statBadge(
                                '${player.stats!.runs}', 'Runs',
                                const Color(0xFF4FC3F7)),
                            const SizedBox(width: 8),
                            _statBadge(
                                '${player.stats!.wickets}', 'Wkts',
                                const Color(0xFF81C784)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    _actionBtn(
                      Icons.visibility_outlined,
                      const Color(0xFF4FC3F7),
                      () {
                        try {
                          Navigator.pushNamed(
                              context, '/player-profile/${player.id}');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Navigation error: $e')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    _actionBtn(
                      Icons.edit_outlined,
                      const Color(0xFFFFB74D),
                      () => Navigator.pushNamed(context, '/create-player',
                          arguments: player.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style:
                TextStyle(color: color.withOpacity(0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A3A),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.07), width: 1),
            ),
            child: Icon(Icons.people_outline,
                size: 40, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Text(
            'No players found',
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search or filters',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadPlayers,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Reload Players',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/create-player'),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FC3F7).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}