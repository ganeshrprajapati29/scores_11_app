import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/services/player_service.dart';
import '../../../data/models/player_model.dart';
import '../../../data/services/team_service.dart';

class CreatePlayerScreen extends StatefulWidget {
  final String? editPlayerId;

  const CreatePlayerScreen({super.key, this.editPlayerId});

  @override
  State<CreatePlayerScreen> createState() => _CreatePlayerScreenState();
}

class _CreatePlayerScreenState extends State<CreatePlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _role;
  String? _battingStyle;
  String? _bowlingStyle;
  String? _teamId;
  int? _jerseyNumber;
  String? _dateOfBirth;
  String? _nationality;
  final PlayerService _playerService = PlayerService();
  final TeamService _teamService = TeamService();
  List<String> _teams = [];
  bool _isLoading = false;
  Player? _editingPlayer;

  final List<String> roles = ['Batsman', 'Bowler', 'All-rounder', 'Wicketkeeper'];
  final List<String> battingStyles = ['Right Handed', 'Left Handed'];
  final List<String> bowlingStyles = ['Right Arm Fast', 'Right Arm Medium', 'Right Arm Spin', 'Left Arm Fast', 'Left Arm Spin'];

  @override
  void initState() {
    super.initState();
    _loadTeams();
    if (widget.editPlayerId != null) {
      _loadPlayerForEdit();
    }
  }

  Future<void> _loadTeams() async {
    try {
      final paginated = await _teamService.getTeams(limit: 50);
      setState(() {
        _teams = paginated.teams.map((t) => t.id).toList();
      });
    } catch (e) {
      // Fallback empty
    }
  }

  Future<void> _loadPlayerForEdit() async {
    try {
      final player = await _playerService.getPlayerById(widget.editPlayerId!);
      setState(() {
        _editingPlayer = player;
        _nameController.text = player.name;
        _phoneController.text = player.phone ?? '';
        _role = player.role;
        _battingStyle = player.battingStyle;
        _bowlingStyle = player.bowlingStyle;
        _teamId = player.team;
        _jerseyNumber = player.jerseyNumber;
        _dateOfBirth = player.dateOfBirth;
        _nationality = player.nationality;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load error: $e')),
      );
    }
  }

  Future<void> _submitPlayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _playerService.createPlayer(
        name: _nameController.text.trim(),
        role: _role,
        battingStyle: _battingStyle,
        bowlingStyle: _bowlingStyle,
        team: _teamId,
        jerseyNumber: _jerseyNumber,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        dateOfBirth: _dateOfBirth,
        nationality: _nationality,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Player created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['message'] ?? 'Create failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DropdownMenuItem<String>> _getTeamItems() {
    if (_teams.isEmpty) {
      return [const DropdownMenuItem(value: null, child: Text('No teams'))];
    }
    List<DropdownMenuItem<String>> items = [const DropdownMenuItem(value: null, child: Text('No team'))];
    for (String id in _teams) {
      items.add(DropdownMenuItem(
        value: id,
        child: Text('Team $id'), // Simple fallback
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editPlayerId != null;
    return Scaffold(
      appBar: CustomAppBar(
        title: isEdit ? 'Edit Player' : 'Create Player',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Update Player Details' : 'New Player Information',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.trim().isEmpty ?? true ? 'Name required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.star),
                          border: OutlineInputBorder(),
                        ),
                        items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (value) => setState(() => _role = value),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _battingStyle,
                              decoration: const InputDecoration(
                                labelText: 'Batting',
                                prefixIcon: const Icon(Icons.sports_cricket),
                                border: OutlineInputBorder(),
                              ),
                              items: battingStyles.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (value) => setState(() => _battingStyle = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _bowlingStyle,
                              decoration: const InputDecoration(
                                labelText: 'Bowling',
                                prefixIcon: const Icon(Icons.sports_baseball),
                                border: OutlineInputBorder(),
                              ),
                              items: bowlingStyles.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (value) => setState(() => _bowlingStyle = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _teamId,
                              decoration: const InputDecoration(
                                labelText: 'Team',
                                prefixIcon: Icon(Icons.group),
                                border: OutlineInputBorder(),
                              ),
                              items: _getTeamItems(),
                              onChanged: (value) => setState(() => _teamId = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Jersey #',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _jerseyNumber = int.tryParse(value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth (YYYY-MM-DD)',
                          prefixIcon: Icon(Icons.cake),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _dateOfBirth = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Nationality',
                          prefixIcon: Icon(Icons.flag),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _nationality = value,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: isEdit ? 'Update Player' : 'Create Player',
                          onPressed: _isLoading ? null : _submitPlayer,
                          icon: _isLoading ? null : Icons.save,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
