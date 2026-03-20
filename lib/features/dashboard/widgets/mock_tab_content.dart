import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MockTabContent extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final List<String> items;

  const MockTabContent({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(icon, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(description, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Demo Content:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...items.map((item) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(item),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          )),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

