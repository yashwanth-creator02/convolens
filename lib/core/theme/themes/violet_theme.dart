import 'package:flutter/material.dart';

/// Signature Violet theme (formerly Cosmos) with rich purple palette.
class VioletTheme {
  static ThemeData get data {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.purple,
        brightness: Brightness.dark,
      ),
    );
  }
}
