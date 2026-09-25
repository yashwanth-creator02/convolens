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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

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

      case 'purple':
      case 'violet':
        return AppThemeType.purple;

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
    required AppDatabase db,
  }) {
    final activeTheme = AppTheme.getTheme(
      themeType == AppThemeType.system ? AppThemeType.dark : themeType,
    );

    return MaterialApp(
      key: const ValueKey('ConvolensAppMaterialApp'),
      navigatorKey: _navigatorKey,
      title: 'Convolens',
      theme: themeType == AppThemeType.light
          ? activeTheme
          : AppTheme.getTheme(AppThemeType.light),
      darkTheme: activeTheme,
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
      home: MainShell(db: db),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Setting>(
      stream: _db.watchSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        final themeType = settings != null
            ? _themeFromString(settings.theme)
            : AppThemeType.dark;

        return _buildAppWithTheme(
          themeType: themeType,
          themeMode: themeType == AppThemeType.system
              ? ThemeMode.system
              : (themeType == AppThemeType.light
                  ? ThemeMode.light
                  : ThemeMode.dark),
          db: _db,
        );
      },
    );
  }
}
