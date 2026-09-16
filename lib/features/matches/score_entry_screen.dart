import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';

class ScoreEntryScreen extends StatefulWidget {
  final String matchId;

  const ScoreEntryScreen({super.key, required this.matchId});

  @override
  State<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

class _ScoreEntryScreenState extends State<ScoreEntryScreen>
    with TickerProviderStateMixin {
  String _selectedBatsman = 'Rohit Sharma';
  String _selectedBowler = 'Deepak Chahar';
  int _currentOver = 14;
  int _currentBall = 2;
  String _lastShot = '';
  String _lastShotType = ''; // 'run', 'wicket', 'extra'

  final List<String> _batsmen = [
    'Rohit Sharma',
    'Hardik Pandya',
    'Ishan Kishan',
    'Surya Kumar'
  ];
  final List<String> _bowlers = [
    'Deepak Chahar',
    'Ravindra Jadeja',
    'Matheesha',
    'Tushar'
  ];

  // Over balls tracker
  final List<String> _overBalls = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _lastShotController;
  late Animation<double> _lastShotAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _lastShotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _lastShotAnim = CurvedAnimation(
      parent: _lastShotController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _lastShotController.dispose();
    super.dispose();
  }

  void _addRuns(int runs) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (runs == -1) {
        _lastShot = 'WICKET!';
        _lastShotType = 'wicket';
        _overBalls.add('W');
      } else if (runs == -2) {
        _lastShot = 'Wide';
        _lastShotType = 'extra';
        _overBalls.add('Wd');
      } else if (runs == -3) {
        _lastShot = 'No Ball';
        _lastShotType = 'extra';
        _overBalls.add('NB');
      } else if (runs == -4) {
        _lastShot = 'Bye';
        _lastShotType = 'extra';
        _overBalls.add('B');
      } else {
        _lastShot = runs == 0
            ? 'Dot Ball'
            : runs == 4
                ? 'FOUR!'
                : runs == 6
                    ? 'SIX!'
                    : '$runs Run${runs > 1 ? 's' : ''}';
        _lastShotType = 'run';
        _overBalls.add('$runs');
      }

      if (runs >= 0 || runs == -4) {
        _currentBall++;
        if (_currentBall > 6) {
          _currentBall = 0;
          _currentOver++;
          _overBalls.clear();
        }
      }
    });

    _lastShotController.forward(from: 0);
  }

  Color get _lastShotColor {
    if (_lastShotType == 'wicket') return const Color(0xFFEF4444);
    if (_lastShotType == 'extra') return const Color(0xFFF97316);
    if (_lastShot.contains('SIX')) return const Color(0xFF8B5CF6);
    if (_lastShot.contains('FOUR')) return const Color(0xFF10B981);
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060D1F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.sports_cricket_rounded, color: Color(0xFF1657CC), size: 15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'SCORE ENTRY',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded,
                  color: Colors.white70, size: 18),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildScoreHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildLastShotBanner(),
                  _buildOverTracker(),
                  _buildPlayerSelection(),
                  _buildScoreGrid(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2460), Color(0xFF1A3A8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A8F).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Team 1
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('MI',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    )),
                const SizedBox(height: 4),
                const Text('145/3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    )),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'BATTING',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Center Over info
          Column(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.4)),
                    ),
                    child: Text(
                      '$_currentOver.$_currentBall',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Target: 186',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // Team 2
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('CSK',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    )),
                const SizedBox(height: 4),
                const Text('—',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    )),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'YET TO BAT',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastShotBanner() {
    return ScaleTransition(
      scale: _lastShotAnim,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: _lastShotType == 'wicket'
              ? const Color(0xFFEF4444).withOpacity(0.12)
              : _lastShotType == 'extra'
                  ? const Color(0xFFF97316).withOpacity(0.10)
                  : _lastShot.contains('SIX')
                      ? const Color(0xFF8B5CF6).withOpacity(0.12)
                      : _lastShot.contains('FOUR')
                          ? const Color(0xFF10B981).withOpacity(0.10)
                          : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _lastShotColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _lastShotType == 'wicket'
                  ? Icons.sports_cricket_rounded
                  : _lastShotType == 'extra'
                      ? Icons.info_outline_rounded
                      : _lastShot.contains('SIX')
                          ? Icons.rocket_launch_rounded
                          : _lastShot.contains('FOUR')
                              ? Icons.bolt_rounded
                              : Icons.fiber_manual_record,
              color: _lastShotColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              _lastShot.isEmpty ? 'Tap a button to score' : _lastShot,
              style: TextStyle(
                color: _lastShot.isEmpty ? Colors.white30 : _lastShotColor,
                fontWeight: FontWeight.w800,
                fontSize: _lastShot.isEmpty ? 13 : 17,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverTracker() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS OVER',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...List.generate(6, (i) {
                final hasBall = i < _overBalls.length;
                final ball = hasBall ? _overBalls[i] : '';
                Color ballColor = Colors.white12;
                Color textColor = Colors.white30;

                if (hasBall) {
                  if (ball == 'W') {
                    ballColor = const Color(0xFFEF4444).withOpacity(0.25);
                    textColor = const Color(0xFFEF4444);
                  } else if (ball == 'Wd' || ball == 'NB' || ball == 'B') {
                    ballColor = const Color(0xFFF97316).withOpacity(0.2);
                    textColor = const Color(0xFFF97316);
                  } else if (ball == '4') {
                    ballColor = const Color(0xFF10B981).withOpacity(0.2);
                    textColor = const Color(0xFF10B981);
                  } else if (ball == '6') {
                    ballColor = const Color(0xFF8B5CF6).withOpacity(0.25);
                    textColor = const Color(0xFF8B5CF6);
                  } else if (ball == '0') {
                    ballColor = Colors.white10;
                    textColor = Colors.white30;
                  } else {
                    ballColor = const Color(0xFF3B82F6).withOpacity(0.2);
                    textColor = const Color(0xFF3B82F6);
                  }
                }

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 36,
                    decoration: BoxDecoration(
                      color: ballColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasBall
                            ? textColor.withOpacity(0.3)
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        hasBall ? ball : '·',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: hasBall ? 12 : 18,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSelection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdownCard(
              label: 'BATSMAN',
              value: _selectedBatsman,
              items: _batsmen,
              icon: Icons.sports_cricket_rounded,
              color: const Color(0xFF3B82F6),
              onChanged: (v) {
                if (v != null) setState(() => _selectedBatsman = v);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdownCard(
              label: 'BOWLER',
              value: _selectedBowler,
              items: _bowlers,
              icon: Icons.sports_baseball_rounded,
              color: const Color(0xFFFF6B35),
              onChanged: (v) {
                if (v != null) setState(() => _selectedBowler = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCard({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Color color,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF0F1E3D),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: color, size: 18),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreGrid() {
    final buttons = [
      {'runs': 0, 'label': '0', 'sub': 'dot', 'type': 'run'},
      {'runs': 1, 'label': '1', 'sub': 'single', 'type': 'run'},
      {'runs': 2, 'label': '2', 'sub': 'double', 'type': 'run'},
      {'runs': 3, 'label': '3', 'sub': 'triple', 'type': 'run'},
      {'runs': 4, 'label': '4', 'sub': 'four', 'type': 'boundary'},
      {'runs': 6, 'label': '6', 'sub': 'six', 'type': 'six'},
      {'runs': -1, 'label': 'W', 'sub': 'wicket', 'type': 'wicket'},
      {'runs': -2, 'label': 'WD', 'sub': 'wide', 'type': 'extra'},
      {'runs': -3, 'label': 'NB', 'sub': 'no ball', 'type': 'extra'},
      {'runs': -4, 'label': 'BYE', 'sub': 'bye', 'type': 'extra'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.88,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: buttons.length,
        itemBuilder: (context, index) {
          final btn = buttons[index];
          return _buildScoreButton(btn, index);
        },
      ),
    );
  }

  Widget _buildScoreButton(Map<String, dynamic> btn, int index) {
    final type = btn['type'] as String;
    final runs = btn['runs'] as int;

    Color bg, border, textColor;

    switch (type) {
      case 'boundary':
        bg = const Color(0xFF10B981).withOpacity(0.18);
        border = const Color(0xFF10B981).withOpacity(0.5);
        textColor = const Color(0xFF10B981);
        break;
      case 'six':
        bg = const Color(0xFF8B5CF6).withOpacity(0.18);
        border = const Color(0xFF8B5CF6).withOpacity(0.5);
        textColor = const Color(0xFF8B5CF6);
        break;
      case 'wicket':
        bg = const Color(0xFFEF4444).withOpacity(0.18);
        border = const Color(0xFFEF4444).withOpacity(0.5);
        textColor = const Color(0xFFEF4444);
        break;
      case 'extra':
        bg = const Color(0xFFF97316).withOpacity(0.15);
        border = const Color(0xFFF97316).withOpacity(0.4);
        textColor = const Color(0xFFF97316);
        break;
      default:
        bg = runs == 0
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFF3B82F6).withOpacity(0.15);
        border = runs == 0
            ? Colors.white.withOpacity(0.1)
            : const Color(0xFF3B82F6).withOpacity(0.4);
        textColor =
            runs == 0 ? Colors.white38 : const Color(0xFF60A5FA);
    }

    return GestureDetector(
      onTap: () => _addRuns(runs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: textColor.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              btn['label'] as String,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              btn['sub'] as String,
              style: TextStyle(
                color: textColor.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.85, 0.85), duration: 300.ms);
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF08112B),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.undo_rounded,
                    label: 'Undo',
                    color: Colors.white38,
                    borderColor: Colors.white12,
                    onTap: _showUndoDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.sports_cricket_rounded,
                    label: 'Wicket',
                    color: const Color(0xFFEF4444),
                    borderColor: const Color(0xFFEF4444).withOpacity(0.3),
                    onTap: _showWicketDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _finishOver,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text(
                  'Finish Over',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUndoDialog() {
    showDialog(
      context: context,
      builder: (context) => _StyledDialog(
        title: 'Undo Last Ball',
        subtitle: 'This will revert the last delivery from the scorecard.',
        icon: Icons.undo_rounded,
        iconColor: Colors.white70,
        confirmLabel: 'Undo',
        confirmColor: Colors.white,
        confirmBg: const Color(0xFF1E3A6E),
        onConfirm: () {
          setState(() {
            if (_currentBall > 0) {
              _currentBall--;
              if (_overBalls.isNotEmpty) _overBalls.removeLast();
            } else if (_currentOver > 0) {
              _currentOver--;
              _currentBall = 6;
              _overBalls.clear();
            }
            _lastShot = '';
            _lastShotType = '';
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showWicketDialog() {
    String selectedWicketType = 'caught';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF0D1B3E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sports_cricket_rounded,
                      color: Color(0xFFEF4444), size: 28),
                ),
                const SizedBox(height: 14),
                const Text('Wicket Type',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 4),
                Text('Select how the batsman was dismissed',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
                const SizedBox(height: 20),
                ...['caught', 'bowled', 'lbw', 'stumped', 'runOut']
                    .map((type) {
                  final labels = {
                    'caught': 'Caught',
                    'bowled': 'Bowled',
                    'lbw': 'LBW',
                    'stumped': 'Stumped',
                    'runOut': 'Run Out',
                  };
                  final isSelected = selectedWicketType == type;
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedWicketType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEF4444).withOpacity(0.15)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEF4444).withOpacity(0.5)
                              : Colors.white.withOpacity(0.07),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? const Color(0xFFEF4444)
                                : Colors.white30,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            labels[type]!,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white60,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('Cancel',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _addRuns(-1);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFEF4444),
                                Color(0xFFDC2626)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('Confirm Wicket',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _finishOver() {
    setState(() {
      _overBalls.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Over completed!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable Styled Dialog
// ─────────────────────────────────────────────

class _StyledDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String confirmLabel;
  final Color confirmColor;
  final Color confirmBg;
  final VoidCallback onConfirm;

  const _StyledDialog({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.confirmLabel,
    required this.confirmColor,
    required this.confirmBg,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1B3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 13)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('Cancel',
                            style: TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: confirmBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: confirmColor.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(confirmLabel,
                            style: TextStyle(
                                color: confirmColor,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
