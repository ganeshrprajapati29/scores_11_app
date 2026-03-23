import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/theme_config.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../data/services/tournament_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/validators.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _organizerController = TextEditingController();
  final _venueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _prizeMoneyController = TextEditingController();
  final _totalTeamsController = TextEditingController(text: '10');

  String _format = 'T20';
  String _type = 'LEAGUE';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPaid = false;
  bool _isLoading = false;

  final TournamentService _tournamentService = TournamentService();

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 60)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tournament = await _tournamentService.createTournament(
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim(),
        organizer: _organizerController.text.trim(),
        format: _format,
        type: _type,
        startDate: _startDate,
        endDate: _endDate,
        venue: _venueController.text.trim(),
        totalTeams: int.tryParse(_totalTeamsController.text) ?? 10,
        isPaid: _isPaid,
        entryFee: double.tryParse(_entryFeeController.text) ?? 0.0,
        prizeMoney: double.tryParse(_prizeMoneyController.text) ?? 0.0,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tournament created successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              onPressed: () => Navigator.pushNamed(
                context,
                '/tournament-detail',
                arguments: tournament.id,
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
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Tournament',
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
                // Tournament Name
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Tournament Name *',
                  prefixIcon: Icons.emoji_events,
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),

                // Short Name
                CustomTextField(
                  controller: _shortNameController,
                  labelText: 'Short Name (Optional)',
                  prefixIcon: Icons.short_text,
                  hintText: 'IPL, Blast etc.',
                ),
                const SizedBox(height: 16),

                // Organizer
                CustomTextField(
                  controller: _organizerController,
                  labelText: 'Organizer *',
                  prefixIcon: Icons.person,
                  validator: Validators.required,
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
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Type *',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'LEAGUE', child: Text('League')),
                          DropdownMenuItem(value: 'KNOCKOUT', child: Text('Knockout')),
                          DropdownMenuItem(value: 'ROUND_ROBIN', child: Text('Round Robin')),
                        ],
                        onChanged: (value) => setState(() => _type = value ?? 'LEAGUE'),
                        validator: Validators.required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectStartDate,
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: TextEditingController(text: _startDate != null ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}' : ''),
                            labelText: 'Start Date *',
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
                        onTap: _selectEndDate,
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: TextEditingController(text: _endDate != null ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}' : ''),
                            labelText: 'End Date *',
                            prefixIcon: Icons.calendar_today,
                            enabled: false,
                            validator: Validators.required,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Venue & Teams
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _venueController,
                        labelText: 'Venue *',
                        prefixIcon: Icons.location_on,
                        validator: Validators.required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _totalTeamsController,
                        labelText: 'Total Teams *',
                        prefixIcon: Icons.groups,
                        keyboardType: TextInputType.number,
                        validator: Validators.requiredNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Paid Tournament
                SwitchListTile.adaptive(
                  title: const Text('Paid Tournament'),
                  subtitle: const Text('Enable entry fees and prize money'),
                  value: _isPaid,
                  onChanged: (value) => setState(() => _isPaid = value),
                ),

                if (_isPaid) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _entryFeeController,
                          labelText: 'Entry Fee (\$)',
                          prefixIcon: Icons.attach_money,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _prizeMoneyController,
                          labelText: 'Prize Money (\$)',
                          prefixIcon: Icons.emoji_events,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Description
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description (Optional)',
                  prefixIcon: Icons.description,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 32),

                // Create Button
                CustomButton(
                  text: 'Create Tournament',
                  icon: Icons.emoji_events,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _createTournament,
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
                          'Tournament will be published and teams can register immediately after creation.',
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
