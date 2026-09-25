import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/contact_cache.dart';
import '../../../core/toast/toast_service.dart';
import '../../../shared/glass_action_ids.dart';
import 'contact_photo_picker_sheet.dart';
import 'edit_contact_screen.dart';

Future<Contact?> showAddContactScreen(
  BuildContext context, {
  String? initialName,
  String? initialPhone,
}) async {
  final status = await Permission.contacts.status;
  if (!status.isGranted) {
    final requested = await Permission.contacts.request();
    if (!requested.isGranted) return null;
  }

  if (!context.mounted) return null;

  return Navigator.of(context).push<Contact>(
    CupertinoPageRoute(
      builder: (context) => AddContactScreen(
        initialName: initialName,
        initialPhone: initialPhone,
      ),
    ),
  );
}

class AddContactScreen extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;

  const AddContactScreen({super.key, this.initialName, this.initialPhone});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _titleController = GlassLargeTitleController();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _emailController = TextEditingController();
  late final List<TextEditingController> _phoneControllers;

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _companyFocus = FocusNode();
  final _jobTitleFocus = FocusNode();
  final _emailFocus = FocusNode();
  late final List<FocusNode> _phoneFocusNodes;

  List<Contact> _allContacts = [];
  final Set<String> _dismissedFields = {};

  Uint8List? _photoBytes;
  bool _saving = false;

  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo to Purple
    [Color(0xFF3B82F6), Color(0xFF06B6D4)], // Blue to Cyan
    [Color(0xFF10B981), Color(0xFF14B8A6)], // Emerald to Teal
    [Color(0xFFF59E0B), Color(0xFFF97316)], // Amber to Orange
    [Color(0xFFEC4899), Color(0xFFF43F5E)], // Pink to Rose
    [Color(0xFF8B5CF6), Color(0xFFD946EF)], // Purple to Fuchsia
    [Color(0xFF14B8A6), Color(0xFF3B82F6)], // Teal to Blue
  ];

  @override
  void initState() {
    super.initState();

    final name = widget.initialName?.trim() ?? '';
    final spaceIndex = name.indexOf(' ');
    final firstGuess = spaceIndex == -1 ? name : name.substring(0, spaceIndex);
    final lastGuess = spaceIndex == -1 ? '' : name.substring(spaceIndex + 1);

    _firstNameController = TextEditingController(text: firstGuess)
      ..addListener(_onNameChanged);
    _lastNameController = TextEditingController(text: lastGuess)
      ..addListener(_onNameChanged);

    final initialPhoneText = widget.initialPhone ?? '';
    final primaryPhoneController = TextEditingController(text: initialPhoneText)
      ..addListener(() => _onPhoneChanged(0));
    _phoneControllers = [primaryPhoneController];

    _phoneFocusNodes = [FocusNode()..addListener(_onFieldChanged)];
    _firstNameFocus.addListener(_onFieldChanged);
    _lastNameFocus.addListener(_onFieldChanged);
    _companyFocus.addListener(_onFieldChanged);
    _jobTitleFocus.addListener(_onFieldChanged);
    _emailFocus.addListener(_onFieldChanged);

    _companyController.addListener(_onCompanyChanged);
    _jobTitleController.addListener(_onJobTitleChanged);
    _emailController.addListener(_onEmailChanged);

    _loadExistingContacts();
  }

  void _onNameChanged() {
    _clearDismissal('name_first');
    _clearDismissal('name_last');
    if (mounted) setState(() {});
  }

  void _onPhoneChanged(int index) {
    _clearDismissal('phone_$index');
    if (mounted) setState(() {});
  }

  void _onCompanyChanged() {
    _clearDismissal('company');
    if (mounted) setState(() {});
  }

  void _onJobTitleChanged() {
    _clearDismissal('job_title');
    if (mounted) setState(() {});
  }

  void _onEmailChanged() {
    _clearDismissal('email');
    if (mounted) setState(() {});
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _clearDismissal(String fieldKey) {
    _dismissedFields.remove(fieldKey);
  }

  Future<void> _loadExistingContacts() async {
    if (ContactCache.contacts.isNotEmpty) {
      if (mounted) {
        setState(() {
          _allContacts = ContactCache.contacts;
        });
      }
    }

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: true,
      );
      if (mounted) {
        setState(() {
          _allContacts = contacts;
        });
        ContactCache.setContacts(contacts);
      }
    } catch (_) {}
  }

  List<Contact> _getMatchingContactsForName() {
    final first = _firstNameController.text.trim().toLowerCase();
    final last = _lastNameController.text.trim().toLowerCase();
    final full = '$first $last'.trim();

    if (first.length < 2 && last.length < 2 && full.length < 2) return const [];

    return _allContacts.where((contact) {
      final cDisplay = contact.displayName.trim().toLowerCase();
      final cFirst = contact.name.first.trim().toLowerCase();
      final cLast = contact.name.last.trim().toLowerCase();
      final cFull = '$cFirst $cLast'.trim();

      if (full.length >= 2 &&
          (cDisplay.contains(full) || (cFull.isNotEmpty && cFull.contains(full)))) {
        return true;
      }
      if (first.length >= 2 &&
          ((cFirst.isNotEmpty && cFirst.contains(first)) || cDisplay.contains(first))) {
        return true;
      }
      if (last.length >= 2 &&
          ((cLast.isNotEmpty && cLast.contains(last)) || cDisplay.contains(last))) {
        return true;
      }
      return false;
    }).take(6).toList();
  }

  List<Contact> _getMatchingContactsForPhone(String phoneText) {
    final digits = phoneText.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3) return const [];

    return _allContacts.where((contact) {
      return contact.phones.any((p) {
        final pDigits = p.number.replaceAll(RegExp(r'\D'), '');
        return pDigits.contains(digits);
      });
    }).take(6).toList();
  }

  List<Contact> _getMatchingContactsForCompany(String companyText) {
    final q = companyText.trim().toLowerCase();
    if (q.length < 2) return const [];

    return _allContacts.where((contact) {
      return contact.organizations.any((o) {
        return o.company.toLowerCase().contains(q);
      });
    }).take(6).toList();
  }

  List<Contact> _getMatchingContactsForJobTitle(String titleText) {
    final q = titleText.trim().toLowerCase();
    if (q.length < 2) return const [];

    return _allContacts.where((contact) {
      return contact.organizations.any((o) {
        return o.title.toLowerCase().contains(q);
      });
    }).take(6).toList();
  }

  List<Contact> _getMatchingContactsForEmail(String emailText) {
    final q = emailText.trim().toLowerCase();
    if (q.length < 2) return const [];

    return _allContacts.where((contact) {
      return contact.emails.any((e) {
        return e.address.toLowerCase().contains(q);
      });
    }).take(6).toList();
  }

  List<Contact> get _nameSuggestions => _getMatchingContactsForName();
  List<Contact> get _companySuggestions =>
      _getMatchingContactsForCompany(_companyController.text);
  List<Contact> get _jobTitleSuggestions =>
      _getMatchingContactsForJobTitle(_jobTitleController.text);
  List<Contact> get _emailSuggestions =>
      _getMatchingContactsForEmail(_emailController.text);

  String _buildNameSubtitle(Contact c) {
    if (c.phones.isNotEmpty) return c.phones.first.number;
    if (c.emails.isNotEmpty) return c.emails.first.address;
    if (c.organizations.isNotEmpty) return c.organizations.first.company;
    return 'Existing contact';
  }

  Future<void> _navigateToEditContact(Contact contact) async {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    final updated = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) => EditContactScreen(contact: contact),
      ),
    );

    if (updated == true && mounted) {
      Navigator.of(context).pop(contact);
    }
  }

  @override
  void dispose() {
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _companyFocus.dispose();
    _jobTitleFocus.dispose();
    _emailFocus.dispose();
    for (final f in _phoneFocusNodes) {
      f.dispose();
    }

    _firstNameController.removeListener(_onNameChanged);
    _lastNameController.removeListener(_onNameChanged);
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
    HapticFeedback.selectionClick();
    final newIndex = _phoneControllers.length;
    final controller = TextEditingController()
      ..addListener(() => _onPhoneChanged(newIndex));
    final focusNode = FocusNode()..addListener(_onFieldChanged);
    setState(() {
      _phoneControllers.add(controller);
      _phoneFocusNodes.add(focusNode);
    });
  }

  void _removePhoneField(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _phoneControllers[index].dispose();
      _phoneControllers.removeAt(index);
      _phoneFocusNodes[index].dispose();
      _phoneFocusNodes.removeAt(index);
    });
  }

  Future<void> _pickPhoto() async {
    final result = await showContactPhotoPickerSheet(
      context,
      hasExistingPhoto: _photoBytes != null,
    );

    if (result == null || !mounted) return;

    if (result is ContactPhotoBytes) {
      setState(() {
        _photoBytes = result.bytes;
      });
      ToastService.info(context, 'Photo added');
    } else if (result is ContactPhotoRemoved) {
      _removePhoto();
    }
  }

  void _removePhoto() {
    HapticFeedback.lightImpact();
    setState(() {
      _photoBytes = null;
    });
    if (mounted) {
      ToastService.info(context, 'Photo removed');
    }
  }

  List<Color> _getGradientForName(String name) {
    if (name.isEmpty) return _avatarGradients[0];
    final hash = name.codeUnits.fold(0, (sum, c) => sum + c);
    return _avatarGradients[hash % _avatarGradients.length];
  }

  String _getInitials() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isEmpty && last.isEmpty) return '?';
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    final s = first.isNotEmpty ? first : last;
    return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s[0].toUpperCase();
  }

  Future<void> _save() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phones = _phoneControllers
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (firstName.isEmpty && lastName.isEmpty && phones.isEmpty) {
      ToastService.warning(context, 'Please enter a name or phone number.');
      return;
    }

    if (phones.isEmpty) {
      ToastService.warning(context, 'Please enter at least one phone number.');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    try {
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

      if (_photoBytes != null) {
        newContact.photo = _photoBytes;
      }

      await newContact.insert();
      ContactCache.updateContact(newContact);

      if (mounted) {
        ToastService.success(context, 'Contact created successfully.');
        Navigator.pop(context, newContact);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ToastService.error(context, 'Failed to save contact: $e');
      }
    }
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: scheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String placeholder,
    FocusNode? focusNode,
    List<Contact>? suggestions,
    String Function(Contact)? suggestionSubtitle,
    String? fieldDismissKey,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool autofocus = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final showSuggestions = suggestions != null &&
        suggestions.isNotEmpty &&
        (focusNode?.hasFocus ?? false) &&
        (fieldDismissKey == null || !_dismissedFields.contains(fieldDismissKey));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 5),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                letterSpacing: 0.2,
              ),
            ),
          ),
          GlassTextField(
            controller: controller,
            focusNode: focusNode,
            placeholder: placeholder,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofocus: autofocus,
            quality: GlassQuality.standard,
            useOwnLayer: false,
            shape: const LiquidRoundedRectangle(borderRadius: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            textStyle: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
            placeholderStyle: TextStyle(
              fontSize: 14,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ),
          if (showSuggestions)
            ContactSuggestionsDropdown(
              contacts: suggestions,
              fieldLabel: label,
              subtitleBuilder: suggestionSubtitle,
              onSelect: _navigateToEditContact,
              onDismiss: () {
                if (fieldDismissKey != null) {
                  setState(() => _dismissedFields.add(fieldDismissKey));
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
    final gradient = _getGradientForName(fullName);
    final initials = _getInitials();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Center(
        child: GestureDetector(
          onTap: _pickPhoto,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _photoBytes == null
                      ? LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: (_photoBytes == null ? gradient.first : scheme.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _photoBytes != null
                      ? Image.memory(
                          _photoBytes!,
                          fit: BoxFit.cover,
                          width: 96,
                          height: 96,
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Add Contact'),
        largeTitleController: _titleController,
        actions: [
          GlassBarItem.icon(
            icon: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            id: 'save',
            label: 'Save',
            onTap: () {
              if (!_saving) _save();
            },
          ),
          GlassBarItem.icon(
            icon: const Icon(Icons.close_rounded, size: 20),
            id: GlassActionIds.settings,
            label: 'Cancel',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          controller: _titleController.scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
            ),
            GlassLargeTitle(
              text: 'New Contact',
              controller: _titleController,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Hero Avatar ───────────────────────────────────────────
                  _buildAvatarHeader(context),

                  // ── 1. Name Section ───────────────────────────────────────
                  _buildSectionHeader(
                    context: context,
                    title: 'Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  _buildField(
                    context: context,
                    label: 'First Name',
                    controller: _firstNameController,
                    focusNode: _firstNameFocus,
                    suggestions: _nameSuggestions,
                    suggestionSubtitle: _buildNameSubtitle,
                    fieldDismissKey: 'name_first',
                    placeholder: 'Given name…',
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                  ),
                  _buildField(
                    context: context,
                    label: 'Last Name',
                    controller: _lastNameController,
                    focusNode: _lastNameFocus,
                    suggestions: _nameSuggestions,
                    suggestionSubtitle: _buildNameSubtitle,
                    fieldDismissKey: 'name_last',
                    placeholder: 'Family name…',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),

                  // ── 2. Phone Numbers Section ──────────────────────────────
                  _buildSectionHeader(
                    context: context,
                    title: 'Phone Numbers',
                    icon: Icons.phone_outlined,
                  ),
                  ..._phoneControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    final focusNode = _phoneFocusNodes.length > index
                        ? _phoneFocusNodes[index]
                        : null;
                    final phoneSuggestions =
                        _getMatchingContactsForPhone(controller.text);
                    final isOnly = _phoneControllers.length == 1;
                    final fieldDismissKey = 'phone_$index';
                    final showSuggestions = phoneSuggestions.isNotEmpty &&
                        (focusNode?.hasFocus ?? false) &&
                        !_dismissedFields.contains(fieldDismissKey);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 5),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  index == 0
                                      ? 'Primary Number'
                                      : 'Alternate Number ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (!isOnly)
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _removePhoneField(index),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.remove_circle_outline_rounded,
                                            size: 14,
                                            color: scheme.error,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Remove',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          GlassTextField(
                            controller: controller,
                            focusNode: focusNode,
                            placeholder: 'e.g. +1 555 123 4567',
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            quality: GlassQuality.standard,
                            useOwnLayer: false,
                            shape: const LiquidRoundedRectangle(
                              borderRadius: 14,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            textStyle: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface,
                            ),
                            placeholderStyle: TextStyle(
                              fontSize: 14,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          if (showSuggestions)
                            ContactSuggestionsDropdown(
                              contacts: phoneSuggestions,
                              fieldLabel: index == 0
                                  ? 'Primary Number'
                                  : 'Alternate Number ${index + 1}',
                              subtitleBuilder: (c) {
                                final digits = controller.text
                                    .replaceAll(RegExp(r'\D'), '');
                                final matchedPhone = c.phones.firstWhere(
                                  (p) => p.number
                                      .replaceAll(RegExp(r'\D'), '')
                                      .contains(digits),
                                  orElse: () => c.phones.isNotEmpty
                                      ? c.phones.first
                                      : Phone(''),
                                );
                                return matchedPhone.number.isNotEmpty
                                    ? matchedPhone.number
                                    : (c.emails.isNotEmpty
                                        ? c.emails.first.address
                                        : 'Existing contact');
                              },
                              onSelect: _navigateToEditContact,
                              onDismiss: () => setState(
                                () => _dismissedFields.add(fieldDismissKey),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GlassChip(
                        label: 'Add Another Number',
                        icon: const Icon(Icons.add_rounded, size: 16),
                        quality: GlassQuality.standard,
                        useOwnLayer: false,
                        onTap: _addPhoneField,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 3. Work Section ───────────────────────────────────────
                  _buildSectionHeader(
                    context: context,
                    title: 'Work & Organization',
                    icon: Icons.work_outline_rounded,
                  ),
                  _buildField(
                    context: context,
                    label: 'Company',
                    controller: _companyController,
                    focusNode: _companyFocus,
                    suggestions: _companySuggestions,
                    suggestionSubtitle: (c) => c.organizations.isNotEmpty
                        ? c.organizations.first.company
                        : (c.phones.isNotEmpty
                            ? c.phones.first.number
                            : 'Existing contact'),
                    fieldDismissKey: 'company',
                    placeholder: 'Company / Organization name…',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildField(
                    context: context,
                    label: 'Job Title',
                    controller: _jobTitleController,
                    focusNode: _jobTitleFocus,
                    suggestions: _jobTitleSuggestions,
                    suggestionSubtitle: (c) => c.organizations.isNotEmpty
                        ? '${c.organizations.first.title}${c.organizations.first.company.isNotEmpty ? " • ${c.organizations.first.company}" : ""}'
                        : (c.phones.isNotEmpty
                            ? c.phones.first.number
                            : 'Existing contact'),
                    fieldDismissKey: 'job_title',
                    placeholder: 'Role or Designation…',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // ── 4. Email Section ──────────────────────────────────────
                  _buildSectionHeader(
                    context: context,
                    title: 'Email Address',
                    icon: Icons.mail_outline_rounded,
                  ),
                  _buildField(
                    context: context,
                    label: 'Email',
                    controller: _emailController,
                    focusNode: _emailFocus,
                    suggestions: _emailSuggestions,
                    suggestionSubtitle: (c) {
                      final q = _emailController.text.trim().toLowerCase();
                      final matched = c.emails.firstWhere(
                        (e) => e.address.toLowerCase().contains(q),
                        orElse: () =>
                            c.emails.isNotEmpty ? c.emails.first : Email(''),
                      );
                      return matched.address.isNotEmpty
                          ? matched.address
                          : 'Existing contact';
                    },
                    fieldDismissKey: 'email',
                    placeholder: 'contact@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactSuggestionsDropdown extends StatelessWidget {
  final List<Contact> contacts;
  final String fieldLabel;
  final String Function(Contact)? subtitleBuilder;
  final ValueChanged<Contact> onSelect;
  final VoidCallback onDismiss;

  const ContactSuggestionsDropdown({
    super.key,
    required this.contacts,
    required this.fieldLabel,
    this.subtitleBuilder,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2230).withValues(alpha: 0.88)
            : const Color(0xFFF1F5F9).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Banner ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 15,
                  color: scheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${contacts.length} existing contact${contacts.length > 1 ? 's' : ''} found',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                Text(
                  'Tap to edit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDismiss,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Contacts List ──────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: contacts.length > 2 ? 180 : 120,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              physics: const ClampingScrollPhysics(),
              itemCount: contacts.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 52,
                endIndent: 12,
                color: scheme.outlineVariant.withValues(alpha: 0.18),
              ),
              itemBuilder: (context, i) {
                final contact = contacts[i];
                final displayName = contact.displayName.trim().isNotEmpty
                    ? contact.displayName.trim()
                    : '${contact.name.first} ${contact.name.last}'.trim();
                final nameToShow =
                    displayName.isNotEmpty ? displayName : 'Unnamed Contact';
                final subtitle = subtitleBuilder != null
                    ? subtitleBuilder!(contact)
                    : (contact.phones.isNotEmpty
                        ? contact.phones.first.number
                        : (contact.emails.isNotEmpty
                            ? contact.emails.first.address
                            : 'Existing contact'));

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelect(contact),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _buildAvatar(contact),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  nameToShow,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: scheme.onSurfaceVariant
                                          .withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: scheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Contact contact) {
    final photo = contact.thumbnail ?? contact.photo;
    if (photo != null) {
      return Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(photo, fit: BoxFit.cover),
      );
    }

    final name = contact.displayName.trim();
    final initials = name.isNotEmpty
        ? (name.length >= 2
            ? name.substring(0, 2).toUpperCase()
            : name[0].toUpperCase())
        : '?';
    final hash = name.codeUnits.fold(0, (sum, c) => sum + c);
    final gradient = _AddContactScreenState._avatarGradients[
        hash % _AddContactScreenState._avatarGradients.length];

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
