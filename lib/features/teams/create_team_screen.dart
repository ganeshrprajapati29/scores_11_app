import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../../data/services/team_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kRadius = 14.0;
const _kCardRadius = 16.0;
const _kFieldGap = 14.0;
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
  int? maxLines,
}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 13, color: _kTextHint),
      hintStyle: const TextStyle(fontSize: 13, color: _kTextHint),
      prefixIcon: Icon(icon, size: 18, color: _kTextHint),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      alignLabelWithHint: (maxLines ?? 1) > 1,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: (maxLines ?? 1) > 1 ? 14 : 14,
      ),
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

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _teamCityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _coachController = TextEditingController();
  final _homeGroundController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  bool _isLoading = false;
  final TeamService _teamService = TeamService();

  @override
  void dispose() {
    _teamNameController.dispose();
    _shortNameController.dispose();
    _teamCityController.dispose();
    _stateController.dispose();
    _homeGroundController.dispose();
    _coachController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _teamService.createTeam(
        name: _teamNameController.text.trim(),
        shortName: _shortNameController.text.trim().isNotEmpty
            ? _shortNameController.text.trim()
            : null,
        city: _teamCityController.text.trim(),
        state: _stateController.text.trim().isNotEmpty
            ? _stateController.text.trim()
            : null,
        homeGround: _homeGroundController.text.trim().isNotEmpty
            ? _homeGroundController.text.trim()
            : null,
        coach: _coachController.text.trim().isNotEmpty
            ? _coachController.text.trim()
            : null,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        country: _countryController.text,
      );

      if (mounted) {
        _showSnack('Team created successfully!', isError: false);
        final newTeamId = await _teamService
            .getMyTeams()
            .then((teams) => teams.isNotEmpty ? teams.first.id : null);
        if (newTeamId != null) {
          Navigator.pushNamed(context, '/players/search',
              arguments: {'teamId': newTeamId});
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, '/my-teams', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader(),
              const SizedBox(height: 20),
              _buildRequiredSection(),
              const SizedBox(height: 16),
              _buildOptionalSection(),
              const SizedBox(height: 24),
              _buildCreateButton(),
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
        'Create Team',
        style: TextStyle(
          color: _kTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
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
            child: Icon(Icons.groups_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Build Your Team',
                  style: TextStyle(
                    color: _kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Fill in the details to create your cricket team',
                  style: TextStyle(color: _kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Required fields card ─────────────────────────────────────────────────────

  Widget _buildRequiredSection() {
    return _SectionCard(
      title: 'Team Information',
      icon: Icons.emoji_events_rounded,
      child: Column(
        children: [
          // Team Name
          TextFormField(
            controller: _teamNameController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Team Name *',
              icon: Icons.emoji_events_rounded,
              hint: 'e.g., Mumbai Warriors',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter team name';
              }
              if (v.trim().length < 3) {
                return 'Team name must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: _kFieldGap),

          // Short Name
          TextFormField(
            controller: _shortNameController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Short Name (Optional)',
              icon: Icons.short_text_rounded,
              hint: 'e.g., MW',
            ),
          ),
          const SizedBox(height: _kFieldGap),

          // City + State row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _teamCityController,
                  style:
                      const TextStyle(fontSize: 13, color: _kTextPrimary),
                  decoration: _fieldDeco(
                    label: 'City',
                    icon: Icons.location_city_rounded,
                    hint: 'e.g., Mumbai',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  style:
                      const TextStyle(fontSize: 13, color: _kTextPrimary),
                  decoration: _fieldDeco(
                    label: 'State',
                    icon: Icons.map_rounded,
                    hint: 'e.g., Maharashtra',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Optional fields card ─────────────────────────────────────────────────────

  Widget _buildOptionalSection() {
    return _SectionCard(
      title: 'Additional Details',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          // Home Ground
          TextFormField(
            controller: _homeGroundController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Home Ground',
              icon: Icons.stadium_rounded,
              hint: 'e.g., Wankhede Stadium',
            ),
          ),
          const SizedBox(height: _kFieldGap),

          // Coach
          TextFormField(
            controller: _coachController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Coach Name',
              icon: Icons.person_rounded,
              hint: 'e.g., Ravi Shastri',
            ),
          ),
          const SizedBox(height: _kFieldGap),

          // Country
          TextFormField(
            controller: _countryController,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Country',
              icon: Icons.flag_rounded,
            ),
          ),
          const SizedBox(height: _kFieldGap),

          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13, color: _kTextPrimary),
            decoration: _fieldDeco(
              label: 'Description (Optional)',
              icon: Icons.description_rounded,
              hint: 'Tell us about your team…',
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Create button ────────────────────────────────────────────────────────────

  Widget _buildCreateButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createTeam,
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
                  Icon(Icons.groups_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Create Team',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Reusable section card ────────────────────────────────────────────────────

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
          // Header
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}