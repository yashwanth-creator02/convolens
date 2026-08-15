import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../history/screens/search_screen.dart';
import '../models/contact_summary.dart';
import '../repository/contacts_repository.dart';
import '../widgets/contact_card.dart';
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
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingContacts = true;
    });

    final status = await Permission.contacts.status;

    if (!mounted) {
      return;
    }

    if (!status.isGranted) {
      setState(() {
        _permissionGranted = false;
        _loadingContacts = false;
      });
      return;
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);

    if (!mounted) {
      return;
    }

    setState(() {
      _permissionGranted = true;
      _deviceContacts = contacts;
      _loadingContacts = false;
    });
  }

  Future<void> _requestContactsPermission() async {
    final status = await Permission.contacts.request();

    if (!mounted) {
      return;
    }

    if (status.isGranted) {
      await _loadDeviceContacts();
    }
  }

  void _openContact(ContactSummary contact) {
    if (contact.displayNumber.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(
          normalizedNumber: contact.normalizedNumber,
          displayName: contact.displayName,
          displayNumber: contact.displayNumber,
          db: widget.db,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingContacts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_permissionGranted) {
      return _buildPermissionView();
    }

    return StreamBuilder<List<ContactSummary>>(
      stream: _repository.watchContacts(_deviceContacts),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load contacts.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final contacts = snapshot.data ?? [];

        if (contacts.isEmpty) {
          return const Center(child: Text('No contacts found.'));
        }

        return ListView.separated(
          itemCount: contacts.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final contact = contacts[index];

            return ContactCard(
              contact: contact,
              onTap: contact.displayNumber.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactDetailScreen(
                            normalizedNumber: contact.normalizedNumber,
                            displayName: contact.displayName,
                            displayNumber: contact.displayNumber,
                            db: widget.db,
                          ),
                        ),
                      );
                    },
            );
          },
        );
      },
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
}
