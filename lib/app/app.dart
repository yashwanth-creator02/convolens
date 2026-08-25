import 'package:flutter/material.dart';

import '../core/database/app_database.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_theme_type.dart';
import '../shared/widgets/cosmo/cosmo_preview_screen.dart';
import 'main_shell.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppDatabase _db;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  AppThemeType _themeFromString(String value) {
    switch (value) {
      case 'light':
        return AppThemeType.light;

      case 'dark':
        return AppThemeType.dark;

      case 'cosmo':
        return AppThemeType.cosmo;

      case 'system':
      default:
        return AppThemeType.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Setting>(
      stream: _db.watchSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(AppThemeType.light),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final settings = snapshot.data!;
        final themeType = _themeFromString(settings.theme);

        // System Default
        if (themeType == AppThemeType.system) {
          return MaterialApp(
            title: 'ConvoLens',
            theme: AppTheme.getTheme(AppThemeType.light),
            darkTheme: AppTheme.getTheme(AppThemeType.dark),
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            home: const CosmoPreviewScreen(),
          );
        }

        // themes
        return MaterialApp(
          title: 'ConvoLens',
          theme: AppTheme.getTheme(themeType),
          debugShowCheckedModeBanner: false,
          home: const CosmoPreviewScreen(),
        );
      },
    );
  }
}
