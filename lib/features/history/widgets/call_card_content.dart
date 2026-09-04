import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../screens/call_details_screen.dart';
import '../utils/call_type_label.dart';
import '../utils/format_call_time.dart';
import 'call_indicators.dart';
import 'call_note_preview.dart';

class CallCardContent extends StatelessWidget {
  final Call call;
  final AppDatabase db;
  final Setting? settings;
  final CallDetail? detail;
  final List<Tag> tags;
  final int attachmentCount;

  const CallCardContent({
    super.key,
    required this.call,
    required this.db,
    required this.settings,
    required this.detail,
    required this.tags,
    required this.attachmentCount,
  });

  @override
  Widget build(BuildContext context) {
    final contactName = call.name?.trim();
    final phoneNumber = call.number?.trim();

    final displayName = contactName?.isNotEmpty == true
        ? contactName!
        : phoneNumber?.isNotEmpty == true
        ? phoneNumber!
        : 'Unknown';

    final showContactName = settings?.showContactName ?? true;
    final showPhoneNumber = settings?.showPhoneNumber ?? true;
    final showCallType = settings?.showCallType ?? true;
    final showDuration = settings?.showDuration ?? true;
    final showTime = settings?.showTime ?? true;
    final showNotePreview = settings?.showNotePreview ?? true;
    final showTags = settings?.showTags ?? true;
    final showReminderIndicator = settings?.showReminderIndicator ?? true;
    final showAttachmentCount = settings?.showAttachmentCount ?? true;

    final detailParts = <String>[
      if (showCallType) callTypeLabel(call.type),
      if (showDuration) '${call.duration}s',
      if (showTime) formatCallTime(call.timestamp),
    ];

    final note = detail?.note?.trim();
    final hasNote = note?.isNotEmpty == true;

    final notePreview = hasNote
        ? note!.length > 50
              ? '${note.substring(0, 50)}…'
              : note
        : null;

    final hasReminder = detail?.reminderAt != null;

    final visibleTags = tags.take(2).toList();
    final remainingTagCount = tags.length - visibleTags.length;

    final showIndicators =
        (hasReminder && showReminderIndicator) ||
        (attachmentCount > 0 && showAttachmentCount) ||
        (showTags && visibleTags.isNotEmpty);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => CallDetailScreen(call: call, db: db),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showContactName)
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

              if (showPhoneNumber &&
                  phoneNumber?.isNotEmpty == true &&
                  contactName?.isNotEmpty == true)
                Text(
                  phoneNumber!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),

              if (detailParts.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  detailParts.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],

              if (hasNote && showNotePreview)
                CallNotePreview(note: notePreview!),

              if (showIndicators)
                CallIndicators(
                  hasReminder: hasReminder,
                  showReminderIndicator: showReminderIndicator,
                  attachmentCount: attachmentCount,
                  showAttachmentCount: showAttachmentCount,
                  showTags: showTags,
                  visibleTags: visibleTags,
                  remainingTagCount: remainingTagCount,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
