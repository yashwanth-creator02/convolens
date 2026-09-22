import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../widgets/contact_glass_card.dart';
import '../widgets/contact_links_section.dart';
import '../widgets/contact_note_section.dart';
import '../widgets/contact_phone_numbers_section.dart';
import '../widgets/contact_tags_section.dart';

class ContactOverviewTab extends StatelessWidget {
  final String normalizedNumber;
  final String displayNumber;
  final Contact? deviceContact;
  final ContactDetail? detail;
  final AppDatabase db;

  const ContactOverviewTab({
    super.key,
    required this.normalizedNumber,
    required this.displayNumber,
    required this.deviceContact,
    required this.detail,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ================================================================
        // Phone Numbers
        // ================================================================
        ContactGlassCard(
          title: 'Phone Numbers',
          icon: Icons.phone_outlined,
          child: ContactPhoneNumbersSection(
            deviceContact: deviceContact,
            fallbackNumber: displayNumber,
          ),
        ),

        // ================================================================
        // Note
        // ================================================================
        ContactGlassCard(
          title: 'Note',
          icon: Icons.notes_outlined,
          child: ContactNoteSection(
            note: detail?.generalNote,
            onSave: (note) async {
              await db.saveContactNote(
                normalizedNumber,
                note,
              );
            },
          ),
        ),

        // ================================================================
        // Tags
        // ================================================================
        ContactGlassCard(
          title: 'Tags',
          icon: Icons.label_outline,
          child: ContactTagsSection(
            normalizedNumber: normalizedNumber,
            db: db,
          ),
        ),

        // ================================================================
        // Links
        // ================================================================
        ContactGlassCard(
          title: 'Links',
          icon: Icons.link_outlined,
          child: ContactLinksSection(
            normalizedNumber: normalizedNumber,
            db: db,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
