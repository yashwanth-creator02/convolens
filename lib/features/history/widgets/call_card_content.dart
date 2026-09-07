import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/call_launcher.dart';
import '../screens/call_details_screen.dart';
import '../utils/call_type_label.dart';
import '../utils/format_call_time.dart';
import '../utils/format_duration.dart';
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
  final bool showCallButton;
  final bool showPhoneNumber;
  final bool showName;

  const CallCardContent({
    super.key,
    required this.call,
    required this.db,
    required this.settings,
    required this.detail,
    required this.tags,
    required this.attachmentCount,
    this.deviceContact,
    this.showCallButton = true,
    this.showPhoneNumber = true,
    this.showName = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final contactName = call.name?.trim();
    final phoneNumber = call.number?.trim();

    // Determine title and subtitle based on overrides and settings
    final hasName = contactName?.isNotEmpty == true;
    final hasNumber = phoneNumber?.isNotEmpty == true;

    final displayTitle = (showName && hasName)
        ? contactName!
        : hasNumber
        ? phoneNumber!
        : 'Unknown';

    final showSubtitle =
        showName &&
        hasName &&
        showPhoneNumber &&
        (settings?.showPhoneNumber ?? true) &&
        hasNumber;

    final displaySubtitle = showSubtitle ? phoneNumber : null;

    // Settings toggles
    final showContactNameSetting = settings?.showContactName ?? true;
    final showCallType = settings?.showCallType ?? true;
    final showDuration = settings?.showDuration ?? true;
    final showTime = settings?.showTime ?? true;
    final showNotePreview = settings?.showNotePreview ?? true;
    final showTags = settings?.showTags ?? true;
    final showReminderIndicator = settings?.showReminderIndicator ?? true;
    final showAttachmentCount = settings?.showAttachmentCount ?? true;

    final note = detail?.note?.trim();
    final hasNote = note?.isNotEmpty == true;

    final notePreview = hasNote
        ? (note!.length > 50 ? '${note.substring(0, 50)}…' : note)
        : null;

    final hasReminder = detail?.reminderAt != null;
    final visibleTags = tags.take(2).toList();
    final remainingTagCount = tags.length - visibleTags.length;

    final showIndicators =
        (hasReminder && showReminderIndicator) ||
        (attachmentCount > 0 && showAttachmentCount) ||
        (showTags && visibleTags.isNotEmpty);

    final callTypeColor = _getCallTypeColor(call.type, scheme);
    final tabBackgroundColor =
        Color.lerp(scheme.surfaceContainer, callTypeColor, 0.06) ??
        scheme.surfaceContainer;

    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 4, 11, 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ------------------------------------------------------------
          // Bottom metadata tab (Background Layer)
          // ------------------------------------------------------------
          Positioned(
            left: 16,
            right: 16,
            bottom: -16,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tabBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: callTypeColor.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 26, 12, 1),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (showCallType)
                        _CallMetaItem(
                          icon: callTypeIcon(call.type),
                          value: callTypeLabel(call.type),
                          color: callTypeColor,
                        ),
                      if (showCallType && (showDuration || showTime))
                        const _MetaDivider(),
                      if (showDuration && call.duration > 0)
                        _CallMetaItem(
                          icon: Icons.timer_outlined,
                          value: formatDuration(call.duration),
                        ),
                      if (showDuration && call.duration > 0 && showTime)
                        const _MetaDivider(),
                      if (showTime)
                        _CallMetaItem(
                          icon: Icons.schedule_outlined,
                          value: formatCallTime(call.timestamp),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ------------------------------------------------------------
          // Main contact card (Foreground Layer)
          // ------------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) =>
                          CallDetailScreen(call: call, db: db),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ------------------------------------------------
                      // Contact Row
                      // ------------------------------------------------
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                (deviceContact?.thumbnail == null &&
                                    deviceContact?.photo == null)
                                ? Text(
                                    _getInitials(
                                      hasName ? contactName! : displayTitle,
                                    ),
                                    style: TextStyle(
                                      color: scheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showContactNameSetting || !showName)
                                  Text(
                                    displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                if (displaySubtitle != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    displaySubtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (showCallButton && hasNumber)
                            IconButton(
                              icon: const Icon(Icons.call_outlined, size: 20),
                              onPressed: () => CallLauncher.call(phoneNumber!),
                              color: scheme.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),

                      // ------------------------------------------------
                      // Optional note
                      // ------------------------------------------------
                      if (hasNote && showNotePreview) ...[
                        const SizedBox(height: 12),
                        CallNotePreview(note: notePreview!),
                      ],

                      // ------------------------------------------------
                      // Existing indicators
                      // ------------------------------------------------
                      if (showIndicators) ...[
                        const SizedBox(height: 12),
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
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Color _getCallTypeColor(int type, ColorScheme scheme) {
    switch (type) {
      case 3: // Missed
      case 5: // Rejected
      case 6: // Blocked
        return scheme.error;
      case 1: // Incoming
        return Colors.teal;
      case 2: // Outgoing
        return scheme.primary;
      default:
        return scheme.onSurfaceVariant;
    }
  }
}

class _CallMetaItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;

  const _CallMetaItem({required this.icon, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveColor = color ?? scheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            color: effectiveColor,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MetaDivider extends StatelessWidget {
  const _MetaDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
