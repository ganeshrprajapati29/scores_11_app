import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../data/services/user_service.dart';
import 'auth_design.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  String _selectedGender = 'male';
  String _selectedPlayerType = 'batsman';
  String _selectedBattingStyle = 'right-hand';
  String _selectedBowlingStyle = 'right-arm-medium';
  bool _isLoading = false;
  final UserService _userService = UserService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await _userService.updatePlayingStyle(_selectedPlayerType);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']?.toString() ?? 'Profile update failed'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Complete profile',
      subtitle: 'Add your cricket details and build your Scores11 identity.',
      heroImage: 'score 11/Create Match Team 1080 x 420 PNG.png',
      heroIcon: Icons.account_circle_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(Icons.badge_outlined, 'Personal Information'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: AuthDesign.input(label: 'Full Name', hint: 'Enter your full name', icon: Icons.person_outline_rounded),
              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: AuthDesign.input(label: 'Phone Number (Optional)', hint: 'Enter your phone number', icon: Icons.phone_android_rounded),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: AuthDesign.input(label: 'City (Optional)', hint: 'City', icon: Icons.location_city_rounded),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: AuthDesign.input(label: 'State (Optional)', hint: 'State', icon: Icons.map_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _fieldLabel('Gender'),
            Row(
              children: [
                Expanded(
                  child: _pill(
                    label: 'Male',
                    icon: Icons.male_rounded,
                    color: AppColors.primary,
                    selected: _selectedGender == 'male',
                    onTap: () => setState(() => _selectedGender = 'male'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _pill(
                    label: 'Female',
                    icon: Icons.female_rounded,
                    color: const Color(0xFFEC4899),
                    selected: _selectedGender == 'female',
                    onTap: () => setState(() => _selectedGender = 'female'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _pill(
                    label: 'Other',
                    icon: Icons.person_rounded,
                    color: const Color(0xFF7C3AED),
                    selected: _selectedGender == 'other',
                    onTap: () => setState(() => _selectedGender = 'other'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Divider(color: AuthDesign.line),
            const SizedBox(height: 18),
            _sectionHeader(Icons.sports_cricket_rounded, 'Cricket Information'),
            const SizedBox(height: 16),
            _fieldLabel('Player Type'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(
                  label: 'Batsman',
                  icon: Icons.sports_cricket_rounded,
                  color: AppColors.primary,
                  selected: _selectedPlayerType == 'batsman',
                  onTap: () => setState(() => _selectedPlayerType = 'batsman'),
                ),
                _pill(
                  label: 'Bowler',
                  icon: Icons.sports_baseball_rounded,
                  color: const Color(0xFFDC2626),
                  selected: _selectedPlayerType == 'bowler',
                  onTap: () => setState(() => _selectedPlayerType = 'bowler'),
                ),
                _pill(
                  label: 'All-Rounder',
                  icon: Icons.swap_horiz_rounded,
                  color: const Color(0xFFF97316),
                  selected: _selectedPlayerType == 'all-rounder',
                  onTap: () => setState(() => _selectedPlayerType = 'all-rounder'),
                ),
                _pill(
                  label: 'Wicket Keeper',
                  icon: Icons.sports_handball_rounded,
                  color: const Color(0xFF16A34A),
                  selected: _selectedPlayerType == 'wicket-keeper',
                  onTap: () => setState(() => _selectedPlayerType = 'wicket-keeper'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _fieldLabel('Batting Style'),
            Row(
              children: [
                Expanded(
                  child: _pill(
                    label: 'Right Hand',
                    icon: Icons.edit_rounded,
                    color: AppColors.primary,
                    selected: _selectedBattingStyle == 'right-hand',
                    onTap: () => setState(() => _selectedBattingStyle = 'right-hand'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _pill(
                    label: 'Left Hand',
                    icon: Icons.edit_rounded,
                    color: const Color(0xFF16A34A),
                    selected: _selectedBattingStyle == 'left-hand',
                    onTap: () => setState(() => _selectedBattingStyle = 'left-hand'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _fieldLabel('Bowling Style'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(
                  label: 'Right Arm Fast',
                  icon: Icons.sports_baseball_rounded,
                  color: const Color(0xFFDC2626),
                  selected: _selectedBowlingStyle == 'right-arm-fast',
                  onTap: () => setState(() => _selectedBowlingStyle = 'right-arm-fast'),
                ),
                _pill(
                  label: 'Right Arm Medium',
                  icon: Icons.sports_baseball_rounded,
                  color: AppColors.primary,
                  selected: _selectedBowlingStyle == 'right-arm-medium',
                  onTap: () => setState(() => _selectedBowlingStyle = 'right-arm-medium'),
                ),
                _pill(
                  label: 'Left Arm Fast',
                  icon: Icons.sports_baseball_rounded,
                  color: const Color(0xFF16A34A),
                  selected: _selectedBowlingStyle == 'left-arm-fast',
                  onTap: () => setState(() => _selectedBowlingStyle = 'left-arm-fast'),
                ),
                _pill(
                  label: 'Spin',
                  icon: Icons.sports_baseball_rounded,
                  color: const Color(0xFF7C3AED),
                  selected: _selectedBowlingStyle == 'spin',
                  onTap: () => setState(() => _selectedBowlingStyle = 'spin'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AuthDesign.chipBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your profile helps teams find you and builds trust in the community. '
                      'You can update these details anytime from your profile.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AuthDesign.muted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(
              onPressed: _completeProfile,
              label: 'Complete Profile',
              loading: _isLoading,
              icon: Icons.person_add_alt_1_rounded,
              trailingArrow: true,
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 13, color: AuthDesign.muted),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Your information is secure and will never be shared.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AuthDesign.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Small bold section header with an icon chip. Purely presentational.
  Widget _sectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: AuthDesign.chipBg, borderRadius: BorderRadius.circular(9)),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AuthDesign.ink)),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AuthDesign.ink)),
    );
  }

  /// Rounded-rect pill-button selector used for gender / player type /
  /// batting style / bowling style. Purely presentational — callers pass in
  /// the same `setState(() => _selectedX = value)` pattern the previous
  /// chip-based implementation used.
  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color color = AppColors.primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? color : AuthDesign.line, width: selected ? 1.6 : 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AuthDesign.ink,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
