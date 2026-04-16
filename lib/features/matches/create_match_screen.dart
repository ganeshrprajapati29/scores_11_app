import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/theme_config.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../data/services/match_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/validators.dart';
import '../../../data/services/team_service.dart';
import '../../../data/services/tournament_service.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/tournament_model.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  final _venueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TextEditingController _venueCityController = TextEditingController();
  final TextEditingController _team1SearchController = TextEditingController();
  final TextEditingController _team2SearchController = TextEditingController();

  String? _format; // Changed to nullable
  String? _matchType; // Changed to nullable
  DateTime? _scheduledDate;
  TimeOfDay? _selectedTimeOfDay;
  bool _isLoading = false;
  bool _loadingTeams = true;
  bool _loadingTournaments = false;

  List<Team> _allTeams = [];
  List<Team> _filteredTeams1 = [];
  List<Team> _filteredTeams2 = [];
  List<Tournament> _tournaments = [];

  String? _selectedTeam1Id;
  Team? _selectedTeam1;
  String? _selectedTeam2Id;
  Team? _selectedTeam2;
  String? _selectedTournamentId;

  String _team1Search = '';
  String _team2Search = '';

  final MatchService _matchService = MatchService();
  final TeamService _teamService = TeamService();
  final TournamentService _tournamentService = TournamentService();

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _format = 't20'; // Initialize after super.initState
    _matchType = 'league'; // Initialize after super.initState
    _loadTeams();
    _loadTournaments();
    _team1SearchController.addListener(_filterTeams1);
    _team2SearchController.addListener(_filterTeams2);
  }

  @override
  void dispose() {
    _team1SearchController.dispose();
    _team2SearchController.dispose();
    _venueCityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _scheduledDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTimeOfDay ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTimeOfDay = time);
    }
  }

  Future<void> _createMatch() async {
    if (_selectedTeam1Id == null || _selectedTeam2Id == null || _scheduledDate == null || _venueController.text.trim().isEmpty) {
      _showSnackBar('Please select both teams, date and enter venue name', isError: true);
      return;
    }
    if (_selectedTeam1Id == _selectedTeam2Id) {
      _showSnackBar('Team1 and Team2 must be different', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final startTime = _selectedTimeOfDay != null 
        ? '${_selectedTimeOfDay!.hour.toString().padLeft(2, '0')}:${_selectedTimeOfDay!.minute.toString().padLeft(2, '0')}'
        : null;

      final scheduledDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _selectedTimeOfDay?.hour ?? 10,
        _selectedTimeOfDay?.minute ?? 0,
      );

      // Pre-validation
      if (_venueController.text.trim().isEmpty) {
        _showSnackBar('Please enter venue name', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      if (!scheduledDateTime.isAfter(DateTime.now())) {
        _showSnackBar('Match date must be in future', isError: true);
        setState(() => _isLoading = false);
        return;
      }
      
      final match = await _matchService.createMatch(
        team1: _selectedTeam1Id!,
        team2: _selectedTeam2Id!,
        tournament: _selectedTournamentId,
        scheduledDate: scheduledDateTime,
        format: _format!,
        matchType: _matchType!,
        venueName: _venueController.text.trim(),
        venueCity: _venueCityController.text.trim().isEmpty ? null : _venueCityController.text.trim(),
        startTime: startTime,
        overs: _format == 't20' ? 20 : _format == 'odi' ? 50 : 90,
      );

      if (mounted) {
        _showSnackBar('Match created successfully!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('💥 Match creation failed: $e');
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        _showSnackBar(errorMsg.length > 100 ? 'Failed to create match. Check console.' : errorMsg, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _loadTeams() async {
    setState(() => _loadingTeams = true);
    try {
      final result = await _teamService.getTeams(page: 1, limit: 100);
      setState(() {
        _allTeams = result.teams;
        _filteredTeams1 = result.teams;
        _filteredTeams2 = result.teams;
        _loadingTeams = false;
      });
    } catch (e) {
      _showSnackBar('Failed to load teams: $e', isError: true);
      setState(() => _loadingTeams = false);
    }
  }

  Future<void> _loadTournaments() async {
    setState(() => _loadingTournaments = true);
    try {
      final result = await _tournamentService.getTournaments(page: 1, limit: 50);
      setState(() {
        _tournaments = result.tournaments;
      });
    } catch (e) {
      // Optional, ignore missing tournaments
    } finally {
      setState(() => _loadingTournaments = false);
    }
  }

  void _filterTeams1() {
    final query = _team1SearchController.text.toLowerCase();
    setState(() {
      _filteredTeams1 = _allTeams.where((team) =>
        team.name.toLowerCase().contains(query) ||
        (team.shortName ?? '').toLowerCase().contains(query)
      ).toList();
    });
  }

  void _filterTeams2() {
    final query = _team2SearchController.text.toLowerCase();
    setState(() {
      _filteredTeams2 = _allTeams.where((team) =>
        team.name.toLowerCase().contains(query) ||
        (team.shortName ?? '').toLowerCase().contains(query) ||
        (_selectedTeam1Id == null || team.id != _selectedTeam1Id)
      ).toList();
    });
  }

  Widget _buildTeamSelector({
    required String title,
    required TextEditingController searchController,
    required Team? selectedTeam,
    required List<Team> filteredTeams,
    required VoidCallback onClear,
    required Function(Team) onSelect,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            )),
            const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              CustomTextField(
                controller: searchController,
                labelText: 'Search $title',
                prefixIcon: Icons.search,
                suffixIcon: selectedTeam != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: onClear,
                      )
                    : null,
              ),
              if (selectedTeam != null)
                Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          selectedTeam.shortName ?? '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      selectedTeam.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: selectedTeam.city != null
                        ? Text(selectedTeam.city!)
                        : null,
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: Colors.green.shade700, size: 20),
                    ),
                  ),
                )
              else if (filteredTeams.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredTeams.length,
                    itemBuilder: (context, index) {
                      final team = filteredTeams[index];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onSelect(team),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        team.shortName ?? '?',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
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
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (team.city != null)
                                          Text(
                                            team.city!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else if (filteredTeams.isEmpty && searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No teams found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: CustomAppBar(
        title: 'Create New Match',
        showBackButton: true,
        actions: [
          if (_selectedTeam1 != null && _selectedTeam2 != null && _scheduledDate != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Ready to create',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _loadingTeams
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading teams...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.sports_cricket,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Create New Match',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Schedule a cricket match between two teams',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.white.withOpacity(0.9), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'All matches are published immediately upon creation',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form Section
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Section Title
                              _buildSectionTitle('Team Selection', Icons.people),
                              const SizedBox(height: 16),
                              
                              // Team Selectors
                              _buildTeamSelector(
                                title: 'Team 1',
                                searchController: _team1SearchController,
                                selectedTeam: _selectedTeam1,
                                filteredTeams: _filteredTeams1,
                                onClear: () {
                                  setState(() {
                                    _selectedTeam1 = null;
                                    _selectedTeam1Id = null;
                                    _team1SearchController.clear();
                                  });
                                },
                                onSelect: (team) {
                                  setState(() {
                                    _selectedTeam1 = team;
                                    _selectedTeam1Id = team.id;
                                    _team1SearchController.text = team.name;
                                  });
                                },
                                isLoading: _loadingTeams,
                              ),
                              const SizedBox(height: 24),
                              
                              // VS Divider
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 2,
                                        color: AppColors.primary.withOpacity(0.3),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'VS',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 40,
                                        height: 2,
                                        color: AppColors.primary.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              _buildTeamSelector(
                                title: 'Team 2',
                                searchController: _team2SearchController,
                                selectedTeam: _selectedTeam2,
                                filteredTeams: _filteredTeams2,
                                onClear: () {
                                  setState(() {
                                    _selectedTeam2 = null;
                                    _selectedTeam2Id = null;
                                    _team2SearchController.clear();
                                  });
                                },
                                onSelect: (team) {
                                  setState(() {
                                    _selectedTeam2 = team;
                                    _selectedTeam2Id = team.id;
                                    _team2SearchController.text = team.name;
                                  });
                                },
                                isLoading: _loadingTeams,
                              ),
                              const SizedBox(height: 24),
                              
                              const Divider(height: 32),
                              
                              // Match Details Section
                              _buildSectionTitle('Match Details', Icons.settings),
                              const SizedBox(height: 16),
                              
                              // Format & Type
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _format,
                                      decoration: InputDecoration(
                                        labelText: 'Format *',
                                        prefixIcon: const Icon(Icons.sports_cricket),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 't20', child: Text('🏏 T20')),
                                        DropdownMenuItem(value: 'odi', child: Text('⚾ ODI')),
                                        DropdownMenuItem(value: 'test', child: Text('🏆 Test')),
                                      ],
                                      onChanged: (value) => setState(() => _format = value),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select a format';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _matchType,
                                      decoration: InputDecoration(
                                        labelText: 'Type *',
                                        prefixIcon: const Icon(Icons.category),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                        fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'league', child: Text('🏆 League')),
                                        DropdownMenuItem(value: 'friendly', child: Text('🤝 Friendly')),
                                        DropdownMenuItem(value: 'knockout', child: Text('🎯 Knockout')),
                                        DropdownMenuItem(value: 'final', child: Text('🏆 Final')),
                                      ],
                                      onChanged: (value) => setState(() => _matchType = value),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select a match type';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Tournament
                              DropdownButtonFormField<String?>(
                                value: _selectedTournamentId,
                                decoration: InputDecoration(
                                  labelText: 'Tournament (Optional)',
                                  prefixIcon: const Icon(Icons.emoji_events),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('No Tournament')),
                                  ..._tournaments.map((t) => DropdownMenuItem(
                                    value: t.id,
                                    child: Text(t.name),
                                  )),
                                ],
                                onChanged: (value) => setState(() => _selectedTournamentId = value),
                              ),
                              const SizedBox(height: 16),
                              
                              // Date & Time
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _selectDate,
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          controller: TextEditingController(
                                            text: _scheduledDate != null 
                                              ? DateFormat('dd MMM yyyy').format(_scheduledDate!)
                                              : ''
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Scheduled Date *',
                                            prefixIcon: const Icon(Icons.calendar_today),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                                          ),
                                          validator: (value) {
                                            if (_scheduledDate == null) {
                                              return 'Please select a date';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _selectTime,
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          controller: TextEditingController(
                                            text: _selectedTimeOfDay != null 
                                              ? _selectedTimeOfDay!.format(context)
                                              : ''
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Start Time *',
                                            prefixIcon: const Icon(Icons.access_time),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
                                          ),
                                          validator: (value) {
                                            if (_selectedTimeOfDay == null) {
                                              return 'Please select a time';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              const Divider(height: 32),
                              
                              // Venue Section
                              _buildSectionTitle('Venue Information', Icons.location_on),
                              const SizedBox(height: 16),
                              
                              CustomTextField(
                                controller: _venueController,
                                labelText: 'Venue Name *',
                                prefixIcon: Icons.location_on,
                                validator: Validators.required,
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                controller: _venueCityController,
                                labelText: 'City (Optional)',
                                prefixIcon: Icons.location_city,
                              ),
                              const SizedBox(height: 16),
                              
                              const Divider(height: 32),
                              
                              // Description Section
                              _buildSectionTitle('Additional Information', Icons.description),
                              const SizedBox(height: 16),
                              
                              CustomTextField(
                                controller: _descriptionController,
                                labelText: 'Match Description (Optional)',
                                prefixIcon: Icons.description,
                                maxLines: 3,
                                keyboardType: TextInputType.multiline,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Create Button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final canCreateMatch = authProvider.user != null &&
                              ['admin', 'umpire', 'manager'].contains(authProvider.user!.role.toLowerCase());
                          
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: ElevatedButton(
                              onPressed: (canCreateMatch && !_isLoading) ? _createMatch : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canCreateMatch ? AppColors.primary : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: canCreateMatch ? 3 : 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(canCreateMatch ? Icons.sports_cricket : Icons.lock_outline),
                                        const SizedBox(width: 12),
                                        Text(
                                          canCreateMatch ? 'Create Match' : 'Admin/Manager/Umpire Only',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Summary Card (when both teams and date selected)
                      if (_selectedTeam1 != null && _selectedTeam2 != null && _scheduledDate != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade50, Colors.blue.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.summarize, color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Match Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        _selectedTeam1!.shortName ?? _selectedTeam1!.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          _selectedTeam1!.shortName?[0] ?? 'T',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Column(
                                    children: [
                                      Text(
                                        _selectedTeam2!.shortName ?? _selectedTeam2!.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          _selectedTeam2!.shortName?[0] ?? 'T',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  '${DateFormat('dd MMM yyyy').format(_scheduledDate!)} • ${_format?.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}