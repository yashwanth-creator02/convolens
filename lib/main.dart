import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  // ignore: invalid_use_of_visible_for_testing_member
  GlassModalSheet.debugMorphSupportsBlending = true;
  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      theme: GlassThemeData.simple(quality: GlassQuality.standard),
      child: const GlassAdaptiveScope(
        maxQuality: GlassQuality.standard,
        child: App(),
      ),
      brightnessResolver: Theme.maybeBrightnessOf,
    ),
  );
}
