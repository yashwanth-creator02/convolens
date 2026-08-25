import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

class ThemeScreen extends StatelessWidget {
  final AppDatabase db;

  const ThemeScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: StreamBuilder<Setting>(
        stream: db.watchSettings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data!;

          return ListView(
            children: [
              _ThemeOption(
                title: 'Light',
                subtitle: 'Use the light appearance',
                icon: Icons.light_mode_outlined,
                selected: settings.theme == 'light',
                onTap: () => _setTheme('light'),
              ),

              _ThemeOption(
                title: 'Dark',
                subtitle: 'Use the dark appearance',
                icon: Icons.dark_mode_outlined,
                selected: settings.theme == 'dark',
                onTap: () => _setTheme('dark'),
              ),

              _ThemeOption(
                title: 'Cosmo',
                subtitle: 'Use the Cosmo appearance',
                icon: Icons.auto_awesome_outlined,
                selected: settings.theme == 'cosmo',
                onTap: () => _setTheme('cosmo'),
              ),

              _ThemeOption(
                title: 'System Default',
                subtitle: 'Follow your device appearance',
                icon: Icons.brightness_auto_outlined,
                selected: settings.theme == 'system',
                onTap: () => _setTheme('system'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _setTheme(String theme) {
    return db.updateSetting(SettingsCompanion(theme: Value(theme)));
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
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}
