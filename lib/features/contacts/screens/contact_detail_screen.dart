import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../widgets/contact_analytics_section.dart';
import '../widgets/contact_call_history_list.dart';
import '../widgets/contact_color_section.dart';
import '../widgets/contact_header.dart';
import '../widgets/contact_links_section.dart';
import '../widgets/contact_note_section.dart';
import '../widgets/contact_preferences_section.dart';
import '../widgets/contact_settings_section.dart';
import '../widgets/contact_tags_section.dart';
import '../widgets/contact_phone_numbers_section.dart';
import '../widgets/contact_timeline_section.dart';

class ContactDetailScreen extends StatelessWidget {
  final String normalizedNumber;
  final String displayName;
  final String displayNumber;
  final Contact? deviceContact;
  final AppDatabase db;

  const ContactDetailScreen({
    super.key,
    required this.normalizedNumber,
    required this.displayName,
    required this.displayNumber,
    this.deviceContact,
    required this.db,
  });

  Future<void> _toggleFavorite(bool isFavorite) async {
    await db.toggleContactFavorite(normalizedNumber, !isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: StreamBuilder<ContactDetail?>(
        stream: db.watchContactDetails(normalizedNumber),
        builder: (context, snapshot) {
          final detail = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContactHeader(
                  displayName: displayName,
                  displayNumber: displayNumber,
                  deviceContact: deviceContact,
                  isFavorite: detail?.isFavorite ?? false,
                  onFavoritePressed: () =>
                      _toggleFavorite(detail?.isFavorite ?? false),
                  colorValue: detail?.colorValue,
                ),

                const Divider(height: 32),

                const Text(
                  'Phone Numbers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ContactPhoneNumbersSection(
                  deviceContact: deviceContact,
                  fallbackNumber: displayNumber,
                ),

                const Divider(height: 32),
                const Text(
                  'Links',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ContactLinksSection(normalizedNumber: normalizedNumber, db: db),

                const Divider(height: 32),

                ContactNoteSection(
                  note: detail?.generalNote,
                  onSave: (note) async {
                    await db.saveContactNote(normalizedNumber, note);
                  },
                ),

                const Divider(height: 32),

                ContactTagsSection(normalizedNumber: normalizedNumber, db: db),
                const Divider(height: 32),
                const Text(
                  'Color',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ContactColorSection(
                  colorValue: detail?.colorValue,
                  onColorSelected: (value) => db.setContactFields(
                    normalizedNumber,
                    ContactDetailsCompanion(colorValue: drift.Value(value)),
                  ),
                ),

                const Divider(height: 32),
                const Text(
                  'Preferences',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ContactPreferencesSection(
                  normalizedNumber: normalizedNumber,
                  detail: detail,
                  db: db,
                ),

                const Divider(height: 32),
                const Text(
                  'Analytics',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ContactAnalyticsSection(
                  normalizedNumber: normalizedNumber,
                  db: db,
                ),

                const Divider(height: 32),
                const Text(
                  'Timeline',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    child: ContactTimelineSection(
                      normalizedNumber: normalizedNumber,
                      db: db,
                    ),
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  'Settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ContactSettingsSection(
                  normalizedNumber: normalizedNumber,
                  displayName: displayName,
                  displayNumber: displayNumber,
                  detail: detail,
                  db: db,
                ),

                const Divider(height: 32),

                const Text(
                  'Call History',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ContactCallHistoryList(
                    normalizedNumber: normalizedNumber,
                    db: db,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
