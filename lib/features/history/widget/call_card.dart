import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../screens/call_details_screen.dart';
import '../utils/call_type_label.dart';
import '../utils/format_call_time.dart';

class CallCard extends StatelessWidget {
  final Call call;
  final AppDatabase db;

  const CallCard({super.key, required this.call, required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Setting>(
      stream: db.watchSettings(),
      builder: (context, settingsSnapshot) {
        return _CallCardStreams(
          call: call,
          db: db,
          settings: settingsSnapshot.data,
        );
      },
    );
  }
}

class _CallCardStreams extends StatelessWidget {
  final Call call;
  final AppDatabase db;
  final Setting? settings;

  const _CallCardStreams({
    required this.call,
    required this.db,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CallDetail?>(
      stream: db.watchDetailsForCall(call.id),
      builder: (context, detailSnapshot) {
        return StreamBuilder<List<Tag>>(
          stream: db.watchTagsForCall(call.id),
          builder: (context, tagsSnapshot) {
            return StreamBuilder<int>(
              stream: db.watchAttachmentCountForCall(call.id),
              builder: (context, attachmentSnapshot) {
                return _CallCardContent(
                  call: call,
                  db: db,
                  settings: settings,
                  detail: detailSnapshot.data,
                  tags: tagsSnapshot.data ?? const [],
                  attachmentCount: attachmentSnapshot.data ?? 0,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CallCardContent extends StatelessWidget {
  final Call call;
  final AppDatabase db;
  final Setting? settings;
  final CallDetail? detail;
  final List<Tag> tags;
  final int attachmentCount;

  const _CallCardContent({
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
          Navigator.push(
            context,
            MaterialPageRoute(
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

              if (hasNote && showNotePreview) _NotePreview(note: notePreview!),

              if (showIndicators)
                _CallIndicators(
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

class _NotePreview extends StatelessWidget {
  final String note;

  const _NotePreview({required this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.notes, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallIndicators extends StatelessWidget {
  final bool hasReminder;
  final bool showReminderIndicator;
  final int attachmentCount;
  final bool showAttachmentCount;
  final bool showTags;
  final List<Tag> visibleTags;
  final int remainingTagCount;

  const _CallIndicators({
    required this.hasReminder,
    required this.showReminderIndicator,
    required this.attachmentCount,
    required this.showAttachmentCount,
    required this.showTags,
    required this.visibleTags,
    required this.remainingTagCount,
  });

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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_file, size: 14, color: Colors.grey),
                Text(
                  ' $attachmentCount',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

          if (showTags)
            ...visibleTags.map(
              (tag) => Chip(
                label: Text(tag.name, style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

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
