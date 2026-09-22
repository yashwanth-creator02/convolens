import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/services/contact_cache.dart';
import '../../../core/toast/toast_service.dart';
import '../../../core/utils/call_launcher.dart';
import '../../../core/utils/call_recording_scanner.dart';
import '../../../core/utils/normalize_number.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../contacts/screens/contact_detail_screen.dart';
import '../../contacts/widgets/add_contact_screen.dart';
import '../repository/attachment_storage.dart';
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

class CallDetailScreen extends StatefulWidget {
  final Call call;
  final AppDatabase db;
  final Contact? initialContact;
  final Future<Contact?>? fullContactFuture;
  final CallDetail? initialDetail;
  final List<Tag>? initialTags;
  final int? initialAttachmentsCount;
  final bool? initialHasRecording;

  const CallDetailScreen({
    super.key,
    required this.call,
    required this.db,
    this.initialContact,
    this.fullContactFuture,
    this.initialDetail,
    this.initialTags,
    this.initialAttachmentsCount,
    this.initialHasRecording,
  });

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  Contact? _deviceContact;

  // Cached streams to prevent duplicate database subscriptions
  late final Stream<List<CallAttachment>> _attachmentsStream =
      widget.db.watchAttachmentsForCall(widget.call.id);
  late final Stream<CallDetail?> _detailsStream =
      widget.db.watchDetailsForCall(widget.call.id);
  late final Stream<List<Tag>> _tagsStream =
      widget.db.watchTagsForCall(widget.call.id);

  // Auto-detected recordings
  List<DeviceRecordingMatch>? _autoScanResults;
  bool _isScanning = false;

  bool _deferredTasksStarted = false;
  Animation<double>? _routeAnimation;

  @override
  void initState() {
    super.initState();
    _deviceContact = widget.initialContact ??
        ContactCache.findContact(
          number: widget.call.number,
          name: widget.call.name,
        );

    // If a future for full-res contact photo was started on tap, listen to it
    // so it seamlessly upgrades from thumbnail to high-res during the slide transition
    if (widget.fullContactFuture != null) {
      widget.fullContactFuture!.then((fullContact) async {
        if (fullContact != null && fullContact.photo != null && mounted) {
          await precacheImage(MemoryImage(fullContact.photo!), context);
          if (mounted) {
            setState(() {
              _deviceContact = fullContact;
            });
            ContactCache.updateContact(fullContact);
          }
        }
      });
    } else if (_deviceContact != null && _deviceContact!.photo == null) {
      // If we only have thumbnail, load full-res photo for this single contact
      _loadFullResPhoto();
    }
  }

  Future<void> _loadFullResPhoto() async {
    if (_deviceContact == null) return;
    try {
      final full = await FlutterContacts.getContact(
        _deviceContact!.id,
        withPhoto: true,
        withThumbnail: true,
      );
      if (full != null && full.photo != null && mounted) {
        await precacheImage(MemoryImage(full.photo!), context);
        if (mounted) {
          setState(() {
            _deviceContact = full;
          });
          ContactCache.updateContact(full);
        }
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final photo = _deviceContact?.photo ?? _deviceContact?.thumbnail;
    if (photo != null && photo.isNotEmpty) {
      precacheImage(MemoryImage(photo), context);
    }
    _setupTransitionListener();
  }

  void _setupTransitionListener() {
    if (_deferredTasksStarted) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _startDeferredTasks();
    } else {
      _routeAnimation = animation;
      animation.addStatusListener(_onRouteAnimationStatus);
    }
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
      _startDeferredTasks();
    }
  }

  void _startDeferredTasks() {
    if (_deferredTasksStarted || !mounted) return;
    _deferredTasksStarted = true;

    if (_deviceContact == null) {
      _loadDeviceContact();
    }
    _autoScanRecording();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    super.dispose();
  }

  Future<void> _autoScanRecording() async {
    setState(() => _isScanning = true);
    try {
      final granted = await CallRecordingScanner.requestPermission();
      if (!granted) {
        if (mounted) setState(() => _isScanning = false);
        return;
      }
      final results = await CallRecordingScanner.findMatchesForCall(
        callTimestampMs: widget.call.timestamp,
        phoneNumber: widget.call.number,
      );
      if (mounted) {
        setState(() {
          _autoScanResults = results;
          _isScanning = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _loadDeviceContact() async {
    final number = widget.call.number?.trim() ?? '';
    final name = widget.call.name?.trim();
    final contact = await _findDeviceContact(number, name: name);
    if (mounted && contact != null) {
      final bytes = contact.photo ?? contact.thumbnail;
      if (bytes != null && bytes.isNotEmpty && mounted) {
        await precacheImage(MemoryImage(bytes), context);
      }
      if (mounted) {
        setState(() {
          _deviceContact = contact;
        });
        ContactCache.updateContact(contact);
      }
    }
  }

  Future<Contact?> _findDeviceContact(String phoneNumber, {String? name}) async {
    final cached = ContactCache.findContact(number: phoneNumber, name: name);
    if (cached != null) {
      if (cached.photo != null) return cached;
      try {
        final full = await FlutterContacts.getContact(
          cached.id,
          withPhoto: true,
          withThumbnail: true,
        );
        return full ?? cached;
      } catch (_) {
        return cached;
      }
    }

    try {
      final status = await Permission.contacts.status;
      if (!status.isGranted) {
        final req = await Permission.contacts.request();
        if (!req.isGranted) return null;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: true,
      );
      ContactCache.setContacts(contacts);

      final matched = ContactCache.findContact(number: phoneNumber, name: name);
      if (matched != null) {
        final full = await FlutterContacts.getContact(
          matched.id,
          withPhoto: true,
          withThumbnail: true,
        );
        return full ?? matched;
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

  /// Saves an inline voice recording captured by [CallAttachmentsSection].
  Future<void> _saveInlineVoiceNote(
    BuildContext context,
    String recordedPath,
  ) async {
    try {
      final copiedPath = await AttachmentStorage.copyToAppStorage(
        recordedPath,
        widget.call.id,
      );
      await widget.db.addAttachment(
        callId: widget.call.id,
        filePath: copiedPath,
        originalFileName: 'Voice note',
        fileType: 'voice',
      );
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
    final photo = _deviceContact?.photo ?? _deviceContact?.thumbnail;

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
      child: Column(
        children: [
          // ── Contact image / gradient hero banner ──────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openContact(context, displayName, phoneNumber),
              child: Stack(
                children: [
                  // Base layer: Always present so Frame 0 has a vibrant banner with initials
                  _buildDefaultHeroBanner(callTypeColor, scheme, initials, height: 280),
                  // High-resolution contact image rendered on top with crisp filtering
                  if (photo != null && photo.isNotEmpty)
                    Positioned.fill(
                      child: Image.memory(
                        photo,
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            child: child,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  // Dark scrim for readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          stops: const [0.60, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Name overlay — bottom-right
                  Positioned(
                    right: 14,
                    bottom: 12,
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Action row ─────────────────────────────────────────────────────
          if (phoneNumber.isNotEmpty) ...[
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultHeroBanner(
    Color callTypeColor,
    ColorScheme scheme,
    String initials, {
    double height = 280,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            callTypeColor.withValues(alpha: 0.55),
            Color.lerp(
                  callTypeColor,
                  scheme.surface,
                  0.45,
                ) ??
                scheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty && initials != '#' ? initials : '?',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 2,
          ),
        ),
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
                      stream: _attachmentsStream,
                      initialData: widget.initialAttachmentsCount == 0
                          ? const []
                          : null,
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
                            autoScanResults: _autoScanResults,
                            isScanning: _isScanning,
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
                      stream: _detailsStream,
                      initialData: widget.initialDetail,
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
                      stream: _tagsStream,
                      initialData: widget.initialTags,
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
                      stream: _detailsStream,
                      initialData: widget.initialDetail,
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
                      stream: _attachmentsStream,
                      initialData: widget.initialAttachmentsCount == 0
                          ? const []
                          : null,
                      builder: (context, attachmentSnapshot) {
                        final attachments = attachmentSnapshot.data ?? const [];
                        return _buildCard(
                          context,
                          title: 'Attachments',
                          icon: Icons.attach_file_rounded,
                          trailing: TextButton.icon(
                            onPressed: () =>
                                _addFileAttachment(context),
                            icon: const Icon(Icons.attach_file_rounded, size: 14),
                            label: const Text('Attach File'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          child: CallAttachmentsSection(
                            attachments: attachments,
                            onView: (attachment) =>
                                _viewAttachment(context, attachment),
                            onDelete: (attachment) =>
                                _deleteAttachment(context, attachment),
                            onVoiceRecorded: (path) => _saveInlineVoiceNote(
                              context,
                              path,
                            ),
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
