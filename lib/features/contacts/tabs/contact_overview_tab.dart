import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../history/widgets/call_details/call_reminder_section.dart';
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
      padding: const EdgeInsets.all(16),
      children: [
        // ================================================================
        // Phone Numbers
        // ================================================================

        _Section(
          title: 'Phone Numbers',
          icon: Icons.phone_outlined,
          child: ContactPhoneNumbersSection(
            deviceContact: deviceContact,
            fallbackNumber: displayNumber,
          ),
        ),

        // ================================================================
        // Links
        // ================================================================

        _Section(
          title: 'Links',
          icon: Icons.link_outlined,
          child: ContactLinksSection(
            normalizedNumber: normalizedNumber,
            db: db,
          ),
        ),

        // ================================================================
        // Note
        // ================================================================

        _Section(
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

        _Section(
          title: 'Tags',
          icon: Icons.label_outline,
          child: ContactTagsSection(
            normalizedNumber: normalizedNumber,
            db: db,
          ),
        ),

        // ================================================================
        // Reminder
        // ================================================================

        _Section(
          title: 'Reminder',
          icon: Icons.notifications_none,
          child: CallReminderSection(
            reminder: null, // Placeholder: detail is ContactDetail, but reminder expects CallDetail
            onSet: () {
              // Keep your existing reminder callback here.
              //
              // Example:
              // _setReminder(context);
            },
            onClear: () {
              // Keep your existing clear-reminder callback here.
            },
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ==========================================================================
// Section wrapper
// ==========================================================================

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
