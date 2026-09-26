import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app/app.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  await NotificationService.init();
  try {
    // ignore: invalid_use_of_visible_for_testing_member
    GlassModalSheet.debugMorphSupportsBlending = true;
  } catch (_) {
    // Fall back to default morph behavior if internal API is unavailable.
  }
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
