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

  String _format = 'T20';
  String _matchType = 'LEAGUE';
  DateTime? _scheduledDate;
  DateTime? _startTime;
  bool _isLoading = false;

  final MatchService _matchService = MatchService();

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
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _startTime = DateTime.now().add(
        Duration(hours: time.hour, minutes: time.minute),
      ));
    }
  }

  Future<void> _createMatch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final match = await _matchService.createMatch(
        team1: _team1Controller.text.trim(),
        team2: _team2Controller.text.trim(),
        format: _format,
        matchType: _matchType,
        venueName: _venueController.text.trim(),
        scheduledDate: _scheduledDate!,
        overs: 20,
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                // Team 1 vs Team 2
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _team1Controller,
                        labelText: 'Team 1 *',
                        prefixIcon: Icons.flag,
                        validator: Validators.required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _team2Controller,
                        labelText: 'Team 2 *',
                        prefixIcon: Icons.flag,
                        validator: Validators.required,
                      ),
                    ),
                  ],
                ),
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
                        ],
                        onChanged: (value) => setState(() => _matchType = value ?? 'LEAGUE'),
                        validator: Validators.required,
                      ),
                    ),
                  ],
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
                            controller: TextEditingController(text: _scheduledDate != null ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}' : ''),
                            labelText: 'Date *',
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
                            controller: TextEditingController(text: _startTime != null ? '${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}' : ''),
                            labelText: 'Time *',
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

                // Venue
                CustomTextField(
                  controller: _venueController,
                  labelText: 'Venue *',
                  prefixIcon: Icons.location_on,
                  validator: Validators.required,
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
