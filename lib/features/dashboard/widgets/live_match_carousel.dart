import 'package:flutter/material.dart';
import 'dart:async';
import '../../../data/models/dashboard_model.dart';
import '../../../core/constants/app_colors.dart';

class LiveMatchCarousel extends StatefulWidget {
  final List<LiveMatch> matches;
  const LiveMatchCarousel({super.key, required this.matches});

  @override
  State<LiveMatchCarousel> createState() => _LiveMatchCarouselState();
}

class _LiveMatchCarouselState extends State<LiveMatchCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (widget.matches.isEmpty) return;
      final nextIndex = (_currentIndex + 1) % widget.matches.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matches.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      height: 190,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: widget.matches.length,
            itemBuilder: (context, index) {
              final match = widget.matches[index];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/scorecard', arguments: match.id),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: LiveMatchCard(match: match),
                ),
              );
            },
          ),
          // Dots indicator with pulse
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.matches.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    entry.key,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == entry.key ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == entry.key 
                          ? AppColors.primary 
                          : AppColors.primary.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: _currentIndex == entry.key 
                          ? [BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveMatchCard extends StatelessWidget {
  final LiveMatch match;
  const LiveMatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live indicator
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.live,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.live,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.live,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  match.format.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 10),
          LiveTeamRow(
            teamName: match.team1.shortName,
            score: _teamScore(match, 1),
            isLeading: match.team1Score != null && match.team1Score! > (match.team2Score ?? 0),
          ),
          const SizedBox(height: 6),
          // Team 2
          LiveTeamRow(
            teamName: match.team2.shortName,
            score: _teamScore(match, 2),
            isLeading: match.team2Score != null && match.team2Score! > (match.team1Score ?? 0),
          ),
          const SizedBox(height: 8),
          _MatchMetaLine(match: match),
          const Spacer(),
          Text(
            match.tournament.name,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          Row(
            children: [
              Icon(Icons.location_on, size: 10, color: Colors.grey[400]),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  '${match.venue ?? match.venueCity ?? ''}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 9,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _teamScore(LiveMatch match, int team) {
    final parsedScore = match.scoreForTeam(team);
    if (parsedScore != null) return parsedScore;

    final score = match.scoreString;
    if (score != null && score.contains('|')) {
      final parts = score.split('|');
      return team == 1 ? parts.first.trim() : parts.last.trim();
    }
    final runs = team == 1 ? match.team1Score : match.team2Score;
    return runs == null ? null : '$runs/0';
  }
}

class _MatchMetaLine extends StatelessWidget {
  final LiveMatch match;
  const _MatchMetaLine({required this.match});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      'Inn ${match.currentInnings}',
      if (match.target != null) 'Target ${match.target}',
      if (match.requiredRuns != null) '${match.requiredRuns} needed',
      if (match.tossWinner != null)
        'Toss: ${match.tossWinner}${match.tossDecision != null ? ' ${match.tossDecision}' : ''}',
    ];

    return SizedBox(
      height: 24,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            chips[index],
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class LiveTeamRow extends StatelessWidget {
  final String teamName;
  final String? score;
  final bool isLeading;

  const LiveTeamRow({
    super.key,
    required this.teamName,
    this.score,
    this.isLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teamName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              if (score != null)
                Text(
                  score!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isLeading ? Colors.green : Color(0xFF1A1A2E),
                  ),
                ),
            ],
          ),
        ),
        if (isLeading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.trending_up,
              size: 14,
              color: Colors.green,
            ),
          ),
      ],
    );
  }
}

