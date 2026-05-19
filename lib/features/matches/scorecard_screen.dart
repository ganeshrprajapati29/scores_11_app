import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/scorecard_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../data/models/scorecard_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/services/match_service.dart';

class ScorecardScreen extends StatefulWidget {
  final String matchId;

  const ScorecardScreen({super.key, required this.matchId});

  @override
  _ScorecardScreenState createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen>
    with SingleTickerProviderStateMixin {
  final MatchService _matchService = MatchService();
  bool _isMatchListLoading = false;
  String? _matchListError;
  List<Match> _scorecardMatches = [];
  late final TabController _tabController;
  ScorecardProvider? _scorecardProvider;
  int _selectedInnings = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.matchId.trim().isEmpty) {
      _loadScorecardMatches();
    } else {
      _scorecardProvider = ScorecardProvider()
        ..loadScorecard(widget.matchId, forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scorecardProvider?.dispose();
    super.dispose();
  }

  Future<void> _loadScorecardMatches() async {
    setState(() {
      _isMatchListLoading = true;
      _matchListError = null;
    });

    try {
      final results = await Future.wait([
        _matchService.getLiveMatches(forceRefresh: true),
        _matchService.getCompletedMatches(limit: 50),
      ]);
      final byId = <String, Match>{};
      for (final match in [...results[0], ...results[1]]) {
        if (match.id.isNotEmpty) byId[match.id] = match;
      }
      final matches = byId.values.toList()
        ..sort((a, b) {
          if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
          return b.scheduledDate.compareTo(a.scheduledDate);
        });
      if (!mounted) return;
      setState(() => _scorecardMatches = matches);
    } catch (e) {
      if (!mounted) return;
      setState(() => _matchListError = 'Scorecards load nahi ho paaye: $e');
    } finally {
      if (mounted) setState(() => _isMatchListLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matchId.trim().isEmpty) {
      return _buildScorecardMatchList();
    }

    final provider = _scorecardProvider ??= ScorecardProvider()
      ..loadScorecard(widget.matchId, forceRefresh: true);

    return ChangeNotifierProvider.value(
      value: provider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: CustomAppBar(
          title: 'Match Scorecard',
          showBackButton: true,
          actions: [
            Consumer<ScorecardProvider>(
              builder: (context, provider, child) => IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : () => provider.refreshScorecard(widget.matchId),
              ),
            ),
          ],
        ),
        body: Consumer<ScorecardProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && !provider.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading scorecard...'),
                  ],
                ),
              );
            }
            
            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : () => provider.refreshScorecard(widget.matchId),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!provider.hasData || provider.scorecard == null) {
              return RefreshIndicator(
                onRefresh: () => provider.refreshScorecard(widget.matchId),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  children: [
                    Icon(Icons.scoreboard, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No scorecard data available',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull to refresh or check back later',
                      style: TextStyle(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final scorecard = provider.scorecard!;
            final inningsCount = scorecard.innings.length;
            if (inningsCount > 0 && _selectedInnings >= inningsCount) {
              _selectedInnings = inningsCount - 1;
            }
            
            return RefreshIndicator(
              onRefresh: () => provider.refreshScorecard(widget.matchId),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfessionalScoreHeader(scorecard, provider),
                    const SizedBox(height: 16),
                    _buildScorecardTabs(),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        return _tabController.index == 0
                            ? _buildMatchDetailsTab(scorecard, provider)
                            : _buildScorecardTab(scorecard);
                      },
                    ),
                  ],
                ),
              ),
            );

          },
        ),
      ),
    );
  }

  Widget _buildScorecardMatchList() {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Scorecards',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isMatchListLoading ? null : _loadScorecardMatches,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadScorecardMatches,
        child: _isMatchListLoading && _scorecardMatches.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _matchListError != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Text(
                        _matchListError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadScorecardMatches,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  )
                : _scorecardMatches.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(28),
                        children: [
                          Icon(Icons.scoreboard_outlined, size: 72, color: Colors.grey[400]),
                          const SizedBox(height: 14),
                          Text(
                            'No live or completed scorecards yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Live aur completed matches yahan dynamic show honge.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _scorecardMatches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildScorecardMatchCard(_scorecardMatches[index]);
                        },
                      ),
      ),
    );
  }

  Widget _buildScorecardMatchCard(Match match) {
    final statusColor = match.isLive ? Colors.red : Colors.green;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pushNamed(context, '/scorecard', arguments: match.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    match.isLive ? 'LIVE' : 'COMPLETED',
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(match.scheduledDate),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildTeamScoreLine(_teamName(match, 1), match.team1ScoreDisplay),
            const SizedBox(height: 8),
            _buildTeamScoreLine(_teamName(match, 2), match.team2ScoreDisplay),
            const SizedBox(height: 12),
            Text(
              _resultText(match),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: match.isLive ? Colors.red[700] : AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    match.venue?.name ?? 'Venue not added',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamScoreLine(String teamName, String score) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: AppColors.primary.withOpacity(0.08),
          child: Text(
            teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
            style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            teamName.isNotEmpty ? teamName : 'Team',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        Text(score, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildScorecardTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(11),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[700],
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        tabs: const [
          Tab(text: 'Match Details'),
          Tab(text: 'Scorecard'),
        ],
      ),
    );
  }

  Widget _buildMatchDetailsTab(
    FullScorecard scorecard,
    ScorecardProvider provider,
  ) {
    final match = provider.match ?? scorecard.match;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeaders(scorecard),
        const SizedBox(height: 16),
        _buildResultPanel(match),
        const SizedBox(height: 16),
        _buildMatchInfo(match),
        const SizedBox(height: 16),
        _buildSquadsSection(scorecard, match),
      ],
    );
  }

  Widget _buildScorecardTab(FullScorecard scorecard) {
    if (scorecard.innings.isEmpty) {
      return Column(
        children: [
          _buildStatsRow(scorecard),
          const SizedBox(height: 16),
          _EmptyScoreSection(
            title: 'Scorecard',
            message: 'Scorecard striker aur bowler set karne ke baad live update hoga.',
          ),
        ],
      );
    }

    final innings = scorecard.innings[_selectedInnings];
    final batting = scorecard.batting.length > _selectedInnings
        ? scorecard.batting[_selectedInnings]
        : <BatsmanStats>[];
    final bowling = scorecard.bowling.length > _selectedInnings
        ? scorecard.bowling[_selectedInnings]
        : <BowlerStats>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInningsSelector(scorecard),
        const SizedBox(height: 16),
        _buildInningsHeader(innings, innings.inningsNumber),
        const SizedBox(height: 12),
        _buildStatsRowForInnings(innings),
        const SizedBox(height: 16),
        _buildDetailedExtras(innings),
        const SizedBox(height: 16),
        _buildEnhancedBattingTable(batting, innings),
        const SizedBox(height: 16),
        _buildEnhancedBowlingTable(bowling, innings),
        if (scorecard.fallOfWickets.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildFallOfWickets(scorecard.fallOfWickets),
        ],
      ],
    );
  }

  Widget _buildInningsSelector(FullScorecard scorecard) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(scorecard.innings.length, (index) {
          final innings = scorecard.innings[index];
          final selected = _selectedInnings == index;
          return Padding(
            padding: EdgeInsets.only(right: index == scorecard.innings.length - 1 ? 0 : 10),
            child: ChoiceChip(
              selected: selected,
              onSelected: (_) => setState(() => _selectedInnings = index),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? AppColors.primary : Colors.grey.shade300,
              ),
              label: Text(
                '${_displayTeamName(innings.battingTeam, fallback: 'Team ${index + 1}')}  ${innings.totalRuns}/${innings.totalWickets}',
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsRowForInnings(Innings innings) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _MiniStat(title: 'Run Rate', value: innings.runRate.toStringAsFixed(2)),
          _MiniStat(title: 'Extras', value: innings.extras.total.toString()),
          _MiniStat(title: 'Wickets', value: innings.totalWickets.toString()),
          _MiniStat(title: 'Overs', value: innings.oversDisplay),
        ],
      ),
    );
  }

  Widget _buildResultPanel(Match match) {
    final result = _resultText(match);
    final isCompleted = match.isCompleted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isCompleted ? Colors.green : Colors.red).withOpacity(0.1),
            child: Icon(
              isCompleted ? Icons.emoji_events_rounded : Icons.circle,
              color: isCompleted ? Colors.green : Colors.red,
              size: isCompleted ? 20 : 10,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? 'Result' : 'Live Match',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  result,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadsSection(FullScorecard scorecard, Match match) {
    final team1Name = _teamName(match, 1);
    final team2Name = _teamName(match, 2);
    final team1Players = _squadForTeam(scorecard, 0);
    final team2Players = _squadForTeam(scorecard, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Squads',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        _SquadCard(teamName: team1Name, players: team1Players),
        const SizedBox(height: 12),
        _SquadCard(teamName: team2Name, players: team2Players),
      ],
    );
  }

  List<String> _squadForTeam(FullScorecard scorecard, int teamIndex) {
    final names = <String>[];
    if (scorecard.match.battingOrder.length > teamIndex) {
      names.addAll(scorecard.match.battingOrder[teamIndex].players);
    }
    if (scorecard.batting.length > teamIndex) {
      names.addAll(scorecard.batting[teamIndex].map((player) => player.playerName));
    }
    if (scorecard.bowling.length > teamIndex) {
      names.addAll(scorecard.bowling[teamIndex].map((player) => player.playerName));
    }
    final cleaned = <String>[];
    final seen = <String>{};
    for (var i = 0; i < names.length; i++) {
      final name = _displayPlayerName(names[i], fallback: 'Player ${i + 1}');
      if (seen.add(name)) cleaned.add(name);
    }
    return cleaned;
  }

  Widget _buildProfessionalScoreHeader(
    FullScorecard scorecard,
    ScorecardProvider provider,
  ) {
    final match = provider.match ?? scorecard.match;
    final currentInnings =
        scorecard.innings.isNotEmpty ? scorecard.innings.last : null;
    final isLive = match.isLive || provider.isLive;
    final accent = isLive ? const Color(0xFFE11D48) : AppColors.primary;
    final venueParts = [
      match.venue?.name,
      match.venue?.city,
    ].where((value) => value != null && value.trim().isNotEmpty).join(', ');
    final battingTeam = currentInnings?.battingTeam?.isNotEmpty == true
        ? _displayTeamName(
            currentInnings!.battingTeam,
            fallback: match.currentInnings == 2 ? _teamName(match, 2) : _teamName(match, 1),
          )
        : (match.currentInnings == 2 ? _teamName(match, 2) : _teamName(match, 1));
    final inningsScore = currentInnings == null
        ? (match.currentInnings == 2
            ? match.team2ScoreDisplay
            : match.team1ScoreDisplay)
        : '${currentInnings.totalRuns}/${currentInnings.totalWickets} (${currentInnings.oversDisplay})';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScoreStatusPill(isLive: isLive),
              const Spacer(),
              _HeaderMiniPill(text: match.format.toUpperCase()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeaderTeamBlock(
                  name: _teamName(match, 1),
                  score: match.team1ScoreDisplay,
                  alignEnd: false,
                  isBatting: isLive && match.currentInnings == 1,
                ),
              ),
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: _HeaderTeamBlock(
                  name: _teamName(match, 2),
                  score: match.team2ScoreDisplay,
                  alignEnd: true,
                  isBatting: isLive && match.currentInnings == 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$battingTeam batting',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inningsScore,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderInfoChip(
                      icon: Icons.speed_rounded,
                      label: currentInnings == null
                          ? 'RR 0.00'
                          : 'RR ${currentInnings.runRate.toStringAsFixed(2)}',
                    ),
                    _HeaderInfoChip(
                      icon: Icons.sports_cricket_rounded,
                      label: 'Inn ${match.currentInnings}',
                    ),
                    if (venueParts.isNotEmpty)
                      _HeaderInfoChip(
                        icon: Icons.location_on_outlined,
                        label: venueParts,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  isLive ? Icons.circle : Icons.emoji_events_rounded,
                  size: isLive ? 10 : 18,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _resultText(match),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
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

Widget _buildMatchHeader(FullScorecard scorecard) {
    final match = scorecard.match;
    final currentInnings = scorecard.innings.isNotEmpty ? scorecard.innings.last : null;
    if (currentInnings == null) return const SizedBox.shrink();

    // Determine which team is batting
    final battingTeamName = currentInnings.battingTeam?.isNotEmpty == true
        ? currentInnings.battingTeam!
        : (match.currentInnings == 2 ? match.team2 : match.team1);
    
    // Truncate long team names
    final displayName = battingTeamName.length > 20 
        ? '${battingTeamName.substring(0, 17)}...' 
        : battingTeamName;

    final totalRuns = currentInnings.totalRuns;
    final totalWickets = currentInnings.totalWickets;
    final oversDisplay = currentInnings.oversDisplay;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalRuns/$totalWickets',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            oversDisplay,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _resultText(match),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resultText(Match match) {
    final result = match.result;
    if (result?.message?.trim().isNotEmpty == true) return result!.message!.trim();
    final winner = _displayTeamName(result?.winner, fallback: '');
    if (winner.isNotEmpty && result?.margin?.trim().isNotEmpty == true) {
      return '$winner won by ${result!.margin}';
    }
    if (result?.margin?.isNotEmpty == true) return result!.margin!;
    return match.isLive ? 'LIVE' : match.status;
  }

  String _teamName(Match match, int teamNumber) {
    final data = teamNumber == 1 ? match.team1Data : match.team2Data;
    final raw = teamNumber == 1 ? match.team1 : match.team2;
    if (data is Map) {
      final name = data['name'] ?? data['teamName'] ?? data['shortName'];
      final text = name?.toString().trim() ?? '';
      if (text.isNotEmpty && !_looksLikeId(text)) return text;
    }
    return _displayTeamName(raw, fallback: 'Team $teamNumber');
  }

  String _displayTeamName(String? value, {required String fallback}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || _looksLikeId(text)) return fallback;
    return text;
  }

  String _displayPlayerName(String? value, {required String fallback}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'unknown' || _looksLikeId(text)) {
      return fallback;
    }
    return text;
  }

  String _tossWinnerName(Match match) {
    final winner = match.toss?.winner?.trim() ?? '';
    if (winner.isEmpty) return 'Team';
    if (winner == match.team1Id || winner == match.team1) return _teamName(match, 1);
    if (winner == match.team2Id || winner == match.team2) return _teamName(match, 2);
    return _displayTeamName(winner, fallback: 'Team');
  }

  String _dismissalText(BatsmanStats player) {
    if (!player.isOut) return 'not out';
    final outText = (player.dismissal ?? '')
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    final bowler = _displayPlayerName(player.bowlerDismissedBy, fallback: '');
    if (bowler.isNotEmpty) return '$outText b $bowler';
    return outText.isNotEmpty ? outText : 'out';
  }

  bool _looksLikeId(String value) {
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value.trim());
  }

Widget _buildStatsRow(FullScorecard scorecard) {
    final currentInnings = scorecard.innings.isNotEmpty ? scorecard.innings[0] : null;
    if (currentInnings == null) return const SizedBox.shrink();

    final runRate = currentInnings.runRate > 0 ? currentInnings.runRate.toStringAsFixed(2) : '0.00';
    final extrasTotal = currentInnings.extras.total;
    final wickets = currentInnings.totalWickets;

// Try to get partnership data from scorecard.partnership
    String partnership = '-';
    if (scorecard.partnerships.isNotEmpty) {
      final p = scorecard.partnerships[0] as Map<String, dynamic>;
      partnership = '${p['runs']}/${p['wickets']}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('Run Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(runRate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('Extras', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('$extrasTotal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('Partnership', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(partnership, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('Wickets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(
                  '$wickets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: wickets >= 8 ? Colors.red : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedExtras(Innings innings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Extras', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildExtraPill('Wd', innings.extras.wides ?? 0),
              _buildExtraPill('Nb', innings.extras.noBalls ?? 0),
              _buildExtraPill('B', innings.extras.byes ?? 0),
              _buildExtraPill('LB', innings.extras.legByes ?? 0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Text(
                  'Total: ${innings.extras.total}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaders(FullScorecard scorecard) {
    final allBatters = scorecard.batting.expand((e) => e).toList()
      ..sort((a, b) {
        final runCompare = b.runs.compareTo(a.runs);
        return runCompare != 0 ? runCompare : b.strikeRate.compareTo(a.strikeRate);
      });
    final allBowlers = scorecard.bowling.expand((e) => e).toList()
      ..sort((a, b) {
        final wicketCompare = b.wickets.compareTo(a.wickets);
        return wicketCompare != 0 ? wicketCompare : a.economy.compareTo(b.economy);
      });

    return Row(
      children: [
        Expanded(
          child: _LeaderCard(
            title: 'Top Batter',
            icon: Icons.sports_cricket_rounded,
            color: AppColors.primary,
            name: allBatters.isNotEmpty
                ? _displayPlayerName(allBatters.first.playerName, fallback: 'Batter')
                : 'Yet to bat',
            primary: allBatters.isNotEmpty
                ? '${allBatters.first.runs} (${allBatters.first.balls})'
                : '-',
            secondary: allBatters.isNotEmpty
                ? 'SR ${allBatters.first.strikeRate.toStringAsFixed(1)}'
                : 'Runs and balls will update live',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LeaderCard(
            title: 'Top Bowler',
            icon: Icons.sports_baseball_rounded,
            color: const Color(0xFFE11D48),
            name: allBowlers.isNotEmpty
                ? _displayPlayerName(allBowlers.first.playerName, fallback: 'Bowler')
                : 'Yet to bowl',
            primary: allBowlers.isNotEmpty
                ? '${allBowlers.first.wickets}/${allBowlers.first.runs}'
                : '-',
            secondary: allBowlers.isNotEmpty
                ? '${allBowlers.first.oversDisplay} ov - Eco ${allBowlers.first.economy.toStringAsFixed(1)}'
                : 'Wickets and economy will update live',
          ),
        ),
      ],
    );
  }

  Widget _buildExtraPill(String type, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Text('$type: $count'),
    );
  }

  Widget _buildCurrentInningsTables(FullScorecard scorecard) {
    return Column(
      children: List.generate(scorecard.innings.length, (index) {
        final innings = scorecard.innings[index];
        final batting = scorecard.batting.length > index
            ? scorecard.batting[index]
            : <BatsmanStats>[];
        final bowling = scorecard.bowling.length > index
            ? scorecard.bowling[index]
            : <BowlerStats>[];

        return Column(
          children: [
            _buildInningsHeader(innings, innings.inningsNumber),
            const SizedBox(height: 12),
            _buildEnhancedBattingTable(batting, innings),
            const SizedBox(height: 16),
            _buildEnhancedBowlingTable(bowling, innings),
            const SizedBox(height: 24),
          ],
        );
      }),
    );
  }

  Widget _buildEnhancedBattingTable(List<dynamic> batting, Innings innings) {
    final List<BatsmanStats> batsmanStats = batting.cast<BatsmanStats>();
    if (batsmanStats.isEmpty) {
      return _EmptyScoreSection(
        title: 'Batting',
        message: 'Batting scorecard will appear after striker is set.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Batting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.grey[50],
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Batsman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('4s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('6s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          ...batsmanStats.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          _displayPlayerName(player.playerName, fallback: 'Batter ${index + 1}'),
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        _dismissalText(player),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: player.isOut ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Text(player.runs.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text(player.balls.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(player.fours.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(player.sixes.toString(), textAlign: TextAlign.center)),
                Expanded(
                  flex: 2,
                  child: Text(
                    player.strikeRate > 0 ? player.strikeRate.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
          }),
        ],
      ),
    );
  }

  Widget _buildEnhancedBowlingTable(List<dynamic> bowling, Innings innings) {
    final List<BowlerStats> bowlerStats = bowling.cast<BowlerStats>();
    if (bowlerStats.isEmpty) {
      return _EmptyScoreSection(
        title: 'Bowling',
        message: 'Bowling scorecard will appear after bowler is set.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Bowling', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.grey[50],
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('O', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('W', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('Econ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          ...bowlerStats.asMap().entries.map((entry) {
            final index = entry.key;
            final bowler = entry.value;
            return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _displayPlayerName(bowler.playerName, fallback: 'Bowler ${index + 1}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(child: Text(bowler.oversDisplay, textAlign: TextAlign.center)),
                Expanded(child: Text(bowler.maidens.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(bowler.runs.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(bowler.wickets.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                Expanded(child: Text(bowler.economy.toStringAsFixed(2), textAlign: TextAlign.center)),
              ],
            ),
          );
          }),
        ],
      ),
    );

  }

Widget _buildTeamsHeader(ScorecardProvider provider) {
    final match = provider.match;
    if (match == null) return const SizedBox.shrink();

    // Get actual team names with fallbacks - team1 and team2 are String properties
    final team1Name = match.team1.isNotEmpty ? match.team1 : 'Team 1';
    final team2Name = match.team2.isNotEmpty ? match.team2 : 'Team 2';
    
    // Handle long team names - truncate for display if too long
    String getShortName(String name) {
      if (name.length > 15) {
        return name.substring(0, 12) + '...';
      }
      return name;
    }
    
    final team1Short = getShortName(team1Name);
    final team2Short = getShortName(team2Name);
    
    final team1Score = '${match.score.team1.runs}/${match.score.team1.wickets} (${match.score.team1.overs})';
    final team2Score = '${match.score.team2.runs}/${match.score.team2.wickets} (${match.score.team2.overs})';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team1Short,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team1Score,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      team2Short,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team2Score,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Current innings info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              match.isLive ? 'LIVE' : (match.result?.margin ?? match.status ?? 'Completed'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${match.venue?.name ?? ''} • ${match.format}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInningsSummary(FullScorecard scorecard) {
    if (scorecard.innings.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Innings Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: scorecard.innings.asMap().entries.map((entry) {
              final innings = entry.value;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      'Innings ${entry.key + 1}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${innings.totalRuns}/${innings.totalWickets}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      innings.oversDisplay,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (innings.runRate > 0)
                      Text(
                        'RR: ${innings.runRate.toStringAsFixed(2)}',
                        style: TextStyle(color: AppColors.primary, fontSize: 11),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInningsSections(FullScorecard scorecard) {
    final List<Widget> sections = [];
    
    for (int i = 0; i < scorecard.innings.length; i++) {
      final innings = scorecard.innings[i];
      final batting = scorecard.batting.length > i ? scorecard.batting[i] : [];
      final bowling = scorecard.bowling.length > i ? scorecard.bowling[i] : [];
      
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInningsHeader(innings, i + 1),
            const SizedBox(height: 12),
            if (batting.isNotEmpty) _buildBattingTable(batting, innings),
            const SizedBox(height: 16),
            if (bowling.isNotEmpty) _buildBowlingTable(bowling, innings),
            const SizedBox(height: 24),
          ],
        ),
      );
    }
    
    return sections;
  }

  Widget _buildInningsHeader(Innings innings, int inningsNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Innings $inningsNumber',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: innings.isCompleted ? Colors.green[100] : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                innings.isCompleted ? 'Completed' : 'In Progress',
                style: TextStyle(
                  color: innings.isCompleted ? Colors.green[700] : AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Text(
          '${innings.totalRuns}/${innings.totalWickets} (${innings.oversDisplay})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildBattingTable(List<dynamic> batting, Innings innings) {
    final List<BatsmanStats> batsmanStats = batting.cast<BatsmanStats>(); // Safe cast
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Batting',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.grey[50],
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Batsman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('4s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('6s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('SR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          // Players List
          ...batsmanStats.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          _displayPlayerName(player.playerName, fallback: 'Batter ${index + 1}'),
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (player.dismissal != null && player.dismissal != 'not_out')
                        Text(
                          _dismissalText(player),
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Expanded(child: Text(player.runs.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text(player.balls.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(player.fours.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(player.sixes.toString(), textAlign: TextAlign.center)),
                Expanded(
                  child: Text(
                    player.strikeRate > 0 ? player.strikeRate.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
          }),
          // Extras Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Extras', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('${innings.extras.total}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBowlingTable(List<dynamic> bowling, Innings innings) {
    final List<BowlerStats> bowlerStats = bowling.cast<BowlerStats>(); // Safe cast
    if (bowlerStats.isEmpty) return const SizedBox.shrink();
    if (bowling.isEmpty) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Bowling',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.grey[50],
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('O', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('W', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('Econ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          // Bowlers List
          ...bowlerStats.asMap().entries.map((entry) {
            final index = entry.key;
            final bowler = entry.value;
            return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _displayPlayerName(bowler.playerName, fallback: 'Bowler ${index + 1}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(child: Text(bowler.oversDisplay, textAlign: TextAlign.center)),
                Expanded(child: Text(bowler.maidens.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(bowler.runs.toString(), textAlign: TextAlign.center)),
                Expanded(child: Text(bowler.wickets.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text(bowler.economy.toStringAsFixed(2), textAlign: TextAlign.center)),
              ],
            ),
          );
          }),
        ],
      ),
    );
  }

  Widget _buildFallOfWickets(List<FallOfWicket> wickets) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 20, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Fall of Wickets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: wickets.map((wicket) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                '${wicket.wicket}-${_displayPlayerName(wicket.batsman, fallback: 'Batsman')} (${wicket.runs}, ${wicket.overs})',
                style: const TextStyle(fontSize: 12),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInfo(Match? match) {
    if (match == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (match.venue != null) ...[
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${match.venue!.name}${match.venue!.city != null ? ', ${match.venue!.city}' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(Icons.sports_cricket, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Format: ${match.format} • ${match.matchType}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                _formatDate(match.scheduledDate),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          if (match.toss != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.flip, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toss: ${_tossWinnerName(match)} won and chose to ${match.toss!.decision ?? 'bat/bowl'}',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (match.result != null && match.result!.playerOfMatch != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.emoji_events, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Player of the Match: ${_displayPlayerName(match.result!.playerOfMatch, fallback: 'Player')}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _LeaderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String name;
  final String primary;
  final String secondary;

  const _LeaderCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.name,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            primary,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ScoreStatusPill extends StatelessWidget {
  final bool isLive;
  const _ScoreStatusPill({required this.isLive});

  @override
  Widget build(BuildContext context) {
    final color = isLive ? const Color(0xFFE11D48) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLive ? Icons.circle : Icons.check_circle_rounded,
            size: isLive ? 7 : 13,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isLive ? 'LIVE SCORE' : 'COMPLETED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMiniPill extends StatelessWidget {
  final String text;
  const _HeaderMiniPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderTeamBlock extends StatelessWidget {
  final String name;
  final String score;
  final bool alignEnd;
  final bool isBatting;

  const _HeaderTeamBlock({
    required this.name,
    required this.score,
    required this.alignEnd,
    required this.isBatting,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignEnd && isBatting) ...[
              const Icon(Icons.sports_cricket_rounded,
                  color: Colors.white, size: 14),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (alignEnd && isBatting) ...[
              const SizedBox(width: 5),
              const Icon(Icons.sports_cricket_rounded,
                  color: Colors.white, size: 14),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          score,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HeaderInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  const _MiniStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SquadCard extends StatelessWidget {
  final String teamName;
  final List<String> players;
  const _SquadCard({required this.teamName, required this.players});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.08),
                child: Text(
                  teamName.isNotEmpty ? teamName[0].toUpperCase() : 'T',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${players.length} players',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (players.isEmpty)
            Text(
              'Squad data available nahi hai.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: players.map((player) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    player,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _EmptyScoreSection extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyScoreSection({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }
}
