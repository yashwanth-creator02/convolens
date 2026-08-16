import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../core/database/app_database.dart';
import '../models/contact_summary.dart';
import '../repository/contacts_repository.dart';
import '../utils/group_contacts_by_letter.dart';
import '../widgets/contact_card.dart';
import '../widgets/side_bar_alphabet_index.dart';
import 'contact_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  final AppDatabase db;

  const ContactsScreen({super.key, required this.db});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with WidgetsBindingObserver {
  late final ContactsRepository _repository;
  final ItemScrollController _itemScrollController = ItemScrollController();

  bool _permissionGranted = false;
  bool _loadingContacts = true;

  List<Contact> _deviceContacts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = ContactsRepository(widget.db);
    _loadDeviceContacts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_permissionGranted) {
      _loadDeviceContacts();
    }
  }

  Future<void> _loadDeviceContacts() async {
    if (!mounted) return;

    setState(() {
      _loadingContacts = true;
    });

    final status = await Permission.contacts.status;

    if (!mounted) return;

    if (!status.isGranted) {
      setState(() {
        _permissionGranted = false;
        _loadingContacts = false;
      });
      return;
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);

    if (!mounted) return;

    setState(() {
      _permissionGranted = true;
      _deviceContacts = contacts;
      _loadingContacts = false;
    });
  }

  Future<void> _requestContactsPermission() async {
    final status = await Permission.contacts.request();

    if (!mounted) return;

    if (status.isGranted) {
      await _loadDeviceContacts();
    }
  }

  void _openContact(ContactSummary contact) {
    if (contact.displayNumber.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ContactDetailScreen(
              normalizedNumber: contact.normalizedNumber,
              displayName: contact.displayName,
              displayNumber: contact.displayNumber,
              db: widget.db,
            ),
      ),
    );
  }

  void _scrollToLetter(String letter, List<Object> items) {
    final index = items.indexOf(letter);
    if (index != -1 && _itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingContacts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_permissionGranted) {
      return _buildPermissionView();
    }

    return _buildContactsList();
  }

  Widget _buildContactsList() {
    return StreamBuilder<List<ContactSummary>>(
      stream: _repository.watchContacts(_deviceContacts),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error);
        }

        final contacts = snapshot.data ?? [];

        if (contacts.isEmpty) {
          return const Center(child: Text('No contacts found.'));
        }

        final grouped = groupContactsByLetter(contacts);
        final orderedLetters = grouped.keys.toList()
          ..sort((a, b) {
            if (a == '#') return 1;
            if (b == '#') return -1;
            return a.compareTo(b);
          });

        final items = <Object>[];
        for (final letter in orderedLetters) {
          items.add(letter);
          items.addAll(grouped[letter]!);
        }

        return Stack(
          children: [
            ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                if (item is String) {
                  return _buildLetterHeader(context, item);
                }

                final contact = item as ContactSummary;

                return ContactCard(
                  contact: contact,
                  onTap: contact.displayNumber.isEmpty
                      ? null
                      : () => _openContact(contact),
                );
              },
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SideBarAlphabetIndex(
                letters: orderedLetters,
                onLetterSelected: (letter) => _scrollToLetter(letter, items),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorView(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Failed to load contacts.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPermissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.contacts_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Contacts permission is needed to show your full contact list.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _requestContactsPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterHeader(BuildContext context, String letter) {
    return Container(
      width: double.infinity,
      color: Theme
          .of(context)
          .colorScheme
          .surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme
              .of(context)
              .colorScheme
              .primary,
        ),
      ),
    );
  }
}