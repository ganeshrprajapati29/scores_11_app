import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../data/services/player_service.dart';
import '../../../data/models/player_model.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String playerId;
  const PlayerProfileScreen({super.key, required this.playerId});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  final PlayerService _playerService = PlayerService();
  Player? _player;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayerProfile();
  }

  Future<void> _loadPlayerProfile() async {
    setState(() => _isLoading = true);
    try {
      final player = await _playerService.getPlayerById(widget.playerId);
      if (mounted) {
        setState(() {
          _player = player;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Player Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share profile logic
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      ElevatedButton(
                        onPressed: _loadPlayerProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _player == null
                  ? const Center(child: Text('Player not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Header
                          Row(
                            children: [
                              // Photo
                              ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  backgroundImage: _player!.photo != null || _player!.profileImage != null
                                      ? NetworkImage(_player!.photo ?? _player!.profileImage!)
                                      : null,
                                  child: _player!.photo == null && _player!.profileImage == null
                                      ? Text(
                                          _player!.name.isNotEmpty ? _player!.name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _player!.name,
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                    if (_player!.role != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _player!.role!.toUpperCase(),
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    if (_player!.jerseyNumber != null)
                                      Text(
                                        '#${_player!.jerseyNumber}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      ),
                                    if (_player!.teamName != null)
                                      Text('Team: ${_player!.teamName}', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Basic Info Cards
                          Row(
                            children: [
                              Expanded(child: _InfoCard(label: 'Batting', value: _player!.battingStyle ?? 'N/A')),
                              const SizedBox(width: 12),
                              Expanded(child: _InfoCard(label: 'Bowling', value: _player!.bowlingStyle ?? 'N/A')),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Stats Section
                          Text(
                            'Career Stats',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (_player!.stats != null) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildBattingStats(_player!.stats!),
                                    const Divider(),
                                    _buildBowlingStats(_player!.stats!),
                                  ],
                                ),
                              ),
                            ),
                          ] else
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No stats available'),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.follow_the_signs),
                                  label: const Text('Follow'),
                                  onPressed: () {},
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share'),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildBattingStats(PlayerStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Batting', style: TextStyle(fontWeight: FontWeight.bold)),
        _StatRow('Matches', stats.matches.toString()),
        _StatRow('Runs', stats.runs.toString()),
        _StatRow('Average', stats.average.toStringAsFixed(1)),
        _StatRow('Strike Rate', stats.strikeRate.toStringAsFixed(1)),
        _StatRow('HS', stats.highestScore.toString()),
        _StatRow('100s', stats.hundreds.toString()),
        _StatRow('50s', stats.fifties.toString()),
      ],
    );
  }

  Widget _buildBowlingStats(PlayerStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bowling', style: TextStyle(fontWeight: FontWeight.bold)),
        _StatRow('Wickets', stats.wickets.toString()),
        _StatRow('Economy', stats.economy.toStringAsFixed(1)),
        _StatRow('Best', '${stats.bestBowlingWickets}/${stats.bestBowlingRuns}'),
      ],
    );
  }

  Widget _InfoCard({required String label, required String value}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _StatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
