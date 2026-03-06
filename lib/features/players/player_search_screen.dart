import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_appbar.dart';

class PlayerSearchScreen extends StatefulWidget {
  const PlayerSearchScreen({super.key});

  @override
  State<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends State<PlayerSearchScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  
  final List<Map<String, dynamic>> _players = [
    {'name': 'Virat Kohli', 'role': 'Batsman', 'team': 'Royal Challengers Bangalore', 'rating': 4.8, 'image': 'https://picsum.photos/100/100'},
    {'name': 'Rohit Sharma', 'role': 'Batsman', 'team': 'Mumbai Indians', 'rating': 4.7, 'image': 'https://picsum.photos/100/100'},
    {'name': 'Jasprit Bumrah', 'role': 'Bowler', 'team': 'Mumbai Indians', 'rating': 4.9, 'image': 'https://picsum.photos/100/100'},
    {'name': 'MS Dhoni', 'role': 'Wicket Keeper', 'team': 'Chennai Super Kings', 'rating': 4.6, 'image': 'https://picsum.photos/100/100'},
    {'name': 'Hardik Pandya', 'role': 'All-Rounder', 'team': 'Mumbai Indians', 'rating': 4.5, 'image': 'https://picsum.photos/100/100'},
    {'name': 'Ravindra Jadeja', 'role': 'All-Rounder', 'team': 'Chennai Super Kings', 'rating': 4.5, 'image': 'https://picsum.photos/100/100'},
    {'name': 'Shubman Gill', 'role': 'Batsman', 'team': 'Gujarat Titans', 'rating': 4.4, 'image': 'https://picsum.photos/100/100'},
    {'name': 'Mohammed Shami', 'role': 'Bowler', 'team': 'Gujarat Titans', 'rating': 4.6, 'image': 'https://picsum.photos/100/100'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlayers = _players.where((player) {
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'batsman') return player['role'] == 'Batsman';
      if (_selectedFilter == 'bowler') return player['role'] == 'Bowler';
      if (_selectedFilter == 'all-rounder') return player['role'] == 'All-Rounder';
      return true;
    }).where((player) {
      if (_searchController.text.isEmpty) return true;
      return player['name'].toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

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
                              setState(() {});
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
                  onChanged: (value) => setState(() {}),
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
            child: filteredPlayers.isEmpty
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
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = filteredPlayers[index];
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
                                arguments: player['name'],
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
                                        backgroundImage: NetworkImage(player['image']),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(player['role']),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            player['role'][0],
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
                                          player['name'],
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
                                                color: _getRoleColor(player['role']).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                player['role'],
                                                style: TextStyle(
                                                  color: _getRoleColor(player['role']),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                player['team'],
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
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            player['rating'].toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
                    },
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
      },
      selectedColor: Colors.white,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.white,
      ),
      checkmarkColor: AppColors.primary,
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Batsman':
        return Colors.blue;
      case 'Bowler':
        return Colors.red;
      case 'All-Rounder':
        return Colors.purple;
      case 'Wicket Keeper':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

