import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/services/player_service.dart';
import '../../../data/models/player_model.dart';
import '../../../data/services/team_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kRadius = 14.0;
const _kCardRadius = 16.0;
const _kFieldGap = 12.0;
const _kBg = Color(0xFFF8F9FA);
const _kBorder = Color(0xFFEEEFF2);
const _kTextPrimary = Color(0xFF0D1117);
const _kTextSecondary = Color(0xFF6B7280);
const _kTextHint = Color(0xFF9CA3AF);
const _kShadow = Color(0x0A000000);

InputDecoration _fieldDeco({
  required String label,
  required IconData icon,
  String? hint,
  int maxLines = 1,
}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 13, color: _kTextHint),
      hintStyle: const TextStyle(fontSize: 13, color: _kTextHint),
      prefixIcon: Icon(icon, size: 18, color: _kTextHint),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      alignLabelWithHint: maxLines > 1,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide:
            const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
      ),
    );

// ─── Screen ───────────────────────────────────────────────────────────────────

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

  final Map<String, IconData> roleIcons = {
    'batsman': Icons.sports_cricket_rounded,
    'bowler': Icons.sports_baseball_rounded,
    'all-rounder': Icons.stars_rounded,
    'wicket-keeper': Icons.shield_rounded,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();

    _loadTeams();
    if (widget.editPlayerId != null) _loadPlayerForEdit();
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

  // ── Data loaders ─────────────────────────────────────────────────────────────

  Future<void> _loadTeams() async {
    try {
      final paginated = await _teamService.getTeams(limit: 50);
      setState(() => _teams = paginated.teams.map((t) => t.id).toList());
    } catch (_) {}
  }

  Future<void> _loadPlayerForEdit() async {
    try {
      final player =
          await _playerService.getPlayerById(widget.editPlayerId!);
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
      if (mounted) _snack('Load error: $e', isError: true);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────────

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
        dateOfBirth: _dobController.text.trim().isEmpty
            ? null
            : _dobController.text.trim(),
        nationality: _nationalityController.text.trim().isEmpty
            ? null
            : _nationalityController.text.trim(),
      );

      if (mounted) {
        _snack(
          widget.editPlayerId != null
              ? 'Player updated successfully!'
              : 'Player created successfully!',
          isError: false,
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (mounted) {
        _snack(e.response?.data['message'] ?? 'Action failed',
            isError: true);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
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
            Expanded(
                child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getTeamItems() {
    return [
      const DropdownMenuItem(value: null, child: Text('No team')),
      ..._teams.map((id) =>
          DropdownMenuItem(value: id, child: Text('Team $id'))),
    ];
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editPlayerId != null;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(isEdit),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAvatarHeader(isEdit),
                  const SizedBox(height: 20),
                  _buildPersonalInfoCard(),
                  const SizedBox(height: 16),
                  _buildRoleCard(),
                  const SizedBox(height: 16),
                  _buildPlayingStyleCard(),
                  const SizedBox(height: 16),
                  _buildTeamJerseyCard(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(isEdit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isEdit) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: _kTextPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? 'Edit Player' : 'New Player',
            style: const TextStyle(
              color: _kTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            isEdit ? 'Update player details' : 'Add to your squad',
            style: const TextStyle(color: _kTextHint, fontSize: 11),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isEdit ? 'EDIT' : 'NEW',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _kBorder),
      ),
    );
  }

  // ── Avatar header ─────────────────────────────────────────────────────────────

  Widget _buildAvatarHeader(bool isEdit) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2), width: 2),
                ),
                child: Icon(Icons.person_rounded,
                    size: 42, color: AppColors.primary),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBorder),
                  boxShadow: const [
                    BoxShadow(
                        color: _kShadow, blurRadius: 6, offset: Offset(0, 2))
                  ],
                ),
                child: Icon(Icons.camera_alt_rounded,
                    size: 14, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isEdit ? 'Update Player Profile' : 'Create Player Profile',
            style: const TextStyle(
              color: _kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Fill in the details below',
            style: TextStyle(color: _kTextHint, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Personal Info card ────────────────────────────────────────────────────────

  Widget _buildPersonalInfoCard() {
    return _SectionCard(
      title: 'Personal Info',
      icon: Icons.person_rounded,
      child: Column(
        children: [
          // Full Name
          TextFormField(
            controller: _nameController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Full Name *',
              icon: Icons.person_rounded,
              hint: 'e.g., Virat Kohli',
            ),
            validator: (v) =>
                v?.trim().isEmpty ?? true ? 'Name is required' : null,
          ),
          const SizedBox(height: _kFieldGap),

          // Phone
          TextFormField(
            controller: _phoneController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Phone Number',
              icon: Icons.phone_rounded,
              hint: '+91 9876543210',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: _kFieldGap),

          // DOB + Nationality row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
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
                    if (picked != null) {
                      _dobController.text =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dobController,
                      style: const TextStyle(
                          fontSize: 13, color: _kTextPrimary),
                      decoration: _fieldDeco(
                        label: 'Date of Birth',
                        icon: Icons.cake_rounded,
                        hint: 'YYYY-MM-DD',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _nationalityController,
                  style: const TextStyle(fontSize: 13, color: _kTextPrimary),
                  decoration: _fieldDeco(
                    label: 'Nationality',
                    icon: Icons.flag_rounded,
                    hint: 'e.g., Indian',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Role card ─────────────────────────────────────────────────────────────────

  Widget _buildRoleCard() {
    return _SectionCard(
      title: 'Player Role',
      icon: Icons.sports_cricket_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: roleOptions.entries.map((e) {
          final selected = _role == e.key;
          return GestureDetector(
            onTap: () => setState(() => _role = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.08)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.primary : _kBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    roleIcons[e.key] ?? Icons.person_rounded,
                    size: 16,
                    color: selected ? AppColors.primary : _kTextHint,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    e.value,
                    style: TextStyle(
                      color:
                          selected ? AppColors.primary : _kTextSecondary,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Playing style card ────────────────────────────────────────────────────────

  Widget _buildPlayingStyleCard() {
    return _SectionCard(
      title: 'Playing Style',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          _WhiteDropdown<String>(
            label: 'Batting Style',
            icon: Icons.sports_cricket_rounded,
            value: _battingStyle,
            items: battingStyleOptions.entries
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _battingStyle = v),
          ),
          const SizedBox(height: _kFieldGap),
          _WhiteDropdown<String>(
            label: 'Bowling Style',
            icon: Icons.sports_baseball_rounded,
            value: _bowlingStyle,
            items: bowlingStyleOptions.entries
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _bowlingStyle = v),
          ),
        ],
      ),
    );
  }

  // ── Team & Jersey card ────────────────────────────────────────────────────────

  Widget _buildTeamJerseyCard() {
    return _SectionCard(
      title: 'Team & Jersey',
      icon: Icons.groups_rounded,
      child: Column(
        children: [
          _WhiteDropdown<String>(
            label: 'Team',
            icon: Icons.groups_rounded,
            value: _teamId,
            items: _getTeamItems(),
            onChanged: (v) => setState(() => _teamId = v),
          ),
          const SizedBox(height: _kFieldGap),
          TextFormField(
            controller: _jerseyController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Jersey Number',
              icon: Icons.tag_rounded,
              hint: 'e.g., 18',
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => _jerseyNumber = int.tryParse(v),
          ),
        ],
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────────

  Widget _buildSubmitButton(bool isEdit) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitPlayer,
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
                children: [
                  Icon(
                      isEdit
                          ? Icons.save_rounded
                          : Icons.person_add_rounded,
                      size: 20),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Update Player' : 'Create Player',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

/// White-theme section card with header
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
          BoxShadow(
              color: _kShadow, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _kBorder),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

/// White-theme dropdown matching the field style
class _WhiteDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;

  const _WhiteDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: Colors.white,
      style: const TextStyle(
          fontSize: 13, color: _kTextPrimary, fontWeight: FontWeight.w500),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _kTextHint, size: 20),
      borderRadius: BorderRadius.circular(12),
      decoration: _fieldDeco(label: label, icon: icon),
      items: items,
      onChanged: onChanged,
    );
  }
}