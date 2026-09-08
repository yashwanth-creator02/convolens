import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_setup.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(
    LiquidGlassWidgets.wrap(
      theme: GlassThemeData.simple(quality: GlassQuality.standard),
      child: const App(),
      brightnessResolver: Theme.maybeBrightnessOf,
    ),
  );
}
