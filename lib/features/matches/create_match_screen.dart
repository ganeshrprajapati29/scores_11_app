import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../core/utils/friendly_error.dart';
import '../../data/services/match_service.dart';
import '../../data/services/team_service.dart';
import '../../data/services/tournament_service_safe.dart'
    as TournamentServiceSafe;
import '../../data/models/team_model.dart';
import '../../data/models/tournament_model.dart';
import '../../providers/auth_provider.dart';
import '../teams/create_team_screen.dart';
import 'package:provider/provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kRadius = 14.0;
const _kCardRadius = 16.0;
const _kSectionGap = 20.0;
const _kFieldGap = 14.0;
const _kBg = Color(0xFFF8F9FA);
const _kBorder = Color(0xFFEEEFF2);
const _kTextPrimary = Color(0xFF0D1117);
const _kTextSecondary = Color(0xFF6B7280);
const _kTextHint = Color(0xFF9CA3AF);
const _kShadow = Color(0x0A000000);

class _BallCategoryData {
  final String value;
  final String title;
  final String format;
  final String category;
  final String description;
  final IconData icon;
  final Color color;

  const _BallCategoryData({
    required this.value,
    required this.title,
    required this.format,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const _ballCategories = [
  _BallCategoryData(
    value: 'tennis',
    title: 'Tennis Ball',
    format: 'Casual / gully',
    category: 'casual',
    description: 'Soft-ball local cricket format',
    icon: Icons.sports_baseball_rounded,
    color: Color(0xFF16A34A),
  ),
  _BallCategoryData(
    value: 'leather',
    title: 'Leather Ball',
    format: 'Standard / professional',
    category: 'standard',
    description: 'Default professional cricket rules',
    icon: Icons.circle_rounded,
    color: AppColors.primary,
  ),
  _BallCategoryData(
    value: 'rubber',
    title: 'Rubber Ball',
    format: 'Child / indoor',
    category: 'child',
    description: 'Child/indoor scoring rules enabled',
    icon: Icons.radio_button_checked_rounded,
    color: Color(0xFFF97316),
  ),
  _BallCategoryData(
    value: 'custom',
    title: 'Custom',
    format: 'Organiser decided',
    category: 'custom',
    description: 'Use organiser-defined match format',
    icon: Icons.tune_rounded,
    color: Color(0xFF7C3AED),
  ),
];

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  Widget? suffix,
}) =>
    InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: _kTextHint),
      prefixIcon: Icon(icon, size: 18, color: _kTextHint),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: Color(0xFFE53E3E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
      ),
    );

// ─── Screen ───────────────────────────────────────────────────────────────────

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final MatchService _matchService = MatchService();
  final TeamService _teamService = TeamService();
  final TournamentServiceSafe.TournamentService _tournamentService =
      TournamentServiceSafe.TournamentService();

  // Controllers
  final _team1SearchController = TextEditingController();
  final _team2SearchController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _venueCityController = TextEditingController();
  final _oversController = TextEditingController(text: '20');
  final _matchTitleController = TextEditingController();
  final _umpireController = TextEditingController();
  final _refereeController = TextEditingController();

  // Dropdowns
  String? _format = 't20';
  String? _matchType = 'league';
  String? _tossDecision = 'bat';
  String? _ballType = 'leather';
  String? _matchCategory = 'standard';
  String? _pitchType = 'hard';
  String? _weatherCondition = 'sunny';
  String? _selectedTournamentId;

  // Date / Time
  DateTime? _scheduledDate;
  TimeOfDay? _selectedTime;
  DateTime? _tossDate;
  TimeOfDay? _tossTime;

  // Data
  List<Team> _allTeams = [];
  List<Team> _filteredTeams1 = [];
  List<Team> _filteredTeams2 = [];
  List<Tournament> _tournaments = [];

  Team? _selectedTeam1;
  Team? _selectedTeam2;
  String? _selectedTeam1Id;
  String? _selectedTeam2Id;

  // State flags
  bool _isLoading = false;
  bool _loadingTeams = true;
  bool _loadingTournaments = false;
  String? _fetchError;
  bool _isTeam1Selected = false;
  bool _isTeam2Selected = false;
  bool _showAdvancedOptions = false;
  bool _redirectingGuest = false;

  @override
  void initState() {
    super.initState();
    // Schedule is optional - left blank so the backend defaults to "now"
    // rather than silently forcing every match to next-day 2 PM.
    _tossDate = DateTime.now().add(const Duration(days: 1));
    _tossTime = const TimeOfDay(hour: 13, minute: 30);
    _loadAllTeams();
    _loadTournaments();
    _team1SearchController.addListener(_filterTeams1);
    _team2SearchController.addListener(_filterTeams2);
  }

  @override
  void dispose() {
    _team1SearchController.dispose();
    _team2SearchController.dispose();
    _venueNameController.dispose();
    _venueCityController.dispose();
    _oversController.dispose();
    _matchTitleController.dispose();
    _umpireController.dispose();
    _refereeController.dispose();
    super.dispose();
  }

  // ── Data loaders ────────────────────────────────────────────────────────────

  Future<void> _loadAllTeams() async {
    setState(() {
      _loadingTeams = true;
      _fetchError = null;
    });
    try {
      final allTeams = await _teamService.getMyTeams();
      setState(() {
        _allTeams = allTeams;
        _filteredTeams1 = allTeams;
        _filteredTeams2 = allTeams;
        _loadingTeams = false;
      });
    } catch (e) {
      setState(() {
        _fetchError = friendlyError(e, fallback: 'Teams load nahi ho paayi.');
        _loadingTeams = false;
      });
    }
  }

  Future<void> _createTeamAndRefresh() async {
    final createdTeam = await Navigator.of(context).push<Team>(
      MaterialPageRoute(
        builder: (_) => const CreateTeamScreen(returnOnCreate: true),
      ),
    );
    if (!mounted || createdTeam == null) return;
    await _loadAllTeams();
    if (!mounted) return;
    setState(() {
      _selectedTeam1 = createdTeam;
      _selectedTeam1Id = createdTeam.id;
      _team1SearchController.text = createdTeam.name;
      _isTeam1Selected = true;
    });
    _filterTeams2();
  }

  Future<void> _loadTournaments() async {
    setState(() => _loadingTournaments = true);
    try {
      final result =
          await _tournamentService.getTournaments(page: 1, limit: 100);
      setState(() => _tournaments = result.tournaments);
    } catch (e) {
      debugPrint('Error loading tournaments: $e');
    } finally {
      setState(() => _loadingTournaments = false);
    }
  }

  void _filterTeams1() {
    final q = _team1SearchController.text.toLowerCase().trim();
    setState(() {
      _filteredTeams1 = _allTeams
          .where((t) =>
              t.name.toLowerCase().contains(q) ||
              (t.shortName ?? '').toLowerCase().contains(q) ||
              (t.city ?? '').toLowerCase().contains(q))
          .toList();
    });
  }

  void _filterTeams2() {
    final q = _team2SearchController.text.toLowerCase().trim();
    setState(() {
      _filteredTeams2 = _allTeams
          .where((t) =>
              (t.name.toLowerCase().contains(q) ||
                  (t.shortName ?? '').toLowerCase().contains(q) ||
                  (t.city ?? '').toLowerCase().contains(q)) &&
              (_selectedTeam1Id == null || t.id != _selectedTeam1Id))
          .toList();
    });
  }

  void _selectBallCategory(_BallCategoryData category) {
    setState(() {
      _ballType = category.value;
      _matchCategory = category.category;
    });
  }

  _BallCategoryData get _selectedBallCategory {
    return _ballCategories.firstWhere(
      (category) => category.value == _ballType,
      orElse: () => _ballCategories[1],
    );
  }

  // ── Date/time pickers ───────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isToss}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isToss ? _tossDate : _scheduledDate) ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: _kTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isToss) {
        _tossDate = picked;
      } else {
        _scheduledDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isToss}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isToss ? _tossTime : _selectedTime) ??
          const TimeOfDay(hour: 14, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isToss) {
        _tossTime = picked;
      } else {
        _selectedTime = picked;
      }
    });
  }

  // ── Validation / submit ─────────────────────────────────────────────────────

  bool _isValidObjectId(String id) => RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);

  Future<void> _createMatch() async {
    if (_selectedTeam1Id == null || _selectedTeam2Id == null) {
      _snack('Minimum 2 teams required to start a match', isError: true);
      return;
    }
    if ((_scheduledDate == null) != (_selectedTime == null)) {
      _snack('Please select both a match date and time, or leave both blank',
          isError: true);
      return;
    }
    if (_venueNameController.text.trim().isEmpty) {
      _snack('Please enter venue name', isError: true);
      return;
    }
    if (_selectedTeam1Id == _selectedTeam2Id) {
      _snack('Teams must be different', isError: true);
      return;
    }
    if (!_isValidObjectId(_selectedTeam1Id!) ||
        !_isValidObjectId(_selectedTeam2Id!)) {
      _snack('Invalid team ID format', isError: true);
      return;
    }
    final overs = int.tryParse(_oversController.text);
    if (overs == null || overs < 1 || overs > 100) {
      _snack('Overs must be between 1 and 100', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final venueMap = {
        'name': _venueNameController.text.trim(),
        if (_venueCityController.text.trim().isNotEmpty)
          'city': _venueCityController.text.trim(),
      };
      DateTime? scheduledDateTime;
      if (_scheduledDate != null && _selectedTime != null) {
        scheduledDateTime = DateTime(
          _scheduledDate!.year,
          _scheduledDate!.month,
          _scheduledDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        if (scheduledDateTime.isBefore(DateTime.now())) {
          _snack('Please select a future match time', isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }
// Create the match
      final newMatch = await _matchService.createMatchSimple(
        team1: _selectedTeam1Id!,
        team2: _selectedTeam2Id!,
        venue: venueMap,
        scheduledDate: scheduledDateTime,
        format: _format!,
        overs: overs,
        ballType: _ballType ?? 'leather',
        matchCategory: _matchCategory ?? 'standard',
      );

      if (mounted) {
        _snack('Match created successfully!', isError: false);

        final currentRouteName = ModalRoute.of(context)?.settings.name;
        if (currentRouteName == '/create-match') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/scheduled-matches',
            (route) => route.settings.name == '/dashboard' || route.isFirst,
          );
        } else {
          Navigator.of(context).pop(newMatch);
        }
      }
    } catch (e) {
      _snack(friendlyError(e, fallback: 'Match create nahi ho paaya.'), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().isGuestUser) {
      if (!_redirectingGuest) {
        _redirectingGuest = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        });
      }
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeroBanner(),
          Expanded(
            child: _loadingTeams && _allTeams.isEmpty
                ? _buildTeamLoader()
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTitleBlock(),
                          const SizedBox(height: _kSectionGap),

                          // Team 1
                          _TeamSelectorCard(
                      title: 'Team 1 (Your Team)',
                      subtitle: 'Select your team',
                      searchLabel: 'Search your teams...',
                      accentColor: AppColors.primary,
                      searchController: _team1SearchController,
                      filteredTeams: _filteredTeams1,
                      selectedTeam: _selectedTeam1,
                      loadingTeams: _loadingTeams,
                      onSelect: (team) {
                        setState(() {
                          _selectedTeam1 = team;
                          _selectedTeam1Id = team.id;
                          _team1SearchController.text = team.name;
                          _isTeam1Selected = true;
                        });
                        _filterTeams2();
                      },
                      onClear: () {
                        setState(() {
                          _selectedTeam1 = null;
                          _selectedTeam1Id = null;
                          _team1SearchController.clear();
                          _isTeam1Selected = false;
                        });
                        _filterTeams2();
                      },
                      onRetry: _loadAllTeams,
                      onCreateTeam: _createTeamAndRefresh,
                    ),

                          const SizedBox(height: 14),
                          _VsDivider(),
                          const SizedBox(height: 14),

                          // Team 2
                          _TeamSelectorCard(
                            title: 'Team 2 (Opponent)',
                            subtitle: 'Select opponent team',
                            searchLabel: 'Search opponent teams...',
                            accentColor: const Color(0xFF16A34A),
                            searchController: _team2SearchController,
                            filteredTeams: _filteredTeams2,
                            selectedTeam: _selectedTeam2,
                            loadingTeams: _loadingTeams,
                            onSelect: (team) {
                              setState(() {
                                _selectedTeam2 = team;
                                _selectedTeam2Id = team.id;
                                _team2SearchController.text = team.name;
                                _isTeam2Selected = true;
                              });
                            },
                            onClear: () {
                              setState(() {
                                _selectedTeam2 = null;
                                _selectedTeam2Id = null;
                                _team2SearchController.clear();
                                _isTeam2Selected = false;
                              });
                            },
                            onRetry: _loadAllTeams,
                            onCreateTeam: _createTeamAndRefresh,
                          ),

                          // Validation warning banner
                          const SizedBox(height: _kSectionGap),
                          _buildValidationWarning(),

                          // Match Details (shown after both teams selected)
                          if (_isTeam1Selected && _isTeam2Selected) ...[
                            const SizedBox(height: _kSectionGap),
                            _buildMatchDetailsCard(),
                          ],

                          // Error banner
                          if (_fetchError != null) ...[
                            const SizedBox(height: 14),
                            _buildErrorBanner(),
                          ],

                          // Create button
                          if (_isTeam1Selected && _isTeam2Selected) ...[
                            const SizedBox(height: 24),
                            _buildCreateButton(),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Hero banner ──────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 18),
      decoration: const BoxDecoration(color: Color(0xFFEAF3FF)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.asset(
                'score 11/Create Match Team 1080 x 420 PNG.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.98),
                    Colors.white.withOpacity(0.78),
                    Colors.white.withOpacity(0.10),
                  ],
                  stops: const [0, 0.45, 1],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  _RoundIconButton(
                    icon: Icons.help_outline_rounded,
                    onTap: _showHelpDialog,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDC2626), width: 1.4),
                      boxShadow: const [
                        BoxShadow(color: _kShadow, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SCORES11',
                    style: TextStyle(
                      color: const Color(0xFF0D2B5E),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Title block ──────────────────────────────────────────────────────────────

  Widget _buildTitleBlock() {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Match',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Select teams and match details to get started',
            style: TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

// ── Loading state ────────────────────────────────────────────────────────────

  Widget _buildTeamLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text('Loading teams…',
              style: TextStyle(color: _kTextSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Validation warning banner ───────────────────────────────────────────────

  Widget _buildValidationWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF3B82F6), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Teams must be different to create a match',
              style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Match details card ───────────────────────────────────────────────────────

  Widget _buildMatchDetailsCard() {
    Widget responsiveFields(List<Widget> children, {int maxColumns = 2}) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 620 ? maxColumns : 1;
          final itemWidth = (width - (columns - 1) * 10) / columns;
          return Wrap(
            spacing: 10,
            runSpacing: _kFieldGap,
            children: [
              for (final child in children)
                SizedBox(
                  width: itemWidth,
                  child: child,
                ),
            ],
          );
        },
      );
    }

    return _SectionCard(
      title: 'Match Details',
      icon: Icons.calendar_month_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          responsiveFields(
            [
              CustomTextField(
                  controller: _matchTitleController,
                  labelText: 'Match Title (Optional)',
                  hintText: 'Eg. Semi Final Match',
                  prefixIcon: Icons.title_rounded,
                ),
              _StyledDropdown<String>(
                  value: _format,
                  label: 'Format',
                  icon: Icons.sports_cricket_rounded,
                  items: const [
                    DropdownMenuItem(value: 't20', child: Text('T20')),
                    DropdownMenuItem(value: 'odi', child: Text('ODI')),
                    DropdownMenuItem(value: 'test', child: Text('Test')),
                  ],
                  onChanged: (v) => setState(() => _format = v),
                ),
              _StyledDropdown<String>(
                  value: _matchType,
                  label: 'Match Type',
                  icon: Icons.category_rounded,
                  items: const [
                    DropdownMenuItem(value: 'league', child: Text('League')),
                    DropdownMenuItem(
                        value: 'knockout', child: Text('Knockout')),
                    DropdownMenuItem(
                        value: 'quarter_final', child: Text('Quarter Final')),
                    DropdownMenuItem(
                        value: 'semi_final', child: Text('Semi Final')),
                    DropdownMenuItem(value: 'final', child: Text('Final')),
                    DropdownMenuItem(
                        value: 'practice', child: Text('Practice')),
                    DropdownMenuItem(
                        value: 'friendly', child: Text('Friendly')),
                  ],
                  onChanged: (v) => setState(() => _matchType = v),
                ),
            ],
            maxColumns: 3,
          ),
          const SizedBox(height: _kFieldGap),

          responsiveFields(
            [
              CustomTextField(
                  controller: _oversController,
                  labelText: 'Overs',
                  prefixIcon: Icons.format_list_numbered_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final o = int.tryParse(v);
                    if (o == null || o < 1 || o > 100) return '1–100';
                    return null;
                  },
                ),
              _StyledDropdown<String>(
                  value: _ballType,
                  label: 'Ball Type / Category',
                  icon: Icons.sports_baseball_rounded,
                  items: _ballCategories
                      .map((category) => DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 10, color: category.color),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${category.title} (${category.category[0].toUpperCase()}${category.category.substring(1)})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    _selectBallCategory(
                        _ballCategories.firstWhere((c) => c.value == v));
                  },
                ),
              _StyledDropdown<String>(
                  value: _pitchType,
                  label: 'Pitch Type',
                  icon: Icons.grass_rounded,
                  items: const [
                    DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    DropdownMenuItem(value: 'green', child: Text('Green')),
                    DropdownMenuItem(value: 'dusty', child: Text('Dusty')),
                    DropdownMenuItem(value: 'wet', child: Text('Wet')),
                  ],
                  onChanged: (v) => setState(() => _pitchType = v),
                ),
            ],
            maxColumns: 3,
          ),
          const SizedBox(height: _kFieldGap),

          responsiveFields(
            [
              CustomTextField(
                  controller: _venueNameController,
                  labelText: 'Venue Name *',
                  prefixIcon: Icons.location_on_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter venue name'
                      : null,
                ),
              CustomTextField(
                  controller: _venueCityController,
                  labelText: 'Venue City (Optional)',
                  prefixIcon: Icons.location_city_rounded,
                ),
            ],
          ),
          const SizedBox(height: _kFieldGap),

          responsiveFields(
            [
              _DateTimeField(
                  label: 'Match Date (Optional)',
                  icon: Icons.calendar_today_rounded,
                  value: _scheduledDate != null
                      ? DateFormat('dd MMM yyyy').format(_scheduledDate!)
                      : 'Select date',
                  onTap: () => _pickDate(isToss: false),
                ),
              _DateTimeField(
                  label: 'Match Time (Optional)',
                  icon: Icons.access_time_rounded,
                  value: _selectedTime?.format(context) ?? 'Select time',
                  onTap: () => _pickTime(isToss: false),
                ),
            ],
          ),
          const SizedBox(height: _kFieldGap),

          responsiveFields(
            [
              _StyledDropdown<String>(
                  value: _tossDecision,
                  label: 'Toss Decision',
                  icon: Icons.flip_rounded,
                  items: const [
                    DropdownMenuItem(value: 'bat', child: Text('Bat First')),
                    DropdownMenuItem(value: 'bowl', child: Text('Bowl First')),
                  ],
                  onChanged: (v) => setState(() => _tossDecision = v),
                ),
              _DateTimeField(
                  label: 'Toss Date & Time (Optional)',
                  icon: Icons.event_rounded,
                  value: _tossDate != null
                      ? '${DateFormat('d MMM').format(_tossDate!)}'
                          '${_tossTime != null ? ', ${_tossTime!.format(context)}' : ''}'
                      : 'Select date & time',
                  onTap: () async {
                    await _pickDate(isToss: true);
                    if (mounted) await _pickTime(isToss: true);
                  },
                ),
            ],
          ),
          const SizedBox(height: _kFieldGap),

          // Advanced toggle
          _AdvancedToggle(
            expanded: _showAdvancedOptions,
            onTap: () =>
                setState(() => _showAdvancedOptions = !_showAdvancedOptions),
          ),

          if (_showAdvancedOptions) ...[
            const SizedBox(height: 14),
            _buildAdvancedSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildBallCategorySection() {
    final selected = _selectedBallCategory;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(selected.icon, color: selected.color, size: 19),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ball Category *',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _kTextPrimary)),
                    SizedBox(height: 2),
                    Text('Select before match start for consistent rules',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: _kTextSecondary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ballCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.62,
            ),
            itemBuilder: (context, index) {
              final category = _ballCategories[index];
              final isSelected = category.value == _ballType;
              return _BallCategoryTile(
                category: category,
                selected: isSelected,
                onTap: () => _selectBallCategory(category),
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected.color.withOpacity(0.20)),
            ),
            child: Text(
              '${selected.title}: ${selected.format}. Category saved as "${_matchCategory ?? selected.category}" and scoring rules will use this ball type.',
              style: TextStyle(
                  color: selected.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ── Advanced section ─────────────────────────────────────────────────────────

  Widget _buildAdvancedSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StyledDropdown<String?>(
            value: _selectedTournamentId,
            label: 'Tournament (Optional)',
            icon: Icons.emoji_events_rounded,
            items: [
              const DropdownMenuItem(value: null, child: Text('No Tournament')),
              ..._tournaments.map(
                  (t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
            ],
            onChanged: (v) => setState(() => _selectedTournamentId = v),
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _umpireController,
            labelText: 'Umpire (Optional)',
            prefixIcon: Icons.gavel_rounded,
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: _refereeController,
            labelText: 'Match Referee (Optional)',
            prefixIcon: Icons.assignment_ind_rounded,
          ),
          const SizedBox(height: 10),
          _StyledDropdown<String>(
            value: _matchCategory,
            label: 'Match Category Override',
            icon: Icons.family_restroom_rounded,
            items: const [
              DropdownMenuItem(
                  value: 'standard', child: Text('Standard Match')),
              DropdownMenuItem(value: 'casual', child: Text('Casual / Gully')),
              DropdownMenuItem(value: 'child', child: Text('Child Match')),
              DropdownMenuItem(value: 'indoor', child: Text('Indoor Match')),
              DropdownMenuItem(value: 'custom', child: Text('Custom Rules')),
            ],
            onChanged: (v) => setState(() => _matchCategory = v),
          ),
          const SizedBox(height: 10),
          _StyledDropdown<String>(
            value: _weatherCondition,
            label: 'Weather Condition',
            icon: Icons.wb_sunny_rounded,
            items: const [
              DropdownMenuItem(value: 'sunny', child: Text('Sunny')),
              DropdownMenuItem(value: 'cloudy', child: Text('Cloudy')),
              DropdownMenuItem(value: 'rainy', child: Text('Rainy')),
              DropdownMenuItem(value: 'overcast', child: Text('Overcast')),
            ],
            onChanged: (v) => setState(() => _weatherCondition = v),
          ),
        ],
      ),
    );
  }

  // ── Error / create button ────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_fetchError!,
                style: const TextStyle(color: Color(0xFF92400E), fontSize: 12)),
          ),
          GestureDetector(
            onTap: _loadAllTeams,
            child: Text('Retry',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Column(
      children: [
        Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(_kRadius + 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_kRadius + 2),
              onTap: _isLoading ? null : _createMatch,
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.sports_cricket_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Create Match',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 13, color: _kTextHint),
            const SizedBox(width: 6),
            Text(
              'Your match will be created securely',
              style: TextStyle(color: _kTextHint, fontSize: 11.5),
            ),
          ],
        ),
      ],
    );
  }

  // ── Help dialog ──────────────────────────────────────────────────────────────

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('How to Create a Match',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _helpStep('1', 'Select Teams', 'Choose both teams for the match'),
            const SizedBox(height: 12),
            _helpStep('2', 'Fill Basic Details',
                'Enter format, overs, date, time and venue'),
            const SizedBox(height: 12),
            _helpStep('3', 'Advanced Options (Optional)',
                'Add umpire, toss details, pitch type etc.'),
            const SizedBox(height: 12),
            _helpStep(
                '4', 'Create Match', 'Click the create button to schedule'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got it',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _helpStep(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration:
              BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Center(
            child: Text(num,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _kTextPrimary)),
              Text(desc,
                  style: const TextStyle(color: _kTextSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

/// Circular white icon button floating over the hero banner
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Icon(icon, size: 19, color: _kTextPrimary),
        ),
      ),
    );
  }
}

/// White card with title + icon header
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Styled dropdown that matches the white theme
class _BallCategoryTile extends StatelessWidget {
  final _BallCategoryData category;
  final bool selected;
  final VoidCallback onTap;

  const _BallCategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withOpacity(0.09)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? category.color : _kBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(category.icon, color: category.color, size: 18),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? category.color : _kTextHint,
                  size: 18,
                ),
              ],
            ),
            const Spacer(),
            Text(
              category.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              category.format,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _kTextSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;

  const _StyledDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _kTextSecondary),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value as T?,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadius),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadius),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 1.7),
            ),
          ),
          style: const TextStyle(
              fontSize: 13, color: _kTextPrimary, fontWeight: FontWeight.w600),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _kTextHint, size: 20),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Align(
                  alignment: Alignment.centerLeft,
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: item.child,
                  ),
                ),
              )
              .toList(),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Tappable read-only date/time display field
class _DateTimeField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _DateTimeField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _kTextSecondary),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_kRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        color: _kTextPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// VS separator between team selectors
class _VsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _kBorder)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'VS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _kBorder)),
      ],
    );
  }
}

/// Advanced options collapse toggle
class _AdvancedToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _AdvancedToggle({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_kRadius),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.settings_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Advanced Options (Umpire, Referee, Weather, Tournament)',
                style: TextStyle(
                  color: _kTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: _kTextSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small labelled divider inside advanced section
class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _kBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary)),
        ),
        const Expanded(child: Divider(color: _kBorder)),
      ],
    );
  }
}

// ─── Team Selector Card ───────────────────────────────────────────────────────

class _TeamSelectorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String searchLabel;
  final Color accentColor;
  final TextEditingController searchController;
  final List<Team> filteredTeams;
  final Team? selectedTeam;
  final bool loadingTeams;
  final void Function(Team) onSelect;
  final VoidCallback onClear;
  final VoidCallback onRetry;
  final VoidCallback onCreateTeam;

  const _TeamSelectorCard({
    required this.title,
    required this.subtitle,
    required this.searchLabel,
    this.accentColor = AppColors.primary,
    required this.searchController,
    required this.filteredTeams,
    required this.selectedTeam,
    required this.loadingTeams,
    required this.onSelect,
    required this.onClear,
    required this.onRetry,
    required this.onCreateTeam,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedTeam != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(
          color: isSelected ? accentColor.withOpacity(0.3) : _kBorder,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header strip
          _CardHeaderStrip(
            title: title,
            subtitle: subtitle,
            isSelected: isSelected,
            accentColor: accentColor,
            onCreateTeam: onCreateTeam,
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Search field
                TextFormField(
                  controller: searchController,
                  style: const TextStyle(fontSize: 13, color: _kTextPrimary),
                  decoration: _fieldDecoration(
                    label: searchLabel,
                    icon: Icons.search_rounded,
                    suffix: isSelected
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: _kTextHint),
                            onPressed: onClear,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Body
                if (isSelected)
                  _SelectedTeamBanner(
                    team: selectedTeam!,
                    accentColor: accentColor,
                    onDelete: onClear,
                  )
                else if (loadingTeams)
                  _TeamListLoader()
                else if (filteredTeams.isEmpty &&
                    searchController.text.isNotEmpty)
                  _NoResultsPlaceholder()
                else if (filteredTeams.isEmpty)
                  _EmptyTeamsPlaceholder(onRetry: onRetry)
                else
                  _TeamListView(
                    teams: filteredTeams,
                    selectedId: null,
                    accentColor: accentColor,
                    onSelect: onSelect,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeaderStrip extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onCreateTeam;

  const _CardHeaderStrip({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.accentColor,
    required this.onCreateTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? accentColor.withOpacity(0.06)
            : const Color(0xFFF8F9FA),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(_kCardRadius - 1)),
        border: const Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? accentColor : accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person_rounded,
              color: isSelected ? Colors.white : accentColor,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? accentColor : _kTextPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: _kTextHint, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onCreateTeam,
            icon: Icon(Icons.add_rounded, size: 16, color: accentColor),
            label: Text(
              'Create Team',
              style: TextStyle(
                color: accentColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedTeamBanner extends StatelessWidget {
  final Team team;
  final Color accentColor;
  final VoidCallback onDelete;
  const _SelectedTeamBanner({
    required this.team,
    required this.accentColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final code = (team.shortName?.isNotEmpty == true
            ? team.shortName!
            : team.name.substring(0, team.name.length >= 3 ? 3 : team.name.length))
        .toUpperCase();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: team.logo?.url != null && team.logo!.url!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: team.logo!.url!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.shield_rounded, color: Colors.white),
                  )
                : const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    code,
                    if (team.city != null && team.city!.isNotEmpty) team.city!,
                  ].join(' · '),
                  style:
                      const TextStyle(color: _kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.check_circle_rounded, color: accentColor, size: 22),
          const SizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamListLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _NoResultsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: const [
          Icon(Icons.search_off_rounded, size: 38, color: _kTextHint),
          SizedBox(height: 8),
          Text('No teams found',
              style: TextStyle(color: _kTextSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _EmptyTeamsPlaceholder extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyTeamsPlaceholder({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.sports_cricket_rounded, size: 38, color: _kTextHint),
          const SizedBox(height: 8),
          const Text('No teams available',
              style: TextStyle(color: _kTextSecondary, fontSize: 13)),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamListView extends StatelessWidget {
  final List<Team> teams;
  final String? selectedId;
  final Color accentColor;
  final void Function(Team) onSelect;

  const _TeamListView({
    required this.teams,
    required this.selectedId,
    this.accentColor = AppColors.primary,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: teams.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
        itemBuilder: (ctx, i) {
          final team = teams[i];
          final isSelected = team.id == selectedId;
          return InkWell(
            onTap: () => onSelect(team),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        (team.shortName?.isNotEmpty == true
                                ? team.shortName![0]
                                : team.name[0])
                            .toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected ? Colors.white : accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                            color: isSelected ? accentColor : _kTextPrimary,
                          ),
                        ),
                        if (team.city != null)
                          Text(team.city!,
                              style: const TextStyle(
                                  color: _kTextHint, fontSize: 11)),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        color: accentColor, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
