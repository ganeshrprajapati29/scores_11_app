import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TeamListScreen extends StatefulWidget {
  const TeamListScreen({super.key});

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500)); // Mock API delay
    setState(() {
      _teams = [
        {
          'id': '1',
          'name': 'Mumbai Indians',
          'logo': 'https://via.placeholder.com/60x60/ff0000/ffffff?text=MI',
          'city': 'Mumbai',
          'wins': 8,
          'losses': 2,
        },
        {
          'id': '2',
          'name': 'Chennai Super Kings',
          'logo': 'https://via.placeholder.com/60x60/yellow/000000?text=CSK',
          'city': 'Chennai',
          'wins': 7,
          'losses': 3,
        },
        {
          'id': '3',
          'name': 'Royal Challengers Bangalore',
          'logo': 'https://via.placeholder.com/60x60/0000ff/ffffff?text=RCB',
          'city': 'Bengaluru',
          'wins': 6,
          'losses': 4,
        },
      ];
      _isLoading = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _isLoadingMore = false;
      _hasMore = false; // Mock no more data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
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
            onRefresh: _loadTeams,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _teams.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _teams.length) {
                  return _isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink();
                }
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(_teams[index]['logo']),
                      onBackgroundImageError: (_, __) {},
                      child: const Icon(Icons.sports_cricket),
                    ),
                    title: Text(_teams[index]['name']),
                    subtitle: Text('${_teams[index]['city']} • ${_teams[index]['wins']}W-${_teams[index]['losses']}L'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => Navigator.pushNamed(context, '/team-detail', arguments: _teams[index]['id']),
                  ),
                );
              },
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-team'),
        icon: const Icon(Icons.add),
        label: const Text('Create Team'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
