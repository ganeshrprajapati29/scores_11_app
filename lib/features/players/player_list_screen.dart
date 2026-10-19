import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/player_service.dart';
import '../../../data/models/player_model.dart';
import '../../core/utils/friendly_error.dart';

// ─── Design tokens (matching community feed) ─────────────────────────────────
const _kBg = Color(0xFFF8F9FA);
const _kBorder = Color(0xFFEEEFF2);
const _kTextPrimary = Color(0xFF0D1117);
const _kTextSecondary = Color(0xFF6B7280);
const _kTextHint = Color(0xFF9CA3AF);
const _kShadow = Color(0x0A000000);
const _kCardRadius = 16.0;

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
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
String? _selectedRole;
  // 🔥 FIX: Add toggle for "My Players" vs "All Players"
  bool _showMyPlayersOnly = false;

  final List<String> _roles = [
    'batsman',
    'bowler',
    'all-rounder',
    'wicket-keeper',
  ];

  String _formatRoleLabel(String role) {
    return role
        .split('-')
        .map((w) =>
            w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '')
        .join(' ');
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'batsman':      return AppColors.primary;
      case 'bowler':       return const Color(0xFF10B981);
      case 'all-rounder':  return const Color(0xFFF59E0B);
      case 'wicket-keeper':return const Color(0xFF8B5CF6);
      default:             return _kTextSecondary;
    }
  }

  IconData _roleIcon(String? role) {
    switch (role) {
      case 'batsman':       return Icons.sports_cricket_rounded;
      case 'bowler':        return Icons.sports_baseball_rounded;
      case 'all-rounder':   return Icons.stars_rounded;
      case 'wicket-keeper': return Icons.shield_rounded;
      default:              return Icons.person_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) _loadPlayers(loadMore: true);
    }
  }

Future<void> _loadPlayers({bool loadMore = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (_showMyPlayersOnly) {
        // getMyPlayers returns PaginatedPlayers
        final paginated = await _playerService.getMyPlayers(
          page: loadMore ? _page + 1 : 1,
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
      } else {
        // getPlayers returns PlayerSearchResult (different structure!)
        final result = await _playerService.getPlayers(
          page: loadMore ? _page + 1 : 1,
          search: _searchQuery.isEmpty ? null : _searchQuery,
          filter: _selectedRole,
        );

        setState(() {
          if (loadMore) {
            _players.addAll(result.players);
            _page = _page + 1;
          } else {
            _players = result.players;
            _page = 1;
          }
          _hasMore = result.hasMore;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(friendlyError(e, fallback: 'Could not load players.')),
            ]),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// 🔥 FIX: Use correct search endpoint based on filter mode
  Future<void> _searchPlayers(String query) async {
    setState(() {
      _searchQuery = query;
      _page = 1;
    });
    
    // If no search query, just reload with pagination
    if (query.isEmpty) {
      await _loadPlayers();
      return;
    }
    
    // Use searchMyPlayers() when in "My Players" mode
    if (_showMyPlayersOnly) {
      setState(() => _isLoading = true);
      try {
        final players = await _playerService.searchMyPlayers(query);
        setState(() {
          _players = players;
          _hasMore = false;
        });
      } catch (e) {
        if (mounted) {
          _snack(friendlyError(e, fallback: 'Search failed. Please try again.'));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Use getPlayers with search parameter for all players
      await _loadPlayers();
    }
  }
  
  // 🔥 NEW: Toggle between "My Players" and "All Players"
  void _toggleMyPlayersFilter(bool value) {
    setState(() {
      _showMyPlayersOnly = value;
      _page = 1;
      _players = []; // Clear current list
    });
    _loadPlayers();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 720 : double.infinity),
          child: Column(
            children: [
              _buildSearchFilterSection(),
              Expanded(child: _buildPlayerList()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ─── AppBar (matching community feed style) ────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Players',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _isLoading
                  ? 'Loading...'
                  : '${_players.length} player${_players.length != 1 ? 's' : ''} found',
              key: ValueKey(_players.length),
              style: TextStyle(
                color: _kTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: _loadPlayers,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Icon(
                    _isLoading ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  // ─── Search & Filter (matching community feed style) ───────────────────────

Widget _buildSearchFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: Colors.white,
      child: Column(
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(_kCardRadius),
              border: Border.all(color: _kBorder),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: const TextStyle(color: _kTextPrimary, fontSize: 14),
              onSubmitted: _searchPlayers,
              decoration: InputDecoration(
                hintText: 'Search players...',
                hintStyle: TextStyle(color: _kTextHint, fontSize: 14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(Icons.search_rounded,
                      color: AppColors.primary, size: 20),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _searchPlayers('');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: _kTextHint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 🔥 NEW: My Players / All Players Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // All Players Option
                GestureDetector(
                  onTap: () => _toggleMyPlayersFilter(false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_showMyPlayersOnly ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 14,
                          color: !_showMyPlayersOnly ? Colors.white : _kTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'All Players',
                          style: TextStyle(
                            color: !_showMyPlayersOnly ? Colors.white : _kTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // My Players Option
                GestureDetector(
                  onTap: () => _toggleMyPlayersFilter(true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _showMyPlayersOnly ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: _showMyPlayersOnly ? Colors.white : _kTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'My Players',
                          style: TextStyle(
                            color: _showMyPlayersOnly ? Colors.white : _kTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Role filter chips (hide when showing My Players only - no search needed)
          if (!_showMyPlayersOnly)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _roles.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildFilterChip(
                      label: 'All',
                      icon: Icons.people_rounded,
                      isSelected: _selectedRole == null,
                      color: AppColors.primary,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : _kBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : _kBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? color : _kTextSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : _kTextSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Player List ───────────────────────────────────────────────────────────

  Widget _buildPlayerList() {
    if (_players.isEmpty && _isLoading) return _buildShimmer();
    if (_players.isEmpty && !_isLoading) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: () => _loadPlayers(),
      color: AppColors.primary,
      strokeWidth: 2.5,
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _players.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _players.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            );
          }
          return _buildPlayerCard(_players[index], index);
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEFF2),
      highlightColor: _kBg,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kCardRadius),
          ),
        ),
      ),
    );
  }

  // ─── Player Card (matching community feed card style) ──────────────────────

  Widget _buildPlayerCard(Player player, int index) {
    final color = _roleColor(player.role);
    final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(_kCardRadius),
          onTap: () {
            try {
              Navigator.pushNamed(context, '/player-profile/${player.id}');
            } catch (e) {
              _snack(friendlyError(e, fallback: 'Could not open this page.'));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar block
                _buildAvatar(initial, color, player.jerseyNumber),

                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        player.name.isNotEmpty ? player.name : 'Unknown Player',
                        style: const TextStyle(
                          color: _kTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Role + team
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_roleIcon(player.role), size: 12, color: color),
                              const SizedBox(width: 4),
                              Text(
                                _formatRoleLabel(player.role ?? ''),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (player.teamName != null) ...[
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: _kTextHint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.group_rounded, size: 11, color: _kTextHint),
                                  const SizedBox(width: 4),
                                  Text(
                                    player.teamName!,
                                    style: TextStyle(
                                      color: _kTextSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (player.stats != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            _statBadge('${player.stats!.runs}', 'Runs',
                                const Color(0xFF4FC3F7)),
                            _statBadge('${player.stats!.wickets}', 'Wkts',
                                const Color(0xFF10B981)),
                            if (player.stats!.average > 0)
                              _statBadge(
                                  player.stats!.average.toStringAsFixed(1),
                                  'Avg',
                                  const Color(0xFFF59E0B)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Action buttons
                Column(
                  children: [
                    _actionBtn(
                      Icons.visibility_rounded,
                      AppColors.primary,
                      () {
                        try {
                          Navigator.pushNamed(
                              context, '/player-profile/${player.id}');
                        } catch (e) {
                          _snack(friendlyError(e, fallback: 'Could not open this page.'));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _actionBtn(
                      Icons.edit_rounded,
                      const Color(0xFFF59E0B),
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
    )
    .animate()
    .fadeIn(duration: 280.ms, delay: (index * 50).ms)
    .slideY(begin: 0.05, end: 0, duration: 280.ms, delay: (index * 50).ms);
  }

  Widget _buildAvatar(String initial, Color color, int? jerseyNumber) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            initial,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          if (jerseyNumber != null) ...[
            const SizedBox(height: 2),
            Text(
              '#$jerseyNumber',
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
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

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'score 11/Empty States 4.png',
            width: 124,
            height: 124,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.people_outline_rounded,
                  size: 40, color: _kTextHint),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : 'No players found',
            style: const TextStyle(
              color: _kTextSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try changing your search or filters',
            style: TextStyle(
              color: _kTextHint,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadPlayers,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Reload Players',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

  // ─── FAB (matching community feed style) ───────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      heroTag: 'player_list_fab_${DateTime.now().millisecondsSinceEpoch}',
      onPressed: () => Navigator.pushNamed(context, '/create-player'),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text('Add Player',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
