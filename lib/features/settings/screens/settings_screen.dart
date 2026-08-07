import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../history/repository/calls_repository.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'developer_screen.dart';
import 'permissions_screen.dart';

class SettingsScreen extends StatelessWidget {
  final AppDatabase db;

  const SettingsScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: StreamBuilder<Setting>(
        stream: db.watchSettings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data!;

          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('App Permissions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PermissionsScreen(),
                    ),
                  );
                },
              ),

              const _SectionHeader('Sync'),
              SwitchListTile(
                title: const Text('Enable Sync'),
                value: settings.syncEnabled,
                onChanged: (value) {
                  db.updateSetting(
                    SettingsCompanion(syncEnabled: Value(value)),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Archive Mode'),
                subtitle: const Text('Keep calls even if removed from device'),
                value: settings.archiveMode,
                onChanged: (value) async {
                  if (value == true) {
                    await db.updateSetting(
                      const SettingsCompanion(archiveMode: Value(true)),
                    );
                    await CallsRepository(db).syncFromDevice(archiveMode: true);
                    return;
                  }

                  final confirmed = await showConfirmDialog(
                    context: context,
                    title: 'Turn off Archive Mode?',
                    message:
                        'Calls that are removed from your phone\'s call log '
                        'will also be permanently deleted from Convolens the '
                        'next time it syncs. This cannot be undone.',
                    confirmLabel: 'Turn Off',
                    isDestructive: true,
                  );

                  if (!confirmed) return;

                  await db.updateSetting(
                    const SettingsCompanion(archiveMode: Value(false)),
                  );

                  await CallsRepository(db).syncFromDevice(archiveMode: false);
                },
              ),
              const _SectionHeader('Display'),
              SwitchListTile(
                title: const Text('Show Contact Name'),
                value: settings.showContactName,
                onChanged: (value) {
                  db.updateSetting(
                    SettingsCompanion(showContactName: Value(value)),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Show Phone Number'),
                value: settings.showPhoneNumber,
                onChanged: (value) {
                  db.updateSetting(
                    SettingsCompanion(showPhoneNumber: Value(value)),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Show Call Type'),
                value: settings.showCallType,
                onChanged: (value) {
                  db.updateSetting(
                    SettingsCompanion(showCallType: Value(value)),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Show Duration'),
                value: settings.showDuration,
                onChanged: (value) {
                  db.updateSetting(
                    SettingsCompanion(showDuration: Value(value)),
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Show Date'),
                value: settings.showDate,
                onChanged: (value) {
                  db.updateSetting(SettingsCompanion(showDate: Value(value)));
                },
              ),
              SwitchListTile(
                title: const Text('Show Time'),
                value: settings.showTime,
                onChanged: (value) {
                  db.updateSetting(SettingsCompanion(showTime: Value(value)));
                },
              ),
              const _SectionHeader('Developer'),
              SwitchListTile(
                title: const Text('Developer Mode'),
                value: settings.devMode,
                onChanged: (value) {
                  db.updateSetting(SettingsCompanion(devMode: Value(value)));
                },
              ),
              if (settings.devMode)
                ListTile(
                  leading: const Icon(Icons.build_outlined),
                  title: const Text('Developer Tools'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeveloperScreen(db: db),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }
}
