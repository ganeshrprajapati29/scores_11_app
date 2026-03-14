import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../core/config/theme_config.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/match_service.dart';
import '../../data/services/tournament_service.dart';
import '../../data/services/leaderboard_service.dart';
import '../../data/services/news_service.dart'; // Assume exists or create
import '../../data/services/community_service.dart'; // Assume exists
import '../../data/models/match_model.dart';
import '../../core/constants/app_routes.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final MatchService _matchService = MatchService();
  final TournamentService _tournamentService = TournamentService();
  final LeaderboardService _leaderboardService = LeaderboardService();

  List<Match> _liveMatches = [];
  List<Match> _upcomingMatches = [];
  List<Map<String, dynamic>> _trendingPlayers = [];
  List _activeTournaments = [];
  List _leaderboard = [];
  List _news = [];
  List _communityPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Parallel API calls
      final liveMatches = _matchService.getLiveMatches();
      final upcomingMatches = _matchService.getUpcomingMatches(limit: 2);
      final trendingPlayers = _leaderboardService.getTopBatsmen(limit: 5);
      final activeTournaments = _tournamentService.getOngoingTournaments(limit: 3);
      final leaderboard = _leaderboardService.getTopBatsmen(limit: 2);
      // Add news and community calls when services ready

      await Future.wait([
        liveMatches.then((matches) => _liveMatches = matches),
        upcomingMatches.then((matches) => _upcomingMatches = matches),
        trendingPlayers.then((players) => _trendingPlayers = players.entries),
        activeTournaments.then((tournaments) => _activeTournaments = tournaments),
        leaderboard.then((lb) => _leaderboard = lb.entries),
      ]);
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: user?.avatar?.url != null 
                      ? NetworkImage(user!.avatar!.url!) 
                      : null,
                    child: user?.avatar?.url == null 
                      ? Icon(Icons.person, color: AppColors.primary)
                      : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, ${user?.name ?? 'Cricketer'} 👋', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(user?.address?.city ?? 'Your City', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.notifications), onPressed: () => Navigator.pushNamed(context, '/notifications')),
              IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.pushNamed(context, '/search')),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else ...[
            // 2. Live Matches
            _buildLiveMatchesSection(),
            // 3. Quick Actions
            _buildQuickActionsSection(),
            // 4. Upcoming Matches
            _buildUpcomingMatchesSection(),
            // 5. Trending Players
            _buildTrendingPlayersSection(),
            // 6. Active Tournaments
            _buildActiveTournamentsSection(),
            // 9. Leaderboard Preview
            _buildLeaderboardPreview(),
            // 8. Community Feed
            _buildCommunitySection(),
            // 7. Latest News
            _buildNewsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveMatchesSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🔴 Live Matches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => Navigator.pushNamed(context, '/matches'), child: const Text('See All')),
              ],
            ),
            const SizedBox(height: 12),
            ..._liveMatches.take(2).map((match) => _LiveMatchCard(match: match)).toList(),
            if (_liveMatches.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/matches'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All Live Matches'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚡ Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _QuickActionButton(
                  icon: Icons.sports_cricket,
                  label: 'Create Match',
                  onTap: () => Navigator.pushNamed(context, '/create-match'),
                ),
                _QuickActionButton(
                  icon: Icons.group_add,
                  label: 'Create Team',
                  onTap: () => Navigator.pushNamed(context, '/create-team'),
                ),
                _QuickActionButton(
                  icon: Icons.emoji_events,
                  label: 'Create Tournament',
                  onTap: () => Navigator.pushNamed(context, '/create-tournament'),
                ),
                _QuickActionButton(
                  icon: Icons.add_circle,
                  label: 'Join Match',
                  onTap: () => Navigator.pushNamed(context, '/join-match'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingMatchesSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📅 Upcoming Matches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => Navigator.pushNamed(context, '/matches'), child: const Text('See All')),
              ],
            ),
            const SizedBox(height: 12),
            ..._upcomingMatches.map((match) => _UpcomingMatchCard(match: match)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingPlayersSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⭐ Trending Players', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _trendingPlayers.length,
                itemBuilder: (context, index) {
                  final player = _trendingPlayers[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(player['avatar'] ?? ''),
                              child: player['avatar'] == null ? const Icon(Icons.person) : null,
                            ),
                            const SizedBox(height: 8),
                            Text(player['name'] ?? 'Player', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            Text('${player['runs'] ?? 0} Runs', style: TextStyle(fontSize: 12)),
                            Text('${player['wickets'] ?? 0} Wkts', style: TextStyle(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add remaining sections similarly: Active Tournaments, Leaderboard Preview, Community, News

  Widget _LiveMatchCard({required Match match}) {
    return Card(
      child: ListTile(
        title: Text('${match.team1} vs ${match.team2}'),
        subtitle: Text('${match.score} (${match.currentOvers})'),
        trailing: const ElevatedButton.icon(
          icon: Icon(Icons.play_arrow),
          label: Text('Live'),
          onPressed: null,
        ),
      ),
    );
  }

  Widget _UpcomingMatchCard({required Match match}) {
    return Card(
      child: ListTile(
        title: Text('${match.team1} vs ${match.team2}'),
        subtitle: Text('${match.scheduledDate} • ${match.venue}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.pushNamed(context, '/match-detail', arguments: match.id),
      ),
    );
  }

  Widget _QuickActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

