import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../widgets/contact_color_section.dart';
import '../widgets/contact_preferences_section.dart';
import '../widgets/contact_settings_section.dart';

class ContactMoreTab extends StatelessWidget {
  final String normalizedNumber;
  final String displayName;
  final String displayNumber;
  final ContactDetail? detail;
  final AppDatabase db;

  const ContactMoreTab({
    super.key,
    required this.normalizedNumber,
    required this.displayName,
    required this.displayNumber,
    required this.detail,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ================================================================
        // Personalization
        // ================================================================

        _Section(
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

        _Section(
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

        _Section(
          title: 'Contact Settings',
          icon: Icons.settings_outlined,
          child: ContactSettingsSection(
            normalizedNumber: normalizedNumber,
            displayName: displayName,
            displayNumber: displayNumber,
            detail: detail,
            db: db,
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
