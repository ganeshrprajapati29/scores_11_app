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
  static const Color _pageBg = Color(0xFFF7F8FA);
  static const Color _navy = Color(0xFF081D35);
  static const Color _cyan = Color(0xFF62C8DF);
  static const Color _panelBorder = Color(0xFFE4E7EC);
  static const Color _softHeader = Color(0xFFF2F4F7);
  static const Color _ink = Color(0xFF101828);
  static const Color _muted = Color(0xFF667085);
  static const Color _green = Color(0xFF12B76A);
  static const Color _red = Color(0xFFF04438);

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
    _tabController = TabController(length: 7, vsync: this, initialIndex: 2);
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: _navy,
          surfaceTintColor: _navy,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'Individual match',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 27),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white, size: 28),
              onPressed: () {},
            ),
            Consumer<ScorecardProvider>(
              builder: (context, provider, child) => IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 30),
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
              child: Column(
                children: [
                  _buildScorecardTabs(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          return _buildMatchCenterTab(_tabController.index, scorecard, provider);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );

          },
        ),
      ),
    );
  }

  Widget _buildScorecardMatchList() {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 19),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Scorecards',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 19),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _ink),
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
    final statusColor = match.isLive ? _red : _green;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(context, '/scorecard', arguments: match.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _panelBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
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
                  style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700),
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
                color: match.isLive ? _red : AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 15, color: _muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    match.venue?.name ?? 'Venue not added',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _muted),
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
      height: 58,
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _panelBorder.withOpacity(0.7))),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: _navy,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelColor: _ink,
        unselectedLabelColor: Colors.black38,
        labelPadding: const EdgeInsets.symmetric(horizontal: 22),
        labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 22),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 21),
        tabs: const [
          Tab(text: 'Info'),
          Tab(text: 'Live'),
          Tab(text: 'Scorecard'),
          Tab(text: 'Insights'),
          Tab(text: 'Comms'),
          Tab(text: 'Squads'),
          Tab(text: 'Gallery'),
        ],
      ),
    );
  }

  Widget _buildMatchCenterTab(
    int index,
    FullScorecard scorecard,
    ScorecardProvider provider,
  ) {
    switch (index) {
      case 0:
        return _buildInfoTab(scorecard, provider);
      case 1:
        return _buildLiveTab(scorecard, provider);
      case 2:
        return _buildScorecardTab(scorecard);
      case 3:
        return _buildInsightsTab(scorecard, provider);
      case 4:
        return _buildCommentaryTab(scorecard.match);
      case 5:
        return _buildSquadsSection(scorecard, provider.match ?? scorecard.match);
      case 6:
        return _buildGalleryTab(scorecard.match);
      default:
        return _buildScorecardTab(scorecard);
    }
  }

  Widget _buildInfoTab(FullScorecard scorecard, ScorecardProvider provider) {
    final match = provider.match ?? scorecard.match;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultPanel(match),
        const SizedBox(height: 16),
        _buildMatchInfo(match),
        const SizedBox(height: 16),
        _InfoGrid(match: match),
      ],
    );
  }

  Widget _buildLiveTab(FullScorecard scorecard, ScorecardProvider provider) {
    final match = provider.match ?? scorecard.match;
    final innings = scorecard.innings.isNotEmpty ? scorecard.innings.last : null;
    final batting = scorecard.batting.isNotEmpty ? scorecard.batting.last : <BatsmanStats>[];
    final bowling = scorecard.bowling.isNotEmpty ? scorecard.bowling.last : <BowlerStats>[];
    final activeBatters = batting.where((b) => !b.isOut && _hasBatted(b)).take(2).toList();
    final activeBowlers = bowling.where(_hasBowled).toList()
      ..sort((a, b) => b.overs.compareTo(a.overs));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LiveMatchPulseCard(match: match, innings: innings),
        const SizedBox(height: 16),
        if (activeBatters.isNotEmpty)
          _MiniPlayerPanel(
            title: 'On crease',
            icon: Icons.sports_cricket_rounded,
            players: activeBatters
                .map((p) => _MiniPlayerLine(
                      id: p.playerId,
                      name: _displayPlayerName(p.playerName, fallback: 'Batter'),
                      stat: '${p.runs} (${p.balls})',
                      meta: 'SR ${p.strikeRate.toStringAsFixed(1)}',
                    ))
                .toList(),
          )
        else
          const _EmptyScoreSection(title: 'On crease', message: 'Live batters will appear after scoring starts.'),
        const SizedBox(height: 16),
        if (activeBowlers.isNotEmpty)
          _MiniPlayerPanel(
            title: 'Current bowling',
            icon: Icons.adjust_rounded,
            players: activeBowlers
                .take(2)
                .map((p) => _MiniPlayerLine(
                      id: p.playerId,
                      name: _displayPlayerName(p.playerName, fallback: 'Bowler'),
                      stat: '${p.wickets}/${p.runs}',
                      meta: '${p.oversDisplay} ov',
                    ))
                .toList(),
          ),
        const SizedBox(height: 16),
        _buildCommentaryTab(match, compact: true),
      ],
    );
  }

  Widget _buildInsightsTab(FullScorecard scorecard, ScorecardProvider provider) {
    final inningsIndex = scorecard.innings.isNotEmpty && _selectedInnings < scorecard.innings.length
        ? _selectedInnings
        : 0;
    final innings = scorecard.innings.isNotEmpty ? scorecard.innings[inningsIndex] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeaders(scorecard),
        const SizedBox(height: 16),
        if (innings != null) ...[
          _buildStatsRowForInnings(innings),
          const SizedBox(height: 16),
          _buildDetailedExtras(innings),
        ],
        const SizedBox(height: 16),
        _InsightCards(scorecard: scorecard),
      ],
    );
  }

  Widget _buildCommentaryTab(Match match, {bool compact = false}) {
    final commentary = match.commentary.toList()
      ..sort((a, b) => b.over.compareTo(a.over));
    if (commentary.isEmpty) {
      return const _EmptyScoreSection(
        title: 'Ball by ball',
        message: 'Ball-by-ball commentary will appear here once scoring starts.',
      );
    }
    final visible = compact ? commentary.take(6).toList() : commentary;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text('Ball by ball', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
          const Divider(height: 1),
          ...visible.map((ball) => _CommentaryTile(ball: ball)),
        ],
      ),
    );
  }

  Widget _buildGalleryTab(Match match) {
    final gallery = <_GalleryItem>[
      _GalleryItem(Icons.scoreboard_rounded, 'Match moments', _teamName(match, 1), AppColors.primary),
      _GalleryItem(Icons.groups_rounded, 'Squad photos', _teamName(match, 2), Colors.green),
      _GalleryItem(Icons.emoji_events_rounded, 'Highlights', match.format.toUpperCase(), Colors.orange),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gallery.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.08,
          ),
          itemBuilder: (context, index) => _GalleryCard(item: gallery[index]),
        ),
        const SizedBox(height: 16),
        _EmptyScoreSection(
          title: 'Upload gallery',
          message: 'Backend gallery media can be connected to match uploads. Use Community posts for now to publish match photos and videos.',
          actionLabel: 'Create post',
          onAction: () => Navigator.pushNamed(context, '/create-post'),
        ),
      ],
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
    final fielding = scorecard.fielding.length > _selectedInnings
        ? scorecard.fielding[_selectedInnings]
        : <FieldingStats>[];
    final wickets = scorecard.fallOfWicketsByInnings.length > _selectedInnings
        ? scorecard.fallOfWicketsByInnings[_selectedInnings]
        : scorecard.fallOfWickets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCricheroInningsBar(scorecard, innings),
        _buildEnhancedBattingTable(batting, innings),
        _buildEnhancedBowlingTable(bowling, innings),
        if (fielding.isNotEmpty) _buildEnhancedFieldingTable(fielding),
        if (wickets.isNotEmpty) ...[
          _buildFallOfWickets(wickets),
        ],
        _buildNextInningsHint(scorecard),
      ],
    );
  }

  Widget _buildCricheroInningsBar(FullScorecard scorecard, Innings innings) {
    final team = _displayTeamName(
      innings.battingTeam,
      fallback: _teamName(scorecard.match, innings.inningsNumber == 2 ? 2 : 1),
    );
    return InkWell(
      onTap: scorecard.innings.length <= 1
          ? null
          : () => setState(() => _selectedInnings = (_selectedInnings + 1) % scorecard.innings.length),
      child: Container(
        height: 63,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: const Color(0xFF303030),
        child: Row(
          children: [
            Expanded(
              child: Text(
                team,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${innings.totalRuns}/${innings.totalWickets}',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Text(
              '(${innings.oversDisplay} Ov)',
              style: const TextStyle(color: Colors.white70, fontSize: 17, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            Icon(
              scorecard.innings.length > 1 ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
              color: Colors.white70,
              size: 34,
            ),
          ],
        ),
      ),
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
              selectedColor: _ink,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? _ink : _panelBorder,
              ),
              label: Text(
                '${_displayTeamName(innings.battingTeam, fallback: 'Team ${index + 1}')}  ${innings.totalRuns}/${innings.totalWickets}',
                style: TextStyle(
                  color: selected ? Colors.white : _ink,
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
        border: Border.all(color: _panelBorder),
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
                  style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  result,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w900),
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

    final maxRows = [
      team1Players.length,
      team2Players.length,
      11,
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _panelBorder.withOpacity(0.7))),
            ),
            child: Row(
              children: [
                Expanded(child: _SquadTeamHeader(teamName: team1Name, alignRight: false)),
                Container(width: 1, color: _panelBorder),
                Expanded(child: _SquadTeamHeader(teamName: team2Name, alignRight: true)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: _softHeader,
            child: const Text(
              'Playing Squad',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          ...List.generate(maxRows, (index) {
            final left = index < team1Players.length ? team1Players[index] : '';
            final right = index < team2Players.length ? team2Players[index] : '';
            return _SquadSplitRow(leftName: left, rightName: right, index: index);
          }),
        ],
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _panelBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withOpacity(0.05),
            blurRadius: 22,
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
          const SizedBox(height: 14),
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
                  color: _pageBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: _panelBorder),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: _muted,
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
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _pageBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _panelBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$battingTeam batting',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inningsScore,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 31,
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
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.16)),
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

  bool _hasBatted(BatsmanStats player) {
    return player.runs > 0 ||
        player.balls > 0 ||
        player.fours > 0 ||
        player.sixes > 0 ||
        player.isOut;
  }

  bool _hasBowled(BowlerStats player) {
    return player.overs > 0 ||
        player.maidens > 0 ||
        player.runs > 0 ||
        player.wickets > 0 ||
        (player.extras ?? 0) > 0;
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
    final clean = player.dismissalDisplay;
    return _looksLikeId(clean) ? 'out' : clean;
  }

  String _pointsLabel(double value) {
    if (value <= 0) return '-';
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
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

// Current (ongoing) partnership for the pair at the crease - resets to 0
    // after each fall of wicket, tracked live on the innings itself.
    final partnership = currentInnings.totalWickets < 10
        ? '${currentInnings.currentPartnershipRuns} (${currentInnings.currentPartnershipBalls}b)'
        : '-';

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Extras', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildExtraPill('Wd', innings.extras.wides),
              _buildExtraPill('Nb', innings.extras.noBalls),
              _buildExtraPill('B', innings.extras.byes),
              _buildExtraPill('LB', innings.extras.legByes),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _pageBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _panelBorder),
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
        color: _pageBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _panelBorder),
      ),
      child: Text('$type: $count', style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 12)),
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
    final List<BatsmanStats> batsmanStats = batting
        .whereType<BatsmanStats>()
        .where(_hasBatted)
        .toList();
    if (batsmanStats.isEmpty) {
      return _EmptyScoreSection(
        title: 'Batting',
        message: 'Batting scorecard will appear after the first delivery.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _panelBorder.withOpacity(0.8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: _softHeader,
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('Batters', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                Expanded(child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                Expanded(child: Text('4s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                Expanded(child: Text('6s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
              ],
            ),
          ),
          ...batsmanStats.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _panelBorder.withOpacity(0.85))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: player.playerId.isEmpty
                            ? null
                            : () => Navigator.pushNamed(context, '/player-profile/${player.playerId}'),
                        child: Text(
                          '${_displayPlayerName(player.playerName, fallback: 'Batter ${index + 1}')}${!player.isOut ? '*' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: _cyan),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        _dismissalText(player),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Text(player.runs.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: _ink))),
                Expanded(child: Text(player.balls.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))),
                Expanded(child: Text(player.fours.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))),
                Expanded(child: Text(player.sixes.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))),
                Expanded(
                  flex: 2,
                  child: Text(
                    player.strikeRate > 0 ? player.strikeRate.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
          }),
          _CricheroSummaryRow(label: 'Extras', value: '${innings.extras.total} ${_extrasBreakup(innings)}'),
          _CricheroSummaryRow(
            label: 'Total',
            value: '${innings.totalRuns}/${innings.totalWickets} (${innings.oversDisplay} Ov)    CRR ${innings.runRate.toStringAsFixed(2)}',
            isTotal: true,
          ),
          _buildToBatRow(batsmanStats),
        ],
      ),
    );
  }

  Widget _buildEnhancedBowlingTable(List<dynamic> bowling, Innings innings) {
    final List<BowlerStats> bowlerStats = bowling
        .whereType<BowlerStats>()
        .where(_hasBowled)
        .toList();
    if (bowlerStats.isEmpty) {
      return _EmptyScoreSection(
        title: 'Bowling',
        message: 'Bowling scorecard will appear after the first delivery.',
      );
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: _panelBorder.withOpacity(0.8)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: _softHeader,
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Bowlers', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                Expanded(child: Text('O', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                Expanded(child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                Expanded(child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                Expanded(child: Text('W', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                Expanded(child: Text('Eco', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
              ],
            ),
          ),
          ...bowlerStats.asMap().entries.map((entry) {
            final index = entry.key;
            final bowler = entry.value;
            return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _panelBorder.withOpacity(0.85))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: InkWell(
                    onTap: bowler.playerId.isEmpty
                        ? null
                        : () => Navigator.pushNamed(context, '/player-profile/${bowler.playerId}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayPlayerName(bowler.playerName, fallback: 'Bowler ${index + 1}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: _cyan, fontSize: 18),
                        ),
                        if (bowler.wicketDetails.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Out: ${bowler.wicketDetails.join(', ')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(child: Text(bowler.oversDisplay, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))),
                Expanded(child: Text(bowler.maidens.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))),
                Expanded(child: Text(bowler.runs.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))),
                Expanded(child: Text(bowler.wickets.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))),
                Expanded(child: Text(bowler.economy.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))),
              ],
            ),
          );
          }),
        ],
      ),
    );

  }

  String _extrasBreakup(Innings innings) {
    final parts = <String>[];
    if (innings.extras.wides > 0) parts.add('wd ${innings.extras.wides}');
    if (innings.extras.noBalls > 0) parts.add('nb ${innings.extras.noBalls}');
    if (innings.extras.byes > 0) parts.add('b ${innings.extras.byes}');
    if (innings.extras.legByes > 0) parts.add('lb ${innings.extras.legByes}');
    return parts.isEmpty ? '' : '(${parts.join(', ')})';
  }

  Widget _buildToBatRow(List<BatsmanStats> batters) {
    final waiting = batters
        .where((player) => !_hasBatted(player))
        .map((player) => _displayPlayerName(player.playerName, fallback: 'Player'))
        .where((name) => name.trim().isNotEmpty)
        .take(8)
        .join(', ');
    if (waiting.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      color: Colors.white,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black54, fontSize: 16, height: 1.25),
          children: [
            const TextSpan(
              text: 'To bat:\n',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
            TextSpan(text: waiting),
          ],
        ),
      ),
    );
  }

  Widget _buildNextInningsHint(FullScorecard scorecard) {
    if (scorecard.innings.length <= 1) return const SizedBox.shrink();
    final nextIndex = (_selectedInnings + 1) % scorecard.innings.length;
    final innings = scorecard.innings[nextIndex];
    return InkWell(
      onTap: () => setState(() => _selectedInnings = nextIndex),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: Text(
                _displayTeamName(innings.battingTeam, fallback: 'Innings ${innings.inningsNumber}'),
                style: const TextStyle(fontSize: 18, color: _ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${innings.totalRuns}/${innings.totalWickets}',
              style: const TextStyle(fontSize: 28, color: _ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFieldingTable(List<FieldingStats> fielding) {
    final rows = fielding.where((player) => player.dismissals > 0 || player.scoringPoints > 0).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _panelBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.front_hand_rounded, color: Color(0xFF12B76A), size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Fielding Points', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                ),
                const Text('0.5 per C/RO/St', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: _softHeader,
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Fielder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('C', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('RO', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('St', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('D', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(child: Text('Pts', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _panelBorder.withOpacity(0.85))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      _displayPlayerName(player.playerName, fallback: 'Fielder ${index + 1}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF067647), fontSize: 13),
                    ),
                  ),
                  Expanded(child: Text(player.catches.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                  Expanded(child: Text(player.runOuts.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                  Expanded(child: Text(player.stumpings.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                  Expanded(child: Text(player.dismissals.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                  Expanded(child: Text(_pointsLabel(player.scoringPoints), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
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
                      Text(
                        _displayPlayerName(player.playerName, fallback: 'Batter ${index + 1}'),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayPlayerName(bowler.playerName, fallback: 'Bowler ${index + 1}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (bowler.wicketDetails.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Out: ${bowler.wicketDetails.join(', ')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700], fontSize: 10.5, height: 1.2),
                        ),
                      ],
                    ],
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
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF101828),
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
                  color: Color(0xFF1A56DB), size: 14),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (alignEnd && isBatting) ...[
              const SizedBox(width: 5),
              const Icon(Icons.sports_cricket_rounded,
                  color: Color(0xFF1A56DB), size: 14),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          score,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: Color(0xFF101828),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Color(0xFF667085)),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF344054),
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

class _InfoGrid extends StatelessWidget {
  final Match match;
  const _InfoGrid({required this.match});

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem(Icons.sports_cricket_rounded, 'Format', match.format.toUpperCase()),
      _InfoItem(Icons.category_rounded, 'Type', match.matchType),
      _InfoItem(Icons.timer_rounded, 'Overs', '${match.overs}'),
      _InfoItem(Icons.calendar_today_rounded, 'Date', '${match.scheduledDate.day}/${match.scheduledDate.month}/${match.scheduledDate.year}'),
      _InfoItem(Icons.place_rounded, 'Venue', match.venue?.name ?? 'TBD'),
      _InfoItem(Icons.wb_sunny_rounded, 'Weather', match.weather?.condition ?? 'TBD'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.45,
      ),
      itemBuilder: (context, index) => _InfoTile(item: items[index]),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _InfoTile extends StatelessWidget {
  final _InfoItem item;
  const _InfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF8)),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700)),
                Text(item.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveMatchPulseCard extends StatelessWidget {
  final Match match;
  final Innings? innings;
  const _LiveMatchPulseCard({required this.match, required this.innings});

  @override
  Widget build(BuildContext context) {
    final score = innings == null
        ? '${match.score.team1.runs}/${match.score.team1.wickets}'
        : '${innings!.totalRuns}/${innings!.totalWickets} (${innings!.oversDisplay})';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF8)),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.09),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.circle, color: Colors.red, size: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.isLive ? 'Live now' : match.status, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(score, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Text(match.format.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _MiniPlayerLine {
  final String id;
  final String name;
  final String stat;
  final String meta;
  const _MiniPlayerLine({required this.id, required this.name, required this.stat, required this.meta});
}

class _MiniPlayerPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_MiniPlayerLine> players;
  const _MiniPlayerPanel({required this.title, required this.icon, required this.players});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF8)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...players.map((p) => ListTile(
                onTap: p.id.isEmpty ? null : () => Navigator.pushNamed(context, '/player-profile/${p.id}'),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(p.meta),
                trailing: Text(p.stat, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
              )),
        ],
      ),
    );
  }
}

class _CommentaryTile extends StatelessWidget {
  final Commentary ball;
  const _CommentaryTile({required this.ball});

  @override
  Widget build(BuildContext context) {
    final isWicket = ball.isWicket == true;
    final runs = ball.batsmanRuns ?? ball.totalRuns ?? 0;
    final color = isWicket
        ? Colors.red
        : runs >= 4
            ? Colors.green
            : AppColors.primary;
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Text(isWicket ? 'W' : '$runs', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
      ),
      title: Text(ball.text?.trim().isNotEmpty == true ? ball.text!.trim() : 'Ball ${ball.overDisplay}', style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('Over ${ball.overDisplay}', style: const TextStyle(fontSize: 12)),
    );
  }
}

class _InsightCards extends StatelessWidget {
  final FullScorecard scorecard;
  const _InsightCards({required this.scorecard});

  @override
  Widget build(BuildContext context) {
    final totalRuns = scorecard.innings.fold<int>(0, (sum, i) => sum + i.totalRuns);
    final totalWickets = scorecard.innings.fold<int>(0, (sum, i) => sum + i.totalWickets);
    final fours = scorecard.batting.expand((e) => e).fold<int>(0, (sum, b) => sum + b.fours);
    final sixes = scorecard.batting.expand((e) => e).fold<int>(0, (sum, b) => sum + b.sixes);
    final items = [
      _InfoItem(Icons.speed_rounded, 'Runs', '$totalRuns'),
      _InfoItem(Icons.adjust_rounded, 'Wickets', '$totalWickets'),
      _InfoItem(Icons.looks_4_rounded, 'Fours', '$fours'),
      _InfoItem(Icons.six_ft_apart_rounded, 'Sixes', '$sixes'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.3),
      itemBuilder: (_, i) => _InfoTile(item: items[i]),
    );
  }
}

class _GalleryItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _GalleryItem(this.icon, this.title, this.subtitle, this.color);
}

class _CricheroSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _CricheroSummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.18))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _ScorecardScreenState._ink,
                fontSize: 16,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _ScorecardScreenState._ink,
                fontSize: 16,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final _GalleryItem item;
  const _GalleryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 28),
          const Spacer(),
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

class _SquadTeamHeader extends StatelessWidget {
  final String teamName;
  final bool alignRight;

  const _SquadTeamHeader({required this.teamName, required this.alignRight});

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE91E63),
      child: Text(
        _initials(teamName),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
      ),
    );
    final name = Expanded(
      child: Text(
        teamName,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _ScorecardScreenState._ink, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: alignRight ? [name, const SizedBox(width: 12), avatar] : [avatar, const SizedBox(width: 12), name],
      ),
    );
  }

  static String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'T';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }
}

class _SquadSplitRow extends StatelessWidget {
  final String leftName;
  final String rightName;
  final int index;

  const _SquadSplitRow({
    required this.leftName,
    required this.rightName,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.14))),
      ),
      child: Row(
        children: [
          Expanded(child: _SquadPerson(name: leftName, reverse: false, index: index)),
          Container(width: 1, color: Colors.grey.withOpacity(0.18)),
          Expanded(child: _SquadPerson(name: rightName, reverse: true, index: index)),
        ],
      ),
    );
  }
}

class _SquadPerson extends StatelessWidget {
  final String name;
  final bool reverse;
  final int index;

  const _SquadPerson({
    required this.name,
    required this.reverse,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    if (name.trim().isEmpty) return const SizedBox.shrink();
    final avatar = CircleAvatar(
      radius: 25,
      backgroundColor: _avatarColors[index % _avatarColors.length],
      child: Text(
        name.trim()[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
    final text = Expanded(
      child: Column(
        crossAxisAlignment: reverse ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: reverse ? TextAlign.right : TextAlign.left,
            style: const TextStyle(color: _ScorecardScreenState._ink, fontSize: 17, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 3),
          Text(
            index % 3 == 0 ? 'Hard Hitter • Aspirant' : index % 3 == 1 ? 'Destroyer • Wildcard' : 'Classicist • Aspirant',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: reverse ? TextAlign.right : TextAlign.left,
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: reverse ? [text, const SizedBox(width: 10), avatar] : [avatar, const SizedBox(width: 10), text],
      ),
    );
  }

  static const _avatarColors = [
    Color(0xFF0EA5E9),
    Color(0xFF22C55E),
    Color(0xFFE11D48),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
  ];
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
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyScoreSection({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
