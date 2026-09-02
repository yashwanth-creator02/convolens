import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/toast/toast_service.dart';
import '../../../shared/widgets/add_tag_dialog.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/text_input_dialog.dart';
import '../repository/attachment_storage.dart';
import '../widgets/call_details/call_attachments_section.dart';
import '../widgets/call_details/call_developer_info.dart';
import '../widgets/call_details/call_info_section.dart';
import '../widgets/call_details/call_note_section.dart';
import '../widgets/call_details/call_reminder_section.dart';
import '../widgets/call_details/call_tags_section.dart';
import '../widgets/voice_note_player_sheet.dart';
import '../widgets/voice_recorder_dialog.dart';

class CallDetailScreen extends StatelessWidget {
  final Call call;
  final AppDatabase db;

  const CallDetailScreen({super.key, required this.call, required this.db});

  Future<void> _editNote(BuildContext context, String? currentNote) async {
    final result = await showTextInputDialog(
      context: context,
      title: 'Call Note',
      initialValue: currentNote,
      hintText: 'Add a note about this call…',
      maxLines: 4,
    );

    if (result == null) return;

    try {
      await db.saveNote(call.id, result);

      if (!context.mounted) return;

      ToastService.success(context, 'Note saved.');
    } catch (e) {
      if (!context.mounted) return;

      ToastService.error(context, 'Failed to save note.');
    }
  }

  Future<void> _addTag(BuildContext context) async {
    final existingTags = await db.getAllTags();

    if (!context.mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AddTagDialog(existingTags: existingTags);
      },
    );

    if (result == null || result.isEmpty) return;

    await db.addTagToCall(call.id, result);
  }

  Future<void> _setReminder(BuildContext context) async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null || !context.mounted) return;

    final reminderTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (reminderTime.isBefore(DateTime.now())) {
      ToastService.error(context, 'Please pick a time in the future.');
      return;
    }

    final label = await showTextInputDialog(
      context: context,
      title: 'Reminder Note',
      hintText: 'e.g. Call back about project',
      confirmLabel: 'Set Reminder',
    );

    if (label == null || !context.mounted) return;

    final notificationsGranted =
        await NotificationService.areNotificationsGranted();

    if (!notificationsGranted) {
      final granted = await NotificationService.requestNotificationPermission();

      if (!granted) {
        if (context.mounted) {
          ToastService.error(
            context,
            'Notification permission is required to set reminders.',
          );
        }
        return;
      }
    }

    final displayName = call.name?.isNotEmpty == true
        ? call.name!
        : (call.number ?? 'Unknown');

    // Use the user's note if provided.
    // Otherwise, create a sensible default title.
    final reminderTitle = label.trim().isNotEmpty
        ? label.trim()
        : 'Call reminder: $displayName';

    await NotificationService.scheduleReminder(
      callId: call.id,
      scheduledTime: reminderTime,
      title: reminderTitle,
      body: 'Follow up on your call with $displayName',
    );

    await db.saveReminder(
      call.id,
      reminderTime,
      label.trim().isNotEmpty ? label.trim() : null,
    );

    if (!context.mounted) return;

    // Calculate how much time is left until the reminder.
    final remaining = reminderTime.difference(DateTime.now());

    String remainingText;

    if (remaining.inDays > 0) {
      final days = remaining.inDays;
      remainingText = '$days ${days == 1 ? 'day' : 'days'}';
    } else if (remaining.inHours > 0) {
      final hours = remaining.inHours;
      remainingText = '$hours ${hours == 1 ? 'hour' : 'hours'}';
    } else {
      final minutes = remaining.inMinutes;

      if (minutes <= 1) {
        remainingText = '1 minute';
      } else {
        remainingText = '$minutes minutes';
      }
    }

    ToastService.success(
      context,
      'Reminder set. You’ll be notified in $remainingText.',
    );
  }

  Future<void> _clearReminder(BuildContext context) async {
    try {
      await NotificationService.cancelReminder(call.id);

      await db.clearReminder(call.id);

      if (!context.mounted) return;

      ToastService.success(context, 'Reminder removed.');
    } catch (e) {
      if (!context.mounted) return;

      ToastService.error(context, 'Failed to remove reminder.');
    }
  }

  Future<void> _chooseAttachmentType(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Photo or PDF'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Voice Note'),
              onTap: () => Navigator.pop(context, 'voice'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || choice == null) return;

    if (choice == 'file') {
      await _addFileAttachment(context);
    } else {
      await _recordVoiceNote(context);
    }
  }

  Future<void> _addFileAttachment(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final pickedFile = result.files.single;
    final sourcePath = pickedFile.path!;

    final extension = pickedFile.extension?.toLowerCase() ?? '';

    final fileType = extension == 'pdf' ? 'pdf' : 'image';

    if (!context.mounted) return;

    try {
      final copiedPath = await AttachmentStorage.copyToAppStorage(
        sourcePath,
        call.id,
      );

      await db.addAttachment(
        callId: call.id,
        filePath: copiedPath,
        originalFileName: pickedFile.name,
        fileType: fileType,
      );

      if (!context.mounted) return;

      ToastService.success(context, 'Attachment added.');
    } catch (e) {
      if (!context.mounted) return;

      ToastService.error(context, 'Failed to add attachment.');
    }
  }

  Future<void> _recordVoiceNote(BuildContext context) async {
    final destinationPath = await AttachmentStorage.newVoiceNotePath(call.id);

    if (!context.mounted) return;

    final savedPath = await showVoiceRecorderDialog(context, destinationPath);

    if (savedPath == null || !context.mounted) return;

    try {
      await db.addAttachment(
        callId: call.id,
        filePath: savedPath,
        originalFileName: 'Voice note',
        fileType: 'voice',
      );

      if (!context.mounted) return;

      ToastService.success(context, 'Voice note added.');
    } catch (e) {
      if (!context.mounted) return;

      ToastService.error(context, 'Failed to save voice note.');
    }
  }

  Future<void> _deleteAttachment(
    BuildContext context,
    CallAttachment attachment,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Remove Attachment?',
      message: 'This will permanently delete "${attachment.originalFileName}".',
      confirmLabel: 'Remove',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      await AttachmentStorage.deleteFile(attachment.filePath);

      await db.deleteAttachment(attachment.id);

      if (!context.mounted) return;

      ToastService.success(context, 'Attachment removed.');
    } catch (e) {
      if (!context.mounted) return;

      ToastService.error(context, 'Failed to remove attachment.');
    }
  }

  void _viewAttachment(BuildContext context, CallAttachment attachment) {
    if (attachment.fileType == 'image') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return _ImagePreviewScreen(
              filePath: attachment.filePath,
              title: attachment.originalFileName,
            );
          },
        ),
      );
      return;
    }

    if (attachment.fileType == 'voice') {
      showVoiceNotePlayerSheet(context, attachment.filePath);
      return;
    }

    OpenFilex.open(attachment.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Details')),
      body: StreamBuilder<Setting>(
        stream: db.watchSettings(),
        builder: (context, settingsSnapshot) {
          final devMode = settingsSnapshot.data?.devMode ?? false;

          return StreamBuilder<CallDetail?>(
            stream: db.watchDetailsForCall(call.id),
            builder: (context, detailSnapshot) {
              final detail = detailSnapshot.data;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CallInfoSection(call: call, db: db),

                    const Divider(height: 32),

                    CallNoteSection(
                      note: detail?.note,
                      onAdd: () => _editNote(context, detail?.note),
                      onEdit: () => _editNote(context, detail?.note),
                    ),

                    const Divider(height: 32),

                    StreamBuilder<List<Tag>>(
                      stream: db.watchTagsForCall(call.id),
                      builder: (context, tagSnapshot) {
                        return CallTagsSection(
                          tags: tagSnapshot.data ?? const [],
                          onAdd: () => _addTag(context),
                          onRemove: (tag) {
                            db.removeTagFromCall(call.id, tag.id);
                          },
                        );
                      },
                    ),

                    const Divider(height: 32),

                    StreamBuilder<CallDetail?>(
                      stream: db.watchReminderForCall(call.id),
                      builder: (context, reminderSnapshot) {
                        return CallReminderSection(
                          reminder: reminderSnapshot.data,
                          onSet: () => _setReminder(context),
                          onClear: () => _clearReminder(context),
                        );
                      },
                    ),

                    const Divider(height: 32),

                    StreamBuilder<List<CallAttachment>>(
                      stream: db.watchAttachmentsForCall(call.id),
                      builder: (context, attachmentSnapshot) {
                        return CallAttachmentsSection(
                          attachments: attachmentSnapshot.data ?? const [],
                          onAdd: () => _chooseAttachmentType(context),
                          onView: (attachment) =>
                              _viewAttachment(context, attachment),
                          onDelete: (attachment) =>
                              _deleteAttachment(context, attachment),
                        );
                      },
                    ),

                    if (devMode) ...[
                      const Divider(height: 32),
                      CallDeveloperInfo(call: call),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ImagePreviewScreen extends StatelessWidget {
  final String filePath;
  final String title;

  const _ImagePreviewScreen({required this.filePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: Colors.black,
      body: Center(child: InteractiveViewer(child: Image.file(File(filePath)))),
    );
  }
}
