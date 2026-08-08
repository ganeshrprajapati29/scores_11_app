import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/team_service.dart';
import '../../core/utils/friendly_error.dart';

class TeamInviteJoinScreen extends StatefulWidget {
  final String code;

  const TeamInviteJoinScreen({super.key, required this.code});

  @override
  State<TeamInviteJoinScreen> createState() => _TeamInviteJoinScreenState();
}

class _TeamInviteJoinScreenState extends State<TeamInviteJoinScreen> {
  final TeamService _teamService = TeamService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  Map<String, dynamic>? _invite;
  bool _isLoading = true;
  bool _isJoining = false;
  String? _error;
  String _role = 'batsman';

  static const Color _primary = Color(0xFF1A1A2E);
  static const Color _accent = Color(0xFF4F8EF7);
  static const Color _bg = Color(0xFFF8F9FC);
  static const Color _border = Color(0xFFE8ECF4);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadInvite();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInvite() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final invite = await _teamService.getInviteInfo(widget.code);
      setState(() => _invite = invite);
    } catch (e) {
      setState(() => _error = friendlyError(e, fallback: 'Invite load nahi ho paaya.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinTeam() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || (email.isEmpty && phone.isEmpty)) {
      _showMessage('Name and mobile/email required', isError: true);
      return;
    }

    setState(() => _isJoining = true);
    try {
      await _teamService.joinByInvite(
        widget.code,
        name: name,
        email: email,
        phone: phone,
        role: _role,
      );
      if (!mounted) return;
      _showMessage('Team joined successfully');
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(friendlyError(e, fallback: 'Team join nahi ho paaya.'), isError: true);
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text('Join Team'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    _buildInviteCard(),
                    const SizedBox(height: 16),
                    _buildJoinForm(),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_rounded, size: 52, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadInvite, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCard() {
    final teamName = _invite?['teamName']?.toString() ?? 'Team';
    final count = _invite?['playersCount']?.toString() ?? '0';
    final city = [_invite?['city'], _invite?['state']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .join(', ');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.groups_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 14),
          Text(teamName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            city.isEmpty ? '$count players in squad' : '$city • $count players in squad',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Player Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary)),
          const SizedBox(height: 14),
          TextField(controller: _nameController, textCapitalization: TextCapitalization.words, decoration: _input('Player name', Icons.person_outline_rounded)),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))],
            decoration: _input('Mobile number', Icons.phone_android_rounded),
          ),
          const SizedBox(height: 12),
          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: _input('Email address', Icons.email_outlined)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: _input('Role', Icons.sports_cricket_rounded),
            items: const [
              DropdownMenuItem(value: 'batsman', child: Text('Batsman')),
              DropdownMenuItem(value: 'bowler', child: Text('Bowler')),
              DropdownMenuItem(value: 'all-rounder', child: Text('All-rounder')),
              DropdownMenuItem(value: 'wicket-keeper', child: Text('Wicket keeper')),
            ],
            onChanged: (value) => setState(() => _role = value ?? 'batsman'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0),
              onPressed: _isJoining ? null : _joinTeam,
              icon: _isJoining
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.login_rounded),
              label: Text(_isJoining ? 'Joining...' : 'Join Team'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: _textSecondary),
      filled: true,
      fillColor: _bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _accent, width: 1.4)),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
