import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/friendly_error.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/services/public_players_service.dart';

class PlayerSearchScreen extends StatefulWidget {
  const PlayerSearchScreen({super.key});

  @override
  State<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

bool _isSafeAvatarUrl(String? value) {
  final url = value?.trim();
  if (url == null || url.isEmpty || url == 'default-avatar-url') return false;
  final uri = Uri.tryParse(url);
  return uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

class _PlayerSearchScreenState extends State<PlayerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PublicPlayersService _publicPlayersService = PublicPlayersService();

  Timer? _searchDebounce;
  List<PublicPlayer> _players = [];

  String _selectedPlayerType = 'all';
  String _searchText = '';
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPublicPlayers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadPublicPlayers({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final nextPage = reset ? 1 : _page + 1;
      final response = await _publicPlayersService.getPublicPlayers(
        page: nextPage,
        limit: 20,
        search: _searchText.trim().isEmpty ? null : _searchText.trim(),
        playerType: _selectedPlayerType == 'all' ? null : _selectedPlayerType,
      );

      if (!mounted) return;
      setState(() {
        _players = reset ? response.players : [..._players, ...response.players];
        _page = response.page;
        _total = response.total;
        _hasMore = response.hasMore;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = friendlyError(e, fallback: 'Players search nahi ho paaye.');
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchText = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadPublicPlayers();
    });
    setState(() {});
  }

  void _onFilterChanged(String playerType) {
    if (_selectedPlayerType == playerType) return;
    setState(() => _selectedPlayerType = playerType);
    _loadPublicPlayers();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadPublicPlayers(reset: false);
    }
  }

  void _openPlayerProfile(PublicPlayer player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PublicPlayerProfileScreen(player: player),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: const CustomAppBar(title: 'Public Player Search'),
      body: Column(
        children: [
          _SearchHeader(
            controller: _searchController,
            selectedPlayerType: _selectedPlayerType,
            resultCount: _total,
            onSearchChanged: _onSearchChanged,
            onClear: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            onFilterChanged: _onFilterChanged,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: () => _loadPublicPlayers());
    }

    if (_players.isEmpty) {
      return _EmptyState(
        hasSearch: _searchText.trim().isNotEmpty || _selectedPlayerType != 'all',
        onRefresh: () => _loadPublicPlayers(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPublicPlayers(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: _players.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _players.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final player = _players[index];
          return _PublicPlayerCard(
            player: player,
            onTap: () => _openPlayerProfile(player),
          ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04, end: 0);
        },
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final String selectedPlayerType;
  final int resultCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onFilterChanged;

  const _SearchHeader({
    required this.controller,
    required this.selectedPlayerType,
    required this.resultCount,
    required this.onSearchChanged,
    required this.onClear,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF00ACC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find public cricket players',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Search by name, username, role or playing style',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontWeight: FontWeight.w700),
            onChanged: onSearchChanged,
            onSubmitted: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search public players',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: onClear,
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _PlayerTypeOption(label: 'All', value: 'all'),
                _PlayerTypeOption(label: 'Batsman', value: 'batsman'),
                _PlayerTypeOption(label: 'Bowler', value: 'bowler'),
                _PlayerTypeOption(label: 'All-rounder', value: 'all-rounder'),
                _PlayerTypeOption(label: 'Wicket keeper', value: 'wicket-keeper'),
              ].map((option) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(option.label),
                    selected: selectedPlayerType == option.value,
                    onSelected: (_) => onFilterChanged(option.value),
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.16),
                    labelStyle: TextStyle(
                      color: selectedPlayerType == option.value ? AppColors.primary : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: selectedPlayerType == option.value
                          ? Colors.white
                          : Colors.white.withOpacity(0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              resultCount == 0 ? 'Public players' : '$resultCount public players found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.92),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerTypeOption {
  final String label;
  final String value;

  const _PlayerTypeOption({required this.label, required this.value});
}

class _PublicPlayerCard extends StatelessWidget {
  final PublicPlayer player;
  final VoidCallback onTap;

  const _PublicPlayerCard({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = _titleCase(player.playerType);
    final avatarUrl = player.avatar?.url;
    final safeAvatarUrl = _isSafeAvatarUrl(avatarUrl) ? avatarUrl : null;
    final cityParts = [
      if (player.city?.isNotEmpty == true) player.city!,
      if (player.state?.isNotEmpty == true) player.state!,
      if (player.teamName?.isNotEmpty == true) player.teamName!,
    ];
    final location = cityParts.join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EEF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.95),
                        _roleColor(player.playerType).withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: safeAvatarUrl != null
                        ? NetworkImage(safeAvatarUrl)
                        : null,
                    child: safeAvatarUrl == null
                        ? Text(
                            player.fullName.isNotEmpty ? player.fullName[0].toUpperCase() : 'P',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              player.fullName.isNotEmpty ? player.fullName : player.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                          _Badge(text: 'Public', color: const Color(0xFF10B981)),
                        ],
                      ),
                      if (player.username.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          '@${player.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            icon: Icons.sports_cricket_rounded,
                            text: type,
                            color: _roleColor(player.playerType),
                          ),
                          if (player.cricketProfile?.battingStyle?.isNotEmpty == true)
                            _InfoChip(
                              icon: Icons.sports_baseball_rounded,
                              text: _cleanStyle(player.cricketProfile!.battingStyle!),
                              color: const Color(0xFFF59E0B),
                            ),
                          if (location.isNotEmpty)
                            _InfoChip(
                              icon: Icons.location_on_outlined,
                              text: location,
                              color: const Color(0xFF6366F1),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'[\s-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String _cleanStyle(String value) {
    return value.replaceAll('-', ' ').replaceAll(' bat', '').trim();
  }

  static Color _roleColor(String? role) {
    switch (role) {
      case 'batsman':
        return AppColors.primary;
      case 'bowler':
        return const Color(0xFF10B981);
      case 'all-rounder':
        return const Color(0xFFF59E0B);
      case 'wicket-keeper':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicPlayerProfileScreen extends StatelessWidget {
  final PublicPlayer player;

  const _PublicPlayerProfileScreen({required this.player});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = player.avatar?.url;
    final safeAvatarUrl = _isSafeAvatarUrl(avatarUrl) ? avatarUrl : null;
    final type = _PublicPlayerCard._titleCase(player.playerType);
    final location = [
      if (player.city?.isNotEmpty == true) player.city!,
      if (player.state?.isNotEmpty == true) player.state!,
      if (player.teamName?.isNotEmpty == true) player.teamName!,
      if (player.location?.country?.isNotEmpty == true) player.location!.country!,
    ].join(', ');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'Player Profile', showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: safeAvatarUrl != null
                      ? NetworkImage(safeAvatarUrl)
                      : null,
                  child: safeAvatarUrl == null
                      ? Text(
                          player.fullName.isNotEmpty ? player.fullName[0].toUpperCase() : 'P',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.fullName.isNotEmpty ? player.fullName : player.username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (player.username.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          '@${player.username}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _Badge(text: type, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProfileSection(
            title: 'Cricket Info',
            children: [
              _ProfileRow(
                icon: Icons.sports_cricket_rounded,
                label: 'Player type',
                value: type,
              ),
              _ProfileRow(
                icon: Icons.sports_baseball_rounded,
                label: 'Batting style',
                value: player.cricketProfile?.battingStyle ?? 'N/A',
              ),
              _ProfileRow(
                icon: Icons.rotate_right_rounded,
                label: 'Bowling style',
                value: player.cricketProfile?.bowlingStyle ?? 'N/A',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProfileSection(
            title: 'Stats',
            children: [
              _ProfileRow(
                icon: Icons.scoreboard_rounded,
                label: 'Matches',
                value: (player.cricketProfile?.matchesPlayed ??
                        player.stats?.matchesPlayed ??
                        0)
                    .toString(),
              ),
              _ProfileRow(
                icon: Icons.trending_up_rounded,
                label: 'Runs',
                value: (player.cricketProfile?.totalRuns ?? 0).toString(),
              ),
              _ProfileRow(
                icon: Icons.sports_baseball_rounded,
                label: 'Wickets',
                value: (player.cricketProfile?.totalWickets ?? 0).toString(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProfileSection(
            title: 'Contact',
            children: [
              _ProfileRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: player.email.isNotEmpty ? player.email : 'N/A',
              ),
              _ProfileRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: location.isNotEmpty ? location : 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Public players load nahi ho paaye',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onRefresh;

  const _EmptyState({required this.hasSearch, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Icon(Icons.person_search_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 14),
          Text(
            hasSearch ? 'No matching public players' : 'No public players found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'Search text ya filter change karke try karo.'
                : 'Player role se signup hone wale users yahan show honge.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
