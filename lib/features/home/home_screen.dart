import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<Map<String, dynamic>> _liveMatches = [
    {'team1': 'India', 'team2': 'Australia', 'score1': '245/6', 'score2': '178/3', 'overs': '34.2', 'status': 'India won', 'isLive': false},
    {'team1': 'England', 'team2': 'Pakistan', 'score1': '156/2', 'score2': '-', 'overs': '25', 'status': 'LIVE', 'isLive': true},
    {'team1': 'South Africa', 'team2': 'New Zealand', 'score1': '0/0', 'score2': '-', 'overs': 'Yet to bat', 'status': 'Starting soon', 'isLive': false},
  ];

  final List<Map<String, dynamic>> _posts = [
    {'user': 'Cricket Fan', 'content': 'Amazing match today! 🏏️', 'likes': 245, 'comments': 32, 'time': '2h ago', 'image': 'https://picsum.photos/400/300'},
    {'user': 'Sports Analyst', 'content': 'Player performance review coming soon...', 'likes': 128, 'comments': 15, 'time': '4h ago', 'image': null},
    {'user': 'Cricket Academy', 'content': 'Join our coaching camp this weekend!', 'likes': 89, 'comments': 45, 'time': '6h ago', 'image': 'https://picsum.photos/400/300'},
  ];

  final List<Map<String, dynamic>> _challenges = [
    {'title': 'T20 Champions', 'entry': '₹50', 'prize': '₹5,000', 'participants': 128, 'ends': '2 days'},
    {'title': 'Sunday League', 'entry': '₹100', 'prize': '₹10,000', 'participants': 64, 'ends': '5 hours'},
    {'title': 'Quick Match', 'entry': '₹25', 'prize': '₹1,000', 'participants': 256, 'ends': '1 day'},
  ];

  final List<Map<String, dynamic>> _popularPlayers = [
    {'name': 'Virat Kohli', 'followers': '2.5M', 'isFollowing': true, 'image': 'https://picsum.photos/100/100', 'id': '1'},
    {'name': 'Rohit Sharma', 'followers': '1.8M', 'isFollowing': false, 'image': 'https://picsum.photos/100/100', 'id': '2'},
    {'name': 'Jasprit Bumrah', 'followers': '900K', 'isFollowing': true, 'image': 'https://picsum.photos/100/100', 'id': '3'},
    {'name': 'Hardik Pandya', 'followers': '750K', 'isFollowing': false, 'image': 'https://picsum.photos/100/100', 'id': '4'},
  ];

  final List<Map<String, dynamic>> _shortcuts = [
    {'icon': Icons.group_add, 'label': 'Create Team', 'route': '/create-team'},
    {'icon': Icons.play_arrow, 'label': 'Start Match', 'route': '/create-match'},
    {'icon': Icons.bar_chart, 'label': 'View Stats', 'route': '/stats'},
    {'icon': Icons.emoji_events, 'label': 'My Tournaments', 'route': '/my-tournaments'},
    {'icon': Icons.wallet, 'label': 'Wallet', 'route': '/wallet'},
    {'icon': Icons.history, 'label': 'History', 'route': '/history'},
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home, 'label': 'Home', 'route': '/home'},
    {'icon': Icons.explore, 'label': 'Discover', 'route': '/discover'},
    {'icon': Icons.person, 'label': 'My Profile', 'route': '/profile'},
    {'icon': Icons.group, 'label': 'My Teams', 'route': '/my-teams'},
    {'icon': Icons.emoji_events, 'label': 'Tournaments', 'route': '/my-tournaments'},
    {'icon': Icons.wallet, 'label': 'Wallet', 'route': '/wallet'},
    {'icon': Icons.settings, 'label': 'Settings', 'route': '/settings'},
    {'icon': Icons.help, 'label': 'Help & Support', 'route': '/support'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDropdown() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Options', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildFilterOption('Matches', Icons.sports_cricket),
            _buildFilterOption('Players', Icons.person),
            _buildFilterOption('Teams', Icons.group),
            _buildFilterOption('Tournaments', Icons.emoji_events),
            _buildFilterOption('Clubs', Icons.groups),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        // Navigate to filtered results
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: CustomScrollView(
        slivers: [
          // Dynamic App Bar
          SliverAppBar(
            expandedHeight: _isSearching ? 60 : 120,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search players, teams, matches...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _searchController.clear();
                          });
                        },
                      ),
                    ),
                    onSubmitted: (value) {
                      // Handle search
                      _performSearch(value);
                    },
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cric11', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      if (user != null)
                        Text(
                          'Welcome, ${user.name ?? 'User'}',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                    ],
                  ),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                    }
                  });
                },
              ),
              // Notification Icon with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
              // Chat/Message Icon
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  Navigator.pushNamed(context, '/messages');
                },
              ),
              // Filter/Dropdown button
              PopupMenuButton<String>(
                icon: const Icon(Icons.tune),
                onSelected: (value) {
                  if (value == 'filter') {
                    _showFilterDropdown();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'filter',
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Filter'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'sort',
                    child: Row(
                      children: [
                        Icon(Icons.sort, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Sort'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bottom Navigation
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Quick Shortcuts
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _shortcuts.length,
                          itemBuilder: (context, index) {
                            final shortcut = _shortcuts[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, shortcut['route']);
                              },
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(shortcut['icon'], color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(shortcut['label'], style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Matches Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('🔴 Live Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(onPressed: () {}, child: const Text('See All')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _liveMatches.length,
                          itemBuilder: (context, index) {
                            final match = _liveMatches[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/match-detail');
                              },
                              child: Container(
                                width: 280,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(match['team1'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(match['score1'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(match['team2'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(match['score2'], style: TextStyle(color: Colors.grey[600])),
                                      ],
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: match['isLive'] ? AppColors.error : Colors.grey,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(match['status'], style: const TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Popular Players (Follow/Unfollow with DM option)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('⭐ Popular Players', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(onPressed: () {}, child: const Text('Find Players')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _popularPlayers.length,
                          itemBuilder: (context, index) {
                            final player = _popularPlayers[index];
                            return Container(
                              width: 110,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          // Navigate to player profile
                                          Navigator.pushNamed(context, '/player-profile', arguments: player['id']);
                                        },
                                        child: CircleAvatar(
                                          radius: 35,
                                          backgroundImage: NetworkImage(player['image']),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(Icons.circle, size: 8, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(player['name'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                                  Text(player['followers'], style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            player['isFollowing'] = !player['isFollowing'];
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: player['isFollowing'] ? Colors.grey[200] : AppColors.primary,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            player['isFollowing'] ? 'Following' : 'Follow',
                                            style: TextStyle(fontSize: 9, color: player['isFollowing'] ? Colors.black : Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          // Open chat/direct message
                                          Navigator.pushNamed(context, '/chat', arguments: player['id']);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.message, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Challenges Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('🏆 Active Challenges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton(onPressed: () {}, child: const Text('Create Challenge')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._challenges.asMap().entries.map((entry) {
                        final index = entry.key;
                        final challenge = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.emoji_events, color: AppColors.secondary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(challenge['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Entry: ${challenge['entry']} | Prize: ${challenge['prize']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    Text('${challenge['participants']} joined | Ends in ${challenge['ends']}', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Join'),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
                      }),
                    ],
                  ),
                ),

                // Posts Feed
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📱 Community Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._posts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final post = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Text(post['user'][0], style: const TextStyle(color: Colors.white)),
                                ),
                                title: Text(post['user'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(post['time'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                trailing: IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(post['content']),
                              ),
                              if (post['image'] != null) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  child: Image.network(post['image'], height: 180, width: double.infinity, fit: BoxFit.cover),
                                ),
                              ],
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    _buildActionButton(Icons.thumb_up, '${post['likes']}'),
                                    _buildActionButton(Icons.comment, '${post['comments']}'),
                                    _buildActionButton(Icons.share, 'Share'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
                      }),
                    ],
                  ),
                ),

                // Find Cricket Section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('🔍 Find Cricket Near You', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Find players, teams, and tournaments near your location', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                        child: const Text('Explore Now'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home, 'Home'),
                _buildNavItem(1, Icons.explore, 'Looking'),
                _buildNavItem(2, Icons.sports_cricket, 'My Cricket'),
                _buildNavItem(3, Icons.people, 'Community'),
                _buildNavItem(4, Icons.store, 'Store'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                const Text('Cric11 User', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('user@scores11.com', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
              ],
            ),
          ),
          ..._menuItems.map((item) => ListTile(
            leading: Icon(item['icon'], color: AppColors.primary),
            title: Text(item['label']),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, item['route']);
            },
          )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    // Implement search functionality
    if (query.isNotEmpty) {
      // Navigate to search results
    }
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Expanded(
      child: TextButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        // Navigate based on index
        switch (index) {
          case 0:
            // Home - already here
            break;
          case 1:
            Navigator.pushNamed(context, '/discover');
            break;
          case 2:
            Navigator.pushNamed(context, '/my-cricket');
            break;
          case 3:
            Navigator.pushNamed(context, '/community');
            break;
          case 4:
            Navigator.pushNamed(context, '/store');
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
