import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../widgets/contact_analytics_section.dart';
import '../widgets/contact_glass_card.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        ContactGlassCard(
          title: 'Communication Analytics',
          icon: Icons.insights_rounded,
          child: ContactAnalyticsSection(
            normalizedNumber: normalizedNumber,
            db: db,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
