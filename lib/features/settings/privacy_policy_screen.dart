import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_appbar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Privacy Policy', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Scores11 Privacy Policy'),
            const SizedBox(height: 16),
            _buildParagraph('Welcome to Scores11! Your privacy is critically important to us. This Privacy Policy explains how Scores11 collects, uses, discloses, and safeguards your information when you visit our mobile application. Please read this privacy policy carefully. IF YOU DO NOT AGREE WITH THE TERMS OF THIS PRIVACY POLICY, PLEASE DO NOT ACCESS THE APP.'),
            const SizedBox(height: 24),
            _buildSectionTitle('1. Information We Collect'),
            _buildBullet('Personal Information: We may collect personal information such as name, email, phone number, date of birth, and profile picture when you register or create a profile.'),
            _buildBullet('Usage Data: We collect information about how you use the app, including pages visited, time spent, and actions performed.'),
            _buildBullet('Cricket Data: Match scores, player statistics, team selections, and contest participation data.'),
            _buildBullet('Device Information: Device ID, IP address, browser type, operating system, and app version.'),
            const SizedBox(height: 24),
            _buildSectionTitle('2. How We Use Your Information'),
            _buildBullet('Provide and improve app services, including matchmaking, leaderboards, and live scoring.'),
            _buildBullet('Personalize your experience with tailored content and recommendations.'),
            _buildBullet('Send notifications, updates, and promotional communications (you can opt-out anytime).'),
            _buildBullet('Analyze usage patterns to enhance app performance and user engagement.'),
            _buildBullet('Prevent fraud, abuse, and ensure compliance with our Terms of Service.'),
            const SizedBox(height: 24),
            _buildSectionTitle('3. Information Sharing'),
            _buildParagraph('We do not sell your personal information. We may share data with:'),
            _buildBullet('Service providers who perform services on our behalf (e.g., hosting, analytics).'),
            _buildBullet('Business partners for joint promotions or contests.'),
            _buildBullet('Legal authorities if required by law or to protect rights/safety.'),
            const SizedBox(height: 24),
            _buildSectionTitle('4. Cookies and Tracking'),
            _buildParagraph('We use cookies and similar technologies for essential functions, analytics, and personalized ads. You can manage cookie preferences through your device settings.'),
            const SizedBox(height: 24),
            _buildSectionTitle('5. Children\'s Privacy'),
            _buildParagraph('Scores11 is not intended for children under 13. We do not knowingly collect personal information from children under 13 without parental consent.'),
            const SizedBox(height: 24),
            _buildSectionTitle('6. Data Security'),
            _buildParagraph('We implement reasonable security measures to protect your information. However, no method of transmission is 100% secure.'),
            const SizedBox(height: 24),
            _buildSectionTitle('7. Your Rights'),
            _buildBullet('Access, correct, or delete your personal information.'),
            _buildBullet('Opt-out of marketing communications.'),
            _buildBullet('Request data portability where applicable.'),
            _buildParagraph('Contact us at support@scores11.com to exercise these rights.'),
            const SizedBox(height: 24),
            _buildSectionTitle('8. Changes to This Policy'),
            _buildParagraph('We may update this policy. Changes will be posted here with the updated effective date. Continued use constitutes acceptance.'),
            const SizedBox(height: 24),
            _buildSectionTitle('9. Contact Us'),
            _buildParagraph('If you have questions about this Privacy Policy, contact:'),
            _buildContactItem('Email: support@scores11.com'),
            _buildContactItem('Address: Scores11 HQ, Cricket Hub, India'),
            const SizedBox(height: 32),
            // Footer
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
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    '© 2024 Scores11. All rights reserved.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Updated: January 2024',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1657CC),
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Color(0xFF1657CC),
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

