import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../models/contact_summary.dart';
import '../repository/contacts_repository.dart';
import '../widgets/contact_card.dart';
import 'contact_detail_screen.dart';

class ArchivedContactsScreen extends StatelessWidget {
  final AppDatabase db;
  final List<Contact> deviceContacts;

  const ArchivedContactsScreen({
    super.key,
    required this.db,
    required this.deviceContacts,
  });

  @override
  Widget build(BuildContext context) {
    final repository = ContactsRepository(db);

    return Scaffold(
      appBar: AppBar(title: const Text('Archived Contacts')),
      body: StreamBuilder<List<ContactSummary>>(
        stream: repository.watchArchivedContacts(deviceContacts),
        builder: (context, snapshot) {
          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return const Center(child: Text('No archived contacts.'));
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ContactCard(
                contact: contact,
                onTap: contact.displayNumber.isEmpty
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactDetailScreen(
                            normalizedNumber: contact.normalizedNumber,
                            displayName: contact.displayName,
                            displayNumber: contact.displayNumber,
                            deviceContact: contact.deviceContact,
                            db: db,
                          ),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
