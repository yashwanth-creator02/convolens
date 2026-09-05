import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../models/contact_summary.dart';
import '../repository/contacts_repository.dart';
import '../widgets/contact_card.dart';
import 'contact_detail_screen.dart';

class ContactSearchScreen extends StatefulWidget {
  final AppDatabase db;

  const ContactSearchScreen({super.key, required this.db});

  @override
  State<ContactSearchScreen> createState() => _ContactSearchScreenState();
}

class _ContactSearchScreenState extends State<ContactSearchScreen> {
  late final ContactsRepository _repository;
  final _queryController = TextEditingController();
  Timer? _debounce;

  String _query = '';
  int? _selectedTagId;
  List<Tag> _allTags = [];
  List<Contact> _deviceContacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = ContactsRepository(widget.db);
    _load();
  }

  Future<void> _load() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      _deviceContacts = await FlutterContacts.getContacts(withProperties: true);
    }
    _allTags = await widget.db.getAllTags();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value.trim().toLowerCase());
    });
  }

  Future<Set<String>> _numbersForTag(int tagId) async {
    final rows = await (widget.db.select(
      widget.db.contactTags,
    )..where((t) => t.tagId.equals(tagId))).get();
    return rows.map((r) => r.normalizedNumber).toSet();
  }

  void _openContact(ContactSummary contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(
          normalizedNumber: contact.normalizedNumber,
          displayName: contact.displayName,
          displayNumber: contact.displayNumber,
          deviceContact: contact.deviceContact,
          db: widget.db,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search contacts…',
            border: InputBorder.none,
          ),
          onChanged: _onQueryChanged,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_allTags.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: _selectedTagId == null,
                            onSelected: (_) =>
                                setState(() => _selectedTagId = null),
                          ),
                        ),
                        ..._allTags.map(
                          (tag) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(tag.name),
                              selected: _selectedTagId == tag.id,
                              onSelected: (_) =>
                                  setState(() => _selectedTagId = tag.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: FutureBuilder<Set<String>?>(
                    future: _selectedTagId != null
                        ? _numbersForTag(_selectedTagId!)
                        : null,
                    builder: (context, tagSnapshot) {
                      final tagNumbers = tagSnapshot.data;

                      return StreamBuilder<List<ContactSummary>>(
                        stream: _repository.watchContacts(_deviceContacts),
                        builder: (context, snapshot) {
                          final contacts = snapshot.data ?? [];

                          final filtered = contacts.where((c) {
                            final matchesQuery =
                                _query.isEmpty ||
                                c.displayName.toLowerCase().contains(_query) ||
                                c.displayNumber.toLowerCase().contains(_query);
                            final matchesTag =
                                tagNumbers == null ||
                                tagNumbers.contains(c.normalizedNumber);
                            return matchesQuery && matchesTag;
                          }).toList();

                          if (_query.isEmpty && _selectedTagId == null) {
                            return const Center(
                              child: Text(
                                'Type to search, or pick a tag.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          if (filtered.isEmpty) {
                            return const Center(
                              child: Text(
                                'No matching contacts.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final contact = filtered[index];
                              return ContactCard(
                                contact: contact,
                                onTap: contact.displayNumber.isEmpty
                                    ? null
                                    : () => _openContact(contact),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
