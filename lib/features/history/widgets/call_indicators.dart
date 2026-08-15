import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

class CallIndicators extends StatelessWidget {
  final bool hasReminder;
  final bool showReminderIndicator;
  final int attachmentCount;
  final bool showAttachmentCount;
  final bool showTags;
  final List<Tag> visibleTags;
  final int remainingTagCount;

  const CallIndicators({
    super.key,
    required this.hasReminder,
    required this.showReminderIndicator,
    required this.attachmentCount,
    required this.showAttachmentCount,
    required this.showTags,
    required this.visibleTags,
    required this.remainingTagCount,
  });

  Widget _buildAttachmentIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.attach_file, size: 14, color: Colors.grey),
        Text(
          ' $attachmentCount',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTagIndicator(String name) {
    return Chip(
      label: Text(name, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (hasReminder && showReminderIndicator)
            const Icon(Icons.alarm, size: 16, color: Colors.orange),

          if (attachmentCount > 0 && showAttachmentCount)
            _buildAttachmentIndicator(),

          if (showTags)
            ...visibleTags.map((tag) => _buildTagIndicator(tag.name)),

          if (showTags && remainingTagCount > 0)
            Text(
              '+$remainingTagCount',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
