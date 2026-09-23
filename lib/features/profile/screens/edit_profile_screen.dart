import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../models/profile_field_def.dart';

class EditProfileScreen extends StatefulWidget {
  final AppDatabase db;

  const EditProfileScreen({super.key, required this.db});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _titleController = GlassLargeTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4.5),
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
    );
  }

  IconData _sectionIcon(String section) {
    switch (section) {
      case 'Basic':
        return Icons.person_outline_rounded;
      case 'Contact':
        return Icons.contact_phone_outlined;
      case 'Professional':
        return Icons.work_outline_rounded;
      case 'Address':
        return Icons.location_on_outlined;
      case 'Online':
        return Icons.language_rounded;
      case 'Additional':
        return Icons.notes_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Edit Details'),
        largeTitleController: _titleController,
      ),
      body: StreamBuilder<Map<String, ProfileFieldEntry>>(
        stream: widget.db.watchProfileFields(),
        builder: (context, snapshot) {
          final fields = snapshot.data ?? {};

          return Material(
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
                  text: 'Edit Details',
                  controller: _titleController,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      profileSectionOrder.map((section) {
                        final sectionDefs = profileFieldDefs
                            .where((def) => def.section == section)
                            .toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: GlassGroupedSection(
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 20,
                            ),
                            quality: GlassQuality.standard,
                            header: _buildSectionHeader(
                              context,
                              title: section,
                              icon: _sectionIcon(section),
                            ),
                            children: sectionDefs
                                .map(
                                  (def) => _FieldEditor(
                                    def: def,
                                    entry: fields[def.key],
                                    db: widget.db,
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FieldEditor extends StatefulWidget {
  final ProfileFieldDef def;
  final ProfileFieldEntry? entry;
  final AppDatabase db;

  const _FieldEditor({
    required this.def,
    required this.entry,
    required this.db,
  });

  @override
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry?.value ?? '');
  }

  @override
  void didUpdateWidget(covariant _FieldEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incomingValue = widget.entry?.value ?? '';
    if (_controller.text != incomingValue && !_controller.selection.isValid) {
      _controller.text = incomingValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextInputType _keyboardTypeFor(FieldInputType type) {
    switch (type) {
      case FieldInputType.phone:
        return TextInputType.phone;
      case FieldInputType.email:
        return TextInputType.emailAddress;
      case FieldInputType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shared = widget.entry?.shared ?? false;
    final isMultiline = widget.def.type == FieldInputType.multiline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: _keyboardTypeFor(widget.def.type),
              maxLines: isMultiline ? 3 : 1,
              style: TextStyle(
                fontSize: 14.5,
                color: scheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: widget.def.label,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: scheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
              ),
              onChanged: (value) =>
                  widget.db.setProfileFieldValue(widget.def.key, value),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              GlassSwitch(
                value: shared,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  widget.db.setProfileFieldShared(widget.def.key, value);
                },
                useOwnLayer: false,
                quality: GlassQuality.standard,
                activeColor: scheme.primary,
                width: 44.0,
                height: 26.0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
