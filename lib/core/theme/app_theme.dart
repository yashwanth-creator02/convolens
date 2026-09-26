import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_theme_type.dart';
import 'themes/cosmo_theme.dart';
import 'themes/dark_theme.dart';
import 'themes/light_theme.dart';
import 'themes/purple_theme.dart';

class AppTheme {
  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData getTheme(AppThemeType type) {
    ThemeData base;
    switch (type) {
      case AppThemeType.light:
        base = LightTheme.data;
        break;

      case AppThemeType.dark:
        base = DarkTheme.data;
        break;

      case AppThemeType.purple:
        base = PurpleTheme.data;
        break;

      case AppThemeType.cosmo:
        base = CosmoTheme.data;
        break;

      case AppThemeType.system:
        throw ArgumentError(
          'System theme does not have a ThemeData. '
          'Use ThemeMode.system in MaterialApp.',
        );
    }
    return base.copyWith(pageTransitionsTheme: _pageTransitionsTheme);
  }
}
