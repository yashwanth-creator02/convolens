import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../models/contact_summary.dart';
import '../repository/contacts_repository.dart';
import '../widgets/contact_card.dart';
import 'contact_detail_screen.dart';

class ArchivedContactsScreen extends StatefulWidget {
  final AppDatabase db;
  final List<Contact> deviceContacts;

  const ArchivedContactsScreen({
    super.key,
    required this.db,
    required this.deviceContacts,
  });

  @override
  State<ArchivedContactsScreen> createState() => _ArchivedContactsScreenState();
}

class _ArchivedContactsScreenState extends State<ArchivedContactsScreen> {
  final _titleController = GlassLargeTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ContactsRepository(widget.db);

    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Archived Contacts'),
        largeTitleController: _titleController,
      ),
      body: StreamBuilder<List<ContactSummary>>(
        stream: repository.watchArchivedContacts(widget.deviceContacts),
        builder: (context, snapshot) {
          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return const Center(child: Text('No archived contacts.'));
          }

          return Material(
            type: MaterialType.transparency,
            child: CustomScrollView(
              controller: _titleController.scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                ),
                GlassLargeTitle(
                  text: 'Archived Contacts',
                  controller: _titleController,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final contact = contacts[index];
                    return ContactCard(
                      contact: contact,
                      onTap: contact.displayNumber.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => ContactDetailScreen(
                                  normalizedNumber: contact.normalizedNumber,
                                  displayName: contact.displayName,
                                  displayNumber: contact.displayNumber,
                                  deviceContact: contact.deviceContact,
                                  db: widget.db,
                                ),
                              ),
                            ),
                    );
                  }, childCount: contacts.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
      ),
    );
  }
}
