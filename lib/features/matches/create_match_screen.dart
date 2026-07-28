import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../core/widgets/custom_button.dart';
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
        _fetchError = 'Failed to load your teams: $e';
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
      _snack('Failed to create match: ${e.toString()}', isError: true);
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
      appBar: _buildAppBar(),
      body: _loadingTeams && _allTeams.isEmpty
          ? _buildTeamLoader()
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: _kSectionGap),

// Validation Warning Banner
                    _buildValidationWarning(),
                    const SizedBox(height: _kSectionGap),

                    // Team 1
                    _TeamSelectorCard(
                      title: 'Team 1',
                      subtitle: 'Select your team',
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
                      title: 'Team 2',
                      subtitle: 'Select opponent team',
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
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: _kTextPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Create Match',
        style: TextStyle(
          color: _kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded,
              size: 20, color: _kTextSecondary),
          onPressed: _showHelpDialog,
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _kBorder),
      ),
    );
  }

  // ── Page header ──────────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.sports_cricket_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule a New Match',
                  style: TextStyle(
                    color: _kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Select teams, set venue & match details',
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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
              'Please ensure both teams are selected before creating a match',
              style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Match details card ───────────────────────────────────────────────────────

  Widget _buildMatchDetailsCard() {
    return _SectionCard(
      title: 'Match Details',
      icon: Icons.edit_note_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Title
          CustomTextField(
            controller: _matchTitleController,
            labelText: 'Match Title (Optional)',
            hintText: 'e.g., El Clasico, Derby Match',
            prefixIcon: Icons.title_rounded,
          ),
          const SizedBox(height: _kFieldGap),

          // Format + Type
          Row(
            children: [
              Expanded(
                child: _StyledDropdown<String>(
                  value: _format,
                  label: 'Format *',
                  icon: Icons.sports_cricket_rounded,
                  items: const [
                    DropdownMenuItem(value: 't20', child: Text('T20')),
                    DropdownMenuItem(value: 'odi', child: Text('ODI')),
                    DropdownMenuItem(value: 'test', child: Text('Test')),
                  ],
                  onChanged: (v) => setState(() => _format = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StyledDropdown<String>(
                  value: _matchType,
                  label: 'Match Type *',
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
              ),
            ],
          ),
          const SizedBox(height: _kFieldGap),

          // Tournament
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
          const SizedBox(height: _kFieldGap),

          // Overs
          CustomTextField(
            controller: _oversController,
            labelText: 'Overs per innings *',
            prefixIcon: Icons.format_list_numbered_rounded,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter overs';
              final o = int.tryParse(v);
              if (o == null || o < 1 || o > 100) return 'Must be 1–100';
              return null;
            },
          ),
          const SizedBox(height: _kFieldGap),

          _buildBallCategorySection(),
          const SizedBox(height: _kFieldGap),

          // Date + Time
          Row(
            children: [
              Expanded(
                child: _DateTimeField(
                  label: 'Match Date (optional)',
                  icon: Icons.calendar_today_rounded,
                  value: _scheduledDate != null
                      ? DateFormat('dd MMM yyyy').format(_scheduledDate!)
                      : 'Not set - starts now',
                  onTap: () => _pickDate(isToss: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateTimeField(
                  label: 'Match Time (optional)',
                  icon: Icons.access_time_rounded,
                  value: _selectedTime?.format(context) ?? 'Not set - starts now',
                  onTap: () => _pickTime(isToss: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: _kFieldGap),

          // Venue Name
          CustomTextField(
            controller: _venueNameController,
            labelText: 'Venue Name *',
            prefixIcon: Icons.location_on_rounded,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter venue name'
                : null,
          ),
          const SizedBox(height: 10),

          // City
          CustomTextField(
            controller: _venueCityController,
            labelText: 'City (Optional)',
            prefixIcon: Icons.location_city_rounded,
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
          const SizedBox(height: 14),

          // Toss Details
          const _SectionDivider(label: 'Toss Details'),
          const SizedBox(height: 12),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateTimeField(
                  label: 'Toss Date',
                  icon: Icons.calendar_today_rounded,
                  value: _tossDate != null
                      ? DateFormat('dd MMM yyyy').format(_tossDate!)
                      : '',
                  onTap: () => _pickDate(isToss: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateTimeField(
                  label: 'Toss Time',
                  icon: Icons.access_time_rounded,
                  value: _tossTime?.format(context) ?? '',
                  onTap: () => _pickTime(isToss: true),
                ),
              ),
            ],
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
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kRadius)),
        ),
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
                  Icon(Icons.sports_cricket_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Create Match',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
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
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
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
    return DropdownButtonFormField<T>(
      value: value as T?,
      decoration: _fieldDecoration(label: label, icon: icon),
      style: const TextStyle(
          fontSize: 13, color: _kTextPrimary, fontWeight: FontWeight.w500),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _kTextHint, size: 20),
      items: items,
      onChanged: onChanged,
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
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(text: value),
          style: const TextStyle(fontSize: 13, color: _kTextPrimary),
          decoration: _fieldDecoration(label: label, icon: icon),
        ),
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'VS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Advanced Options',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              expanded ? 'Hide' : 'Show',
              style: TextStyle(
                color: AppColors.primary.withOpacity(0.7),
                fontSize: 12,
              ),
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
          color: isSelected ? AppColors.primary.withOpacity(0.3) : _kBorder,
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
              title: title, subtitle: subtitle, isSelected: isSelected),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Search field
                TextFormField(
                  controller: searchController,
                  style: const TextStyle(fontSize: 13, color: _kTextPrimary),
                  decoration: _fieldDecoration(
                    label: 'Search $title',
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

                OutlinedButton.icon(
                  onPressed: onCreateTeam,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create a new team'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Body
                if (isSelected)
                  _SelectedTeamBanner(team: selectedTeam!)
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

  const _CardHeaderStrip({
    required this.title,
    required this.subtitle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.06)
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
              color: isSelected ? AppColors.primary : const Color(0xFFEEEFF2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSelected ? Icons.check_rounded : Icons.add_rounded,
              color: isSelected ? Colors.white : _kTextHint,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : _kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: _kTextHint, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedTeamBanner extends StatelessWidget {
  final Team team;
  const _SelectedTeamBanner({required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Center(
              child: Text(
                (team.shortName?.isNotEmpty == true
                        ? team.shortName![0]
                        : team.name[0])
                    .toUpperCase(),
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
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
                ),
                if (team.city != null)
                  Text(team.city!,
                      style: const TextStyle(
                          color: _kTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF16A34A), size: 22),
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
  final void Function(Team) onSelect;

  const _TeamListView({
    required this.teams,
    required this.selectedId,
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
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
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
                          color: isSelected ? Colors.white : AppColors.primary,
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
                            color:
                                isSelected ? AppColors.primary : _kTextPrimary,
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
                        color: AppColors.primary, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
