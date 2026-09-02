import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../widgets/contact_analytics_section.dart';

class ContactAnalyticsTab extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;

  const ContactAnalyticsTab({
    super.key,
    required this.normalizedNumber,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ContactAnalyticsSection(
          normalizedNumber: normalizedNumber,
          db: db,
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
