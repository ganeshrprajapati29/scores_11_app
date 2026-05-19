import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_client.dart';
import '../../core/config/api_config.dart';
import '../../data/services/match_service.dart';
import '../../data/models/match_model.dart';
import '../../providers/live_score_control_provider.dart';
import '../matches/live_score_control_screen.dart';
import '../matches/wagon_wheel_screen.dart';

class TossScreen extends StatefulWidget {
  final String matchId;
  const TossScreen({super.key, required this.matchId});

  @override
  State<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends State<TossScreen>
    with TickerProviderStateMixin {
  final MatchService _matchService = MatchService();
  String? selectedDecision;
  String? tossWinner;
  bool isLoading = false;
  Match? _match;

  // Coin flip animation
  late AnimationController _coinController;
  late Animation<double> _coinAnimation;
  bool _isCoinFlipping = false;
  bool _coinFlipped = false;
  String? _coinResult; // 'heads' or 'tails'

  // Shimmer / glow animation
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Selection reveal animation
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _loadMatch();

    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _coinAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 6 * pi)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 6 * pi, end: 8 * pi)
            .chain(CurveTween(curve: Curves.decelerate)),
        weight: 40,
      ),
    ]).animate(_coinController);

    _coinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isCoinFlipping = false;
          _coinFlipped = true;
        });
        _revealController.forward(from: 0);
      }
    });

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _coinController.dispose();
    _glowController.dispose();
    _revealController.dispose();
    super.dispose();
  }

Future<void> _loadMatch() async {
    try {
      _match = await _matchService.getMatchById(widget.matchId);
      
      // Update match status based on backend status
      _updateFlowFromMatch();
      
      // If match is already live, navigate to live score control
      if (_match?.isLive == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LiveScoreControlScreen(matchId: widget.matchId),
          ),
        );
        return;
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading match: $e');
    }
  }
  
  void _updateFlowFromMatch() {
    if (_match == null) return;
    
    // Update flow based on match status from backend
    final status = _match!.status.toLowerCase();
    debugPrint('📊 Match status from backend: $status');
    
// If we've already done toss, go to live score
    if (_match!.toss?.winner != null && _match!.toss?.decision != null) {
      // Toss already done, navigate to live control
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LiveScoreControlScreen(matchId: widget.matchId),
              ),
            );
          }
        });
      }
    }
  }

void _flipCoin() {
    if (_isCoinFlipping || _coinFlipped) return;
    setState(() {
      _isCoinFlipping = true;
      _coinFlipped = false;
      _coinResult = null;
      selectedDecision = null;
      tossWinner = null;
    });
    _revealController.reset();
    _coinController.forward(from: 0);
    // Randomly decide heads or tails
    _coinResult = Random().nextBool() ? 'heads' : 'tails';
  }

  // Open Wagon Wheel Screen
  void _openWagonWheel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WagonWheelScreen(
          matchId: widget.matchId,
          match: _match,
        ),
      ),
    );
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
          'TOSS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        actions: [
          // Wagon Wheel Quick Access Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar_rounded,
                  color: Color(0xFFFFD700), size: 20),
            ),
            onPressed: () => _openWagonWheel(),
            tooltip: 'Wagon Wheel',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
      body: _match == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildMatchBanner(),
                    const SizedBox(height: 36),
                    _buildCoinSection(),
                    const SizedBox(height: 32),
                    if (_coinFlipped) ...[
                      _buildResultSection(),
                      const SizedBox(height: 28),
                      _buildDecisionSection(),
                      const SizedBox(height: 28),
                      _buildWinnerSection(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                      const SizedBox(height: 32),
                    ] else ...[
                      _buildInstructionText(),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMatchBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2460), Color(0xFF1A3A8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A8F).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTeamBadge(_match!.team1, true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _match!.format.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildTeamBadge(_match!.team2, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBadge(String teamName, bool isLeft) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isLeft
                    ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                    : [const Color(0xFF10B981), const Color(0xFF059669)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isLeft
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF10B981))
                      .withOpacity(0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: Text(
                teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            teamName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinSection() {
    return Column(
      children: [
        const Text(
          'Flip the Coin',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: (_isCoinFlipping || _coinFlipped) ? null : _flipCoin,
          child: AnimatedBuilder(
            animation: Listenable.merge([_coinAnimation, _glowAnimation]),
            builder: (context, child) {
              final angle = _coinAnimation.value;
              final isHeadsSide = (angle / pi).floor() % 2 == 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Glow ring
                  if (_isCoinFlipping || _coinFlipped)
                    Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700)
                                .withOpacity(0.35 * _glowAnimation.value),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  // Coin with flip
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: isHeadsSide
                              ? [
                                  const Color(0xFFFFE566),
                                  const Color(0xFFFFD700),
                                  const Color(0xFFB8860B),
                                ]
                              : [
                                  const Color(0xFFE8C84A),
                                  const Color(0xFFC9A227),
                                  const Color(0xFF9A7B0A),
                                ],
                          stops: const [0.2, 0.6, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.6),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Coin rim effect
                          Container(
                            width: 136,
                            height: 136,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 2,
                              ),
                            ),
                          ),
                          // Inner circle
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: isHeadsSide
                                    ? [
                                        const Color(0xFFFFF0A0),
                                        const Color(0xFFFFD700),
                                      ]
                                    : [
                                        const Color(0xFFD4A017),
                                        const Color(0xFF9A7B0A),
                                      ],
                              ),
                            ),
                          ),
                          // Face
                          if (isHeadsSide)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.sports_cricket,
                                  color: Color(0xFF7A5C00),
                                  size: 36,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'HEADS',
                                  style: TextStyle(
                                    color: Color(0xFF7A5C00),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.catching_pokemon,
                                  color: Color(0xFF4A3800),
                                  size: 36,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'TAILS',
                                  style: TextStyle(
                                    color: Color(0xFF4A3800),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        // Tap button
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton.icon(
            onPressed: (_isCoinFlipping || _coinFlipped) ? null : _flipCoin,
            icon: Icon(
              _isCoinFlipping ? Icons.hourglass_top_rounded : Icons.touch_app_rounded,
              size: 20,
            ),
            label: Text(
              _isCoinFlipping
                  ? 'Flipping...'
                  : _coinFlipped
                      ? 'Coin Flipped'
                      : 'Tap to Flip',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCoinFlipping
                  ? Colors.grey.shade800
                  : const Color(0xFFFFD700),
              foregroundColor: _isCoinFlipping ? Colors.white60 : const Color(0xFF1A0A00),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionText() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tap the coin to flip it. Winner selects bat or bowl.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    return ScaleTransition(
      scale: _revealAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C1200), Color(0xFF2A1F00)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 22),
            const SizedBox(width: 10),
            Text(
              'Coin landed on ${_coinResult?.toUpperCase() ?? ''}!',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'WINNER CHOOSES TO'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ChoiceCard(
                label: 'Bat First',
                subtitle: 'Set the target',
                icon: Icons.sports_cricket_rounded,
                selected: selectedDecision == 'bat',
                accentColor: const Color(0xFF3B82F6),
                onTap: () => setState(() => selectedDecision = 'bat'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ChoiceCard(
                label: 'Bowl First',
                subtitle: 'Chase the target',
                icon: Icons.sports_baseball_rounded,
                selected: selectedDecision == 'bowl',
                accentColor: const Color(0xFFFF6B35),
                onTap: () => setState(() => selectedDecision = 'bowl'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWinnerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'TOSS WINNER'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _TeamWinnerCard(
                teamName: _match!.team1,
                selected: tossWinner == 'team1',
                color: const Color(0xFF3B82F6),
                onTap: () => setState(() => tossWinner = 'team1'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _TeamWinnerCard(
                teamName: _match!.team2,
                selected: tossWinner == 'team2',
                color: const Color(0xFF10B981),
                onTap: () => setState(() => tossWinner = 'team2'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final bool isReady =
        selectedDecision != null && tossWinner != null && !isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: isReady
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              )
            : null,
        color: isReady ? null : Colors.white12,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isReady
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isReady ? _submitToss : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isReady ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isReady ? 'Start Match →' : 'Select Winner & Decision',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(isReady ? 1.0 : 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitToss() async {
    if (selectedDecision == null || tossWinner == null || _match == null) return;

    setState(() => isLoading = true);

    try {
      final winnerTeamName =
          tossWinner == 'team1' ? _match!.team1 : _match!.team2;
      final winnerTeamId =
          tossWinner == 'team1' ? _match!.team1Id : _match!.team2Id;

      _match = await _matchService.updateToss(
          widget.matchId, winnerTeamId, selectedDecision!);

      debugPrint(
          '✅ Toss saved: $winnerTeamName won toss and chose to ${selectedDecision == 'bat' ? 'bat' : 'bowl'} first');

      // Backend moves the match to team selection after toss; scoring goes live after XI initialization.

      debugPrint('✅ Match status updated to LIVE');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$winnerTeamName won the toss. Confirm Playing XI next.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LiveScoreControlScreen(matchId: widget.matchId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving toss: $e');
      await _loadMatch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_match?.toss?.winner != null
                ? 'Toss already completed. Opening match setup.'
                : 'Toss failed: $e'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LiveScoreControlScreen(matchId: widget.matchId),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

// ─────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.4),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.5,
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accentColor : Colors.white.withOpacity(0.08),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? accentColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.06),
              ),
              child: Icon(
                icon,
                size: 30,
                color: selected ? accentColor : Colors.white38,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: selected
                    ? accentColor.withOpacity(0.8)
                    : Colors.white30,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 10),
              Icon(Icons.check_circle_rounded, color: accentColor, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamWinnerCard extends StatelessWidget {
  final String teamName;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TeamWinnerCard({
    required this.teamName,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.08),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: selected
                        ? LinearGradient(
                            colors: [color.withOpacity(0.8), color],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: selected ? null : Colors.white12,
                  ),
                  child: Center(
                    child: Text(
                      teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white38,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF060D1F), width: 2),
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              teamName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
color: selected ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'WINNER',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
