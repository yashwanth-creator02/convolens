import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/notifications/notification_service.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _callLogGranted = false;
  bool _notificationsGranted = false;
  bool _exactAlarmGranted = false;
  bool _contactsGranted = false;
  bool _microphoneGranted = false;

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatuses();
    }
  }

  Future<void> _refreshStatuses() async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;

    try {
      final callLogStatus = await Permission.phone.status;

      final notificationsGranted =
          await NotificationService.areNotificationsGranted();

      final exactAlarmGranted =
          await NotificationService.canScheduleExactAlarms();

      final contactsStatus = await Permission.contacts.status;

      final microphoneStatus = await Permission.microphone.status;

      if (!mounted) {
        return;
      }

      setState(() {
        _callLogGranted = callLogStatus.isGranted;
        _notificationsGranted = notificationsGranted;
        _exactAlarmGranted = exactAlarmGranted;
        _contactsGranted = contactsStatus.isGranted;
        _microphoneGranted = microphoneStatus.isGranted;
      });
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _requestCallLogPermission() async {
    final status = await Permission.phone.status;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await Permission.phone.request();
    }

    await _refreshStatuses();
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await NotificationService.requestNotificationPermission();

    if (!granted && mounted) {
      await openAppSettings();
    }

    await _refreshStatuses();
  }

  Future<void> _requestExactAlarmPermission() async {
    await NotificationService.requestExactAlarmPermission();

    await _refreshStatuses();
  }

  Future<void> _requestContactsPermission() async {
    final status = await Permission.contacts.status;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await Permission.contacts.request();
    }

    await _refreshStatuses();
  }

  Future<void> _openSystemSettings() async {
    await openAppSettings();

    if (!mounted) {
      return;
    }

    await _refreshStatuses();
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await Permission.microphone.request();
    }

    await _refreshStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Permissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_applications),
            tooltip: 'Open System Settings',
            onPressed: _openSystemSettings,
          ),
        ],
      ),
      body: ListView(
        children: [
          _PermissionTile(
            title: 'Call Log',
            subtitle: 'Required to import and archive your call history',
            granted: _callLogGranted,
            onTap: _requestCallLogPermission,
          ),
          _PermissionTile(
            title: 'Notifications',
            subtitle: 'Required to show call reminders',
            granted: _notificationsGranted,
            onTap: _requestNotificationPermission,
          ),
          _PermissionTile(
            title: 'Exact Alarms',
            subtitle: 'Required for reminders to fire at the exact time set',
            granted: _exactAlarmGranted,
            onTap: _requestExactAlarmPermission,
          ),
          _PermissionTile(
            title: 'Contacts',
            subtitle: 'Required to show all your device contacts',
            granted: _contactsGranted,
            onTap: _requestContactsPermission,
          ),
          _PermissionTile(
            title: 'Microphone',
            subtitle: 'Required to record voice notes attachments',
            granted: _microphoneGranted,
            onTap: _requestMicrophonePermission,
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: granted
          ? const Icon(Icons.check_circle, color: Colors.green)
          : TextButton(onPressed: onTap, child: const Text('Grant')),
    );
  }
}
