import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../data/services/user_service.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> 
  with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  
  List<dynamic> _followers = [];
  List<dynamic> _following = [];
  
  late TabController _tabController;
  bool _isLoading = true;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConnections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    setState(() => _isLoading = true);
    try {
      final followersResult = await _userService.getFollowers();
      final followingResult = await _userService.getFollowing();
      
      if (mounted) {
        setState(() {
          _followers = followersResult['data'] ?? [];
          _following = followingResult['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading connections: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Connections',
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _ConnectionList(
                users: _followers,
                type: 'followers',
                onAction: _unfollowUser,
              ),
              _ConnectionList(
                users: _following,
                type: 'following',
                onAction: _unfollowUser,
              ),
            ],
          ),
    );
  }

  Future<void> _unfollowUser(String userId) async {
    try {
      await _userService.unfollowUser(userId);
      _loadConnections(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class _ConnectionList extends StatelessWidget {
  final List<dynamic> users;
  final String type;
  final Function(String) onAction;

  const _ConnectionList({
    required this.users,
    required this.type,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No ${type}',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }


    return RefreshIndicator(
      onRefresh: () async {
        final state = context.findAncestorStateOfType<_ConnectionsScreenState>();
        if (state != null) {
          await state._loadConnections();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(user['name']?[0]?.toUpperCase() ?? '?'),
              ),
              title: Text(user['name'] ?? 'Unknown'),
              subtitle: Text(user['role'] ?? user['playingStyle'] ?? 'Player'),
              trailing: ElevatedButton(
                onPressed: () => onAction(user['id']),
                child: Text(type == 'followers' ? 'Remove' : 'Unfollow'),
              ),
              onTap: () => Navigator.pushNamed(context, '/profile/${user['id']}'),
            ),
          );
        },
      ),
    );
  }
}

