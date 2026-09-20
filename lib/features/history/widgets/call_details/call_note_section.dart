import 'package:flutter/material.dart';

class CallNoteSection extends StatelessWidget {
  final String? note;
  final VoidCallback onAdd;
  final VoidCallback onEdit;

  const CallNoteSection({
    super.key,
    required this.note,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trimmedNote = note?.trim();
    final hasNote = trimmedNote?.isNotEmpty == true;

    if (hasNote) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.3),
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
                        trimmedNote!,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 14.5,
                          height: 1.45,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: scheme.primary.withValues(alpha: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap to edit',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 20,
              color: scheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add a note about this call…',
                style: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 13.5,
                ),
              ),
            ),
            Icon(
              Icons.add_rounded,
              size: 18,
              color: scheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

