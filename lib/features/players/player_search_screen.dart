import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/utils/debounce.dart';
import '../../data/models/player_model.dart';
import '../../data/services/player_service.dart';

class PlayerSearchScreen extends StatefulWidget {
  const PlayerSearchScreen({super.key});

  @override
  State<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends State<PlayerSearchScreen> {
  final _searchController = TextEditingController();
  final PlayerService _playerService = PlayerService();
  String _selectedFilter = 'all';
  bool _searchPublicPlayers = false; // Toggle for public/regular players
  
  // Debounce for search
  Debounce? _debounce;
  
  // Pagination state
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  
  List<Player> _players = [];

  @override
  void initState() {
    super.initState();
    _debounce = Debounce(delay: const Duration(milliseconds: 500));
    _loadPlayers();
  }

  @override
  void dispose() {
    _debounce?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final result;
      if (_searchPublicPlayers) {
        // Search public players
        result = await _playerService.getPublicPlayers(
          page: 1,
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          filter: _selectedFilter != 'all' ? _selectedFilter : null,
        );
      } else {
        // Search regular players
        result = await _playerService.getPlayers(
          page: 1,
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          filter: _selectedFilter != 'all' ? _selectedFilter : null,
        );
      }
      setState(() {
        _players = result.players;
        _hasMore = result.hasMore;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Load more players
  Future<void> _loadMorePlayers() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      _currentPage++;
      final result;
      if (_searchPublicPlayers) {
        result = await _playerService.getPublicPlayers(
          page: _currentPage,
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          filter: _selectedFilter != 'all' ? _selectedFilter : null,
        );
      } else {
        result = await _playerService.getPlayers(
          page: _currentPage,
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          filter: _selectedFilter != 'all' ? _selectedFilter : null,
        );
      }
      setState(() {
        _players.addAll(result.players);
        _hasMore = result.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _currentPage--;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Find Players',
      ),
      body: Column(
        children: [
          // Search Bar and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Column(
              children: [
                // Public/Regular Player Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleChip('My Players', false),
                      const SizedBox(width: 8),
                      _buildToggleChip('Public Players', true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _searchPublicPlayers 
                        ? 'Search public players by name...' 
                        : 'Search players by name...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadPlayers();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    _debounce?.run(() {
                      _loadPlayers();
                    });
                  },
                  onSubmitted: (_) => _loadPlayers(),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Batsmen', 'batsman'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Bowlers', 'bowler'),
                      const SizedBox(width: 8),
                      _buildFilterChip('All-Rounders', 'all-rounder'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Wicket Keepers', 'wicket-keeper'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _players.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchPublicPlayers 
                                  ? 'No public players found' 
                                  : 'No players found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchPublicPlayers
                                  ? 'Try searching for players from other teams'
                                  : 'Try adjusting your search or filters',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _PlayerList(
                        players: _players,
                        isLoadingMore: _isLoadingMore,
                        hasMore: _hasMore,
                        loadMore: _loadMorePlayers,
                        isPublicPlayers: _searchPublicPlayers,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isPublic) {
    final isSelected = _searchPublicPlayers == isPublic;
    return GestureDetector(
      onTap: () {
        if (_searchPublicPlayers != isPublic) {
          setState(() {
            _searchPublicPlayers = isPublic;
            _selectedFilter = 'all'; // Reset filter when toggling
          });
          _loadPlayers();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
        _loadPlayers();
      },
      selectedColor: Colors.white,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.white,
      ),
      checkmarkColor: AppColors.primary,
    );
  }
}

class _PlayerList extends StatefulWidget {
  final List<Player> players;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback loadMore;
  final bool isPublicPlayers;

  const _PlayerList({
    required this.players,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadMore,
    this.isPublicPlayers = false,
  });

  @override
  State<_PlayerList> createState() => _PlayerListState();
}

class _PlayerListState extends State<_PlayerList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Detect when user scrolls to bottom and load more
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      widget.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Implement refresh logic if needed
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: widget.players.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.players.length) {
            return widget.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }
          final player = widget.players[index];
          return _PlayerCard(
            player: player, 
            isPublicPlayer: widget.isPublicPlayers,
          );
        },
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  final bool isPublicPlayer;

  const _PlayerCard({
    required this.player,
    this.isPublicPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/player-profile',
              arguments: {
                'playerId': player.id,
                'isPublic': isPublicPlayer,
              },
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: player.profileImage != null
                          ? NetworkImage(player.profileImage!)
                          : null,
                      child: player.profileImage == null
                          ? Icon(Icons.person)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(player.role ?? ''),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          player.role != null && player.role!.isNotEmpty ? player.role![0].toUpperCase() : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                              player.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPublicPlayer)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Public',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleColor(player.role ?? '').withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              player.role ?? 'Player',
                              style: TextStyle(
                                color: _getRoleColor(player.role ?? ''),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (player.teamName != null)
                            Flexible(
                              child: Text(
                                player.teamName!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      if (player.country != null && player.country!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.public,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                player.country!,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'batsman':
        return Colors.blue;
      case 'bowler':
        return Colors.red;
      case 'all-rounder':
        return Colors.purple;
      case 'wicket keeper':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}