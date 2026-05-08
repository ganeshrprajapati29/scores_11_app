// Team Selection Screen - For batting/bowling team selection before toss

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../data/models/match_model.dart';
import '../../data/services/match_service.dart';
import '../../providers/auth_provider.dart';

class TeamSelectionScreen extends StatefulWidget {
  final String matchId;

  const TeamSelectionScreen({super.key, required this.matchId});

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen>
    with TickerProviderStateMixin {
  final MatchService _matchService = MatchService();
  Match? _match;
  bool _isLoading = true;
  String? _error;
  String? _selectedDecision; // 'bat' or 'bowl'

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadMatch();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadMatch() async {
    try {
      setState(() => _isLoading = true);
      final match = await _matchService.getMatchById(widget.matchId);
      setState(() {
        _match = match;
        _isLoading = false;
      });
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          'MATCH SETUP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.4)),
            ),
            child: const Text(
              'STEP 1',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : _error != null
              ? _buildError()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildBody(),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMatch,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildMatchBanner(),
          const SizedBox(height: 32),
          _buildStepIndicator(),
          const SizedBox(height: 28),
          _buildTeamCards(),
          const SizedBox(height: 20),
          if (_selectedDecision != null) ...[
            _buildSelectionSummary(),
            const SizedBox(height: 28),
          ] else ...[
            const SizedBox(height: 8),
          ],
          _buildContinueButton(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildMatchBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2460), Color(0xFF1A3A8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A8F).withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _match?.format.toUpperCase() ?? 'T20',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTeamPill(_match?.team1 ?? 'Team 1', const Color(0xFF3B82F6)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const Text(
                      'VS',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTeamPill(_match?.team2 ?? 'Team 2', const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPill(String name, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
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

  Widget _buildStepIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Batting Team',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'The other team will bowl first',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progress bar
        Row(
          children: [
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _TeamCard(
            teamName: _match?.team1 ?? 'Team 1',
            role: _selectedDecision == null
                ? null
                : _selectedDecision == 'bat'
                    ? 'BAT'
                    : 'BOWL',
            isSelected: _selectedDecision == 'bat',
            accentColor: const Color(0xFF3B82F6),
            onTap: () {
              setState(() => _selectedDecision = 'bat');
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _TeamCard(
            teamName: _match?.team2 ?? 'Team 2',
            role: _selectedDecision == null
                ? null
                : _selectedDecision == 'bowl'
                    ? 'BAT'
                    : 'BOWL',
            isSelected: _selectedDecision == 'bowl',
            accentColor: const Color(0xFF10B981),
            onTap: () {
              setState(() => _selectedDecision = 'bowl');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionSummary() {
    final battingTeam = _selectedDecision == 'bat'
        ? (_match?.team1 ?? 'Team 1')
        : (_match?.team2 ?? 'Team 2');
    final bowlingTeam = _selectedDecision == 'bat'
        ? (_match?.team2 ?? 'Team 2')
        : (_match?.team1 ?? 'Team 1');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Selection confirmed',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _SummaryChip(label: battingTeam, role: 'BATTING', color: const Color(0xFF3B82F6))),
              const SizedBox(width: 10),
              Expanded(child: _SummaryChip(label: bowlingTeam, role: 'BOWLING', color: const Color(0xFFFF6B35))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final bool isReady = _selectedDecision != null && !_isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: isReady
            ? const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              )
            : null,
        color: isReady ? null : Colors.white12,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isReady
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isReady ? _proceedToToss : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
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
                    isReady
                        ? Icons.arrow_forward_rounded
                        : Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isReady ? 'Continue to Toss →' : 'Select a Team First',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(isReady ? 1.0 : 0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _proceedToToss() async {
    if (_match == null) return;

    setState(() => _isLoading = true);

    try {
      final matchService = MatchService();
      final battingFirst =
          _selectedDecision == 'bat' ? _match!.team1 : _match!.team2;
      final bowlingFirst =
          _selectedDecision == 'bat' ? _match!.team2 : _match!.team1;

      await matchService.updateMatch(_match!.id, {
        'battingFirst': battingFirst,
        'bowlingFirst': bowlingFirst,
      });

      debugPrint('✅ Team selection saved: $battingFirst will bat first');

      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.tossRoute(widget.matchId),
        );
      }
    } catch (e) {
      debugPrint('Error saving team selection: $e');
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.tossRoute(widget.matchId),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─────────────────────────────────────────────
// Reusable Sub-Widgets
// ─────────────────────────────────────────────

class _TeamCard extends StatelessWidget {
  final String teamName;
  final String? role; // 'BAT' | 'BOWL' | null
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _TeamCard({
    required this.teamName,
    required this.role,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBatting = role == 'BAT';
    final isBowling = role == 'BOWL';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accentColor
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.28),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // Avatar circle
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              accentColor.withOpacity(0.7),
                              accentColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.07),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accentColor.withOpacity(0.5),
                              blurRadius: 16,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      teamName.isNotEmpty
                          ? teamName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white38,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                // Badge
                if (isSelected)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF060D1F), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Team name
            Text(
              teamName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            // Role chip
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isBatting
                    ? const Color(0xFF3B82F6).withOpacity(0.18)
                    : isBowling
                        ? const Color(0xFFFF6B35).withOpacity(0.18)
                        : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isBatting
                      ? const Color(0xFF3B82F6).withOpacity(0.4)
                      : isBowling
                          ? const Color(0xFFFF6B35).withOpacity(0.4)
                          : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBatting
                        ? Icons.sports_cricket_rounded
                        : isBowling
                            ? Icons.sports_baseball_rounded
                            : Icons.touch_app_rounded,
                    size: 12,
                    color: isBatting
                        ? const Color(0xFF3B82F6)
                        : isBowling
                            ? const Color(0xFFFF6B35)
                            : Colors.white30,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isBatting
                        ? 'BATTING'
                        : isBowling
                            ? 'BOWLING'
                            : 'Tap to select',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: isBatting
                          ? const Color(0xFF3B82F6)
                          : isBowling
                              ? const Color(0xFFFF6B35)
                              : Colors.white30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String role;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.role,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
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
}