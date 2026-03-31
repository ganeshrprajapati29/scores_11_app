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
  final TeamService _teamService = TeamService();

  @override
  void initState() {
    super.initState();
    _loadMyTeams();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMyTeams() async {
    setState(() => _isLoading = true);
    try {
      final teams = await _teamService.getMyTeams();
      setState(() {
        _teams = teams;
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
    // Pagination future expansion
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadMyTeams,
            child: _teams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_cricket, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No teams yet', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Create your first cricket team!', style: TextStyle(color: Colors.grey[600])),
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
                      child: ListTile(
leading: team.logo?.url != null
                          ? CircleAvatar(backgroundImage: NetworkImage(team.logo!.url!))
                          : const CircleAvatar(child: Icon(Icons.sports_cricket)),
                        title: Text(team.name ?? 'Unnamed Team'),
                        subtitle: Text('${team.city ?? 'Unknown'}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => Navigator.pushNamed(context, '/team-detail', arguments: team.id),
                      ),
                    );
                  },
                ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'team_list_create_${DateTime.now().millisecondsSinceEpoch}',
        onPressed: () => Navigator.pushNamed(context, '/create-team'),
        icon: const Icon(Icons.add),
        label: const Text('Create Team'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
