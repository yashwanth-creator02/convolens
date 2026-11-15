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
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
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
      ),
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
                    height:
                        MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                ),
                GlassLargeTitle(
                  text: 'Edit Details',
                  controller: _titleController,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Field input sections ───────────────────────────
                      ...profileSectionOrder.map((section) {
                        final sectionDefs = profileFieldDefs
                            .where((def) => def.section == section)
                            .toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                context,
                                title: section,
                                icon: _sectionIcon(section),
                              ),
                              const SizedBox(height: 12),
                              ...sectionDefs.map(
                                (def) => _FieldEditor(
                                  def: def,
                                  entry: fields[def.key],
                                  db: widget.db,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ]),
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

// ── Field editor (text input only, no share toggle) ────────────────────────

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
    final isMultiline = widget.def.type == FieldInputType.multiline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              widget.def.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                letterSpacing: 0.2,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: isMultiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _controller,
                  placeholder: 'Enter ${widget.def.label.toLowerCase()}…',
                  keyboardType: _keyboardTypeFor(widget.def.type),
                  minLines: 1,
                  maxLines: isMultiline ? 3 : 1,
                  quality: GlassQuality.standard,
                  useOwnLayer: false,
                  shape: const LiquidRoundedRectangle(borderRadius: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  textStyle: TextStyle(
                    fontSize: 14.5,
                    color: scheme.onSurface,
                  ),
                  placeholderStyle: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                  ),
                  onChanged: (value) =>
                      widget.db.setProfileFieldValue(widget.def.key, value),
                ),
              ),
              const SizedBox(width: 8),
              _EyeShareButton(
                db: widget.db,
                def: widget.def,
                entry: widget.entry,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Per-field eye/share toggle ───────────────────────────────────

class _EyeShareButton extends StatelessWidget {
  final AppDatabase db;
  final ProfileFieldDef def;
  final ProfileFieldEntry? entry;

  const _EyeShareButton({
    required this.db,
    required this.def,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isShared = entry?.shared ?? true;

    return Tooltip(
      message: isShared
          ? '${def.label}: Sharable (tap to hide)'
          : '${def.label}: Excluded (tap to share)',
      child: GlassIconButton(
        size: 46,
        shape: GlassIconButtonShape.roundedSquare,
        borderRadius: 14,
        quality: GlassQuality.standard,
        useOwnLayer: false,
        glowColor: isShared
            ? scheme.primary.withValues(alpha: 0.25)
            : scheme.error.withValues(alpha: 0.2),
        onPressed: () {
          HapticFeedback.selectionClick();
          db.setProfileFieldShared(def.key, !isShared);
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: Icon(
            isShared ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            key: ValueKey<bool>(isShared),
            size: 20,
            color: isShared
                ? scheme.primary
                : scheme.error.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
