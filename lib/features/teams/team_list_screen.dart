import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../../data/models/team_model.dart';
import '../../../data/services/team_service.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  List<Team> _teams = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final TeamService _teamService = TeamService();

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final paginated = await _teamService.getTeams(search: search ?? _searchController.text.trim());
      setState(() {
        _teams = paginated.teams;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading teams: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    // Add pagination logic here
    setState(() => _isLoadingMore = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Teams'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTeams(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search teams...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadTeams(),
                    child: _teams.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sports_cricket, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text('No teams found', style: TextStyle(fontSize: 18)),
                                const SizedBox(height: 8),
                                Text('Try searching or create new team!', style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pushNamed(context, '/create-team'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Team'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _teams.length,
                            itemBuilder: (context, index) {
                              final team = _teams[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: team.logo?.url != null
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(team.logo!.url!),
                                        )
                                      : CircleAvatar(
                                          backgroundColor: AppColors.primary.withOpacity(0.2),
                                          child: Text(
                                            team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                  title: Text(
                                    team.name ?? 'Unnamed Team',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (team.city != null) Text('${team.city}, ${team.state ?? ''}'),
                                      Text('${team.players.length} players'),
                                      if (team.stats != null) Text('Win Rate: ${team.stats!.winPercentage.toStringAsFixed(1)}%'),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () => Navigator.pushNamed(
                                    context, 
                                    '/team-detail', 
                                    arguments: team.id,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_team_${DateTime.now().millisecondsSinceEpoch}',
        onPressed: () => Navigator.pushNamed(context, '/create-team'),
        icon: const Icon(Icons.add),
        label: const Text('Create Team'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
