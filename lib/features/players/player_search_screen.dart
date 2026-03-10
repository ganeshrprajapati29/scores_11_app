import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
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
  
  // Debounce for search
  Debounce? _debounce;
  
  // Pagination state
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  
  List<Player> _players = [];

  /// Pagination Algorithm:
  /// int page = 1;
  /// loadMore(){
  ///   page++;
  ///   fetchPlayers(page);
  /// }

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
      final result = await _playerService.getPlayers(
        page: 1,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
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
      final result = await _playerService.getPlayers(
        page: _currentPage,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
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
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search players by name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
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
                ? const Center(child: CircularProgressIndicator())
                : _players.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No players found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _PlayerList(
                        players: _players,
                        isLoadingMore: _isLoadingMore,
                        hasMore: _hasMore,
                        loadMore: _loadMorePlayers,
                      ),
          ),
        ],
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

  const _PlayerList({
    required this.players,
    required this.isLoadingMore,
    required this.hasMore,
    required this.loadMore,
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
      onRefresh: () async {},
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
          return _PlayerCard(player: player);
        },
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;

  const _PlayerCard({required this.player});

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
              arguments: player.id,
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
                          ? const Icon(Icons.person)
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
                          player.role != null && player.role!.isNotEmpty ? player.role![0] : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn();
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

