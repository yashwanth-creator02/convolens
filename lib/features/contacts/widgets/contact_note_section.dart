import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Shows an interactive liquid glass bottom sheet popup modal
/// for writing or editing a note about a contact, identical in style to [TagSelectionGlassSheet].
Future<void> showContactNoteModal({
  required BuildContext context,
  required String? initialNote,
  String? contactName,
  required FutureOr<void> Function(String note) onSave,
  VoidCallback? onDelete,
}) {
  return GlassSheet.show(
    context: context,
    quality: GlassQuality.standard,
    showDragIndicator: true,
    isScrollable: false,
    enableDrag: false,
    interactionScale: 1.0,
    enableSaturationGlow: false,
    enableInteractionGlow: false,
    suppressInteractionOnChildren: true,
    topBorderRadius: 24,
    bottomBorderRadius: 0,
    margin: EdgeInsets.zero,
    builder: (context) => _ContactNoteGlassSheet(
      initialNote: initialNote,
      contactName: contactName,
      onSave: onSave,
      onDelete: onDelete,
    ),
  );
}

class _ContactNoteGlassSheet extends StatefulWidget {
  final String? initialNote;
  final String? contactName;
  final FutureOr<void> Function(String note) onSave;
  final VoidCallback? onDelete;

  const _ContactNoteGlassSheet({
    required this.initialNote,
    required this.contactName,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_ContactNoteGlassSheet> createState() => _ContactNoteGlassSheetState();
}

class _ContactNoteGlassSheetState extends State<_ContactNoteGlassSheet> {
  static const List<String> _suggestedTemplates = [
    'Spoke today',
    'Follow up required',
    'Callback requested',
    'Meeting scheduled',
    'Important client',
    'Personal / Family',
  ];

  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted) _focusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isEditing =
        widget.initialNote != null && widget.initialNote!.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pinned Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        size: 17,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Contact Note' : 'Contact Note',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isEditing && widget.onDelete != null)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                          widget.onDelete!();
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: scheme.error,
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: () async {
                        final text = _controller.text.trim();
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        await widget.onSave(text);
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.contactName != null &&
                  widget.contactName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: Text(
                    widget.contactName!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Note editor area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 5,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: scheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Write a note about this contact…',
                      hintStyle: TextStyle(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2, right: 2),
                                child: Icon(
                                  Icons.cancel,
                                  size: 16,
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          : null,
                      suffixIconConstraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),

              // Scrollable Quick Suggestions matching GlassChips
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, 'QUICK SUGGESTIONS'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestedTemplates.map((template) {
                          return GlassChip(
                            label: template,
                            icon: Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                            ),
                            selected: false,
                            labelStyle: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            quality: GlassQuality.standard,
                            useOwnLayer: false,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              final cur = _controller.text.trim();
                              if (cur.isEmpty) {
                                _controller.text = template;
                              } else {
                                _controller.text = '$cur • $template';
                              }
                              _controller.selection =
                                  TextSelection.fromPosition(
                                TextPosition(offset: _controller.text.length),
                              );
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays the saved contact note inside the Contact Detail Screen area,
/// or an inviting placeholder when empty. Tapping anywhere opens the note popup modal.
class ContactNoteSection extends StatelessWidget {
  final String? note;
  final String? contactName;
  final FutureOr<void> Function(String note)? onSave;
  final VoidCallback? onClear;

  const ContactNoteSection({
    super.key,
    required this.note,
    this.contactName,
    this.onSave,
    this.onClear,
  });

  bool get _hasNote => note != null && note!.trim().isNotEmpty;

  void _openModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showContactNoteModal(
      context: context,
      initialNote: note,
      contactName: contactName,
      onSave: (newNote) async {
        if (onSave != null) {
          await onSave!(newNote);
        }
      },
      onDelete: onClear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!_hasNote) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openModal(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_comment_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add a note about this contact…',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to write in popup modal',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openModal(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note!.trim(),
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to edit',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
