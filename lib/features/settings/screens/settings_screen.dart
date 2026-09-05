import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../history/repository/calls_repository.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'developer_screen.dart';
import 'permissions_screen.dart';
import 'call_card_settings_screen.dart';
import 'theme_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppDatabase db;

  const SettingsScreen({super.key, required this.db});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _titleController = GlassLargeTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Settings'),
        largeTitleController: _titleController,
      ),
      body: Material(
        type: MaterialType.transparency,
        child: StreamBuilder<Setting>(
          stream: widget.db.watchSettings(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final settings = snapshot.data!;

            return CustomScrollView(
              controller: _titleController.scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                ),
                GlassLargeTitle(text: 'Settings', controller: _titleController),
                SliverList(
                  delegate: SliverChildListDelegate([
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('App Permissions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
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
                        widget.db.updateSetting(
                          SettingsCompanion(syncEnabled: Value(value)),
                        );
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Archive Mode'),
                      subtitle: const Text(
                        'Keep calls even if removed from device',
                      ),
                      value: settings.archiveMode,
                      onChanged: (value) async {
                        if (value == true) {
                          await widget.db.updateSetting(
                            const SettingsCompanion(archiveMode: Value(true)),
                          );
                          await CallsRepository(
                            widget.db,
                          ).syncFromDevice(archiveMode: true);
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

                        await widget.db.updateSetting(
                          const SettingsCompanion(archiveMode: Value(false)),
                        );

                        await CallsRepository(
                          widget.db,
                        ).syncFromDevice(archiveMode: false);
                      },
                    ),
                    const _SectionHeader('Display'),
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('Theme'),
                      subtitle: const Text(
                        'Choose the appearance of Convolens',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => ThemeScreen(db: widget.db),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.credit_card),
                      title: const Text('Call Card Display'),
                      subtitle: const Text(
                        'Choose what appears on each call card',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) =>
                                CallCardSettingsScreen(db: widget.db),
                          ),
                        );
                      },
                    ),
                    const _SectionHeader('Developer'),
                    SwitchListTile(
                      title: const Text('Developer Mode'),
                      value: settings.devMode,
                      onChanged: (value) {
                        widget.db.updateSetting(
                          SettingsCompanion(devMode: Value(value)),
                        );
                      },
                    ),
                    if (settings.devMode)
                      ListTile(
                        leading: const Icon(Icons.build_outlined),
                        title: const Text('Developer Tools'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) =>
                                  DeveloperScreen(db: widget.db),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ],
            );
          },
        ),
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
