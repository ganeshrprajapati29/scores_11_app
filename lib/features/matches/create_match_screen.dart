import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
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

  String _format = 'T20';
  String _matchType = 'LEAGUE';
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _scheduledDate = date);
    }
  }

Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTimeOfDay ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTimeOfDay = time);
    }
  }

Future<void> _createMatch() async {
    if (_selectedTeam1Id == null || _selectedTeam2Id == null || _scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both teams and date')),
      );
      return;
    }
    if (_selectedTeam1Id == _selectedTeam2Id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team1 and Team2 must be different')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    // Validate teams exist before API call
    setState(() => _isLoading = true);
    try {
      debugPrint('🔍 Validating Team1: $_selectedTeam1Id');
      await _teamService.getTeamById(_selectedTeam1Id!);
      debugPrint('✅ Team1 valid');
      
      debugPrint('🔍 Validating Team2: $_selectedTeam2Id');
      await _teamService.getTeamById(_selectedTeam2Id!);
      debugPrint('✅ Team2 valid');
    } catch (teamError) {
      debugPrint('❌ Team validation failed: $teamError');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid team selected. Please refresh and try again. Error: $teamError')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final scheduledDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _selectedTimeOfDay?.hour ?? 10,
        _selectedTimeOfDay?.minute ?? 0,
      );

      debugPrint('📅 Creating match: ${_selectedTeam1!.name} vs ${_selectedTeam2!.name}');
      debugPrint('   Tournament: ${_selectedTournamentId ?? "None"}');
      debugPrint('   Date: $scheduledDateTime');
      
      final match = await _matchService.createMatch(
        team1: _selectedTeam1Id!,
        team2: _selectedTeam2Id!,
        tournament: _selectedTournamentId,
        scheduledDate: scheduledDateTime,
        format: _format,
        matchType: _matchType,
        venueName: _venueController.text.trim(),
        venueCity: _venueCityController.text.trim().isEmpty ? null : _venueCityController.text.trim(),
        overs: _format == 'T20' ? 20 : _format == 'ODI' ? 50 : 90,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Match scheduled successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              onPressed: () => Navigator.pushNamed(
                context,
                '/match-detail',
                arguments: match.id,
              ),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('💥 Match creation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating match: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

@override
  void initState() {
    super.initState();
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
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load teams: $e')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Match',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
// Team Selection Section
                if (_loadingTeams)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Team 1 Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Team 1 *', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _team1SearchController,
                        labelText: 'Search Team 1',
                        prefixIcon: Icons.search,
                        suffixIcon: _selectedTeam1 != null 
                          ? IconButton(icon: Icon(Icons.clear), onPressed: () {
                              setState(() {
                                _selectedTeam1 = null;
                                _selectedTeam1Id = null;
                                _team1SearchController.clear();
                              });
                            })
                          : null,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedTeam1 != null 
                          ? ListTile(
                              leading: CircleAvatar(child: Text(_selectedTeam1!.shortName ?? '?')),
                              title: Text(_selectedTeam1!.name),
                              subtitle: Text(_selectedTeam1!.city ?? ''),
                              trailing: Icon(Icons.check_circle, color: Colors.green),
                            )
                          : _filteredTeams1.isEmpty
                            ? const ListTile(title: Text('No teams found'))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredTeams1.length,
                                itemBuilder: (context, index) {
                                  final team = _filteredTeams1[index];
                                  return ListTile(
                                    leading: CircleAvatar(child: Text(team.shortName ?? '?')),
                                    title: Text(team.name),
                                    subtitle: Text(team.city ?? ''),
                                    onTap: () => setState(() {
                                      _selectedTeam1 = team;
                                      _selectedTeam1Id = team.id;
                                      _team1SearchController.text = team.name;
                                      _filteredTeams1.clear(); // Close dropdown
                                    }),
                                  );
                                },
                              ),
                      ),
                      if (_selectedTeam1 == null) const SizedBox(height: 16),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Team 2 Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Team 2 *', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _team2SearchController,
                        labelText: 'Search Team 2',
                        prefixIcon: Icons.search,
                        suffixIcon: _selectedTeam2 != null 
                          ? IconButton(icon: Icon(Icons.clear), onPressed: () {
                              setState(() {
                                _selectedTeam2 = null;
                                _selectedTeam2Id = null;
                                _team2SearchController.clear();
                              });
                            })
                          : null,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedTeam2 != null 
                          ? ListTile(
                              leading: CircleAvatar(child: Text(_selectedTeam2!.shortName ?? '?')),
                              title: Text(_selectedTeam2!.name),
                              subtitle: Text(_selectedTeam2!.city ?? ''),
                              trailing: Icon(Icons.check_circle, color: Colors.green),
                            )
                          : _filteredTeams2.isEmpty
                            ? const ListTile(title: Text('No teams found'))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredTeams2.length,
                                itemBuilder: (context, index) {
                                  final team = _filteredTeams2[index];
                                  return ListTile(
                                    leading: CircleAvatar(child: Text(team.shortName ?? '?')),
                                    title: Text(team.name),
                                    subtitle: Text(team.city ?? ''),
                                    onTap: () => setState(() {
                                      _selectedTeam2 = team;
                                      _selectedTeam2Id = team.id;
                                      _team2SearchController.text = team.name;
                                    }),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                const SizedBox(height: 16),

                // Format & Type
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _format,
                        decoration: const InputDecoration(
                          labelText: 'Format *',
                          prefixIcon: Icon(Icons.sports_cricket),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'T20', child: Text('T20')),
                          DropdownMenuItem(value: 'ODI', child: Text('ODI')),
                          DropdownMenuItem(value: 'TEST', child: Text('Test')),
                        ],
                        onChanged: (value) => setState(() => _format = value ?? 'T20'),
                        validator: Validators.required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _matchType,
                        decoration: const InputDecoration(
                          labelText: 'Type *',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
DropdownMenuItem(value: 'LEAGUE', child: Text('League')),
                          DropdownMenuItem(value: 'FRIENDLY', child: Text('Friendly')),
                          DropdownMenuItem(value: 'KNOCKOUT', child: Text('Knockout')),
                          DropdownMenuItem(value: 'FINAL', child: Text('Final')),
                        ],
                        onChanged: (value) => setState(() => _matchType = value ?? 'LEAGUE'),
                        validator: Validators.required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

// Tournament (Optional)
                DropdownButtonFormField<String>(
                  value: _selectedTournamentId,
                  decoration: const InputDecoration(
                    labelText: 'Tournament (Optional)',
                    prefixIcon: Icon(Icons.emoji_events),
                    border: OutlineInputBorder(),
                  ),
                  items: _tournaments.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.name),
                  )).toList(),
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
                          child: CustomTextField(
                            controller: TextEditingController(
                              text: _scheduledDate != null 
                                ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}' 
                                : ''
                            ),
                            labelText: 'Scheduled Date *',
                            prefixIcon: Icons.calendar_today,
                            enabled: false,
                            validator: Validators.required,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectTime,
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: TextEditingController(
                              text: _selectedTimeOfDay != null 
                                ? '${_selectedTimeOfDay!.hour}:${_selectedTimeOfDay!.minute.toString().padLeft(2, '0')}' 
                                : ''
                            ),
                            labelText: 'Start Time *',
                            prefixIcon: Icons.access_time,
                            enabled: false,
                            validator: Validators.required,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

// Venue Details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Match Description (Optional)',
                  prefixIcon: Icons.description,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 32),

                // Create Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final canCreateMatch = authProvider.user != null &&
                        ['admin', 'umpire', 'manager'].contains(authProvider.user!.role.toLowerCase());
                    
                    return CustomButton(
                      text: canCreateMatch ? 'Create Match' : 'Admin/Manager/Umpire Only',
                      icon: Icons.sports_cricket,
                      isLoading: _isLoading,
                      onPressed: (canCreateMatch && !_isLoading) ? _createMatch : null,
                      color: canCreateMatch ? null : Colors.grey,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Match will be published immediately. Players and teams can join and view scorecard.',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
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
}
