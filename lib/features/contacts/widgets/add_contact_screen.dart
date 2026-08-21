import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> showAddContactScreen(BuildContext context) async {
  final status = await Permission.contacts.status;
  if (!status.isGranted) {
    final requested = await Permission.contacts.request();
    if (!requested.isGranted) return false;
  }

  if (!context.mounted) return false;

  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (context) => const AddContactScreen()),
  );

  return result ?? false;
}

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _emailController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [
    TextEditingController(),
  ];

  bool _saving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _emailController.dispose();
    for (final c in _phoneControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPhoneField() {
    setState(() => _phoneControllers.add(TextEditingController()));
  }

  void _removePhoneField(int index) {
    setState(() {
      _phoneControllers[index].dispose();
      _phoneControllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phones = _phoneControllers
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (firstName.isEmpty && lastName.isEmpty) return;
    if (phones.isEmpty) return;

    setState(() => _saving = true);

    final newContact = Contact()
      ..name.first = firstName
      ..name.last = lastName
      ..phones = phones.map((p) => Phone(p)).toList();

    final company = _companyController.text.trim();
    final jobTitle = _jobTitleController.text.trim();
    if (company.isNotEmpty || jobTitle.isNotEmpty) {
      newContact.organizations = [
        Organization(company: company, title: jobTitle),
      ];
    }

    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      newContact.emails = [Email(email)];
    }

    await newContact.insert();

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contact'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _firstNameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            const Divider(height: 32),
            const Text(
              'Phone Numbers',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._phoneControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                        ),
                      ),
                    ),
                    if (_phoneControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removePhoneField(index),
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addPhoneField,
              icon: const Icon(Icons.add),
              label: const Text('Add another number'),
            ),
            const Divider(height: 32),
            const Text('Work', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Company'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jobTitleController,
              decoration: const InputDecoration(labelText: 'Job title'),
            ),
            const Divider(height: 32),
            const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email address'),
            ),
          ],
        ),
      ),
    );
  }
}
