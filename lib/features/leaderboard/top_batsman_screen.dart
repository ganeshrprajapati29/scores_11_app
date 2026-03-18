import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';

class TopBatsmanScreen extends StatefulWidget {
  const TopBatsmanScreen({super.key});

  @override
  State<TopBatsmanScreen> createState() => _TopBatsmanScreenState();
}

class _TopBatsmanScreenState extends State<TopBatsmanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFormat = 'T20';
  
  final List<Map<String, dynamic>> _batsmen = [
    {'name': 'Virat Kohli', 'team': 'RCB', 'runs': 741, 'matches': 14, 'avg': 61.75, 'sr': 154.69, 'fours': 84, 'sixes': 38, 'image': 'https://picsum.photos/100/100', 'rank': 1},
    {'name': 'Rohit Sharma', 'team': 'MI', 'runs': 512, 'matches': 12, 'avg': 42.66, 'sr': 148.54, 'fours': 56, 'sixes': 24, 'image': 'https://picsum.photos/100/100', 'rank': 2},
    {'name': 'Shubman Gill', 'team': 'GT', 'runs': 489, 'matches': 11, 'avg': 44.45, 'sr': 151.16, 'fours': 52, 'sixes': 28, 'image': 'https://picsum.photos/100/100', 'rank': 3},
    {'name': 'Faf du Plessis', 'team': 'RCB', 'runs': 456, 'matches': 12, 'avg': 38.00, 'sr': 152.51, 'fours': 45, 'sixes': 22, 'image': 'https://picsum.photos/100/100', 'rank': 4},
    {'name': 'David Warner', 'team': 'DC', 'runs': 432, 'matches': 11, 'avg': 39.27, 'sr': 147.95, 'fours': 48, 'sixes': 18, 'image': 'https://picsum.photos/100/100', 'rank': 5},
    {'name': 'KL Rahul', 'team': 'LSG', 'runs': 421, 'matches': 12, 'avg': 35.08, 'sr': 144.52, 'fours': 42, 'sixes': 20, 'image': 'https://picsum.photos/100/100', 'rank': 6},
    {'name': 'Suryakumar Yadav', 'team': 'MI', 'runs': 398, 'matches': 10, 'avg': 39.80, 'sr': 160.48, 'fours': 38, 'sixes': 24, 'image': 'https://picsum.photos/100/100', 'rank': 7},
    {'name': 'Hardik Pandya', 'team': 'MI', 'runs': 345, 'matches': 11, 'avg': 31.36, 'sr': 138.80, 'fours': 32, 'sixes': 18, 'image': 'https://picsum.photos/100/100', 'rank': 8},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Top Batsmen',
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'T20'),
            Tab(text: 'ODI'),
            Tab(text: 'Test'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top 3 Podium
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPodiumItem(_batsmen[1], 2),
                _buildPodiumItem(_batsmen[0], 1),
                _buildPodiumItem(_batsmen[2], 3),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),
          
          // Stats Header
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildHeaderCell('Rank', flex: 1),
                _buildHeaderCell('Player', flex: 4),
                _buildHeaderCell('M', flex: 1),
                _buildHeaderCell('Runs', flex: 1),
                _buildHeaderCell('Avg', flex: 1),
                _buildHeaderCell('SR', flex: 1),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: ListView.builder(
              itemCount: _batsmen.length,
              itemBuilder: (context, index) {
                final batsman = _batsmen[index];
                final isTop3 = index < 3;
                
                return Container(
                  color: isTop3 ? Colors.amber[50] : Colors.white,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Rank
                        SizedBox(
                          width: 30,
                          child: isTop3
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _getRankColor(index),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : Text(
                                  '${index + 1}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                        ),
                        // Player
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(batsman['image']),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      batsman['name'],
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      batsman['team'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Stats
                        _buildStatCell(batsman['matches'].toString()),
                        _buildStatCell(batsman['runs'].toString(), isBold: true, color: AppColors.primary),
                        _buildStatCell(batsman['avg'].toStringAsFixed(2)),
                        _buildStatCell(batsman['sr'].toStringAsFixed(2)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> player, int position) {
    final height = position == 1 ? 100.0 : (position == 2 ? 80.0 : 60.0);
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getRankColor(position - 1),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 27,
                backgroundImage: NetworkImage(player['image']),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _getRankColor(position - 1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$position',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                player['name'].split(' ').last,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${player['runs']} runs',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 70,
                height: height - 30,
                decoration: BoxDecoration(
                  color: _getRankColor(position - 1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatCell(String text, {bool isBold = false, Color? color}) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey[400]!;
      case 2:
        return Colors.brown[400]!;
      default:
        return Colors.grey;
    }
  }
}


