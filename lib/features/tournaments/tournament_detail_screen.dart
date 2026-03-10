import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../data/models/tournament_model.dart';
import '../../data/services/tournament_service.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TournamentService _tournamentService = TournamentService();
  
  Tournament? _tournament;
  bool _isLoading = true;
  String? _error;
  bool _isRegistered = false;
  
  // Filters
  String _selectedFormat = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTournament();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTournament() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Simulate loading - in real app, call API
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock tournament data
      final tournament = Tournament(
        id: widget.tournamentId,
        name: 'Champions League 2024',
        description: 'The biggest cricket tournament featuring top teams from across the country. Compete for glory and huge prize money!',
        organizer: 'Cricket Association',
        type: 'League',
        format: 'T20',
        status: 'UPCOMING',
        startDate: DateTime(2024, 12, 1),
        endDate: DateTime(2024, 12, 31),
        venue: 'Wankhede Stadium, Mumbai',
        city: 'Mumbai',
        state: 'Maharashtra',
        country: 'India',
        bannerUrl: 'https://picsum.photos/800/400',
        logoUrl: 'https://picsum.photos/200/200',
        entryFee: 5000,
        prizeMoney: 500000,
        maxTeams: 16,
        registeredTeams: 12,
        isPaid: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      setState(() {
        _tournament = tournament;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _participate() async {
    // Call backend API to participate
    setState(() => _isRegistered = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully registered for the tournament! 🎉'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildContent(),
      bottomNavigationBar: _tournament != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // Hero Banner
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              _tournament!.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                _tournament!.bannerUrl != null
                    ? Image.network(_tournament!.bannerUrl!, fit: BoxFit.cover)
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                        ),
                        child: const Icon(Icons.emoji_events, size: 80, color: Colors.white30),
                      ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
          ],
        ),
        
        // Tournament Info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status & Format Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(_tournament!.format, Icons.sports_cricket, AppColors.primary),
                    _buildChip(_tournament!.type, Icons.emoji_events, AppColors.secondary),
                    _buildChip(_tournament!.status, Icons.circle, _tournament!.status == 'LIVE' ? AppColors.error : AppColors.success),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  _tournament!.description ?? 'No description available',
                  style: TextStyle(color: Colors.grey[700], height: 1.5),
                ),
                
                const SizedBox(height: 24),
                
                // Quick Info Cards
                Row(
                  children: [
                    Expanded(child: _buildInfoCard('📅', 'Start Date', _formatDate(_tournament!.startDate))),
                    Expanded(child: _buildInfoCard('🏟️', 'Venue', _tournament!.venue ?? 'TBD')),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(child: _buildInfoCard('👥', 'Teams', '${_tournament!.registeredTeams}/${_tournament!.maxTeams}')),
                    Expanded(child: _buildInfoCard('💰', 'Entry Fee', '₹${_tournament!.entryFee}')),
                  ],
                ),
                
                if (_tournament!.prizeMoney != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoCard('🏆', 'Prize Money', '₹${_tournament!.prizeMoney}'),
                ],
                
                const SizedBox(height: 24),
                
                // Filters
                const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'All'),
                      _buildFilterChip('T20', 'T20'),
                      _buildFilterChip('ODI', 'ODI'),
                      _buildFilterChip('Test', 'Test'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tabs: const [
                      Tab(text: '📊 Overview'),
                      Tab(text: '👥 Teams'),
                      Tab(text: '📅 Matches'),
                      Tab(text: '📈 Points'),
                      Tab(text: '🏆 Prizes'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Tab Content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildTeamsTab(),
              _buildMatchesTab(),
              _buildPointsTab(),
              _buildPrizesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String emoji, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFormat == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFormat = value);
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Entry Fee', style: TextStyle(color: Colors.grey[600])),
                  Text('₹${_tournament!.entryFee}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isRegistered ? null : _participate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRegistered ? Colors.green : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isRegistered ? '✓ Registered' : 'Participate Now',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament Rules
          const Text('📋 Tournament Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRuleItem('1', 'Each team must have minimum 11 players'),
          _buildRuleItem('2', 'Match will be of 20 overs per side'),
          _buildRuleItem('3', 'No bowler can bowl more than 4 overs'),
          _buildRuleItem('4', 'Decision of umpire will be final'),
          _buildRuleItem('5', 'Entry fee is non-refundable'),
          
          const SizedBox(height: 24),
          
          // Organizer Info
          const Text('👤 Organized By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary,
                  child: Text(_tournament!.organizer[0], style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_tournament!.organizer, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Tournament Organizer', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Venue Info
          const Text('📍 Venue Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Map View'),
                  Text('Tap to see on Google Maps', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 12))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    // Mock registered teams
    final List<Map<String, dynamic>> teams = [
      {'name': 'Mumbai Indians', 'players': 15, 'captain': 'Rohit Sharma'},
      {'name': 'Chennai Super Kings', 'players': 14, 'captain': 'MS Dhoni'},
      {'name': 'Royal Challengers Bangalore', 'players': 15, 'captain': 'Virat Kohli'},
      {'name': 'Kolkata Knight Riders', 'players': 14, 'captain': 'Shreyas Iyer'},
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text('${index + 1}', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Captain: ${team['captain']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text('${team['players']} players', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 100)).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildMatchesTab() {
    // Mock matches
    final matches = [
      {'team1': 'Mumbai Indians', 'team2': 'CSK', 'date': 'Dec 1', 'time': '7:00 PM', 'status': 'SCHEDULED'},
      {'team1': 'RCB', 'team2': 'KKR', 'date': 'Dec 2', 'time': '3:00 PM', 'status': 'SCHEDULED'},
      {'team1': 'MI', 'team2': 'RCB', 'date': 'Dec 3', 'time': '7:00 PM', 'status': 'SCHEDULED'},
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Text(match['date']!, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMatchTeam(match['team1']!),
                  Text('VS', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
                  _buildMatchTeam(match['team2']!),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(match['time']!, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(match['status']!, style: TextStyle(color: AppColors.success, fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
      },
    );
  }

  Widget _buildMatchTeam(String name) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(name.isNotEmpty ? name[0] : '', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPointsTab() {
    // Mock points table
    final List<Map<String, dynamic>> teams = [
      {'team': 'Mumbai Indians', 'played': 3, 'won': 3, 'lost': 0, 'points': 6, 'nrr': '+1.250', 'nrRate': 1.245},
      {'team': 'Chennai Super Kings', 'played': 3, 'won': 2, 'lost': 1, 'points': 4, 'nrr': '+0.850', 'nrRate': 1.123},
      {'team': 'Royal Challengers Bangalore', 'played': 3, 'won': 1, 'lost': 2, 'points': 2, 'nrr': '-0.450', 'nrRate': 0.945},
      {'team': 'Kolkata Knight Riders', 'played': 3, 'won': 0, 'lost': 3, 'points': 0, 'nrr': '-1.150', 'nrRate': 1.056},
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 30, child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(child: Text('Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                SizedBox(width: 40, child: Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                SizedBox(width: 40, child: Text('W', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                SizedBox(width: 40, child: Text('L', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                SizedBox(width: 50, child: Text('Pts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                SizedBox(width: 60, child: Text('NRR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Table Rows
          ...teams.asMap().entries.map((entry) {
            final index = entry.key;
            final team = entry.value;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text('${index + 1}', style: TextStyle(color: index < 2 ? AppColors.success : Colors.grey[600]))),
                  Expanded(child: Text(team['team']!, style: const TextStyle(fontWeight: FontWeight.w500))),
                  SizedBox(width: 40, child: Text('${team['played']}', textAlign: TextAlign.center)),
                  SizedBox(width: 40, child: Text('${team['won']}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.green))),
                  SizedBox(width: 40, child: Text('${team['lost']}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
                  SizedBox(width: 50, child: Text('${team['points']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 60, child: Text('${team['nrr']}', textAlign: TextAlign.center)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPrizesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Prize Pool
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('🏆 Total Prize Pool', style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
                Text('₹${_tournament!.prizeMoney ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Prize Distribution
          const Text('Prize Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          _buildPrizeCard(1, '₹${((_tournament!.prizeMoney ?? 0) * 0.5).toInt()}', '🥇 Champion', Colors.amber),
          const SizedBox(height: 12),
          _buildPrizeCard(2, '₹${((_tournament!.prizeMoney ?? 0) * 0.25).toInt()}', '🥈 Runner Up', Colors.grey[400]!),
          const SizedBox(height: 12),
          _buildPrizeCard(3, '₹${((_tournament!.prizeMoney ?? 0) * 0.15).toInt()}', '🥉 Third Place', Colors.brown[300]!),
          const SizedBox(height: 12),
          _buildPrizeCard(4, '₹${((_tournament!.prizeMoney ?? 0) * 0.10).toInt()}', '🎖️ Fourth Place', Colors.orange[200]!),
          
          const SizedBox(height: 24),
          
          // Individual Awards
          const Text('Individual Awards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildAwardItem('🏏 Player of the Tournament', '₹50,000'),
          _buildAwardItem('🔥 Best Batsman', '₹25,000'),
          _buildAwardItem('⚡ Best Bowler', '₹25,000'),
          _buildAwardItem('⭐ Most Valuable Player', '₹25,000'),
        ],
      ),
    );
  }

  Widget _buildPrizeCard(int position, String prize, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
            child: Center(child: Text('$position', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(prize, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAwardItem(String title, String prize) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(prize, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
    return '${date.day}/${date.month}/${date.year}';
  }
}
