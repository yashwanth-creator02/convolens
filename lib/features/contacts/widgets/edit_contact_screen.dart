import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/services/contact_cache.dart';
import '../../../core/toast/toast_service.dart';
import '../../../shared/glass_action_ids.dart';
import 'contact_photo_picker_sheet.dart';

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
    final displayName = widget.contact.displayName.trim();
    final spaceIdx = displayName.indexOf(' ');
    final initialFirst = widget.contact.name.first.isNotEmpty
        ? widget.contact.name.first
        : (spaceIdx == -1 ? displayName : displayName.substring(0, spaceIdx));
    final initialLast = widget.contact.name.last.isNotEmpty
        ? widget.contact.name.last
        : (spaceIdx == -1 ? '' : displayName.substring(spaceIdx + 1));

    _firstNameController = TextEditingController(
      text: initialFirst,
    )..addListener(_onNameChanged);
    _lastNameController = TextEditingController(
      text: initialLast,
    )..addListener(_onNameChanged);
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

    _loadFullContactWithAccounts();
  }

  Contact? _fullContact;

  Future<void> _loadFullContactWithAccounts() async {
    try {
      final full = await FlutterContacts.getContact(
        widget.contact.id,
        withAccounts: true,
        withProperties: true,
        withPhoto: true,
        withThumbnail: true,
      );
      if (full != null && mounted) {
        setState(() {
          _fullContact = full;
          if (_firstNameController.text.isEmpty && full.name.first.isNotEmpty) {
            _firstNameController.text = full.name.first;
          }
          if (_lastNameController.text.isEmpty && full.name.last.isNotEmpty) {
            _lastNameController.text = full.name.last;
          }
          if (_companyController.text.isEmpty && full.organizations.isNotEmpty) {
            _companyController.text = full.organizations.first.company;
          }
          if (_jobTitleController.text.isEmpty && full.organizations.isNotEmpty) {
            _jobTitleController.text = full.organizations.first.title;
          }
          if (_emailController.text.isEmpty && full.emails.isNotEmpty) {
            _emailController.text = full.emails.first.address;
          }
          if (_phoneControllers.isEmpty ||
              (_phoneControllers.length == 1 && _phoneControllers.first.text.isEmpty)) {
            if (full.phones.isNotEmpty) {
              for (final c in _phoneControllers) {
                c.dispose();
              }
              _phoneControllers = full.phones
                  .map((p) => TextEditingController(text: p.number))
                  .toList();
            }
          }
        });
        ContactCache.updateContact(full);
      }
    } catch (_) {}
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
    setState(() => _phoneControllers.add(TextEditingController()));
  }

  void _removePhoneField(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _phoneControllers[index].dispose();
      _phoneControllers.removeAt(index);
    });
  }

  Future<void> _pickPhoto() async {
    final result = await showContactPhotoPickerSheet(
      context,
      hasExistingPhoto: _effectivePhotoBytes != null,
    );

    if (result == null || !mounted) return;

    if (result is ContactPhotoBytes) {
      setState(() {
        _photoBytes = result.bytes;
        _photoChanged = true;
      });
      ToastService.info(context, 'Photo updated');
    } else if (result is ContactPhotoRemoved) {
      _removePhoto();
    }
  }

  void _removePhoto() {
    HapticFeedback.lightImpact();
    setState(() {
      _photoBytes = null;
      _photoChanged = true;
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

  Uint8List? get _effectivePhotoBytes {
    if (_photoChanged) {
      return _photoBytes;
    }
    return _fullContact?.photo ??
        _fullContact?.thumbnail ??
        widget.contact.photo ??
        widget.contact.thumbnail;
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
      // On Android, updating contacts requires raw account IDs to be present.
      Contact target = _fullContact ?? widget.contact;
      if (target.accounts.isEmpty) {
        final full = await FlutterContacts.getContact(
          target.id,
          withAccounts: true,
          withProperties: true,
          withPhoto: true,
          withThumbnail: true,
        );
        if (full != null) {
          target = full;
        }
      }

      target.name.first = firstName;
      target.name.last = lastName;
      target.phones = phones.map((p) => Phone(p)).toList();

      final company = _companyController.text.trim();
      final jobTitle = _jobTitleController.text.trim();
      target.organizations = (company.isNotEmpty || jobTitle.isNotEmpty)
          ? [Organization(company: company, title: jobTitle)]
          : [];

      final email = _emailController.text.trim();
      target.emails = email.isNotEmpty ? [Email(email)] : [];

      if (_photoChanged) {
        target.photo = _photoBytes;
      }

      await target.update();
      ContactCache.updateContact(target);

      if (mounted) {
        ToastService.success(context, 'Contact updated successfully.');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ToastService.error(context, 'Failed to update contact: $e');
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
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    final scheme = Theme.of(context).colorScheme;

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
            placeholder: placeholder,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
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
    final photo = _effectivePhotoBytes;

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
                  gradient: photo == null
                      ? LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: (photo == null ? gradient.first : scheme.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: photo != null
                      ? Image.memory(
                          photo,
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
        title: const Text('Edit Contact'),
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
            onTap: () => Navigator.of(context).pop(false),
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
              text: 'Edit Contact',
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
                    placeholder: 'Given name…',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildField(
                    context: context,
                    label: 'Last Name',
                    controller: _lastNameController,
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
                    final isOnly = _phoneControllers.length == 1;

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
                    placeholder: 'Company / Organization name…',
                    textInputAction: TextInputAction.next,
                  ),
                  _buildField(
                    context: context,
                    label: 'Job Title',
                    controller: _jobTitleController,
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
