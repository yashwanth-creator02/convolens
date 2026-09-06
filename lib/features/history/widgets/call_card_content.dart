import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

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
  final Contact? deviceContact;

  const CallCardContent({
    super.key,
    required this.call,
    required this.db,
    required this.settings,
    required this.detail,
    required this.tags,
    required this.attachmentCount,
    this.deviceContact,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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

    final initials = _getInitials(displayName);

    final visibleTags = tags.take(2).toList();
    final remainingTagCount = tags.length - visibleTags.length;

    final showIndicators =
        (hasReminder && showReminderIndicator) ||
        (attachmentCount > 0 && showAttachmentCount) ||
        (showTags && visibleTags.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => CallDetailScreen(call: call, db: db),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: deviceContact?.thumbnail != null
                          ? MemoryImage(deviceContact!.thumbnail!)
                          : deviceContact?.photo != null
                          ? MemoryImage(deviceContact!.photo!)
                          : null,
                      backgroundColor: scheme.secondaryContainer,
                      child:
                          deviceContact?.thumbnail == null &&
                              deviceContact?.photo == null
                          ? Text(
                              initials,
                              style: TextStyle(
                                color: scheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showContactName)
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                          if (showPhoneNumber &&
                              phoneNumber?.isNotEmpty == true &&
                              contactName?.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              phoneNumber!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                if (detailParts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.call_outlined,
                        size: 15,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          detailParts.join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (hasNote && showNotePreview) ...[
                  const SizedBox(height: 8),
                  CallNotePreview(note: notePreview!),
                ],

                if (showIndicators) ...[
                  const SizedBox(height: 8),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
