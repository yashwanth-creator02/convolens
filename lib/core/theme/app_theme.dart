import 'package:flutter/material.dart';

import 'app_theme_type.dart';
import 'themes/light_theme.dart';
import 'themes/dark_theme.dart';
import 'themes/cosmo_theme.dart';

class AppTheme {
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.light:
        return LightTheme.data;

      case AppThemeType.dark:
        return DarkTheme.data;

      case AppThemeType.cosmo:
        return CosmoTheme.data;

      case AppThemeType.system:
        throw ArgumentError(
          'System theme does not have a ThemeData. '
          'Use ThemeMode.system in MaterialApp.',
        );
    }
  }
}
