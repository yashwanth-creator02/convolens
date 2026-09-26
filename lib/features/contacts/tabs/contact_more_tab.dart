import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../widgets/contact_color_section.dart';
import '../widgets/contact_glass_card.dart';
import '../widgets/contact_preferences_section.dart';
import '../widgets/contact_settings_section.dart';

class ContactMoreTab extends StatelessWidget {
  final String normalizedNumber;
  final String displayName;
  final String displayNumber;
  final ContactDetail? detail;
  final AppDatabase db;
  final Future<void> Function(String number)? onDeleteNumber;

  const ContactMoreTab({
    super.key,
    required this.normalizedNumber,
    required this.displayName,
    required this.displayNumber,
    required this.detail,
    required this.db,
    this.onDeleteNumber,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ================================================================
        // Personalization
        // ================================================================
        ContactGlassCard(
          title: 'Personalization',
          icon: Icons.palette_outlined,
          child: ContactColorSection(
            colorValue: detail?.colorValue,
            onColorSelected: (value) {
              db.setContactFields(
                normalizedNumber,
                ContactDetailsCompanion(
                  colorValue: drift.Value(value),
                ),
              );
            },
          ),
        ),

        // ================================================================
        // Preferences
        // ================================================================
        ContactGlassCard(
          title: 'Preferences',
          icon: Icons.tune_outlined,
          child: ContactPreferencesSection(
            normalizedNumber: normalizedNumber,
            detail: detail,
            db: db,
          ),
        ),

        // ================================================================
        // Contact settings
        // ================================================================
        ContactGlassCard(
          title: 'Contact Settings',
          icon: Icons.settings_outlined,
          child: ContactSettingsSection(
            normalizedNumber: normalizedNumber,
            displayName: displayName,
            displayNumber: displayNumber,
            detail: detail,
            db: db,
            onDeleteNumber: onDeleteNumber,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
