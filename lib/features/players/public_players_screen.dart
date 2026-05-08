import 'package:flutter/material.dart';
import '../../data/services/public_players_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';

class PublicPlayersScreen extends StatefulWidget {
  const PublicPlayersScreen({super.key});

  @override
  State<PublicPlayersScreen> createState() => _PublicPlayersScreenState();
}

class _PublicPlayersScreenState extends State<PublicPlayersScreen> {
  final PublicPlayersService _service = PublicPlayersService();
  List<PublicPlayer> _players = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedPlayerType;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers({String? search, String? playerType}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _service.getPublicPlayers(
        search: search,
        playerType: playerType,
      );
      setState(() {
        _players = response.players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _loadPlayers(search: query.isEmpty ? null : query);
  }

  void _onFilterByType(String? playerType) {
    _selectedPlayerType = playerType;
    _loadPlayers(search: _searchQuery.isEmpty ? null : _searchQuery, playerType: playerType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(title: 'Find Players'),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or username',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _onSearch,
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedPlayerType == null,
                  onSelected: () => _onFilterByType(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Batsman',
                  isSelected: _selectedPlayerType == 'batsman',
                  onSelected: () => _onFilterByType('batsman'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Bowler',
                  isSelected: _selectedPlayerType == 'bowler',
                  onSelected: () => _onFilterByType('bowler'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'All-Rounder',
                  isSelected: _selectedPlayerType == 'all-rounder',
                  onSelected: () => _onFilterByType('all-rounder'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Wicket-Keeper',
                  isSelected: _selectedPlayerType == 'wicket-keeper',
                  onSelected: () => _onFilterByType('wicket-keeper'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Player List
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlayers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No players found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPlayers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        playerType: _selectedPlayerType,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          final player = _players[index];
          return _PlayerCard(
            player: player,
            onAddToTeam: () => _showAddToTeamDialog(player),
          );
        },
      ),
    );
  }

  void _showAddToTeamDialog(PublicPlayer player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Team'),
        content: Text('Add ${player.fullName} to your team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${player.fullName} added to team!')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final PublicPlayer player;
  final VoidCallback onAddToTeam;

  const _PlayerCard({
    required this.player,
    required this.onAddToTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              backgroundImage: player.avatar?.url != null
                  ? NetworkImage(player.avatar!.url!)
                  : null,
              child: player.avatar?.url == null
                  ? Text(
                      player.fullName.isNotEmpty
                          ? player.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${player.username}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.sports_cricket,
                        label: player.playerType,
                      ),
                      if (player.city != null) ...[
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.location_on,
                          label: player.city!,
                        ),
                      ],
                    ],
                  ),
                  if (player.cricketProfile?.matchesPlayed != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Matches: ${player.cricketProfile!.matchesPlayed}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Add To Team Button
            ElevatedButton(
              onPressed: onAddToTeam,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
