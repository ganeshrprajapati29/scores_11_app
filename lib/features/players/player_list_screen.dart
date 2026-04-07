import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/player_service.dart';
import '../../../data/models/player_model.dart';


class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({super.key});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  final PlayerService _playerService = PlayerService();
  List<Player> _players = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedRole;

  final List<String> _roles = ['Batsman', 'Bowler', 'All-rounder', 'Wicketkeeper'];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Players List',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadPlayers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onSubmitted: _searchPlayers,
                  decoration: InputDecoration(
                    hintText: 'Search players...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchPlayers('');
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _roles.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _FilterChip(
                          label: 'All',
                          isSelected: _selectedRole == null,
                          onTap: () => setState(() => _selectedRole = null),
                        );
                      }
                      final role = _roles[index - 1];
                      return _FilterChip(
                        label: role,
                        isSelected: _selectedRole == role,
                        onTap: () => setState(() => _selectedRole = role),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _players.isEmpty && !_isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No players found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPlayers,
                        child: const Text('Load Players'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _players.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _players.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final player = _players[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          player.name.isNotEmpty ? player.name : 'Unknown Player',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (player.role != null) Text('Role: ${player.role}'),
                            if (player.teamName != null) Text('Team: ${player.teamName}'),
                            if (player.jerseyNumber != null) Text('#${player.jerseyNumber}'),
                            if (player.stats != null) Text('${player.stats!.runs} Runs | ${player.stats!.wickets} Wkts'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () async {
                                try {
                                  Navigator.pushNamed(context, '/player-profile/${player.id}');
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Navigation error: $e')),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => Navigator.pushNamed(context, '/create-player', arguments: player.id),
                            ),
                          ],
                        ),
                        onTap: () async {
                          try {
                            Navigator.pushNamed(context, '/player-profile/${player.id}');
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Navigation error: $e')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-player'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
