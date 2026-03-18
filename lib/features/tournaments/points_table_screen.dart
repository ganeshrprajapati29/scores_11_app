import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_appbar.dart';

class PointsTableScreen extends StatelessWidget {
  final String tournamentId;
  
  const PointsTableScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> teams = [
      {'name': 'Mumbai Indians', 'matches': 10, 'won': 7, 'lost': 3, 'tied': 0, 'nr': 0, 'points': 14, 'nrRate': 1.245, 'logo': 'https://picsum.photos/40/40'},
      {'name': 'Chennai Super Kings', 'matches': 10, 'won': 6, 'lost': 4, 'tied': 0, 'nr': 0, 'points': 12, 'nrRate': 1.123, 'logo': 'https://picsum.photos/40/40'},
      {'name': 'Delhi Capitals', 'matches': 10, 'won': 6, 'lost': 4, 'tied': 0, 'nr': 0, 'points': 12, 'nrRate': 0.987, 'logo': 'https://picsum.photos/40/40'},
      {'name': 'Kolkata Knight Riders', 'matches': 10, 'won': 5, 'lost': 5, 'tied': 0, 'nr': 0, 'points': 10, 'nrRate': 1.056, 'logo': 'https://picsum.photos/40/40'},
      {'name': 'Royal Challengers Bangalore', 'matches': 10, 'won': 4, 'lost': 6, 'tied': 0, 'nr': 0, 'points': 8, 'nrRate': 0.945, 'logo': 'https://picsum.photos/40/40'},
      {'name': 'Punjab Kings', 'matches': 10, 'won': 3, 'lost': 7, 'tied': 0, 'nr': 0, 'points': 6, 'nrRate': 0.876, 'logo': 'https://picsum.photos/40/40'},
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Points Table',
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showPointsExplanation(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tournament Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.emoji_events, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IPL 2024',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '6 Teams â€¢ 10 Matches Each',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'League Stage',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),
          
          // Points Table Header
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildHeaderCell('', flex: 1),
                _buildHeaderCell('M', flex: 1),
                _buildHeaderCell('W', flex: 1),
                _buildHeaderCell('L', flex: 1),
                _buildHeaderCell('T', flex: 1),
                _buildHeaderCell('NR', flex: 1),
                _buildHeaderCell('Pts', flex: 1, isBold: true),
                _buildHeaderCell('NRR', flex: 1, isBold: true),
              ],
            ),
          ),
          
          // Points Table Body
          Expanded(
            child: ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                final isPlayoff = index < 4;
                final isEliminated = index >= 4;
                
                return Container(
                  color: isPlayoff 
                      ? AppColors.success.withValues(alpha: 0.1) 
                      : isEliminated 
                          ? AppColors.error.withValues(alpha: 0.1) 
                          : Colors.white,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Position
                        SizedBox(
                          width: 30,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isPlayoff 
                                  ? AppColors.success 
                                  : isEliminated 
                                      ? Colors.grey 
                                      : AppColors.primary,
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
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Team
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundImage: NetworkImage(team['logo']),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  team['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Stats
                        _buildStatCell(team['matches'].toString()),
                        _buildStatCell(team['won'].toString(), color: AppColors.success),
                        _buildStatCell(team['lost'].toString(), color: AppColors.error),
                        _buildStatCell(team['tied'].toString()),
                        _buildStatCell(team['nr'].toString()),
                        _buildStatCell(team['points'].toString(), isBold: true),
                        _buildStatCell(team['nrRate'].toStringAsFixed(3)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
              },
            ),
          ),
          
          // Legend
          Container(
            padding: const EdgeInsets.all(16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('Playoffs', AppColors.success),
                  _buildLegendItem('Eliminated', Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1, bool isBold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatCell(String text, {Color? color, bool isBold = false}) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showPointsExplanation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points System',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildExplanationRow('Win', '2 Points'),
            _buildExplanationRow('Tie/No Result', '1 Point'),
            _buildExplanationRow('Loss', '0 Points'),
            const SizedBox(height: 16),
            Text(
              'NRR (Net Run Rate)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Net Run Rate is calculated by subtracting the run rate of the opposing team from the run rate of your team.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}




