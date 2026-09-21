import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/toast/toast_service.dart';
import '../../../core/utils/call_launcher.dart';
import '../../../core/utils/call_recording_scanner.dart';
import '../../../core/utils/normalize_number.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../contacts/screens/contact_detail_screen.dart';
import '../../contacts/widgets/add_contact_screen.dart';
import '../repository/attachment_storage.dart';
import '../utils/call_type_label.dart';
import '../utils/format_call_time.dart';
import '../utils/format_duration.dart';
import '../widgets/call_details/call_attachments_section.dart';
import '../widgets/call_details/call_developer_info.dart';
import '../widgets/call_details/call_info_section.dart';
import '../widgets/call_details/call_note_section.dart';
import '../widgets/call_details/call_recording_section.dart';
import '../widgets/call_details/call_reminder_section.dart';
import '../widgets/call_details/call_tags_section.dart';
import '../widgets/call_details/reminder_glass_sheet.dart';
import '../widgets/call_details/tag_selection_glass_sheet.dart';
import '../widgets/voice_note_player_sheet.dart';
import '../widgets/voice_recorder_dialog.dart';

class CallDetailScreen extends StatefulWidget {
  final Call call;
  final AppDatabase db;

  const CallDetailScreen({super.key, required this.call, required this.db});

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  Contact? _deviceContact;

  @override
  void initState() {
    super.initState();
    _loadDeviceContact();
  }

  Future<void> _loadDeviceContact() async {
    final number = widget.call.number?.trim();
    if (number != null && number.isNotEmpty) {
      final contact = await _findDeviceContact(number);
      if (mounted) {
        setState(() {
          _deviceContact = contact;
        });
      }
    }
  }

  Future<Contact?> _findDeviceContact(String phoneNumber) async {
    try {
      final normalized = normalizePhoneNumber(phoneNumber);
      final contacts = await FlutterContacts.getContacts(withProperties: true);

      for (final contact in contacts) {
        for (final phone in contact.phones) {
          if (normalizePhoneNumber(phone.number) == normalized) {
            return contact;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Color _getCallTypeColor(int type, ColorScheme scheme) {
    switch (type) {
      case 3: // Missed
      case 5: // Rejected
      case 6: // Blocked
        return scheme.error;
      case 1: // Incoming
        return scheme.tertiary;
      case 2: // Outgoing
        return scheme.primary;
      default:
        return scheme.onSurfaceVariant;
    }
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    if (RegExp(r'^[+0-9\s\-()]+$').hasMatch(trimmed)) {
      return '#';
    }
    final words =
        trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return words.first.substring(0, 1).toUpperCase();
  }

  Future<void> _openContact(
    BuildContext context,
    String displayName,
    String phoneNumber,
  ) async {
    if (_deviceContact != null) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => ContactDetailScreen(
            normalizedNumber: normalizePhoneNumber(phoneNumber),
            displayName: displayName,
            displayNumber: phoneNumber,
            deviceContact: _deviceContact,
            db: widget.db,
          ),
        ),
      );
    } else {
      final created = await showAddContactScreen(
        context,
        initialName: widget.call.name?.trim().isNotEmpty == true
            ? widget.call.name!.trim()
            : null,
        initialPhone: phoneNumber,
      );

      if (created != null && mounted) {
        setState(() => _deviceContact = created);
        if (context.mounted) {
          ToastService.success(context, 'Contact created.');
        }
      }
    }
  }

  Future<void> _saveNote(BuildContext context, String note) async {
    try {
      await widget.db.saveNote(widget.call.id, note);

      if (!context.mounted) return;

      ToastService.success(context, 'Note saved.');
    } catch (e) {
      if (!context.mounted) return;

      ToastService.error(context, 'Failed to save note.');
    }
  }

  Future<void> _clearNote(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Clear Note?',
      message: 'Are you sure you want to remove the note for this call?',
      confirmLabel: 'Clear',
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) return;

    try {
      await widget.db.saveNote(widget.call.id, '');

      if (!context.mounted) return;
      ToastService.success(context, 'Note cleared.');
    } catch (e) {
      if (!context.mounted) return;
      ToastService.error(context, 'Failed to clear note.');
    }
  }

  Future<void> _addTag(BuildContext context) async {
    await TagSelectionGlassSheet.show(
      context: context,
      db: widget.db,
      callId: widget.call.id,
    );
  }

  Future<void> _setReminder(BuildContext context) async {
    await ReminderGlassSheet.show(
      context: context,
      onSet: (scheduledTime, label) async {
        final notificationsGranted =
            await NotificationService.areNotificationsGranted();

        if (!notificationsGranted) {
          final granted =
              await NotificationService.requestNotificationPermission();
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

        final displayName = widget.call.name?.isNotEmpty == true
            ? widget.call.name!
            : (widget.call.number ?? 'Unknown');

        final reminderTitle = (label != null && label.isNotEmpty)
            ? label
            : 'Call reminder: $displayName';

        await NotificationService.scheduleReminder(
          callId: widget.call.id,
          scheduledTime: scheduledTime,
          title: reminderTitle,
          body: 'Follow up on your call with $displayName',
        );

        await widget.db.saveReminder(
          widget.call.id,
          scheduledTime,
          label,
        );

        if (!context.mounted) return;

        final remaining = scheduledTime.difference(DateTime.now());
        String remainingText;
        if (remaining.inDays > 0) {
          final days = remaining.inDays;
          remainingText = '$days ${days == 1 ? 'day' : 'days'}';
        } else if (remaining.inHours > 0) {
          final hours = remaining.inHours;
          remainingText = '$hours ${hours == 1 ? 'hour' : 'hours'}';
        } else {
          final minutes = remaining.inMinutes;
          remainingText = minutes <= 1 ? '1 minute' : '$minutes minutes';
        }

        ToastService.success(
          context,
          'Reminder set. You\'ll be notified in $remainingText.',
        );
      },
    );
  }

  Future<void> _importRecording(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m4a', 'mp3', 'aac', 'wav', 'ogg', 'opus', 'amr'],
    );

    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;

    final pickedFile = result.files.single;
    final sourcePath = pickedFile.path!;

    try {
      final copiedPath = await AttachmentStorage.copyToAppStorage(
        sourcePath,
        widget.call.id,
      );

      await widget.db.addAttachment(
        callId: widget.call.id,
        filePath: copiedPath,
        originalFileName: pickedFile.name,
        fileType: 'call_recording',
      );

      if (!context.mounted) return;
      ToastService.success(context, 'Call recording linked.');
    } catch (e) {
      if (!context.mounted) return;
      ToastService.error(context, 'Failed to import recording.');
    }
  }

  /// Links an auto-detected device recording (from [CallRecordingScanner])
  /// by copying it into app storage and saving as a [CallAttachment].
  Future<void> _linkRecording(
    BuildContext context,
    String sourcePath,
    String fileName,
  ) async {
    try {
      final copiedPath = await AttachmentStorage.copyToAppStorage(
        sourcePath,
        widget.call.id,
      );

      await widget.db.addAttachment(
        callId: widget.call.id,
        filePath: copiedPath,
        originalFileName: fileName,
        fileType: 'call_recording',
      );

      if (!context.mounted) return;
      ToastService.success(context, 'Recording linked.');
    } catch (e) {
      if (!context.mounted) return;
      ToastService.error(context, 'Failed to link recording.');
    }
  }

  Future<void> _deleteRecording(
    BuildContext context,
    CallAttachment attachment,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Remove Recording?',
      message: 'This will unlink and delete the recording file.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      await AttachmentStorage.deleteFile(attachment.filePath);
      await widget.db.deleteAttachment(attachment.id);

      if (!context.mounted) return;
      ToastService.success(context, 'Recording removed.');
    } catch (e) {
      if (!context.mounted) return;
      ToastService.error(context, 'Failed to remove recording.');
    }
  }

  Future<void> _clearReminder(BuildContext context) async {
    try {
      await NotificationService.cancelReminder(widget.call.id);

      await widget.db.clearReminder(widget.call.id);

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
        widget.call.id,
      );

      await widget.db.addAttachment(
        callId: widget.call.id,
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
    final destinationPath = await AttachmentStorage.newVoiceNotePath(
      widget.call.id,
    );

    if (!context.mounted) return;

    final savedPath = await showVoiceRecorderDialog(context, destinationPath);

    if (savedPath == null || !context.mounted) return;

    try {
      await widget.db.addAttachment(
        callId: widget.call.id,
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

      await widget.db.deleteAttachment(attachment.id);

      if (!context.mounted) return;

      ToastService.success(context, 'Attachment removed.');
    } catch (e) {
      if (!context.mounted) return;

      ToastService.error(context, 'Failed to remove attachment.');
    }
  }

  void _viewAttachment(BuildContext context, CallAttachment attachment) {
    if (attachment.fileType == 'image') {
      Navigator.of(context).push(
        CupertinoPageRoute(
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

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    Color? titleColor,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: titleColor ?? scheme.primary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: titleColor ?? scheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildHeroActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    String displayName,
    String phoneNumber,
    Color callTypeColor,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initials = _getInitials(displayName);

    return Container(
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(scheme.surfaceContainer, callTypeColor, 0.12) ??
                  scheme.surfaceContainer,
              border: Border.all(
                color: callTypeColor.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Center(
              child: initials.isNotEmpty && initials != '#'
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    )
                  : Icon(
                      Icons.person_outline_rounded,
                      size: 30,
                      color: scheme.onSurface,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          if (phoneNumber.isNotEmpty && phoneNumber != displayName) ...[
            const SizedBox(height: 4),
            Text(
              phoneNumber,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color.lerp(scheme.surfaceContainer, callTypeColor, 0.08) ??
                  scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: callTypeColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  callTypeIcon(widget.call.type),
                  size: 14,
                  color: callTypeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  callTypeLabel(widget.call.type),
                  style: TextStyle(
                    color: callTypeColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.call.duration > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '•',
                    style: TextStyle(
                      color: callTypeColor.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatDuration(widget.call.duration),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                Text(
                  '•',
                  style: TextStyle(
                    color: callTypeColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  formatCallTime(widget.call.timestamp),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildHeroActionButton(
                  context,
                  icon: Icons.call_rounded,
                  label: 'Call',
                  color: scheme.primary,
                  onTap: () => CallLauncher.call(phoneNumber),
                ),
                _buildHeroActionButton(
                  context,
                  icon: Icons.message_rounded,
                  label: 'Message',
                  color: scheme.tertiary,
                  onTap: () => CallLauncher.message(phoneNumber),
                ),
                _buildHeroActionButton(
                  context,
                  icon: _deviceContact != null
                      ? Icons.person_rounded
                      : Icons.person_add_rounded,
                  label: _deviceContact != null ? 'Contact' : 'Save',
                  color: Colors.deepPurpleAccent,
                  onTap: () => _openContact(context, displayName, phoneNumber),
                ),
                _buildHeroActionButton(
                  context,
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  color: scheme.onSurfaceVariant,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: phoneNumber));
                    ToastService.info(context, 'Number copied to clipboard');
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phoneNumber = widget.call.number?.trim() ?? '';
    final rawName = widget.call.name?.trim();

    final displayName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (_deviceContact?.displayName.trim().isNotEmpty == true
            ? _deviceContact!.displayName.trim()
            : (phoneNumber.isNotEmpty ? phoneNumber : 'Unknown'));

    final callTypeColor = _getCallTypeColor(widget.call.type, scheme);

    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Call Details'),
        actions: [
          if (phoneNumber.isNotEmpty) ...[
            GlassBarItem.icon(
              icon: const Icon(Icons.call_outlined),
              id: 'call_action',
              label: 'Call',
              onTap: () => CallLauncher.call(phoneNumber),
            ),
            GlassBarItem.icon(
              icon: const Icon(Icons.person_outline),
              id: 'context_action',
              label: 'View Contact',
              onTap: () async {
                final deviceContact = await _findDeviceContact(phoneNumber);

                if (!context.mounted) return;

                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => ContactDetailScreen(
                      normalizedNumber: normalizePhoneNumber(phoneNumber),
                      displayName: displayName,
                      displayNumber: phoneNumber,
                      deviceContact: deviceContact,
                      db: widget.db,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeroCard(
                      context,
                      displayName,
                      phoneNumber,
                      callTypeColor,
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      context,
                      title: 'Call Information',
                      icon: Icons.info_outline_rounded,
                      child: CallInfoSection(call: widget.call, db: widget.db),
                    ),
                    const SizedBox(height: 16),
                    // ── Call Recording (only when a recording exists) ──────
                    StreamBuilder<List<CallAttachment>>(
                      stream: widget.db.watchAttachmentsForCall(widget.call.id),
                      builder: (context, attachSnap) {
                        final allAttachments = attachSnap.data ?? const [];
                        final recording = allAttachments
                            .where((a) => a.fileType == 'call_recording')
                            .firstOrNull;

                        // Always render when loading so the card can show
                        // the import prompt even before data arrives
                        return _buildCard(
                          context,
                          title: 'Call Recording',
                          icon: Icons.fiber_smart_record_rounded,
                          titleColor: recording != null
                              ? Colors.redAccent
                              : null,
                          child: CallRecordingSection(
                            recording: recording,
                            callTimestampMs: widget.call.timestamp,
                            callPhoneNumber: widget.call.number,
                            onLink: (path, name) =>
                                _linkRecording(context, path, name),
                            onImport: () => _importRecording(context),
                            onDelete: () =>
                                _deleteRecording(context, recording!),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<CallDetail?>(
                      stream: widget.db.watchDetailsForCall(widget.call.id),
                      builder: (context, detailSnapshot) {
                        final detail = detailSnapshot.data;
                        final hasNote = detail?.note != null &&
                            detail!.note!.trim().isNotEmpty;
                        final scheme = Theme.of(context).colorScheme;
                        return _buildCard(
                          context,
                          title: 'Call Note',
                          icon: Icons.edit_note_rounded,
                          trailing: hasNote
                              ? TextButton.icon(
                                  onPressed: () => _clearNote(context),
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 14,
                                    color: scheme.error,
                                  ),
                                  label: Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: scheme.error,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                )
                              : null,
                          child: CallNoteSection(
                            note: detail?.note,
                            onSave: (note) => _saveNote(context, note),
                            onClear: () => _clearNote(context),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<Tag>>(
                      stream: widget.db.watchTagsForCall(widget.call.id),
                      builder: (context, tagSnapshot) {
                        final tags = tagSnapshot.data ?? const [];
                        return _buildCard(
                          context,
                          title: 'Tags',
                          icon: Icons.local_offer_outlined,
                          trailing: tags.isNotEmpty
                              ? TextButton.icon(
                                  onPressed: () => _addTag(context),
                                  icon: const Icon(Icons.edit_outlined, size: 14),
                                  label: const Text('Edit'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                )
                              : null,
                          child: CallTagsSection(
                            tags: tags,
                            onAdd: () => _addTag(context),
                            onRemove: (tag) {
                              widget.db.removeTagFromCall(
                                widget.call.id,
                                tag.id,
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<CallDetail?>(
                      stream: widget.db.watchReminderForCall(widget.call.id),
                      builder: (context, reminderSnapshot) {
                        return _buildCard(
                          context,
                          title: 'Follow-up Reminder',
                          icon: Icons.alarm_rounded,
                          child: CallReminderSection(
                            reminder: reminderSnapshot.data,
                            onSet: () => _setReminder(context),
                            onClear: () => _clearReminder(context),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<CallAttachment>>(
                      stream: widget.db.watchAttachmentsForCall(widget.call.id),
                      builder: (context, attachmentSnapshot) {
                        final attachments = attachmentSnapshot.data ?? const [];
                        return _buildCard(
                          context,
                          title: 'Attachments',
                          icon: Icons.attach_file_rounded,
                          trailing: attachments.isNotEmpty
                              ? TextButton.icon(
                                  onPressed: () =>
                                      _chooseAttachmentType(context),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text('Add'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                )
                              : null,
                          child: CallAttachmentsSection(
                            attachments: attachments,
                            onAdd: () => _chooseAttachmentType(context),
                            onView: (attachment) =>
                                _viewAttachment(context, attachment),
                            onDelete: (attachment) =>
                                _deleteAttachment(context, attachment),
                          ),
                        );
                      },
                    ),
                    StreamBuilder<Setting>(
                      stream: widget.db.watchSettings(),
                      builder: (context, settingsSnapshot) {
                        final devMode = settingsSnapshot.data?.devMode ?? false;
                        if (!devMode) return const SizedBox.shrink();

                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildCard(
                              context,
                              title: 'Developer Diagnostics',
                              icon: Icons.bug_report_outlined,
                              titleColor: Colors.orangeAccent,
                              child: CallDeveloperInfo(call: widget.call),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 60),
                  ]),
                ),
              ),
            ],
          ),
        ),
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
    return GlassScaffold(
      appBar: GlassAppBar.pinned(title: Text(title)),
      backgroundColor: Colors.black,
      body: Center(child: InteractiveViewer(child: Image.file(File(filePath)))),
    );
  }
}
