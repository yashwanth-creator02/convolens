import 'package:flutter/material.dart';

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
