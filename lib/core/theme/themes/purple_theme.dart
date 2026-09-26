import 'package:flutter/material.dart';

/// Signature Purple theme with rich purple palette.
class PurpleTheme {
  static ThemeData get data {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF130E26),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purple,
        brightness: Brightness.dark,
      ),
    );
  }
}
