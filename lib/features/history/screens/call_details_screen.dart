import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/toast/toast_service.dart';
import '../../../core/utils/normalize_number.dart';
import '../../../shared/widgets/add_tag_dialog.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/text_input_dialog.dart';
import '../../contacts/screens/contact_detail_screen.dart';
import '../repository/attachment_storage.dart';
import '../utils/call_type_label.dart';
import '../utils/format_call_time.dart';

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

    await db.saveNote(call.id, result);

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
      builder: (context) => AddTagDialog(existingTags: existingTags),
    );

    if (result == null || result.isEmpty) return;

    await db.addTagToCall(call.id, result);
  }

  Future<void> _setReminder(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      if (context.mounted) {
        ToastService.error(context, 'Please pick a time in the future.');
      }
      return;
    }

    if (!context.mounted) return;
    final label = await showTextInputDialog(
      context: context,
      title: 'Reminder Note',
      hintText: 'e.g. Call back about project',
      confirmLabel: 'Set Reminder',
    );
    if (label == null) return;

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

    await NotificationService.scheduleReminder(
      callId: call.id,
      scheduledTime: reminderTime,
      title: label.isNotEmpty ? label : 'Call reminder: $displayName',
      body: 'Follow up on your call with $displayName',
    );

    await db.saveReminder(
      call.id,
      reminderTime,
      label.isNotEmpty ? label : null,
    );

    if (context.mounted) {
      ToastService.success(context, 'Reminder set.');
    }
  }

  Future<void> _clearReminder(BuildContext context) async {
    await NotificationService.cancelReminder(call.id);
    await db.clearReminder(call.id);
    if (context.mounted) {
      ToastService.success(context, 'Reminder removed.');
    }
  }

  Future<void> _addAttachment(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result == null || result.files.single.path == null) return;

    final pickedFile = result.files.single;
    final sourcePath = pickedFile.path!;
    final extension = pickedFile.extension?.toLowerCase() ?? '';
    final fileType = extension == 'pdf' ? 'pdf' : 'image';

    if (!context.mounted) return;

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

    if (context.mounted) {
      ToastService.success(context, 'Attachment added.');
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

    await AttachmentStorage.deleteFile(attachment.filePath);
    await db.deleteAttachment(attachment.id);

    if (context.mounted) {
      ToastService.success(context, 'Attachment removed.');
    }
  }

  void _viewAttachment(BuildContext context, CallAttachment attachment) {
    if (attachment.fileType == 'image') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ImagePreviewScreen(
            filePath: attachment.filePath,
            title: attachment.originalFileName,
          ),
        ),
      );
    } else {
      OpenFilex.open(attachment.filePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = call.name?.isNotEmpty == true
        ? call.name!
        : (call.number ?? 'Unknown');

    return Scaffold(
      appBar: AppBar(title: const Text('Call Details')),
      body: StreamBuilder<Setting>(
        stream: db.watchSettings(),
        builder: (context, settingsSnapshot) {
          final devMode = settingsSnapshot.data?.devMode ?? false;

          return StreamBuilder<CallDetail?>(
            stream: db.watchDetailsForCall(call.id),
            builder: (context, detailSnapshot) {
              final note = detailSnapshot.data?.note;
              final hasNote = note != null && note.isNotEmpty;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContactDetailScreen(
                              normalizedNumber: normalizePhoneNumber(
                                call.number,
                              ),
                              displayName: displayName,
                              displayNumber: call.number ?? '',
                              db: db,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const Text('View Contact'),
                    ),
                    const SizedBox(height: 4),
                    if (call.number != null) Text(call.number!),
                    const SizedBox(height: 16),

                    _DetailRow(label: 'Type', value: callTypeLabel(call.type)),
                    _DetailRow(
                      label: 'Duration',
                      value: '${call.duration} seconds',
                    ),
                    _DetailRow(
                      label: 'Time',
                      value: formatCallTime(call.timestamp),
                    ),

                    const Divider(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Note',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (!hasNote)
                          TextButton.icon(
                            onPressed: () => _editNote(context, note),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (hasNote)
                      InkWell(
                        onTap: () => _editNote(context, note),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Text(note)),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),

                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tags',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () => _addTag(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Tag>>(
                      stream: db.watchTagsForCall(call.id),
                      builder: (context, tagSnapshot) {
                        final callTags = tagSnapshot.data ?? [];

                        if (callTags.isEmpty) {
                          return const Text(
                            'No tags yet.',
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: callTags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag.name),
                                  onDeleted: () =>
                                      db.removeTagFromCall(call.id, tag.id),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),

                    const Divider(height: 32),
                    StreamBuilder<CallDetail?>(
                      stream: db.watchReminderForCall(call.id),
                      builder: (context, reminderSnapshot) {
                        final reminder = reminderSnapshot.data;
                        final hasReminder = reminder?.reminderAt != null;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Reminder',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (!hasReminder)
                                  TextButton.icon(
                                    onPressed: () => _setReminder(context),
                                    icon: const Icon(Icons.alarm_add, size: 18),
                                    label: const Text('Set'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (hasReminder)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.alarm,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (reminder?.reminderLabel != null &&
                                              reminder!
                                                  .reminderLabel!
                                                  .isNotEmpty)
                                            Text(
                                              reminder.reminderLabel!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          Text(
                                            DateTime.fromMillisecondsSinceEpoch(
                                              reminder!.reminderAt!,
                                            ).toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => _clearReminder(context),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Attachments',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () => _addAttachment(context),
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<CallAttachment>>(
                      stream: db.watchAttachmentsForCall(call.id),
                      builder: (context, attachmentSnapshot) {
                        final attachments = attachmentSnapshot.data ?? [];

                        if (attachments.isEmpty) {
                          return const Text(
                            'No attachments yet.',
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        return Column(
                          children: attachments.map((attachment) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () => _viewAttachment(context, attachment),
                              leading: Icon(
                                attachment.fileType == 'pdf'
                                    ? Icons.picture_as_pdf
                                    : Icons.image,
                                color: attachment.fileType == 'pdf'
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                              title: Text(attachment.originalFileName),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _deleteAttachment(context, attachment),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    if (devMode) ...[
                      const Divider(height: 32),
                      const Text(
                        'Developer Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(label: 'Row ID', value: call.id.toString()),
                      _DetailRow(
                        label: 'Raw type code',
                        value: call.type.toString(),
                      ),
                      _DetailRow(
                        label: 'Raw timestamp (epoch ms)',
                        value: call.timestamp.toString(),
                      ),
                      _DetailRow(
                        label: 'Removed from device',
                        value: call.removedFromDevice.toString(),
                      ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
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
