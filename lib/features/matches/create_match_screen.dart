import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/theme_config.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../data/services/match_service.dart';
import '../../../data/services/team_service.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/team_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/validators.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matchNameController = TextEditingController();
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _venueController = TextEditingController();
  final _formatController = TextEditingController(text: 'T20');

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedTournament;
  List<Team> _teams = [];
  bool _isLoading = false;
  bool _isLoadingTeams = true;

  final MatchService _matchService = MatchService();
  final TeamService _teamService = TeamService();

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _teamService.getTeamsList(limit: 100);
      setState(() {
        _teams = teams;
        _isLoadingTeams = false;
      });
    } catch (e) {
      debugPrint('Error loading teams: $e');
      setState(() => _isLoadingTeams = false);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      _dateController.text = '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
      _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String? _team1Validator(String? value) {
    if (value == null || value.isEmpty) return 'Team 1 required';
    if (!_teams.any((team) => team.name!.contains(value))) return 'Select valid team';
    return null;
  }

  String? _team2Validator(String? value) {
    if (value == null || value.isEmpty) return 'Team 2 required';
    if (value == _team1Controller.text) return 'Teams must be different';
    if (!_teams.any((team) => team.name!.contains(value))) return 'Select valid team';
    return null;
  }

  Future<void> _createMatch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final match = await _matchService.createMatch(
        team1: _team1Controller.text.trim(),
        team2: _team2Controller.text.trim(),
        scheduledDate: scheduledDateTime,
        venueName: _venueController.text.trim(),
        format: _formatController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Match created successfully!'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Match',
        showBackButton: true,
      ),
      body: _isLoadingTeams
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Match Name
                      CustomTextField(
                        controller: _matchNameController,
                        labelText: 'Match Name (Optional)',
                        prefixIcon: Icons.sports_cricket,
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 16),
                      
                      // Team 1
                      CustomTextField(
                        controller: _team1Controller,
                        labelText: 'Team 1',
                        prefixIcon: Icons.group,
                        hintText: 'Search team...',
                        validator: _team1Validator,
                      ),
                      const SizedBox(height: 16),
                      
                      // Team 2
                      CustomTextField(
                        controller: _team2Controller,
                        labelText: 'Team 2',
                        prefixIcon: Icons.group,
                        hintText: 'Search team...',
                        validator: _team2Validator,
                      ),
                      const SizedBox(height: 16),
                      
                      // Date & Time
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _dateController,
                              labelText: 'Date',
                              prefixIcon: Icons.calendar_today,
                              enabled: false,
                              validator: Validators.required,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _timeController,
                              labelText: 'Time',
                              prefixIcon: Icons.access_time,
                              enabled: false,
                              validator: Validators.required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Format
                      CustomTextField(
                        controller: _formatController,
                        labelText: 'Format',
                        prefixIcon: Icons.format_list_bulleted,
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 16),
                      
                      // Venue
                      CustomTextField(
                        controller: _venueController,
                        labelText: 'Venue',
                        prefixIcon: Icons.location_on,
                        hintText: 'Stadium, City',
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 24),
                      
                      // Tournament dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tournament (Optional)',
                          prefixIcon: Icon(Icons.emoji_events),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ..._teams.map((team) => DropdownMenuItem(
                            value: team.id,
                            child: Text(team.name ?? ''),
                          )),
                        ],
                        onChanged: (value) => setState(() => _selectedTournament = value),
                        validator: (value) => null, // Optional
                      ),
                      const SizedBox(height: 32),
                      
                      // Create Button
                      CustomButton(
                        text: 'Create Match',
                        icon: Icons.sports_cricket,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _createMatch,
                      ),
                      const SizedBox(height: 16),
                      
                      // Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Match will be scheduled and visible in Live tab after creation. Only admins can create matches.',
                                style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
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
