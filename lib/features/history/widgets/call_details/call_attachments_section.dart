import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class CallAttachmentsSection extends StatelessWidget {
  final List<CallAttachment> attachments;
  final VoidCallback onAdd;
  final void Function(CallAttachment attachment) onView;
  final void Function(CallAttachment attachment) onDelete;

  const CallAttachmentsSection({
    super.key,
    required this.attachments,
    required this.onAdd,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (attachments.isEmpty) {
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
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                size: 20,
                color: scheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Attach photos, PDFs, or voice notes…',
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

    return Column(
      children: [
        ...attachments.map((attachment) {
          final isPdf = attachment.fileType == 'pdf';
          final isVoice = attachment.fileType == 'voice';

          final IconData iconData;
          final Color iconColor;
          final String title;

          if (isVoice) {
            iconData = Icons.graphic_eq_rounded;
            iconColor = Colors.purpleAccent;
            title = 'Voice Note';
          } else if (isPdf) {
            iconData = Icons.picture_as_pdf_rounded;
            iconColor = Colors.redAccent;
            title = attachment.originalFileName;
          } else {
            iconData = Icons.image_rounded;
            iconColor = Colors.blueAccent;
            title = attachment.originalFileName;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onView(attachment),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(iconData, size: 20, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13.5,
                                color: scheme.onSurface,
                              ),
                            ),
                            if (isVoice)
                              Text(
                                'Tap to play audio',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: scheme.error.withValues(alpha: 0.8),
                        ),
                        tooltip: 'Remove Attachment',
                        onPressed: () => onDelete(attachment),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Another'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}

