import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0D2147),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _TermsSection(
            title: 'Scores11 Terms',
            body:
                'By using Scores11, you agree to keep your account information accurate, use fair-play features responsibly, and follow cricket community standards.',
          ),
          _TermsSection(
            title: 'Matches and Scoring',
            body:
                'Match creators, scorers, and team admins are responsible for entering correct teams, players, toss details, score updates, and results.',
          ),
          _TermsSection(
            title: 'Community Content',
            body:
                'Posts, comments, photos, and shared content must be respectful, cricket-focused, and must not include abusive, illegal, or misleading material.',
          ),
          _TermsSection(
            title: 'Account Safety',
            body:
                'Keep your login secure. Scores11 may restrict accounts that misuse scoring, teams, community posts, notifications, or wallet/store features.',
          ),
          _TermsSection(
            title: 'Support',
            body:
                'For help with account, scoring, payment, or technical issues, contact support from the Help & Support screen.',
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String body;

  const _TermsSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
