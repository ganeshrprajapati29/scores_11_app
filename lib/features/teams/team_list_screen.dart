import 'package:flutter/material.dart';
import '../../core/config/theme_config.dart';
import '../../data/models/team_model.dart';
import '../../data/services/team_service.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  final TeamService _teamService = TeamService();
  List<Team> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      final teams = await _teamService.getTeams();
      setState(() {
        _teams = teams;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      const Text(
                        'No teams yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/create-team');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Team'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTeams,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      return _TeamCard(team: _teams[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-team');
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Team'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/team-detail', arguments: team.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Team Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: team.logo?.url != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          team.logo!.url!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.groups,
                        color: AppColors.primary,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 16),
              // Team Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (team.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team.shortName ?? team.name.substring(0, 3).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatChip(
                          label: 'P',
                          value: '${team.stats?.matchesPlayed ?? 0}',
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'W',
                          value: '${team.stats?.matchesWon ?? 0}',
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'L',
                          value: '${team.stats?.matchesLost ?? 0}',
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
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
