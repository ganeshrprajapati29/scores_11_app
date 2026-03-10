import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/config/theme_config.dart';
import '../../core/widgets/custom_button.dart';

class ScoreEntryScreen extends StatefulWidget {
  final String matchId;
  
  const ScoreEntryScreen({super.key, required this.matchId});

  @override
  State<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

class _ScoreEntryScreenState extends State<ScoreEntryScreen> {
  String _selectedBatsman = 'Rohit Sharma';
  String _selectedBowler = 'Deepak Chahar';
  int _currentOver = 14;
  int _currentBall = 2;
  String _lastShot = '';
  
  final List<String> _batsmen = ['Rohit Sharma', 'Hardik Pandya', 'Ishan Kishan', 'Surya Kumar'];
  final List<String> _bowlers = ['Deepak Chahar', 'Ravindra Jadeja', 'Matheesha', 'Tushar'];
  
  final List<Map<String, dynamic>> _scoreButtons = [
    {'runs': 0, 'label': '0', 'color': Colors.grey},
    {'runs': 1, 'label': '1', 'color': Colors.blue},
    {'runs': 2, 'label': '2', 'color': Colors.blue},
    {'runs': 3, 'label': '3', 'color': Colors.blue},
    {'runs': 4, 'label': '4', 'color': AppColors.primary},
    {'runs': 6, 'label': '6', 'color': AppColors.secondary},
    {'runs': -1, 'label': 'W', 'color': AppColors.error},
    {'runs': -2, 'label': 'WD', 'color': Colors.orange},
    {'runs': -3, 'label': 'NB', 'color': Colors.purple},
    {'runs': -4, 'label': 'Bye', 'color': Colors.teal},
  ];

  void _addRuns(int runs) {
    setState(() {
      if (runs == -1) {
        _lastShot = 'WICKET!';
      } else if (runs == -2) {
        _lastShot = 'Wide';
      } else if (runs == -3) {
        _lastShot = 'No Ball';
      } else if (runs == -4) {
        _lastShot = 'Bye';
      } else {
        _lastShot = '$runs runs';
      }
      
      if (runs >= 0 || runs == -4) {
        _currentBall++;
        if (_currentBall > 6) {
          _currentBall = 0;
          _currentOver++;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Entry'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Match Score Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('MI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('145/3', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('Over $_currentOver.$_currentBall', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Target: 186', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('CSK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Yet to bat', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Last Ball Result
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.amber[100],
            child: Text(
              _lastShot.isEmpty ? 'Tap a button to add score' : _lastShot,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _lastShot.contains('WICKET') ? AppColors.error : Colors.black,
              ),
            ),
          ).animate().fadeIn(),
          
          // Player Selection
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildPlayerDropdown(
                    label: 'Batsman',
                    value: _selectedBatsman,
                    items: _batsmen,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedBatsman = value);
                    }
                  },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPlayerDropdown(
                    label: 'Bowler',
                    value: _selectedBowler,
                    items: _bowlers,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedBowler = value);
                    }
                  },
                  ),
                ),
              ],
            ),
          ),
          
          // Score Buttons Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _scoreButtons.length,
                itemBuilder: (context, index) {
                  final button = _scoreButtons[index];
                  return _buildScoreButton(button);
                },
              ),
            ),
          ),
          
          // Extra Options
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showUndoDialog(),
                          icon: const Icon(Icons.undo),
                          label: const Text('Undo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showWicketDialog(),
                          icon: const Icon(Icons.sports_cricket, color: AppColors.error),
                          label: const Text('Wicket', style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _finishOver(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Finish Over'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreButton(Map<String, dynamic> button) {
    final runs = button['runs'];
    return Material(
      color: button['color'],
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _addRuns(runs),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          child: Text(
            button['label'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: runs * 50));
  }

  void _showUndoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Undo Last Ball'),
        content: const Text('Are you sure you want to undo the last ball?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_currentBall > 0) {
                  _currentBall--;
                } else if (_currentOver > 0) {
                  _currentOver--;
                  _currentBall = 6;
                }
                _lastShot = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Undo'),
          ),
        ],
      ),
    );
  }

  void _showWicketDialog() {
    String selectedWicketType = 'caught';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Wicket Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWicketOption('caught', 'Caught', selectedWicketType, (v) { if (v != null) setDialogState(() => selectedWicketType = v); }),
              _buildWicketOption('bowled', 'Bowled', selectedWicketType, (v) { if (v != null) setDialogState(() => selectedWicketType = v); }),
              _buildWicketOption('lbw', 'LBW', selectedWicketType, (v) { if (v != null) setDialogState(() => selectedWicketType = v); }),
              _buildWicketOption('stumped', 'Stumped', selectedWicketType, (v) { if (v != null) setDialogState(() => selectedWicketType = v); }),
              _buildWicketOption('runOut', 'Run Out', selectedWicketType, (v) { if (v != null) setDialogState(() => selectedWicketType = v); }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addRuns(-1);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Confirm Wicket'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWicketOption(String value, String label, String selected, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: selected,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _finishOver() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Over completed!')),
    );
  }
}

