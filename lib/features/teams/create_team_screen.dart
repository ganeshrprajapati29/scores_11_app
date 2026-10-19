import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../../data/services/team_service.dart';
import '../../../data/services/player_service.dart';
import '../../../data/models/player_model.dart';
import '../../core/utils/friendly_error.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
const _kRadius = 14.0;
const _kCardRadius = 18.0;
const _kFieldGap = 14.0;
const _kBg = Color(0xFFF1F5F9);
const _kBorder = Color(0xFFE2E8F0);
const _kNavy = Color(0xFF1a1a2e);
const _kNavyDeep = Color(0xFF0f3460);
const _kGold = Color(0xFFE8B84B);
const _kGoldLight = Color(0xFFFEF3C7);
const _kTextPrimary = Color(0xFF1E293B);
const _kTextSecondary = Color(0xFF64748B);
const _kTextHint = Color(0xFF94A3B8);
const _kShadow = Color(0x0A000000);

const _roleColors = {
  'BAT': Color(0xFF3B82F6),
  'BWL': Color(0xFFEF4444),
  'AR': Color(0xFF10B981),
  'WK': Color(0xFFF59E0B),
};
const _roleBg = {
  'BAT': Color(0xFFEFF6FF),
  'BWL': Color(0xFFFEF2F2),
  'AR': Color(0xFFECFDF5),
  'WK': Color(0xFFFFFBEB),
};

InputDecoration _fieldDeco({
  required String label,
  required IconData icon,
  String? hint,
  int? maxLines,
}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: _kTextSecondary),
      hintStyle: const TextStyle(fontSize: 13, color: _kTextHint),
      prefixIcon: Icon(icon, size: 18, color: _kTextHint),
      filled: true,
      fillColor: Colors.white,
      alignLabelWithHint: (maxLines ?? 1) > 1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: _kGold, width: 1.8),
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

// ─── Screen ────────────────────────────────────────────────────────────────────
class CreateTeamScreen extends StatefulWidget {
  final bool returnOnCreate;

  const CreateTeamScreen({super.key, this.returnOnCreate = false});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  AnimationController? _progressAnim;
  int _currentStep = 0;
  final int _totalSteps = 3;

  // ── Team Info ─────────────────────────────────────────────────────────────
  final TextEditingController _teamNameCtrl = TextEditingController();
  final TextEditingController _shortNameCtrl = TextEditingController();
  final TextEditingController _coachCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _countryCtrl =
      TextEditingController(text: 'India');
  String _selectedState = 'Maharashtra';

  // ── Logo ──────────────────────────────────────────────────────────────────
  File? _logoFile;

  // ── Players ───────────────────────────────────────────────────────────────
  List<Player?> _teamPlayers = List.filled(11, null);
  Player? _captain;
  Player? _viceCaptain;

  // ── Player Search ─────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  List<Player> _searchResults = [];
  bool _isLoadingPlayers = false;
  String _searchMessage = '';

  // ── Instant Player ────────────────────────────────────────────────────────
  bool _showInstantPlayer = false;
  final TextEditingController _instantNameCtrl = TextEditingController();
  final TextEditingController _instantEmailCtrl = TextEditingController();
  final TextEditingController _instantPhoneCtrl = TextEditingController();
  String _selRole = 'BAT';
  String _selBatting = 'RHB';
  String? _selBowling;
  bool _isCreatingPlayer = false;

  // ── Submit ────────────────────────────────────────────────────────────────
  bool _isSubmitting = false;

  final TeamService _teamService = TeamService();
  final PlayerService _playerService = PlayerService();

  // ── Constants ─────────────────────────────────────────────────────────────
  final List<String> _roleOptions = ['BAT', 'BWL', 'AR', 'WK'];
  final Map<String, String> _roleLabels = {
    'BAT': 'Batsman',
    'BWL': 'Bowler',
    'AR': 'All-Rounder',
    'WK': 'Wicket Keeper'
  };
  final List<String> _battingOpts = ['RHB', 'LHB'];
  final Map<String, String> _battingLabels = {
    'RHB': 'Right Hand Bat',
    'LHB': 'Left Hand Bat'
  };
  final List<String> _bowlingOpts = ['RFM', 'RWM', 'LFM', 'LWM', 'LA', 'OA'];
  final Map<String, String> _bowlingLabels = {
    'RFM': 'Right Arm Fast',
    'RWM': 'Right Arm Medium',
    'LFM': 'Left Arm Fast',
    'LWM': 'Left Arm Medium',
    'LA': 'Leg Spin',
    'OA': 'Off Spin',
  };
  final List<String> _stateOptions = [
    'Maharashtra',
    'Delhi',
    'Karnataka',
    'Uttar Pradesh',
    'Tamil Nadu',
    'Gujarat',
    'West Bengal',
    'Rajasthan',
    'Punjab',
    'Haryana',
    'Telangana',
    'Andhra Pradesh',
    'Kerala',
    'Madhya Pradesh',
    'Bihar',
  ];
  final List<String> _stepTitles = ['Team Info', 'Add Players', 'Leadership'];
  final List<IconData> _stepIcons = [
    Icons.info_outline_rounded,
    Icons.people_alt_outlined,
    Icons.military_tech_outlined,
  ];

  // ──────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _progressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnim!.animateTo(1 / _totalSteps);
    _searchMessage = 'Search players to add.';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnim?.dispose();
    _teamNameCtrl.dispose();
    _shortNameCtrl.dispose();
    _coachCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _searchCtrl.dispose();
    _instantNameCtrl.dispose();
    _instantEmailCtrl.dispose();
    _instantPhoneCtrl.dispose();
    super.dispose();
  }

  // ─── Navigation ────────────────────────────────────────────────────────────
  Future<void> _goNext() async {
    if (_currentStep == 0) {
      if (_teamNameCtrl.text.trim().isEmpty) {
        _toast('Team name is required!', isError: true);
        return;
      }
    }
    if (_currentStep == 1) {
      final filled = _teamPlayers.where((p) => p != null).length;
      if (filled < 2) {
        _toast('Add at least 2 players to continue!', isError: true);
        return;
      }
    }
    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
    _progressAnim?.animateTo((_currentStep + 1) / _totalSteps);
  }

  Future<void> _goBack() async {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
    _progressAnim?.animateTo((_currentStep + 1) / _totalSteps);
  }

  // ─── Player Search ─────────────────────────────────────────────────────────
  Future<void> _searchPlayers(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _isLoadingPlayers = false;
        _searchResults = [];
        _searchMessage = 'Search players to add.';
      });
      return;
    }
    setState(() {
      _isLoadingPlayers = true;
      _searchMessage = '';
    });
    try {
      final players = await _playerService.searchPlayers(query, limit: 50);
      setState(() {
        _searchResults = players;
        _searchMessage =
            players.isEmpty ? 'No players found. Create one below.' : '';
        _isLoadingPlayers = false;
      });
    } catch (e) {
      setState(() {
        _searchMessage = friendlyError(e, fallback: 'Something went wrong. Please try again.');
        _searchResults = [];
        _isLoadingPlayers = false;
      });
    }
  }

  // ─── Player Management ─────────────────────────────────────────────────────
  void _addToTeam(Player player) {
    if (_teamPlayers.any((p) => p?.id == player.id)) {
      _toast('${player.name} already in team!', isError: true);
      return;
    }
    final idx = _teamPlayers.indexWhere((p) => p == null);
    setState(() {
      if (idx != -1) {
        _teamPlayers[idx] = player;
      } else {
        _teamPlayers.add(player);
      }
    });
    _toast('${player.name} added! ✓');
  }

  void _removeFromTeam(int index) {
    final p = _teamPlayers[index];
    if (p == null) return;
    setState(() {
      _teamPlayers[index] = null;
      if (_captain?.id == p.id) _captain = null;
      if (_viceCaptain?.id == p.id) _viceCaptain = null;
    });
    _toast('${p.name} removed');
  }

  void _setCaptain(Player player) {
    if (_viceCaptain?.id == player.id) {
      _toast('Already Vice-Captain!', isError: true);
      return;
    }
    setState(() => _captain = player);
    _toast('${player.name} is now Captain 🏆');
  }

  void _setViceCaptain(Player player) {
    if (_captain?.id == player.id) {
      _toast('Already Captain!', isError: true);
      return;
    }
    setState(() => _viceCaptain = player);
    _toast('${player.name} is now Vice-Captain ⭐');
  }

  // ─── Instant Player ────────────────────────────────────────────────────────
  Future<void> _createInstantPlayer() async {
    if (_instantNameCtrl.text.trim().isEmpty) {
      _toast('Enter player name', isError: true);
      return;
    }
    setState(() => _isCreatingPlayer = true);
    try {
      final np = await _playerService.createPlayer(
        name: _instantNameCtrl.text.trim(),
        role: _selRole.toLowerCase(),
        battingStyle: _selBatting.toLowerCase(),
        bowlingStyle: _selBowling?.toLowerCase(),
        email: _instantEmailCtrl.text.trim(),
        phone: _instantPhoneCtrl.text.trim(),
      );
      _instantNameCtrl.clear();
      _instantEmailCtrl.clear();
      _instantPhoneCtrl.clear();
      setState(() {
        _showInstantPlayer = false;
        _selRole = 'BAT';
        _selBatting = 'RHB';
        _selBowling = null;
      });
      await _searchPlayers(_searchCtrl.text);
      if (np.id != null) _addToTeam(np);
      _toast('${np.name} created & added ⚡');
    } catch (e) {
      _toast(friendlyError(e, fallback: 'Something went wrong. Please try again.'), isError: true);
    } finally {
      setState(() => _isCreatingPlayer = false);
    }
  }

  // ─── Logo ──────────────────────────────────────────────────────────────────
  Future<void> _pickLogo() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => _logoFile = File(f.path));
  }

  // ─── Submit ────────────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    final filled = _teamPlayers.where((p) => p != null).toList();
    if (filled.length < 2) {
      _toast('Need at least 2 players!', isError: true);
      return;
    }
    if (_captain == null || _viceCaptain == null) {
      _toast('Select Captain & Vice-Captain!', isError: true);
      return;
    }
    if (_captain!.id == _viceCaptain!.id) {
      _toast('C and VC must be different!', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final team = await _teamService.createTeam(
        name: _teamNameCtrl.text.trim(),
        shortName: _shortNameCtrl.text.trim().isNotEmpty
            ? _shortNameCtrl.text.trim()
            : null,
        coach:
            _coachCtrl.text.trim().isNotEmpty ? _coachCtrl.text.trim() : null,
        description:
            _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
        state: _selectedState,
        country: _countryCtrl.text.trim().isNotEmpty
            ? _countryCtrl.text.trim()
            : null,
        players: filled.map((p) => p!.id!).toList(),
        captainId: _captain!.id!,
        viceCaptainId: _viceCaptain!.id!,
      );
      if (_logoFile != null && team.id != null) {
        try {
          await _teamService.uploadTeamLogo(team.id!, _logoFile!);
        } catch (_) {}
      }
      _toast('Team created successfully! 🎉');
      if (mounted) {
        if (widget.returnOnCreate) {
          Navigator.pop(context, team);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/my-teams', (_) => false);
        }
      }
    } catch (e) {
      _toast(friendlyError(e, fallback: 'Something went wrong. Please try again.'), isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor:
          isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final int filledCount = _teamPlayers.where((p) => p != null).length;
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(filledCount),
          _buildStepIndicator(),
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep0(),
                  _buildStep1(),
                  _buildStep2(),
                ],
              ),
            ),
          ),
          _buildBottomBar(filledCount),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(int filledCount) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavy, _kNavyDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: DecorationImage(
          image: AssetImage('score 11/Team  cover page.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          opacity: 0.20,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 8,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps · ${_stepTitles[_currentStep]}',
                  style: const TextStyle(
                    color: _kGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGold.withOpacity(0.3)),
            ),
            child: Text(
              '$filledCount Players',
              style: const TextStyle(
                  color: _kGold, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step Indicator ────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Container(
      color: _kNavy,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            final bool done = _currentStep > (i ~/ 2);
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                height: 2,
                decoration: BoxDecoration(
                  color: done ? _kGold : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final int stepIdx = i ~/ 2;
          final bool isActive = _currentStep == stepIdx;
          final bool isDone = _currentStep > stepIdx;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 38 : 32,
            height: isActive ? 38 : 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  (isDone || isActive) ? _kGold : Colors.white.withOpacity(0.1),
              border: Border.all(
                color: (isDone || isActive)
                    ? _kGold
                    : Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: _kGold.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 1)
                    ]
                  : [],
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded, size: 16, color: _kNavy)
                  : Icon(
                      _stepIcons[stepIdx],
                      size: isActive ? 18 : 15,
                      color: isActive ? _kNavy : Colors.white.withOpacity(0.5),
                    ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Bottom Navigation Bar ─────────────────────────────────────────────────
  Widget _buildBottomBar(int filledCount) {
    final bool isLastStep = _currentStep == _totalSteps - 1;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _kBorder)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _goBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kBorder, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _kTextSecondary,
                      fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 4,
            child: isLastStep
                ? ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGold,
                      foregroundColor: _kNavy,
                      disabledBackgroundColor: _kGold.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kNavy),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 19),
                              SizedBox(width: 8),
                              Text('Create Team',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900)),
                            ],
                          ),
                  )
                : ElevatedButton(
                    onPressed: _goNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kNavy,
                      foregroundColor: _kGold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 0 — Team Info
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          _sectionCard(
            title: 'Team Details',
            icon: Icons.emoji_events_outlined,
            color1: _kNavy,
            color2: _kNavyDeep,
            child: Column(
              children: [
                TextFormField(
                  controller: _teamNameCtrl,
                  style: const TextStyle(fontSize: 14, color: _kTextPrimary),
                  decoration: _fieldDeco(
                    label: 'Team Name *',
                    icon: Icons.emoji_events_rounded,
                    hint: 'Enter team name',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: _kFieldGap),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _shortNameCtrl,
                        style:
                            const TextStyle(fontSize: 14, color: _kTextPrimary),
                        decoration: _fieldDeco(
                          label: 'Short Name',
                          icon: Icons.short_text_rounded,
                          hint: 'MI, CSK...',
                        ),
                        maxLength: 10,
                        buildCounter: (_,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _coachCtrl,
                        style:
                            const TextStyle(fontSize: 14, color: _kTextPrimary),
                        decoration: _fieldDeco(
                          label: 'Coach',
                          icon: Icons.person_outline_rounded,
                          hint: 'Coach name',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _kFieldGap),
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(fontSize: 14, color: _kTextPrimary),
                  decoration: _fieldDeco(
                    label: 'Description',
                    icon: Icons.description_outlined,
                    hint: 'Tell about your team...',
                    maxLines: 3,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Location',
            icon: Icons.location_on_outlined,
            color1: _kNavyDeep,
            color2: const Color(0xFF533483),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityCtrl,
                        style:
                            const TextStyle(fontSize: 14, color: _kTextPrimary),
                        decoration: _fieldDeco(
                          label: 'City',
                          icon: Icons.location_city_rounded,
                          hint: 'Mumbai',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedState,
                        decoration: InputDecoration(
                          labelText: 'State',
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kTextSecondary,
                          ),
                          prefixIcon: const Icon(Icons.map_rounded,
                              size: 18, color: _kTextHint),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
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
                            borderSide:
                                const BorderSide(color: _kGold, width: 1.8),
                          ),
                        ),
                        items: _stateOptions
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedState = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _kFieldGap),
                TextFormField(
                  controller: _countryCtrl,
                  style: const TextStyle(fontSize: 14, color: _kTextPrimary),
                  decoration: _fieldDeco(
                    label: 'Country',
                    icon: Icons.flag_rounded,
                    hint: 'India',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Team Logo',
            icon: Icons.cloud_upload_outlined,
            color1: const Color(0xFFD97706),
            color2: const Color(0xFFF59E0B),
            child: GestureDetector(
              onTap: _pickLogo,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 130,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _logoFile != null ? _kGold : _kBorder, width: 2),
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                ),
                child: _logoFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_logoFile!,
                            width: double.infinity,
                            height: 130,
                            fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _kGold.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: _kGold,
                                size: 26),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Tap to upload logo',
                            style: TextStyle(
                                fontSize: 13,
                                color: _kTextSecondary,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'PNG, JPG up to 5MB',
                            style: TextStyle(fontSize: 11, color: _kTextHint),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (_teamNameCtrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTeamPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamPreview() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kNavy, _kNavyDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: const DecorationImage(
          image: AssetImage('score 11/Team  cover page.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          opacity: 0.18,
        ),
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
              color: _kNavy.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  const LinearGradient(colors: [_kGold, Color(0xFFF59E0B)]),
              boxShadow: [
                BoxShadow(color: _kGold.withOpacity(0.4), blurRadius: 12)
              ],
            ),
            child: _logoFile != null
                ? ClipOval(child: Image.file(_logoFile!, fit: BoxFit.cover))
                : ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'score 11/Team Profile logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                        Center(
                          child: Text(
                            _teamNameCtrl.text.trim()[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _teamNameCtrl.text.trim(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16),
                ),
                if (_shortNameCtrl.text.isNotEmpty)
                  Text(
                    _shortNameCtrl.text,
                    style: const TextStyle(
                        color: _kGold,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                if (_cityCtrl.text.isNotEmpty)
                  Text(
                    '${_cityCtrl.text}, $_selectedState',
                    style:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
              ],
            ),
          ),
          const Icon(Icons.sports_cricket, color: _kGold, size: 22),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 — Add Players
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          _sectionCard(
            title: 'Search Players',
            icon: Icons.search_rounded,
            color1: const Color(0xFF7C3AED),
            color2: const Color(0xFF5B21B6),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _showInstantPlayer = !_showInstantPlayer),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _showInstantPlayer ? _kGoldLight : _kGold,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGold),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showInstantPlayer
                              ? Icons.close_rounded
                              : Icons.person_add_rounded,
                          size: 17,
                          color: _showInstantPlayer
                              ? const Color(0xFF92400E)
                              : _kNavy,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showInstantPlayer
                              ? 'Cancel'
                              : '⚡  Create Instant Player',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _showInstantPlayer
                                ? const Color(0xFF92400E)
                                : _kNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _showInstantPlayer
                      ? _buildInstantPlayerForm()
                      : const SizedBox.shrink(),
                ),
                if (!_showInstantPlayer) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 13, color: _kTextPrimary),
                    decoration: _fieldDeco(
                      label: 'Search all players',
                      icon: Icons.search_rounded,
                      hint: 'Search by name, email, or mobile...',
                    ),
                    onChanged: _searchPlayers,
                  ),
                  const SizedBox(height: 12),
                  if (_searchMessage.isNotEmpty) _infoBox(_searchMessage),
                  if (_isLoadingPlayers)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _kGold),
                      ),
                    )
                  else
                    ..._searchResults.take(30).map((p) => _playerSearchRow(p)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildLineupCard(),
        ],
      ),
    );
  }

  Widget _buildInstantPlayerForm() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kGoldLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          const Text(
            'Quick Create Player ⚡',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF92400E)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _instantNameCtrl,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Player Name *',
              hintStyle: const TextStyle(color: _kTextHint),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFFDE68A)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFFDE68A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kGold, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _instantEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 13),
                  decoration: _instantInputDecoration('Email (optional)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _instantPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 13),
                  decoration: _instantInputDecoration('Mobile (optional)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniDropdown<String>(
                  value: _selRole,
                  items: _roleOptions,
                  labelOf: (v) => _roleLabels[v] ?? v,
                  onChanged: (v) {
                    if (v != null) setState(() => _selRole = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniDropdown<String>(
                  value: _selBatting,
                  items: _battingOpts,
                  labelOf: (v) => _battingLabels[v] ?? v,
                  onChanged: (v) {
                    if (v != null) setState(() => _selBatting = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            value: _selBowling,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Bowling Style (Optional)',
              hintStyle: const TextStyle(fontSize: 12, color: _kTextHint),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFFDE68A)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFFDE68A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kGold, width: 1.5),
              ),
            ),
            items: _bowlingOpts
                .map((b) => DropdownMenuItem<String?>(
                      value: b,
                      child: Text(_bowlingLabels[b] ?? b,
                          style: const TextStyle(fontSize: 12)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selBowling = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCreatingPlayer ? null : _createInstantPlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isCreatingPlayer
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create & Add to Team ⚡',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _instantInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: _kTextHint),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFDE68A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFDE68A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kGold, width: 1.5),
      ),
    );
  }

  Widget _playerSearchRow(Player player) {
    final bool isInTeam = _teamPlayers.any((p) => p?.id == player.id);
    final String role = player.role?.toUpperCase() ?? 'BAT';
    final Color roleColor = _roleColors[role] ?? const Color(0xFF3B82F6);
    final Color roleBg = _roleBg[role] ?? const Color(0xFFEFF6FF);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: roleBg,
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: roleBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(role,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: roleColor)),
                ),
              ],
            ),
          ),
          isInTeam
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded,
                          size: 12, color: Color(0xFF059669)),
                      SizedBox(width: 4),
                      Text('Added',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669))),
                    ],
                  ),
                )
              : ElevatedButton(
                  onPressed: () => _addToTeam(player),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(70, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('+ Add',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
        ],
      ),
    );
  }

  Widget _buildLineupCard() {
    final int filledCount = _teamPlayers.where((p) => p != null).length;
    return _sectionCard(
      title: 'Team Lineup · $filledCount Players',
      icon: Icons.people_alt_rounded,
      color1: const Color(0xFF059669),
      color2: const Color(0xFF047857),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 600 ? 3 : 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.74,
            ),
            itemCount: _teamPlayers.length,
            itemBuilder: (ctx, i) =>
                _playerSlotCard(_teamPlayers[i], i, showCaptainButtons: false),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => setState(() => _teamPlayers.add(null)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Player Slot',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          if (filledCount < 2) ...[
            const SizedBox(height: 10),
            _infoBox('⚠️  Add at least 2 players ($filledCount/2 minimum)',
                isWarning: true),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2 — Leadership
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStep2() {
    final List<Player> filled =
        _teamPlayers.where((p) => p != null).cast<Player>().toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kNavy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kNavy.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kGold.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.military_tech_outlined,
                      color: _kGold, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tap  C  to assign Captain and  VC  to assign Vice-Captain.',
                    style: TextStyle(
                        fontSize: 13,
                        color: _kTextSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Select Captain & Vice-Captain',
            icon: Icons.emoji_events_outlined,
            color1: _kNavy,
            color2: _kNavyDeep,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 3 : 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.64,
              ),
              itemCount: filled.length,
              itemBuilder: (ctx, i) {
                final int idx = _teamPlayers.indexOf(filled[i]);
                return _playerSlotCard(filled[i], idx,
                    showCaptainButtons: true);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _leaderCard(
                  label: 'Captain',
                  icon: '🏆',
                  player: _captain,
                  color: _kGold,
                  bg: _kGoldLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _leaderCard(
                  label: 'Vice-Captain',
                  icon: '⭐',
                  player: _viceCaptain,
                  color: const Color(0xFF3B82F6),
                  bg: const Color(0xFFEFF6FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Squad Summary',
            icon: Icons.bar_chart_rounded,
            color1: const Color(0xFF533483),
            color2: const Color(0xFF7C3AED),
            child: Column(
              children: <Widget>[
                ..._roleOptions.map((role) {
                  final int count = filled
                      .where((p) => _normalizeRole(p.role) == role)
                      .length;
                  final Color color =
                      _roleColors[role] ?? const Color(0xFF3B82F6);
                  final Color bg = _roleBg[role] ?? const Color(0xFFEFF6FF);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _roleLabels[role] ?? role,
                            style: const TextStyle(
                                fontSize: 13,
                                color: _kTextSecondary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            '$count',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(color: _kBorder, height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Players',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _kTextPrimary,
                            fontSize: 14),
                      ),
                    ),
                    Text(
                      '${filled.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: _kNavy),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderCard({
    required String label,
    required String icon,
    required Player? player,
    required Color color,
    required Color bg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(
            color: player != null ? color.withOpacity(0.3) : _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: player != null
          ? Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        LinearGradient(colors: [color.withOpacity(0.8), color]),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)
                    ],
                  ),
                  child: Center(
                    child: Text(
                      player.name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  player.name.split(' ').take(2).join(' '),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w700)),
              ],
            )
          : Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(height: 10),
                Text(
                  'No $label',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kTextHint),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap C / VC on a player',
                  style: TextStyle(
                      fontSize: 10, color: _kTextHint.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  // ─── Player Slot Card ──────────────────────────────────────────────────────
  Widget _playerSlotCard(Player? player, int index,
      {required bool showCaptainButtons}) {
    final bool isCap = _captain != null && _captain!.id == player?.id;
    final bool isVc = _viceCaptain != null && _viceCaptain!.id == player?.id;
    final String role = player?.role?.toUpperCase() ?? 'BAT';
    final Color roleColor = _roleColors[role] ?? const Color(0xFF3B82F6);

    if (player == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder, width: 2),
          color: const Color(0xFFF8FAFC),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_alt_1_outlined,
                size: 24, color: _kTextHint.withOpacity(0.5)),
            const SizedBox(height: 6),
            Text('Slot ${index + 1}',
                style: const TextStyle(
                    fontSize: 10,
                    color: _kTextHint,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [_kNavy, _kNavyDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isCap
              ? _kGold
              : isVc
                  ? const Color(0xFF60A5FA)
                  : Colors.transparent,
          width: (isCap || isVc) ? 2 : 0,
        ),
        boxShadow: [
          BoxShadow(
              color: _kNavy.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 5,
            left: 7,
            child: Text(
              '#${index + 1}',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.4)),
            ),
          ),
          if (isCap || isVc)
            Positioned(
              top: 3,
              right: 3,
              child: Text(isCap ? '🏆' : '⭐',
                  style: const TextStyle(fontSize: 13)),
            ),
          Positioned(
            top: 4,
            left: 4,
            child: GestureDetector(
              onTap: () => _removeFromTeam(index),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 10, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: roleColor.withOpacity(0.2),
                    border: Border.all(color: roleColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      player.name[0].toUpperCase(),
                      style: TextStyle(
                          color: roleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  player.name.split(' ').take(2).join(' '),
                  style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(role,
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: roleColor)),
                ),
                if (showCaptainButtons) ...[
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _capBtn(
                          label: 'C',
                          active: isCap,
                          color: _kGold,
                          onTap: () => _setCaptain(player)),
                      const SizedBox(width: 4),
                      _capBtn(
                          label: 'VC',
                          active: isVc,
                          color: const Color(0xFF60A5FA),
                          onTap: () => _setViceCaptain(player)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _capBtn({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: active ? color : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: active ? color : Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: active ? _kNavy : Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  String _normalizeRole(String? value) {
    final raw = (value ?? '').trim().toUpperCase().replaceAll('_', ' ');
    if (raw == 'BAT' || raw.contains('BATSMAN') || raw.contains('BATTER')) {
      return 'BAT';
    }
    if (raw == 'BWL' || raw.contains('BOWL')) return 'BWL';
    if (raw == 'AR' || raw.contains('ALL')) return 'AR';
    if (raw == 'WK' || raw.contains('WICKET')) return 'WK';
    return 'BAT';
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color1,
    required Color color2,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 12, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color1, color2],
                begin: Alignment.topLeft,
                end: Alignment.topRight,
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_kCardRadius)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _infoBox(String msg, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF7ED) : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWarning ? const Color(0xFFFED7AA) : const Color(0xFFBAE6FD),
        ),
      ),
      child: Text(
        msg,
        style: TextStyle(
          fontSize: 12,
          color: isWarning ? const Color(0xFFD97706) : const Color(0xFF0369A1),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _miniDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFDE68A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFDE68A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kGold, width: 1.5),
        ),
      ),
      items: items
          .map((i) => DropdownMenuItem<T>(
                value: i,
                child: Text(labelOf(i),
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
