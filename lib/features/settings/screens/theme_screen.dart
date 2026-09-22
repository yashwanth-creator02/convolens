import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../widgets/settings_glass_card.dart';

class ThemeScreen extends StatefulWidget {
  final AppDatabase db;

  const ThemeScreen({super.key, required this.db});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
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
        title: const Text('Theme'),
        largeTitleController: _titleController,
      ),
      body: StreamBuilder<Setting>(
        stream: widget.db.watchSettings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data!;

          return Material(
            type: MaterialType.transparency,
            child: CustomScrollView(
              controller: _titleController.scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                ),
                GlassLargeTitle(text: 'Theme', controller: _titleController),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SettingsGlassCard(
                        title: 'Appearance Mode',
                        icon: Icons.palette_outlined,
                        child: Column(
                          children: [
                            _ThemeOption(
                              title: 'System Default',
                              subtitle: 'Follow device appearance dynamically',
                              icon: Icons.brightness_auto_rounded,
                              selected: settings.theme == 'system',
                              onTap: () => _setTheme('system'),
                            ),
                            _ThemeOption(
                              title: 'Light',
                              subtitle: 'Clean, radiant and crisp daylight look',
                              icon: Icons.light_mode_rounded,
                              selected: settings.theme == 'light',
                              onTap: () => _setTheme('light'),
                            ),
                            _ThemeOption(
                              title: 'Dark',
                              subtitle: 'Subtle, battery-friendly low light look',
                              icon: Icons.dark_mode_rounded,
                              selected: settings.theme == 'dark',
                              onTap: () => _setTheme('dark'),
                            ),
                            _ThemeOption(
                              title: 'Violet',
                              subtitle: 'Signature purple and violet dark theme',
                              icon: Icons.lens_blur_rounded,
                              selected: settings.theme == 'violet',
                              onTap: () => _setTheme('violet'),
                            ),
                            _ThemeOption(
                              title: 'Cosmo',
                              subtitle: 'Fresh Cosmo theme template',
                              icon: Icons.auto_awesome_rounded,
                              selected: settings.theme == 'cosmo',
                              onTap: () => _setTheme('cosmo'),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _setTheme(String theme) {
    HapticFeedback.selectionClick();
    return widget.db.updateSetting(SettingsCompanion(theme: Value(theme)));
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.8)
              : colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey('selected'),
                          color: colorScheme.primary,
                          size: 22,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          key: const ValueKey('unselected'),
                          color: colorScheme.outline.withValues(alpha: 0.4),
                          size: 22,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
