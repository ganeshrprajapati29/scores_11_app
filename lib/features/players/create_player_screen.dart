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

class _CreatePlayerScreenState extends State<CreatePlayerScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _jerseyController = TextEditingController();

  String? _role;
  String? _battingStyle;
  String? _bowlingStyle;
  String? _teamId;
  int? _jerseyNumber;

  final PlayerService _playerService = PlayerService();
  final TeamService _teamService = TeamService();
  List<String> _teams = [];
  bool _isLoading = false;
  Player? _editingPlayer;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, String> roleOptions = {
    'batsman': 'Batsman',
    'bowler': 'Bowler',
    'all-rounder': 'All-rounder',
    'wicket-keeper': 'Wicket-keeper',
  };

  final Map<String, String> battingStyleOptions = {
    'right-hand bat': 'Right Hand Bat',
    'left-hand bat': 'Left Hand Bat',
  };

  final Map<String, String> bowlingStyleOptions = {
    'right-arm fast': 'Right Arm Fast',
    'right-arm medium': 'Right Arm Medium',
    'left-arm fast': 'Left Arm Fast',
    'left-arm medium': 'Left Arm Medium',
    'off-spin': 'Off Spin',
    'leg-spin': 'Leg Spin',
    'none': 'None',
  };

  // Role icons
  final Map<String, IconData> roleIcons = {
    'batsman': Icons.sports_cricket,
    'bowler': Icons.sports_baseball,
    'all-rounder': Icons.stars,
    'wicket-keeper': Icons.shield,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();

    _loadTeams();
    if (widget.editPlayerId != null) {
      _loadPlayerForEdit();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _nationalityController.dispose();
    _jerseyController.dispose();
    super.dispose();
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
        _jerseyController.text = player.jerseyNumber?.toString() ?? '';
        _dobController.text = player.dateOfBirth ?? '';
        _nationalityController.text = player.nationality ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Load error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
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
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        dateOfBirth:
            _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
        nationality: _nationalityController.text.trim().isEmpty
            ? null
            : _nationalityController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Player created successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['message'] ?? 'Create failed'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DropdownMenuItem<String>> _getTeamItems() {
    List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: null, child: Text('No team')),
    ];
    for (String id in _teams) {
      items.add(DropdownMenuItem(value: id, child: Text('Team $id')));
    }
    return items;
  }

  // ─── Build Helpers ────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF4FC3F7), size: 20),
      filled: true,
      fillColor: const Color(0xFF1E2A3A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: Colors.white.withOpacity(0.07), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4FC3F7),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: roleOptions.entries.map((e) {
        final selected = _role == e.key;
        return GestureDetector(
          onTap: () => setState(() => _role = e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF4FC3F7).withOpacity(0.15)
                  : const Color(0xFF1E2A3A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF4FC3F7)
                    : Colors.white.withOpacity(0.07),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  roleIcons[e.key] ?? Icons.person,
                  size: 16,
                  color: selected
                      ? const Color(0xFF4FC3F7)
                      : Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  e.value,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF4FC3F7)
                        : Colors.grey.shade400,
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: const Color(0xFF1A2535),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      icon: const Icon(Icons.expand_more, color: Color(0xFF4FC3F7)),
      decoration: _inputDecoration(label, icon),
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editPlayerId != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A3A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Player' : 'New Player',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              isEdit ? 'Update player details' : 'Add to your squad',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isEdit ? 'EDIT' : 'NEW',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar / Hero Banner ──────────────────────────────
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4FC3F7),
                                Color(0xFF0288D1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4FC3F7)
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person,
                              size: 44, color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B2A),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF4FC3F7), width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Color(0xFF4FC3F7)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Personal Info ─────────────────────────────────────
                  _buildCard(children: [
                    _sectionLabel('PERSONAL INFO'),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          _inputDecoration('Full Name *', Icons.person),
                      validator: (v) => v?.trim().isEmpty ?? true
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          _inputDecoration('Phone Number', Icons.phone),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dobController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                                'Date of Birth', Icons.cake),
                            onTap: () async {
                              FocusScope.of(context).requestFocus(
                                  FocusNode());
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF4FC3F7),
                                      surface: Color(0xFF1A2535),
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                _dobController.text =
                                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nationalityController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                                'Nationality', Icons.flag),
                          ),
                        ),
                      ],
                    ),
                  ]),

                  const SizedBox(height: 14),

                  // ── Role Selector ─────────────────────────────────────
                  _buildCard(children: [
                    _sectionLabel('PLAYER ROLE'),
                    _buildRoleSelector(),
                  ]),

                  const SizedBox(height: 14),

                  // ── Playing Style ─────────────────────────────────────
                  _buildCard(children: [
                    _sectionLabel('PLAYING STYLE'),
                    _buildDropdown<String>(
                      label: 'Batting Style',
                      icon: Icons.sports_cricket,
                      value: _battingStyle,
                      items: battingStyleOptions.entries
                          .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _battingStyle = v),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<String>(
                      label: 'Bowling Style',
                      icon: Icons.sports_baseball,
                      value: _bowlingStyle,
                      items: bowlingStyleOptions.entries
                          .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _bowlingStyle = v),
                    ),
                  ]),

                  const SizedBox(height: 14),

                  // ── Team & Jersey ─────────────────────────────────────
                  _buildCard(children: [
                    _sectionLabel('TEAM & JERSEY'),
                    _buildDropdown<String>(
                      label: 'Team',
                      icon: Icons.group,
                      value: _teamId,
                      items: _getTeamItems(),
                      onChanged: (v) => setState(() => _teamId = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _jerseyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                          'Jersey Number', Icons.tag),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          _jerseyNumber = int.tryParse(v),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── Submit Button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: _isLoading
                        ? Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4FC3F7),
                                  Color(0xFF0288D1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: _submitPlayer,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4FC3F7),
                                    Color(0xFF0288D1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4FC3F7)
                                        .withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.save_alt,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    isEdit
                                        ? 'Update Player'
                                        : 'Create Player',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF132030),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}