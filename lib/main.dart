import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app/app.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  } catch (e) {
    debugPrint('LiquidGlassWidgets initialization fallback: $e');
  }

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('NotificationService initialization fallback: $e');
  }

  try {
    // ignore: invalid_use_of_visible_for_testing_member
    GlassModalSheet.debugMorphSupportsBlending = true;
  } catch (_) {
    // Fall back to default morph behavior if internal API is unavailable.
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

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
