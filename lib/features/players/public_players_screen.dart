import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/user_service.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/models/team_model.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/public_players_service.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/services/team_service.dart';
import '../chat/chat_screen.dart';

class PublicPlayersScreen extends StatefulWidget {
  const PublicPlayersScreen({super.key});

  @override
  State<PublicPlayersScreen> createState() => _PublicPlayersScreenState();
}

class _PublicPlayersScreenState extends State<PublicPlayersScreen> {
  final PublicPlayersService _service = PublicPlayersService();
  final TeamService _teamService = TeamService();
  List<PublicPlayer> _players = [];
  List<Team> _myTeams = [];
  bool _isLoading = false;
  bool _isAddingPlayer = false;
  Timer? _searchDebounce;
  String? _error;
  String _searchQuery = '';
  String? _selectedPlayerType;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

@override
  void initState() {
    super.initState();
    _loadPlayers();
    _loadMyTeams();
  }

  Future<void> _loadMyTeams() async {
    try {
      final teams = await _teamService.getMyTeams();
      if (mounted) {
        setState(() => _myTeams = teams);
      }
    } catch (e) {
      // Silently fail - user may not have any teams
    }
  }

  Future<void> _loadPlayers({String? search, String? playerType}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _service.getPublicPlayers(
        search: search,
        playerType: playerType,
      );
      if (!mounted) return;
      setState(() {
        _players = response.players;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e, fallback: 'Players load nahi ho paaye.');
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadPlayers(
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        playerType: _selectedPlayerType,
      );
    });
  }

  void _onFilterByType(String? playerType) {
    _selectedPlayerType = playerType;
    _loadPlayers(search: _searchQuery.isEmpty ? null : _searchQuery, playerType: playerType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Find Players'),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or username',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _onSearch,
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedPlayerType == null,
                  onSelected: () => _onFilterByType(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Batsman',
                  isSelected: _selectedPlayerType == 'batsman',
                  onSelected: () => _onFilterByType('batsman'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Bowler',
                  isSelected: _selectedPlayerType == 'bowler',
                  onSelected: () => _onFilterByType('bowler'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'All-Rounder',
                  isSelected: _selectedPlayerType == 'all-rounder',
                  onSelected: () => _onFilterByType('all-rounder'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Wicket-Keeper',
                  isSelected: _selectedPlayerType == 'wicket-keeper',
                  onSelected: () => _onFilterByType('wicket-keeper'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Player List
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlayers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'score 11/Empty States 6.png',
              width: 124,
              height: 124,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              'No players found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPlayers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        playerType: _selectedPlayerType,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          final player = _players[index];
          return _PlayerCard(
            player: player,
            onViewProfile: () => _openPlayerProfile(player),
            onAddToTeam: () => _showAddToTeamDialog(player),
          );
        },
      ),
    );
  }

  void _openPlayerProfile(PublicPlayer player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicPlayerProfileView(player: player),
      ),
    );
  }

void _showAddToTeamDialog(PublicPlayer player) {
    if (_myTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to create a team first to add players'),
        ),
      );
      return;
    }

    Team? selectedTeam;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add to Team'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select a team to add ${player.fullName}:'),
              const SizedBox(height: 16),
              if (_myTeams.isEmpty)
                const Text('No teams found. Create a team first.')
              else
                DropdownButton<Team>(
                  isExpanded: true,
                  value: selectedTeam,
                  hint: const Text('Select Team'),
                  items: _myTeams.map((team) {
                    return DropdownMenuItem(
                      value: team,
                      child: Text(team.name),
                    );
                  }).toList(),
                  onChanged: (team) {
                    setDialogState(() => selectedTeam = team);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isAddingPlayer
                  ? null
                  : () async {
                      if (selectedTeam == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a team')),
                        );
                        return;
                      }

                      Navigator.pop(dialogContext);
                      await _addPlayerToTeam(selectedTeam!, player);
                    },
              child: _isAddingPlayer
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _addPlayerToTeam(Team team, PublicPlayer player) async {
    setState(() => _isAddingPlayer = true);

    try {
      await _teamService.addPlayerWithDetails(
        team.id,
        playerId: player.playerIdForTeam,
        identifier: player.connectionUserId,
        name: player.fullName,
        email: player.email,
        role: player.playerType,
        battingStyle: player.cricketProfile?.battingStyle,
        bowlingStyle: player.cricketProfile?.bowlingStyle,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${player.fullName} added to ${team.name}!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e, fallback: 'Player add nahi ho paaya.'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingPlayer = false);
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final PublicPlayer player;
  final VoidCallback onViewProfile;
  final VoidCallback onAddToTeam;

  const _PlayerCard({
    required this.player,
    required this.onViewProfile,
    required this.onAddToTeam,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _safeUrl(player.avatar?.url);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onViewProfile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      player.fullName.isNotEmpty
                          ? player.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${player.username}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: Icons.sports_cricket,
                        label: player.playerType,
                      ),
                      if (player.city != null) ...[
                        _InfoChip(
                          icon: Icons.location_on,
                          label: player.city!,
                        ),
                      ],
                    ],
                  ),
                  if (player.cricketProfile?.matchesPlayed != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Matches: ${player.cricketProfile!.matchesPlayed}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Add To Team Button
            ElevatedButton(
              onPressed: onAddToTeam,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(44, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String? _safeUrl(String? value) {
    final url = value?.trim();
    if (url == null || url.isEmpty || url == 'default-avatar-url') return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty)) return null;
    return url;
  }
}

class PublicPlayerProfileView extends StatefulWidget {
  final PublicPlayer player;

  const PublicPlayerProfileView({super.key, required this.player});

  @override
  State<PublicPlayerProfileView> createState() => _PublicPlayerProfileViewState();
}

class _PublicPlayerProfileViewState extends State<PublicPlayerProfileView> {
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();

  bool _isLoadingFollowStatus = true;
  bool _isFollowing = false;
  bool _isActionProcessing = false;
  String? _followError;

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    bool followQuerySuccess = false;
    try {
      final result = await _userService.getFollowing();
      if (!mounted) return;
      if (result['success'] == true) {
        followQuerySuccess = true;
        final following = result['data'] is List ? result['data'] as List<dynamic> : <dynamic>[];
        setState(() {
          _isFollowing = following.any((item) {
            if (item is Map) {
              final id = item['_id']?.toString() ?? item['id']?.toString();
              return id == widget.player.connectionUserId;
            }
            return false;
          });
          _followError = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _followError = friendlyError(e, fallback: 'Follow update nahi ho paaya.');
      });
    }
    if (!mounted) return;
    setState(() {
      _isLoadingFollowStatus = false;
      if (!followQuerySuccess && _followError == null) {
        _followError = 'Unable to load follow status';
      }
    });
  }

  Future<void> _toggleFollow() async {
    if (_isActionProcessing) return;

    setState(() => _isActionProcessing = true);
    try {
      final result = _isFollowing
          ? await _userService.unfollowUser(widget.player.connectionUserId)
          : await _userService.followUser(widget.player.connectionUserId);

      if (result['success'] == true) {
        if (!mounted) return;
        setState(() {
          _isFollowing = !_isFollowing;
          _followError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'Followed successfully' : 'Unfollowed successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (!mounted) return;
        final message = result['message']?.toString() ?? 'Unable to update follow status';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(e, fallback: 'Action complete nahi ho paaya.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionProcessing = false);
      }
    }
  }

  Future<void> _openChat() async {
    try {
      final chat = await _chatService.getChatByUserId(widget.player.connectionUserId);
      if (!mounted) return;
      final chatId = chat['chatId']?.toString() ?? '';
      final otherUser = {
        '_id': widget.player.connectionUserId,
        'playerId': widget.player.id,
        'name': widget.player.fullName.isNotEmpty ? widget.player.fullName : widget.player.username,
      };
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: chatId, otherUser: otherUser),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyError(e, fallback: 'Chat open nahi ho paayi.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.player.cricketProfile;
    final avatarUrl = _safeUrl(widget.player.avatar?.url);
    final location = [
      widget.player.city,
      widget.player.state,
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

    return Scaffold(
      appBar: CustomAppBar(title: widget.player.fullName.isEmpty ? 'Player Profile' : widget.player.fullName),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('score 11/Player Profile cover page.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  opacity: 0.12,
                ),
              ),
              child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.primary,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? ClipOval(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'score 11/Player Profile avatr circle page.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                ),
                                Center(
                                  child: Text(
                                    widget.player.fullName.isNotEmpty ? widget.player.fullName[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.player.fullName.isEmpty ? 'Unknown Player' : widget.player.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  if (widget.player.username.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('@${widget.player.username}', style: TextStyle(color: Colors.grey[600])),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            location,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isActionProcessing ? null : _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.grey[700] : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoadingFollowStatus
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : Text(_isFollowing ? 'Unfollow' : 'Follow'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _openChat,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.9)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Message'),
                ),
              ),
            ],
          ),
          if (_followError != null) ...[
            const SizedBox(height: 12),
            Text(
              _followError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Playing Style',
            children: [
              _ProfileRow(label: 'Role', value: profile?.playerType ?? widget.player.playerType),
              _ProfileRow(label: 'Batting', value: profile?.battingStyle ?? 'N/A'),
              _ProfileRow(label: 'Bowling', value: profile?.bowlingStyle ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Career Stats',
            children: [
              _ProfileRow(label: 'Matches', value: (profile?.matchesPlayed ?? widget.player.stats?.matchesPlayed ?? 0).toString()),
              _ProfileRow(label: 'Runs', value: (profile?.totalRuns ?? 0).toString()),
              _ProfileRow(label: 'Wickets', value: (profile?.totalWickets ?? 0).toString()),
              _ProfileRow(label: 'Highest Score', value: (profile?.highestScore ?? 0).toString()),
              _ProfileRow(
                label: 'Batting Average',
                value: profile?.battingAverage?.toStringAsFixed(1) ?? '0.0',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _safeUrl(String? value) {
    final url = value?.trim();
    if (url == null || url.isEmpty || url == 'default-avatar-url') return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty)) return null;
    return url;
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
