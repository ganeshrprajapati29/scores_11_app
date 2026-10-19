import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_appbar.dart';
import '../../data/services/app_config_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  AppConfig _config = const AppConfig();

  @override
  void initState() {
    super.initState();
    AppConfigService.load().then((config) {
      if (mounted) setState(() => _config = config);
    });
  }

  Future<void> _open(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No app available to open ${uri.scheme == 'mailto' ? 'email' : 'this link'}')),
      );
    }
  }

  void _email(String subject) => _open(Uri(
        scheme: 'mailto',
        path: _config.supportEmail,
        query: 'subject=${Uri.encodeComponent(subject)}',
      ));

  void _whatsapp() => _open(Uri.parse('https://wa.me/${_config.supportWhatsapp}'));

  void _showGuide(
    BuildContext context, {
    required String title,
    required List<String> points,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1657CC), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.help_outline_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...points.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF1657CC), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Help & Support', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Getting Started'),
            _buildSupportItem(
              icon: Icons.help_outline,
              title: 'How to create matches?',
              onTap: () => _showGuide(
                context,
                title: 'How to create matches?',
                points: const [
                  'Open Matches and tap Create Match.',
                  'Select both teams, venue, date, time and match format.',
                  'Do the toss, pick the playing XI and start live scoring.',
                ],
              ),
              subtitle: 'Set up a match and start scoring',
            ),
            _buildSupportItem(
              icon: Icons.emoji_events,
              title: 'Joining Tournaments',
              onTap: () => _showGuide(
                context,
                title: 'Joining Tournaments',
                points: const [
                  'Open Tournaments and choose the tournament you want.',
                  'Check eligibility, schedule and team requirements.',
                  'Register your team from the tournament page.',
                ],
              ),
              subtitle: 'Step-by-step guide to participate in tournaments',
            ),
            _buildSupportItem(
              icon: Icons.videocam_rounded,
              title: 'Going live on YouTube',
              onTap: () => _showGuide(
                context,
                title: 'Going live on YouTube',
                points: const [
                  'Open the menu and tap Go Live, or tap the camera icon while scoring.',
                  'Start a live stream in the YouTube app and paste its link, or connect your channel.',
                  'Pick the match and tap Go Live Now. Viewers see Watch Live on the match page.',
                  'When you end the stream, the full replay appears under Highlights.',
                ],
              ),
              subtitle: 'Stream your match and save the replay',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Account & Profile'),
            _buildSupportItem(
              icon: Icons.person,
              title: 'Profile Setup',
              onTap: () => _showGuide(
                context,
                title: 'Profile Setup',
                points: const [
                  'Open Profile and tap edit to update basic details.',
                  'Complete Cricket Profile with role, batting and bowling style.',
                  'Add location and profile image to make your profile complete.',
                ],
              ),
              subtitle: 'Complete your player profile and stats',
            ),
            _buildSupportItem(
              icon: Icons.lock,
              title: 'Login & OTP issues',
              onTap: () => _email('Login / OTP issue'),
              subtitle: 'Not receiving the OTP or cannot sign in',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Technical Issues'),
            _buildSupportItem(
              icon: Icons.live_tv,
              title: 'Live Streaming Problems',
              onTap: () => _email('Live streaming problem'),
              subtitle: 'Go Live not working or stream quality issues',
            ),
            _buildSupportItem(
              icon: Icons.sports_cricket,
              title: 'Score Entry Errors',
              onTap: () => _email('Scoring problem'),
              subtitle: 'Issues with scorecard or match data',
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Contact Us'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent, size: 64, color: Color(0xFF1657CC)),
                  const SizedBox(height: 16),
                  const Text(
                    'Get Help Fast',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _config.supportEmail,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _email('Scores11 support'),
                          icon: const Icon(Icons.email, size: 18),
                          label: const Text('Email Support'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1657CC),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (_config.supportWhatsapp.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _whatsapp,
                            icon: const Icon(Icons.message, size: 18),
                            label: const Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_config.supportPhone.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _open(Uri(scheme: 'tel', path: _config.supportPhone)),
                      icon: const Icon(Icons.phone),
                      label: Text(_config.supportPhone),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '© ${DateTime.now().year} Scores11. All rights reserved.',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1657CC), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
