import 'package:flutter/material.dart';

import '../../../shared/widgets/text_input_dialog.dart';

class ContactNoteSection extends StatelessWidget {
  final String? note;
  final Future<void> Function(String note) onSave;

  const ContactNoteSection({
    super.key,
    required this.note,
    required this.onSave,
  });

  bool get _hasNote => note != null && note!.trim().isNotEmpty;

  Future<void> _editNote(BuildContext context) async {
    final result = await showTextInputDialog(
      context: context,
      title: 'Contact Note',
      initialValue: note,
      hintText: 'General notes about this contact…',
      maxLines: 4,
    );

    if (result == null) {
      return;
    }

    await onSave(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!_hasNote) {
      return InkWell(
        onTap: () => _editNote(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Add note about this contact...',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _NoteCard(
      note: note!,
      onTap: () => _editNote(context),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                note,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined, size: 16, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
