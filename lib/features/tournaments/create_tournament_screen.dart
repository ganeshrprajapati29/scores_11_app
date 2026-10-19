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
import '../../core/utils/friendly_error.dart';

// ── Design tokens (compile-time constants — no runtime cost) ──────────────────
const _white       = Color(0xFFFFFFFF);
const _pageBg      = Color(0xFFF4F5F8);
const _fieldBg     = Color(0xFFF4F5F8);
const _border      = Color(0xFFE4E8F0);
const _green       = Color(0xFF1B8A4E);
const _greenBg     = Color(0xFFE6F5ED);
const _textPrimary = Color(0xFF0D1B2A);
const _textMuted   = Color(0xFF8A8F9C);
const _blue        = Color(0xFF2563EB);
const _blueBg      = Color(0xFFEFF4FF);
const _cardShadow  = Color(0x08000000);

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen>
    with SingleTickerProviderStateMixin {

  // ── Controllers ──────────────────────────────────────────────────────────────
  final _formKey              = GlobalKey<FormState>();
  final _nameController       = TextEditingController();
  final _shortNameController  = TextEditingController();
  final _organizerController  = TextEditingController();
  final _venueController      = TextEditingController();
  final _descController       = TextEditingController();
  final _entryFeeController   = TextEditingController();
  final _prizeMoneyController = TextEditingController();
  final _totalTeamsController = TextEditingController(text: '10');

  // ── State ────────────────────────────────────────────────────────────────────
  String    _format    = 'T20';
  String    _type      = 'LEAGUE';
  DateTime? _startDate;
  DateTime? _endDate;
  bool      _isPaid    = false;
  bool      _isLoading = false;

  // ── Animation — nullable to avoid LateInitializationError ────────────────────
  AnimationController? _animCtrl;
  Animation<double>?   _fadeAnim;

  final TournamentService _tournamentService = TournamentService();

  // ────────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl!, curve: Curves.easeOut);
    _animCtrl!.forward();
  }

  @override
  void dispose() {
    _animCtrl?.dispose();
    _nameController.dispose();
    _shortNameController.dispose();
    _organizerController.dispose();
    _venueController.dispose();
    _descController.dispose();
    _entryFeeController.dispose();
    _prizeMoneyController.dispose();
    _totalTeamsController.dispose();
    super.dispose();
  }

  // ── Date pickers ─────────────────────────────────────────────────────────────
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => _pickerTheme(child),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (_startDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => _pickerTheme(child),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Widget _pickerTheme(Widget? child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: _green,
            onPrimary: _white,
            surface: _white,
          ),
          dialogBackgroundColor: _white,
        ),
        child: child!,
      );

  // ── Submit ───────────────────────────────────────────────────────────────────
  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final tournament = await _tournamentService.createTournament(
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim().isNotEmpty
            ? _shortNameController.text.trim()
            : null,
        format: _format,
        type: _type,
        startDate: _startDate!,
        endDate: _endDate!,
        venue: _venueController.text.trim(),
        totalTeams: int.tryParse(_totalTeamsController.text) ?? 10,
        entryFee: double.tryParse(_entryFeeController.text) ?? null,
        prizeMoney: double.tryParse(_prizeMoneyController.text) ?? null,
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tournament.name} created successfully!'),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e, fallback: 'Something went wrong. Please try again.')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ────────────────────────────── UI Helpers ───────────────────────────────────

  String _fmtDate(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';

  /// Dropdown InputDecoration — consistent with field style
  InputDecoration _dropDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: _textMuted, size: 19),
        filled: true,
        fillColor: _fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 0.8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
        ),
      );

  /// Section header with green icon badge + title
  Widget _sectionHeader(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 9, top: 2),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _greenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _green, size: 15),
            ),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      );

  /// White card with subtle shadow + border
  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 0.8),
          boxShadow: const [
            BoxShadow(
                color: _cardShadow, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: child,
      );

  /// Animated date selector tile
  Widget _dateTile({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final has = value != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: has ? _greenBg : _fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: has ? _green.withOpacity(0.4) : _border,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: has ? _green : _textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: has ? _green : _textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    has ? _fmtDate(value) : 'Tap to select',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: has ? _textPrimary : _textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: has ? _green : _textMuted,
            ),
          ],
        ),
      ),
    );
  }

  /// Animated paid toggle row
  Widget _paidToggle() => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _isPaid ? _greenBg : _fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isPaid ? _green.withOpacity(0.35) : _border,
            width: 0.8,
          ),
        ),
        child: SwitchListTile.adaptive(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          title: Text(
            'Paid Tournament',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: _isPaid ? _green : _textPrimary,
            ),
          ),
          subtitle: const Text(
            'Enable entry fees and prize money',
            style: TextStyle(fontSize: 11.5, color: _textMuted),
          ),
          value: _isPaid,
          activeColor: _green,
          onChanged: (v) => setState(() => _isPaid = v),
        ),
      );

  /// Blue info banner at the bottom
  Widget _infoBanner() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _blueBg,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: _blue.withOpacity(0.2), width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: _blue, size: 15),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tournament will be published and teams can register immediately after creation.',
                style: TextStyle(
                  fontSize: 12,
                  color: _blue,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq   = MediaQuery.of(context);
    final w    = mq.size.width;

    // Responsive padding: phone / large-phone / tablet / desktop
    final double hPad = w > 900
        ? w * 0.18
        : w > 720
            ? w * 0.10
            : w > 500
                ? w * 0.06
                : 16.0;

    final Animation<double> fade =
        _fadeAnim ?? const AlwaysStoppedAnimation<double>(1.0);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: CustomAppBar(
        title: 'Create Tournament',
        showBackButton: true,
      ),
      body: FadeTransition(
        opacity: fade,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── BASIC INFO ────────────────────────────────────────────
                _sectionHeader('Basic Information', Icons.emoji_events_rounded),
                _card(
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Tournament Name *',
                        prefixIcon: Icons.emoji_events_outlined,
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _shortNameController,
                        labelText: 'Short Name (Optional)',
                        prefixIcon: Icons.short_text_rounded,
                        hintText: 'IPL, Blast etc.',
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _organizerController,
                        labelText: 'Organizer *',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: Validators.required,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── FORMAT & TYPE ─────────────────────────────────────────
                _sectionHeader('Format & Type', Icons.sports_cricket_rounded),
                _card(
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _format,
                          decoration: _dropDeco(
                              'Format *', Icons.sports_cricket_rounded),
                          dropdownColor: _white,
                          borderRadius: BorderRadius.circular(12),
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                          // Must match the backend's tournament formats.
                          items: const [
                            DropdownMenuItem(value: 'T20', child: Text('T20')),
                            DropdownMenuItem(value: 'T10', child: Text('T10')),
                            DropdownMenuItem(value: 'ODI', child: Text('ODI')),
                            DropdownMenuItem(
                                value: 'CUSTOM', child: Text('Custom overs')),
                          ],
                          onChanged: (v) =>
                              setState(() => _format = v ?? 'T20'),
                          validator: Validators.required,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _type,
                          decoration:
                              _dropDeco('Type *', Icons.category_outlined),
                          dropdownColor: _white,
                          borderRadius: BorderRadius.circular(12),
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                          // League = round robin (every team plays each other).
                          items: const [
                            DropdownMenuItem(
                                value: 'LEAGUE', child: Text('League (round robin)')),
                            DropdownMenuItem(
                                value: 'KNOCKOUT', child: Text('Knockout')),
                            DropdownMenuItem(
                                value: 'HYBRID', child: Text('League + Knockout')),
                          ],
                          onChanged: (v) =>
                              setState(() => _type = v ?? 'LEAGUE'),
                          validator: Validators.required,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── SCHEDULE ──────────────────────────────────────────────
                _sectionHeader('Schedule', Icons.date_range_rounded),
                _card(
                  child: Row(
                    children: [
                      Expanded(
                        child: _dateTile(
                          label: 'Start Date *',
                          value: _startDate,
                          onTap: _selectStartDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dateTile(
                          label: 'End Date *',
                          value: _endDate,
                          onTap: _selectEndDate,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── VENUE & TEAMS ─────────────────────────────────────────
                _sectionHeader('Venue & Teams', Icons.location_on_rounded),
                _card(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          controller: _venueController,
                          labelText: 'Venue *',
                          prefixIcon: Icons.location_on_outlined,
                          validator: Validators.required,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          controller: _totalTeamsController,
                          labelText: 'Total Teams *',
                          prefixIcon: Icons.groups_outlined,
                          keyboardType: TextInputType.number,
                          validator: Validators.requiredNumber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── ENTRY & PRIZE ─────────────────────────────────────────
                _sectionHeader('Entry & Prize', Icons.monetization_on_rounded),
                _card(
                  child: Column(
                    children: [
                      _paidToggle(),
                      if (_isPaid) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _entryFeeController,
                                labelText: 'Entry Fee (\$)',
                                prefixIcon: Icons.attach_money_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomTextField(
                                controller: _prizeMoneyController,
                                labelText: 'Prize Money (\$)',
                                prefixIcon: Icons.emoji_events_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── DESCRIPTION ───────────────────────────────────────────
                _sectionHeader('Description', Icons.description_rounded),
                _card(
                  child: CustomTextField(
                    controller: _descController,
                    labelText: 'Description (Optional)',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(height: 26),

                // ── SUBMIT BUTTON ─────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: CustomButton(
                    text: 'Create Tournament',
                    icon: Icons.emoji_events_rounded,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _createTournament,
                  ),
                ),
                const SizedBox(height: 14),

                // ── INFO BANNER ───────────────────────────────────────────
                _infoBanner(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
