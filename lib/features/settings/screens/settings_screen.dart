import 'package:drift/drift.dart' show Value;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../history/repository/calls_repository.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../widgets/settings_glass_tile.dart';
import 'app_features_screen.dart';
import 'call_card_settings_screen.dart';
import 'connect_developer_screen.dart';
import 'developer_screen.dart';
import 'notification_troubleshooting_screen.dart';
import 'permissions_screen.dart';
import 'theme_screen.dart';
import '../../contacts/screens/archived_contacts_screen.dart';

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
  VoidCallback? _currentToastDismiss;

  @override
  void dispose() {
    try {
      _currentToastDismiss?.call();
    } catch (_) {}
    _currentToastDismiss = null;
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
      try {
        _currentToastDismiss?.call();
      } catch (_) {}
      _currentToastDismiss = null;
      HapticFeedback.heavyImpact();
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => const AppFeaturesScreen(),
        ),
      );
    } else if (_easterEggTapCount >= 4) {
      HapticFeedback.selectionClick();
      final remaining = 7 - _easterEggTapCount;
      try {
        _currentToastDismiss?.call();
      } catch (_) {}
      _currentToastDismiss = GlassToast.show(
        context,
        message:
            'Tap $remaining more ${remaining == 1 ? "time" : "times"} to explore features',
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        type: GlassToastType.info,
        position: GlassToastPosition.bottom,
        duration: const Duration(milliseconds: 1200),
      );
    } else {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _toggleArchiveMode(BuildContext context, bool current) async {
    final next = !current;
    if (next) {
      await widget.db.updateSetting(
        const SettingsCompanion(archiveMode: Value(true)),
      );
      final syncEnabled = await widget.db.getSyncEnabled();
      if (syncEnabled) {
        await CallsRepository(widget.db).syncFromDevice(archiveMode: true);
      }
      return;
    }

    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Turn off Archive Mode?',
      message:
          'Calls that are removed from your phone\'s call log '
          'will also be permanently deleted from Point the '
          'next time it syncs. This cannot be undone.',
      confirmLabel: 'Turn Off',
      isDestructive: true,
    );

    if (!confirmed) return;

    await widget.db.updateSetting(
      const SettingsCompanion(archiveMode: Value(false)),
    );

    final syncEnabled = await widget.db.getSyncEnabled();
    if (syncEnabled) {
      await CallsRepository(widget.db).syncFromDevice(archiveMode: false);
    }
  }

  Widget _buildTitleWithInfo({
    required String title,
    required String infoTooltip,
    required ColorScheme scheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 4),
        SettingsInfoTooltipButton(message: infoTooltip),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4.5),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: scheme.primary),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildTileLeading(IconData icon, ColorScheme scheme) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 17,
        color: scheme.primary,
      ),
    );
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
                      GlassGroupedSection(
                        margin: const EdgeInsets.only(bottom: 18),
                        shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                        quality: GlassQuality.standard,
                        header: _buildSectionHeader(
                          context,
                          title: 'Permissions & Security',
                          icon: Icons.shield_outlined,
                        ),
                        children: [
                          GlassListTile(
                            leading: _buildTileLeading(Icons.lock_outline_rounded, scheme),
                            title: _buildTitleWithInfo(
                              title: 'App Permissions',
                              infoTooltip:
                                  'Manage call log, contacts, and notification access permissions',
                              scheme: scheme,
                            ),
                            trailing: GlassListTile.chevron,
                            onTap: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) => const PermissionsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // ── Notifications ─────────────────────────────────────
                      GlassGroupedSection(
                        margin: const EdgeInsets.only(bottom: 18),
                        shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                        quality: GlassQuality.standard,
                        header: _buildSectionHeader(
                          context,
                          title: 'Notifications',
                          icon: Icons.notifications_outlined,
                        ),
                        children: [
                          GlassListTile(
                            leading: _buildTileLeading(Icons.local_fire_department_outlined, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Streak Milestones',
                              infoTooltip: 'Get notified when you hit new calling streak records',
                              scheme: scheme,
                            ),
                            trailing: GlassSwitch(
                              value: settings.streakNotifications,
                              onChanged: (value) {
                                widget.db.updateSetting(
                                  SettingsCompanion(streakNotifications: Value(value)),
                                );
                              },
                              useOwnLayer: false,
                              quality: GlassQuality.standard,
                              activeColor: scheme.primary,
                              width: 50.0,
                              height: 28.0,
                            ),
                            onTap: () {
                              widget.db.updateSetting(
                                SettingsCompanion(
                                  streakNotifications: Value(!settings.streakNotifications),
                                ),
                              );
                            },
                          ),
                          GlassListTile(
                            leading: _buildTileLeading(Icons.insights_rounded, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Weekly Summary',
                              infoTooltip: 'Receive weekly calling digest and trend updates',
                              scheme: scheme,
                            ),
                            trailing: GlassSwitch(
                              value: settings.weeklySummaryNotifications,
                              onChanged: (value) {
                                widget.db.updateSetting(
                                  SettingsCompanion(weeklySummaryNotifications: Value(value)),
                                );
                              },
                              useOwnLayer: false,
                              quality: GlassQuality.standard,
                              activeColor: scheme.primary,
                              width: 50.0,
                              height: 28.0,
                            ),
                            onTap: () {
                              widget.db.updateSetting(
                                SettingsCompanion(
                                  weeklySummaryNotifications: Value(!settings.weeklySummaryNotifications),
                                ),
                              );
                            },
                          ),
                          GlassListTile(
                            leading: _buildTileLeading(Icons.star_outline_rounded, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Favorite Inactivity',
                              infoTooltip: 'Gentle reminders when you haven\'t called a favorite in 14+ days',
                              scheme: scheme,
                            ),
                            trailing: GlassSwitch(
                              value: settings.favoriteInactivityNotifications,
                              onChanged: (value) {
                                widget.db.updateSetting(
                                  SettingsCompanion(favoriteInactivityNotifications: Value(value)),
                                );
                              },
                              useOwnLayer: false,
                              quality: GlassQuality.standard,
                              activeColor: scheme.primary,
                              width: 50.0,
                              height: 28.0,
                            ),
                            onTap: () {
                              widget.db.updateSetting(
                                SettingsCompanion(
                                  favoriteInactivityNotifications: Value(!settings.favoriteInactivityNotifications),
                                ),
                              );
                            },
                          ),
                          GlassListTile(
                            leading: _buildTileLeading(Icons.phone_missed_rounded, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Missed Call Alerts',
                              infoTooltip: 'Immediate alerts when a favorite contact calls and is missed',
                              scheme: scheme,
                            ),
                            trailing: GlassSwitch(
                              value: settings.missedCallAlerts,
                              onChanged: (value) {
                                widget.db.updateSetting(
                                  SettingsCompanion(missedCallAlerts: Value(value)),
                                );
                              },
                              useOwnLayer: false,
                              quality: GlassQuality.standard,
                              activeColor: scheme.primary,
                              width: 50.0,
                              height: 28.0,
                            ),
                            onTap: () {
                              widget.db.updateSetting(
                                SettingsCompanion(
                                  missedCallAlerts: Value(!settings.missedCallAlerts),
                                ),
                              );
                            },
                          ),
                          GlassListTile(
                            leading: _buildTileLeading(Icons.notifications_active_outlined, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Notification Troubleshooting',
                              infoTooltip: 'Verify notification channels and trigger test reminders',
                              scheme: scheme,
                            ),
                            trailing: GlassListTile.chevron,
                            onTap: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) =>
                                      const NotificationTroubleshootingScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // ── 2. Sync & Storage ────────────────────────────────
                      GlassGroupedSection(
                        margin: const EdgeInsets.only(bottom: 18),
                        shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                        quality: GlassQuality.standard,
                        header: _buildSectionHeader(
                          context,
                          title: 'Sync & Storage',
                          icon: Icons.sync_rounded,
                        ),
                        children: [
                          GlassListTile(
                            leading: _buildTileLeading(Icons.cloud_sync_outlined, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Enable Sync',
                              infoTooltip:
                                  'Keep call records synchronized with device logs',
                              scheme: scheme,
                            ),
                            trailing: GlassSwitch(
                              value: settings.syncEnabled,
                              onChanged: (value) {
                                widget.db.updateSetting(
                                  SettingsCompanion(syncEnabled: Value(value)),
                                );
                              },
                              useOwnLayer: false,
                              quality: GlassQuality.standard,
                              activeColor: scheme.primary,
                              width: 50.0,
                              height: 28.0,
                            ),
                            onTap: () {
                              widget.db.updateSetting(
                                SettingsCompanion(syncEnabled: Value(!settings.syncEnabled)),
                              );
                            },
                          ),
                          GlassListTile(
                            leading: _buildTileLeading(Icons.inventory_2_outlined, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Archive Mode',
                              infoTooltip:
                                  'Preserve calls even if deleted from phone log',
                              scheme: scheme,
                            ),
                            trailing: GlassSwitch(
                              value: settings.archiveMode,
                              onChanged: (_) => _toggleArchiveMode(context, settings.archiveMode),
                              useOwnLayer: false,
                              quality: GlassQuality.standard,
                              activeColor: scheme.primary,
                              width: 50.0,
                              height: 28.0,
                            ),
                            onTap: () => _toggleArchiveMode(context, settings.archiveMode),
                          ),
                          GlassListTile(
                            leading: _buildTileLeading(Icons.archive_outlined, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Archived Contacts',
                              infoTooltip:
                                  'Manage contacts hidden from the main contacts directory',
                              scheme: scheme,
                            ),
                            trailing: GlassListTile.chevron,
                            onTap: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) => ArchivedContactsScreen(db: widget.db),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // ── 3. Appearance & Display ──────────────────────────
                      GlassGroupedSection(
                        margin: const EdgeInsets.only(bottom: 18),
                        shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                        quality: GlassQuality.standard,
                        header: _buildSectionHeader(
                          context,
                          title: 'Appearance & Display',
                          icon: Icons.palette_outlined,
                        ),
                        children: [
                          GlassListTile(
                            leading: _buildTileLeading(Icons.color_lens_outlined, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Theme',
                              infoTooltip:
                                  'Choose the visual appearance theme for Point',
                              scheme: scheme,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SettingsGlassPillBadge(
                                  label: _getThemeLabel(settings.theme),
                                  icon: _getThemeIcon(settings.theme),
                                ),
                                const SizedBox(width: 4),
                                GlassListTile.chevron,
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) => ThemeScreen(db: widget.db),
                                ),
                              );
                            },
                          ),
                          GlassListTile(
                            leading: _buildTileLeading(Icons.dashboard_customize_outlined, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Call Card Display',
                              infoTooltip:
                                  'Choose which fields appear on each call history card',
                              scheme: scheme,
                            ),
                            trailing: GlassListTile.chevron,
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

                      // ── 4. Developer Contact / Support ──────────────────
                      GlassGroupedSection(
                        margin: const EdgeInsets.only(bottom: 18),
                        shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                        quality: GlassQuality.standard,
                        header: _buildSectionHeader(
                          context,
                          title: 'Support & Feedback',
                          icon: Icons.support_agent_rounded,
                        ),
                        children: [
                          GlassListTile(
                            leading: _buildTileLeading(Icons.outgoing_mail, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Connect with the developer',
                              infoTooltip:
                                  'Compose an email to the developer at leo.two.dev@gmail.com',
                              scheme: scheme,
                            ),
                            trailing: GlassListTile.chevron,
                            onTap: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) =>
                                      const ConnectDeveloperScreen(),
                                ),
                              );
                            },
                          ),
                          GlassListTile(
                            leading: _buildTileLeading(Icons.auto_awesome_rounded, scheme),
                            title: _buildTitleWithInfo(
                              title: 'App Features & Capabilities',
                              infoTooltip:
                                  'Explore features, gestures, and tips in Point',
                              scheme: scheme,
                            ),
                            trailing: GlassListTile.chevron,
                            onTap: () {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (context) =>
                                      const AppFeaturesScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // ── 5. Developer Options ─────────────────────────────
                      GlassGroupedSection(
                        margin: const EdgeInsets.only(bottom: 18),
                        shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                        quality: GlassQuality.standard,
                        header: _buildSectionHeader(
                          context,
                          title: 'Developer Options',
                          icon: Icons.code_rounded,
                        ),
                        children: [
                          GlassListTile(
                            leading: _buildTileLeading(Icons.developer_mode_outlined, scheme),
                            title: _buildTitleWithInfo(
                              title: 'Developer Mode',
                              infoTooltip:
                                  'Unlock advanced diagnostic tools, database browser, and experimental features',
                              scheme: scheme,
                            ),
                            trailing: GlassSwitch(
                              value: settings.devMode,
                              onChanged: (value) {
                                widget.db.updateSetting(
                                  SettingsCompanion(devMode: Value(value)),
                                );
                              },
                              useOwnLayer: false,
                              quality: GlassQuality.standard,
                              activeColor: scheme.primary,
                              width: 50.0,
                              height: 28.0,
                            ),
                            onTap: () {
                              widget.db.updateSetting(
                                SettingsCompanion(devMode: Value(!settings.devMode)),
                              );
                            },
                          ),
                          if (settings.devMode)
                            GlassListTile(
                              leading: _buildTileLeading(Icons.build_circle_outlined, scheme),
                              title: _buildTitleWithInfo(
                                title: 'Developer Tools',
                                infoTooltip:
                                    'Database browser, notification troubleshooting & test calls',
                                scheme: scheme,
                              ),
                              trailing: GlassListTile.chevron,
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
                                  'Version 1.1.0 • Liquid Glass UI',
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
