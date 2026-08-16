import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../widgets/contact_call_history.dart';
import '../widgets/contact_header.dart';
import '../widgets/contact_note_section.dart';
import '../widgets/contact_tags_section.dart';

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

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
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
                      ),
                      const Divider(height: 32),

                      ContactNoteSection(
                        note: detail?.generalNote,
                        onSave: (note) async {
                          await db.saveContactNote(normalizedNumber, note);
                        },
                      ),

                      const Divider(height: 32),

                      ContactTagsSection(
                        normalizedNumber: normalizedNumber,
                        db: db,
                      ),

                      const Divider(height: 32),

                      const Text(
                        'Call History',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              ContactCallHistory(normalizedNumber: normalizedNumber, db: db),
            ],
          );
        },
      ),
    );
  }
}
