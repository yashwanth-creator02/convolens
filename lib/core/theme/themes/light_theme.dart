import 'package:flutter/material.dart';

class LightTheme {
  static ThemeData get data {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: Brightness.light,
      ),
    );
  }
}
