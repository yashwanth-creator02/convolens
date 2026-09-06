import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class EditContactScreen extends StatefulWidget {
  final Contact contact;

  const EditContactScreen({super.key, required this.contact});

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _titleController = GlassLargeTitleController();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _companyController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _emailController;
  late final List<TextEditingController> _phoneControllers;

  Uint8List? _photoBytes;
  bool _photoChanged = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.contact.name.first,
    );
    _lastNameController = TextEditingController(text: widget.contact.name.last);
    _companyController = TextEditingController(
      text: widget.contact.organizations.isNotEmpty
          ? widget.contact.organizations.first.company
          : '',
    );
    _jobTitleController = TextEditingController(
      text: widget.contact.organizations.isNotEmpty
          ? widget.contact.organizations.first.title
          : '',
    );
    _emailController = TextEditingController(
      text: widget.contact.emails.isNotEmpty
          ? widget.contact.emails.first.address
          : '',
    );
    _phoneControllers = widget.contact.phones.isNotEmpty
        ? widget.contact.phones
              .map((p) => TextEditingController(text: p.number))
              .toList()
        : [TextEditingController()];
  }

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
    _titleController.dispose();
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

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    final bytes = result?.files.single.bytes;
    if (bytes == null) return;

    setState(() {
      _photoBytes = bytes;
      _photoChanged = true;
    });
  }

  void _removePhoto() {
    setState(() {
      _photoBytes = null;
      _photoChanged = true;
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

    try {
      widget.contact.name.first = firstName;
      widget.contact.name.last = lastName;
      widget.contact.phones = phones.map((p) => Phone(p)).toList();

      final company = _companyController.text.trim();
      final jobTitle = _jobTitleController.text.trim();
      widget.contact.organizations = (company.isNotEmpty || jobTitle.isNotEmpty)
          ? [Organization(company: company, title: jobTitle)]
          : [];

      final email = _emailController.text.trim();
      widget.contact.emails = email.isNotEmpty ? [Email(email)] : [];

      if (_photoChanged) {
        widget.contact.photo = _photoBytes;
      }

      await widget.contact.update();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update contact: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Edit Contact'),
        largeTitleController: _titleController,
        actions: [
          GlassBarItem.icon(
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            id: 'save',
            label: 'Save',
            onTap: () {
              if (!_saving) _save();
            },
          ),
        ],
      ),
      body: Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          controller: _titleController.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
            ),
            GlassLargeTitle(text: 'Edit Contact', controller: _titleController),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundImage: _photoChanged
                              ? (_photoBytes != null
                                    ? MemoryImage(_photoBytes!)
                                    : null)
                              : (widget.contact.thumbnail != null
                                    ? MemoryImage(widget.contact.thumbnail!)
                                    : null),
                          child:
                              (_photoChanged
                                      ? _photoBytes
                                      : widget.contact.thumbnail) ==
                                  null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _pickPhoto,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((_photoChanged
                          ? _photoBytes
                          : widget.contact.thumbnail) !=
                      null)
                    Center(
                      child: TextButton(
                        onPressed: _removePhoto,
                        child: const Text('Remove Photo'),
                      ),
                    ),
                  const SizedBox(height: 16),
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
                  const Text(
                    'Work',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
