import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../history/repository/calls_repository.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../widgets/settings_glass_card.dart';
import '../widgets/settings_glass_tile.dart';
import 'app_features_screen.dart';
import 'call_card_settings_screen.dart';
import 'connect_developer_screen.dart';
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
  int _easterEggTapCount = 0;
  DateTime? _lastEasterEggTap;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _handleEasterEggTap() {
    final now = DateTime.now();
    if (_lastEasterEggTap == null ||
        now.difference(_lastEasterEggTap!) > const Duration(seconds: 2)) {
      _easterEggTapCount = 1;
    } else {
      _easterEggTapCount++;
    }
    _lastEasterEggTap = now;

    if (_easterEggTapCount >= 7) {
      _easterEggTapCount = 0;
      HapticFeedback.heavyImpact();
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => const AppFeaturesScreen(),
        ),
      );
    } else if (_easterEggTapCount >= 4) {
      HapticFeedback.selectionClick();
      final remaining = 7 - _easterEggTapCount;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tap $remaining more ${remaining == 1 ? "time" : "times"} to explore features...',
          ),
          duration: const Duration(milliseconds: 700),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      HapticFeedback.selectionClick();
    }
  }

  String _getThemeLabel(String theme) {
    switch (theme.toLowerCase()) {
      case 'purple':
      case 'violet':
        return 'Purple';
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
      case 'purple':
      case 'violet':
        return Icons.lens_blur_rounded;
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
                          infoTooltip:
                              'Manage call log, contacts, and notification access permissions',
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
                              infoTooltip:
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
                              infoTooltip:
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
                              infoTooltip:
                                  'Choose the visual appearance theme for ConvoLens',
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
                              infoTooltip:
                                  'Choose which fields appear on each call history card',
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

                      // ── 4. Developer Contact / Support ──────────────────
                      SettingsGlassCard(
                        title: 'Support & Feedback',
                        icon: Icons.support_agent_rounded,
                        child: SettingsGlassTile(
                          icon: Icons.outgoing_mail,
                          title: 'Connect with the developer',
                          infoTooltip:
                              'Compose an email to the developer at leo.two.dev@gmail.com',
                          trailing: const SettingsGlassPillBadge(
                            label: 'Contact',
                            icon: Icons.send_rounded,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const ConnectDeveloperScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── 5. Developer Options ─────────────────────────────
                      SettingsGlassCard(
                        title: 'Developer Options',
                        icon: Icons.code_rounded,
                        child: Column(
                          children: [
                            SettingsGlassSwitchTile(
                              icon: Icons.terminal_rounded,
                              title: 'Developer Mode',
                              infoTooltip:
                                  'Enable internal diagnostics, logs, and database inspection tools',
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
                                infoTooltip:
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

                      // ── 6. App Information & Branding ────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: GestureDetector(
                            onTap: _handleEasterEggTap,
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/icons/logo.png',
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: scheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.all_inclusive_rounded,
                                        size: 26,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Point',
                                  style: TextStyle(
                                    fontSize: 16,
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
