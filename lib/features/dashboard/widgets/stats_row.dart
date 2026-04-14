import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../core/constants/app_colors.dart';

class DashboardStatsRow extends StatelessWidget {
  final QuickStats stats;
  const DashboardStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedStatsCard(
            title: 'Matches',
            value: stats.totalMatches,
            change: '+${stats.todayMatches}',
            icon: Icons.sports_cricket,
            gradient: const [Color(0xFF1565C0), Color(0xFF1E88E5)],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedStatsCard(
            title: 'Live',
            value: stats.liveMatches,
            isLive: true,
            icon: Icons.live_tv_rounded,
            gradient: const [Color(0xFFE53935), Color(0xFFEF5350)],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedStatsCard(
            title: 'Cups',
            value: stats.totalTournaments,
            change: '+${stats.activeTournaments}',
            icon: Icons.emoji_events,
            gradient: const [Color(0xFFFF8F00), Color(0xFFFFB300)],
          ),
        ),
      ],
    );
  }
}

class AnimatedStatsCard extends StatefulWidget {
  final String title;
  final int value;
  final String? change;
  final IconData icon;
  final List<Color> gradient;
  final bool isLive;

  const AnimatedStatsCard({
    super.key,
    required this.title,
    required this.value,
    this.change,
    required this.icon,
    required this.gradient,
    this.isLive = false,
  });

  @override
  State<AnimatedStatsCard> createState() => _AnimatedStatsCardState();
}

class _AnimatedStatsCardState extends State<AnimatedStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _displayedValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: widget.value.toDouble()),
    duration: const Duration(milliseconds: 1200),
    builder: (context, value, child) {
        _displayedValue = value.round();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 20),
                  if (widget.isLive)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  '$_displayedValue',
                  key: ValueKey(_displayedValue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.change != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.change!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

