import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/database/app_database.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_theme_type.dart';
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

      case 'violet':
        return AppThemeType.violet;

      case 'cosmo':
        return AppThemeType.cosmo;

      case 'system':
      default:
        return AppThemeType.dark;
    }
  }

  Widget _buildAppWithTheme({
    required AppThemeType themeType,
    ThemeMode themeMode = ThemeMode.dark,
    AppDatabase? db,
    Widget? home,
  }) {
    return MaterialApp(
      title: 'Point',
      theme: AppTheme.getTheme(
        themeType == AppThemeType.system ? AppThemeType.dark : themeType,
      ),
      darkTheme: AppTheme.getTheme(AppThemeType.dark),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return GlassNavigationShell(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: child!,
          ),
        );
      },
      home:
          home ??
          (db != null
              ? MainShell(db: db)
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Setting>(
      stream: _db.watchSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildAppWithTheme(
            themeType: AppThemeType.dark,
            themeMode: ThemeMode.dark,
          );
        }

        final settings = snapshot.data!;
        final themeType = _themeFromString(settings.theme);

        return _buildAppWithTheme(
          themeType: themeType,
          themeMode: themeType == AppThemeType.light
              ? ThemeMode.light
              : ThemeMode.dark,
          db: _db,
        );
      },
    );
  }
}
