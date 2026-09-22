import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../history/repository/calls_repository.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../widgets/settings_glass_card.dart';
import '../widgets/settings_glass_tile.dart';
import 'call_card_settings_screen.dart';
import 'developer_screen.dart';
import 'permissions_screen.dart';
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

  String _getThemeLabel(String theme) {
    switch (theme.toLowerCase()) {
      case 'cosmo':
        return 'Cosmo';
      case 'dark':
        return 'Dark';
      case 'light':
        return 'Light';
      default:
        return 'System';
    }
  }

  IconData _getThemeIcon(String theme) {
    switch (theme.toLowerCase()) {
      case 'cosmo':
        return Icons.auto_awesome_rounded;
      case 'dark':
        return Icons.dark_mode_rounded;
      case 'light':
        return Icons.light_mode_rounded;
      default:
        return Icons.brightness_auto_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                ),
                GlassLargeTitle(text: 'Settings', controller: _titleController),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── 1. Permissions & Privacy ─────────────────────────
                      SettingsGlassCard(
                        title: 'Permissions & Security',
                        icon: Icons.shield_outlined,
                        child: SettingsGlassTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'App Permissions',
                          subtitle:
                              'Manage call log, contacts, and notification access',
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => const PermissionsScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── 2. Sync & Storage ────────────────────────────────
                      SettingsGlassCard(
                        title: 'Sync & Storage',
                        icon: Icons.sync_rounded,
                        child: Column(
                          children: [
                            SettingsGlassSwitchTile(
                              icon: Icons.cloud_sync_outlined,
                              title: 'Enable Sync',
                              subtitle:
                                  'Keep call records synchronized with device logs',
                              value: settings.syncEnabled,
                              onChanged: (value) {
                                widget.db.updateSetting(
                                  SettingsCompanion(syncEnabled: Value(value)),
                                );
                              },
                            ),
                            const SettingsGlassDivider(),
                            SettingsGlassSwitchTile(
                              icon: Icons.inventory_2_outlined,
                              title: 'Archive Mode',
                              subtitle:
                                  'Preserve calls even if deleted from phone log',
                              value: settings.archiveMode,
                              onChanged: (value) async {
                                if (value == true) {
                                  await widget.db.updateSetting(
                                    const SettingsCompanion(
                                        archiveMode: Value(true)),
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
                                  const SettingsCompanion(
                                      archiveMode: Value(false)),
                                );

                                await CallsRepository(
                                  widget.db,
                                ).syncFromDevice(archiveMode: false);
                              },
                            ),
                          ],
                        ),
                      ),

                      // ── 3. Appearance & Display ──────────────────────────
                      SettingsGlassCard(
                        title: 'Appearance & Display',
                        icon: Icons.palette_outlined,
                        child: Column(
                          children: [
                            SettingsGlassTile(
                              icon: Icons.color_lens_outlined,
                              title: 'Theme',
                              subtitle: 'Choose the visual theme for ConvoLens',
                              trailing: SettingsGlassPillBadge(
                                label: _getThemeLabel(settings.theme),
                                icon: _getThemeIcon(settings.theme),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        ThemeScreen(db: widget.db),
                                  ),
                                );
                              },
                            ),
                            const SettingsGlassDivider(),
                            SettingsGlassTile(
                              icon: Icons.dashboard_customize_outlined,
                              title: 'Call Card Display',
                              subtitle:
                                  'Choose which fields appear on each call card',
                              onTap: () {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        CallCardSettingsScreen(db: widget.db),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // ── 4. Developer Options ─────────────────────────────
                      SettingsGlassCard(
                        title: 'Developer Options',
                        icon: Icons.code_rounded,
                        child: Column(
                          children: [
                            SettingsGlassSwitchTile(
                              icon: Icons.terminal_rounded,
                              title: 'Developer Mode',
                              subtitle:
                                  'Enable internal diagnostics and inspection tools',
                              value: settings.devMode,
                              onChanged: (value) {
                                widget.db.updateSetting(
                                  SettingsCompanion(devMode: Value(value)),
                                );
                              },
                            ),
                            if (settings.devMode) ...[
                              const SettingsGlassDivider(),
                              SettingsGlassTile(
                                icon: Icons.build_circle_outlined,
                                title: 'Developer Tools',
                                subtitle:
                                    'Database browser, notification troubleshooting & test calls',
                                onTap: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          DeveloperScreen(db: widget.db),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── 5. App Information & Branding ────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.primary.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 24,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'ConvoLens',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Version 1.0.0 • Liquid Glass UI',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
