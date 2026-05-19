// Wagon Wheel Screen - Visual scoring zones for cricket

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/match_model.dart';
import '../../providers/live_score_control_provider.dart';

class WagonWheelScreen extends StatefulWidget {
  final String matchId;
  final Match? match;

  const WagonWheelScreen({
    super.key,
    required this.matchId,
    this.match,
  });

  @override
  State<WagonWheelScreen> createState() => _WagonWheelScreenState();
}

class _WagonWheelScreenState extends State<WagonWheelScreen>
    with TickerProviderStateMixin {
  int? _selectedZone;
  final List<Map<String, dynamic>> _recentShots = [];

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _shotController;
  late Animation<double> _shotAnimation;

  // Cricket wagon wheel zones — 8 sectors around a cricket field
  final List<Map<String, dynamic>> _zones = [
    {
      'zone': 0,
      'label': 'Point',
      'angle': 0.0,
      'primaryColor': const Color(0xFF3B82F6),
      'darkColor': const Color(0xFF1D4ED8),
    },
    {
      'zone': 1,
      'label': 'Cover',
      'angle': math.pi / 4,
      'primaryColor': const Color(0xFF10B981),
      'darkColor': const Color(0xFF059669),
    },
    {
      'zone': 2,
      'label': 'Mid Off',
      'angle': math.pi / 2,
      'primaryColor': const Color(0xFF06B6D4),
      'darkColor': const Color(0xFF0891B2),
    },
    {
      'zone': 3,
      'label': 'Mid On',
      'angle': 3 * math.pi / 4,
      'primaryColor': const Color(0xFF8B5CF6),
      'darkColor': const Color(0xFF7C3AED),
    },
    {
      'zone': 4,
      'label': 'Square Leg',
      'angle': math.pi,
      'primaryColor': const Color(0xFFF59E0B),
      'darkColor': const Color(0xFFD97706),
    },
    {
      'zone': 5,
      'label': 'Fine Leg',
      'angle': 5 * math.pi / 4,
      'primaryColor': const Color(0xFFEF4444),
      'darkColor': const Color(0xFFDC2626),
    },
    {
      'zone': 6,
      'label': 'Third Man',
      'angle': 3 * math.pi / 2,
      'primaryColor': const Color(0xFFF97316),
      'darkColor': const Color(0xFFEA580C),
    },
    {
      'zone': 7,
      'label': 'Gully',
      'angle': 7 * math.pi / 4,
      'primaryColor': const Color(0xFFEC4899),
      'darkColor': const Color(0xFFDB2777),
    },
  ];

  // Runs per ring (inner → outer)
  final List<int> _ringRuns = [0, 1, 2, 4, 6];

  int? _selectedRing; // 0-4

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _shotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shotAnimation = CurvedAnimation(
      parent: _shotController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _shotController.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details, Size painterSize) {
    final center = Offset(painterSize.width / 2, painterSize.height / 2);
    final radius = math.min(painterSize.width, painterSize.height) / 2;
    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist > radius) return; // tapped outside wheel

    // Determine ring (distance based)
    final relDist = dist / radius;
    int ring;
    if (relDist < 0.15) {
      ring = 0; // center = dot
    } else if (relDist < 0.38) {
      ring = 1;
    } else if (relDist < 0.58) {
      ring = 2;
    } else if (relDist < 0.78) {
      ring = 3;
    } else {
      ring = 4;
    }

    // Determine zone (angle based)
    var angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;
    final zoneIndex = ((angle / (math.pi / 4)).round() % 8);

    HapticFeedback.lightImpact();

    setState(() {
      _selectedZone = zoneIndex;
      _selectedRing = ring;
    });
  }

  Future<void> _confirmShot() async {
    if (_selectedZone == null || _selectedRing == null) return;
    HapticFeedback.mediumImpact();

    final zone = _zones[_selectedZone!];
    final runs = _ringRuns[_selectedRing!];
    final zoneIndex = _selectedZone!;
    final ringIndex = _selectedRing!;

    try {
      final provider = context.read<LiveScoreControlProvider>();
      await provider.addWagonShot(
        runs: runs,
        zone: zoneIndex,
        label: zone['label'] as String,
      );
      if (!mounted) return;
      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open wagon wheel from live score control after setting striker and bowler.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _recentShots.insert(0, {
        'zone': zoneIndex,
        'ring': ringIndex,
        'runs': runs,
        'label': zone['label'],
        'color': zone['primaryColor'],
      });
      if (_recentShots.length > 12) _recentShots.removeLast();
      _selectedZone = null;
      _selectedRing = null;
    });

    _shotController.forward(from: 0);
  }

  Color _runsColor(int runs) {
    switch (runs) {
      case 0:
        return Colors.white30;
      case 1:
        return const Color(0xFF3B82F6);
      case 2:
        return const Color(0xFF10B981);
      case 4:
        return const Color(0xFFFFD700);
      case 6:
        return const Color(0xFF8B5CF6);
      default:
        return Colors.white;
    }
  }

  IconData _runsIcon(int runs) {
    switch (runs) {
      case 0:
        return Icons.fiber_manual_record;
      case 4:
        return Icons.bolt_rounded;
      case 6:
        return Icons.rocket_launch_rounded;
      default:
        return Icons.sports_cricket_rounded;
    }
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
        title: const Text(
          'WAGON WHEEL',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
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
              child: const Icon(Icons.help_outline_rounded,
                  color: Colors.white70, size: 18),
            ),
            onPressed: _showHelp,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildMatchBanner(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildWheelSection(),
                  const SizedBox(height: 16),
                  if (_selectedZone != null) _buildSelectionPanel(),
                  if (_recentShots.isNotEmpty) _buildRecentShots(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2460), Color(0xFF1A3A8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.match?.team1 ?? 'Team 1',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          Text(
            widget.match?.team2 ?? 'Team 2',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Instruction
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.touch_app_rounded,
                    color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 8),
                Text(
                  _selectedZone == null
                      ? 'Tap the field to select shot direction & runs'
                      : 'Zone: ${_zones[_selectedZone!]['label']}  •  Runs: ${_ringRuns[_selectedRing ?? 0]}',
                  style: TextStyle(
                    color: _selectedZone == null
                        ? Colors.white38
                        : Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // The wheel
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapDown: (d) => _handleTap(d, size),
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: size,
                        painter: _WagonWheelPainter(
                          zones: _zones,
                          ringRuns: _ringRuns,
                          selectedZone: _selectedZone,
                          selectedRing: _selectedRing,
                          recentShots: _recentShots,
                          glowValue: _glowAnimation.value,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPanel() {
    final zone = _zones[_selectedZone!];
    final runs = _ringRuns[_selectedRing ?? 0];
    final color = zone['primaryColor'] as Color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on_rounded,
                      color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone['label'] as String,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$runs run${runs != 1 ? 's' : ''} selected',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Runs badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.8), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$runs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quick run overrides
            Row(
              children: _ringRuns.map((r) {
                final isSelected = r == runs;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final idx = _ringRuns.indexOf(r);
                      setState(() => _selectedRing = idx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.25)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : Colors.white.withOpacity(0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _runsIcon(r),
                            color: isSelected ? color : Colors.white30,
                            size: r == 0 ? 10 : 14,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r == 0 ? 'Dot' : '$r',
                            style: TextStyle(
                              color: isSelected ? color : Colors.white38,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmShot,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text(
                  'Confirm Shot',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentShots() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'RECENT SHOTS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _recentShots.clear()),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentShots.length,
              itemBuilder: (context, index) {
                final shot = _recentShots[index];
                final color = shot['color'] as Color;
                final runs = shot['runs'] as int;
                final isNew = index == 0;

                return ScaleTransition(
                  scale: isNew ? _shotAnimation : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 52,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$runs',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          shot['label'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color.withOpacity(0.7),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  color: const Color(0xFFFFD700).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline_rounded,
                    color: Color(0xFFFFD700), size: 28),
              ),
              const SizedBox(height: 14),
              const Text(
                'How to use Wagon Wheel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              ...[
                ['Center circle', 'Dot ball (0 runs)', Colors.white30],
                ['Inner ring', '1 run', Color(0xFF3B82F6)],
                ['Middle ring', '2 runs', Color(0xFF10B981)],
                ['Boundary ring', '4 runs', Color(0xFFFFD700)],
                ['Outer ring', '6 runs (SIX!)', Color(0xFF8B5CF6)],
              ].map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: row[2] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${row[0]}',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        '${row[1]}',
                        style: TextStyle(
                            color: row[2] as Color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              Divider(color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 10),
              Text(
                'Tap the sector for shot direction, then confirm.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A6E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Got it!',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Painter — Premium Wagon Wheel
// ─────────────────────────────────────────────

class _WagonWheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> zones;
  final List<int> ringRuns;
  final int? selectedZone;
  final int? selectedRing;
  final List<Map<String, dynamic>> recentShots;
  final double glowValue;

  _WagonWheelPainter({
    required this.zones,
    required this.ringRuns,
    this.selectedZone,
    this.selectedRing,
    this.recentShots = const [],
    this.glowValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 - 8;

    // Ring radii as fraction of maxR
    final ringFractions = [0.0, 0.15, 0.38, 0.58, 0.78, 1.0];
    // Ring colors (outer glow colors)
    final ringColors = [
      Colors.white12,
      const Color(0xFF3B82F6).withOpacity(0.15),
      const Color(0xFF10B981).withOpacity(0.12),
      const Color(0xFFFFD700).withOpacity(0.15),
      const Color(0xFF8B5CF6).withOpacity(0.18),
    ];

    // ── Draw background circle (field) ──
    final fieldPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0B3D1F),
          const Color(0xFF072010),
          const Color(0xFF040E08),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, fieldPaint);

    // ── Field boundary ──
    canvas.drawCircle(
      center,
      maxR,
      Paint()
        ..color = const Color(0xFF22C55E).withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // ── Draw pitch (center rectangle) ──
    final pitchRect = Rect.fromCenter(
      center: center,
      width: maxR * 0.1,
      height: maxR * 0.28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pitchRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF8B6914).withOpacity(0.6),
    );

    // ── Draw sectors ──
    for (int i = 0; i < zones.length; i++) {
      final zone = zones[i];
      final sectorAngle = math.pi / 4;
      final startAngle = (i - 0.5) * sectorAngle;

      // Outer sector (full radius, for visual separation)
      for (int r = 1; r < ringFractions.length; r++) {
        final innerR = maxR * ringFractions[r - 1];
        final outerR = maxR * ringFractions[r];
        final isSelected =
            selectedZone == i && selectedRing == (r - 1);

        final baseColor = zone['primaryColor'] as Color;

        // Calculate opacity based on ring and selection
        double opacity;
        if (selectedZone == i) {
          opacity = isSelected ? 0.45 : 0.12;
        } else {
          opacity = r == ringFractions.length - 1 ? 0.18 : 0.08;
        }

        final paint = Paint()
          ..color = baseColor.withOpacity(opacity)
          ..style = PaintingStyle.fill;

        final path = Path();
        path.moveTo(center.dx + innerR * math.cos(startAngle),
            center.dy + innerR * math.sin(startAngle));
        path.arcTo(
            Rect.fromCircle(center: center, radius: outerR),
            startAngle,
            sectorAngle,
            false);
        path.arcTo(
            Rect.fromCircle(center: center, radius: innerR),
            startAngle + sectorAngle,
            -sectorAngle,
            false);
        path.close();
        canvas.drawPath(path, paint);

        // Glow highlight on selected sector+ring
        if (isSelected) {
          final glowPaint = Paint()
            ..color = baseColor.withOpacity(0.25 * glowValue)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
          canvas.drawPath(path, glowPaint);
        }
      }

      // Sector divider lines
      final lineAngle = startAngle;
      final linePaint = Paint()
        ..color = const Color(0xFF22C55E).withOpacity(0.2)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        center,
        Offset(
          center.dx + maxR * math.cos(lineAngle),
          center.dy + maxR * math.sin(lineAngle),
        ),
        linePaint,
      );

      // Zone label (outer area)
      final labelAngle = i * sectorAngle;
      final labelR = maxR * 0.89;
      final lx = center.dx + labelR * math.cos(labelAngle);
      final ly = center.dy + labelR * math.sin(labelAngle);

      final tp = TextPainter(
        text: TextSpan(
          text: zone['label'],
          style: TextStyle(
            color: selectedZone == i
                ? (zone['primaryColor'] as Color)
                : Colors.white.withOpacity(0.4),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }

    // ── Concentric ring circles ──
    for (int r = 1; r < ringFractions.length - 1; r++) {
      final ringR = maxR * ringFractions[r];
      final ringColor = ringColors[r - 1];
      canvas.drawCircle(
        center,
        ringR,
        Paint()
          ..color = const Color(0xFF22C55E).withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // ── Ring run labels (left side) ──
    final runLabels = ['DOT', '1', '2', '4', '6'];
    for (int r = 0; r < runLabels.length; r++) {
      final ringR = r == 0
          ? 0.0
          : maxR * (ringFractions[r - 1] + ringFractions[r]) / 2;
      final labelR = r == 0 ? maxR * 0.075 : ringR;
      final isSelectedRing = selectedRing == r;

      final tp = TextPainter(
        text: TextSpan(
          text: runLabels[r],
          style: TextStyle(
            color: isSelectedRing
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.25),
            fontSize: r == 0 ? 7 : 8,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      // Place at left of ring
      final px = center.dx - labelR - tp.width / 2 - 4;
      final py = center.dy - tp.height / 2;
      if (px > 0) tp.paint(canvas, Offset(px, py));
    }

    // ── Draw recent shots as lines ──
    for (int i = 0; i < recentShots.length; i++) {
      final shot = recentShots[i];
      final z = shot['zone'] as int;
      final ring = shot['ring'] as int;
      final color = shot['color'] as Color;
      final alpha = (1.0 - (i / recentShots.length) * 0.7).clamp(0.2, 1.0);

      final shotAngle = zones[z]['angle'] as double;
      final shotR = maxR * (ringFractions[ring] + ringFractions[ring + 1]) / 2;

      final tx = center.dx + shotR * math.cos(shotAngle);
      final ty = center.dy + shotR * math.sin(shotAngle);

      // Shot line
      canvas.drawLine(
        center,
        Offset(tx, ty),
        Paint()
          ..color = color.withOpacity(alpha * 0.7)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      // Shot endpoint dot
      canvas.drawCircle(
        Offset(tx, ty),
        4,
        Paint()..color = color.withOpacity(alpha),
      );
    }

    // ── Center stumps indicator ──
    canvas.drawCircle(
      center,
      maxR * 0.06,
      Paint()
        ..color = const Color(0xFF8B6914)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      maxR * 0.06,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Bat icon (small cross at center)
    final crossPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final cr = maxR * 0.03;
    canvas.drawLine(
        Offset(center.dx - cr, center.dy),
        Offset(center.dx + cr, center.dy),
        crossPaint);
    canvas.drawLine(
        Offset(center.dx, center.dy - cr),
        Offset(center.dx, center.dy + cr),
        crossPaint);
  }

  @override
  bool shouldRepaint(covariant _WagonWheelPainter oldDelegate) {
    return oldDelegate.selectedZone != selectedZone ||
        oldDelegate.selectedRing != selectedRing ||
        oldDelegate.recentShots.length != recentShots.length ||
        oldDelegate.glowValue != glowValue;
  }
}
