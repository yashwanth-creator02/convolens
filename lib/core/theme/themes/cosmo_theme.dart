import 'package:flutter/material.dart';

/// Obsidian Dark Cosmo theme with pitch dark surfaces and electric teal/cyan highlights.
class CosmoTheme {
  static ThemeData get data {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF08090C),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00D2C4),
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF101217),
        surfaceContainer: const Color(0xFF161920),
        surfaceContainerHigh: const Color(0xFF1D212A),
        outlineVariant: const Color(0xFF272D3A),
      ),
    );
  }
}
