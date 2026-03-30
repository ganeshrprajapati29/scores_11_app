import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/custom_button.dart';
import '../../data/services/player_service.dart';
import '../../data/models/player_model.dart';
import '../../data/services/team_service.dart';
import '../../core/constants/enums.dart';

class FindPlayerScreen extends StatefulWidget {
  final String? teamId; 

  const FindPlayerScreen({super.key, this.teamId});

  @override
  State<FindPlayerScreen> createState() => _FindPlayerScreenState();
}

class _FindPlayerScreenState extends State<FindPlayerScreen> {
  final PlayerService _playerService = PlayerService();
  final TeamService _teamService = TeamService();
  final TextEditingController _searchController = TextEditingController();
  List<Player> _players = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _query = '';
  Player? _selectedPlayer;
  bool _isDetailLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length > 1 && query != _query) {
      _performSearch(query);
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
      final players = await _playerService.searchPlayers(query);
      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPlayerToTeam(Player player) async {
    if (widget.teamId == null) return;
    try {
      await _teamService.addPlayer(widget.teamId!, player.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${player.name} added to team!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showPlayerDetails(Player player) async {
    setState(() {
      _selectedPlayer = player;
      _isDetailLoading = true;
    });

    try {
      final fullPlayer = await _playerService.getPlayerById(player.id);
      if (mounted) {
        _showDetailsModal(fullPlayer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load details: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetailLoading = false);
      }
    }
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
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Player Photo
                    if (player.profileImage != null || player.photo != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.network(
                          player.profileImage ?? player.photo!,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 40,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Name & Role
                    Text(
                      player.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (player.role != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          player.role!,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (player.jerseyNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '#${player.jerseyNumber}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Basic Info
                    _buildInfoRow(Icons.flag, 'Nationality', player.nationality ?? 'N/A'),
                    _buildInfoRow(Icons.cake, 'Date of Birth', player.dateOfBirth ?? 'N/A'),
                    _buildInfoRow(Icons.sports_baseball, 'Batting', player.battingStyle ?? 'N/A'),
                    _buildInfoRow(Icons.sports_cricket, 'Bowling', player.bowlingStyle ?? 'N/A'),
                    if (player.teamName != null) _buildInfoRow(Icons.group, 'Team', player.teamName!),
                    const SizedBox(height: 24),
                    // Stats
                    if (player.stats != null) ...[
                      Text(
                        'Career Stats',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsRow(Icons.sports_score, 'Matches', player.stats!.matches.toString()),
                      _buildStatsRow(Icons.trending_up, 'Runs', '${player.stats!.runs} (Avg: ${player.stats!.average.toStringAsFixed(1)} SR: ${player.stats!.strikeRate.toStringAsFixed(1)}'),
                      _buildStatsRow(Icons.local_fire_department, '100s/50s', '${player.stats!.hundreds}/${player.stats!.fifties}'),
                      _buildStatsRow(Icons.remove, 'HS', player.stats!.highestScore.toString()),
                      _buildStatsRow(Icons.sports_tennis, 'Wickets', player.stats!.wickets.toString()),
                      if (player.stats!.economy > 0) _buildStatsRow(Icons.speed, 'Economy', player.stats!.economy.toStringAsFixed(1)),
                    ],
                    const SizedBox(height: 24),
                    // Action Button
                    if (widget.teamId != null)
                      CustomButton(
                        text: 'Add to Team',
                        onPressed: () {
                          Navigator.pop(context);
                          _addPlayerToTeam(player);
                        },
                        icon: Icons.add,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStatsRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _viewPlayerProfile(Player player) {
    _showPlayerDetails(player);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Find Players',
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _players.clear();
                  _isSearching = false;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search players by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ) : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          Expanded(
            child: _isSearching && _players.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No players found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  )
                : _players.isEmpty && !_isSearching
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_cricket, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Start typing to find players', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _players.length,
                        itemBuilder: (context, index) {
                          final player = _players[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                player.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (player.role != null) Text(player.role!),
                                  if (player.battingStyle != null) ...[
                                    Text(player.battingStyle!, style: TextStyle(color: Colors.green[600], fontSize: 12)),
                                    if (player.bowlingStyle != null) Text('${player.bowlingStyle}'),
                                  ],
                                  if (player.teamName != null) Text(player.teamName!, style: TextStyle(color: Colors.grey[600])),
                                  if (player.jerseyNumber != null) Text('#${player.jerseyNumber}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () => _showPlayerDetails(player),
                                  ),
                                  if (widget.teamId != null)
                                    CustomButton(
                                      text: 'Add',
                                      onPressed: () => _addPlayerToTeam(player),
                                      variant: ButtonVariant.outlined,
                                      icon: Icons.add,
                                    ),
                                ],
                              ),
                              onTap: () => _viewPlayerProfile(player),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

