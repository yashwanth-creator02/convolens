import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

enum ToastType { success, error, info, warning, neutral }

class ToastService {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    GlassToastPosition position = GlassToastPosition.top,
    Widget? icon,
    GlassToastAction? action,
    bool dismissible = true,
  }) {
    if (!context.mounted) return;
    if (Overlay.maybeOf(context) == null) return;

    final glassType = switch (type) {
      ToastType.success => GlassToastType.success,
      ToastType.error => GlassToastType.error,
      ToastType.warning => GlassToastType.warning,
      ToastType.info => GlassToastType.info,
      ToastType.neutral => GlassToastType.neutral,
    };

    GlassToast.show(
      context,
      message: message,
      type: glassType,
      position: position,
      duration: duration,
      icon: icon,
      action: action,
      dismissible: dismissible,
    );
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    GlassToastPosition position = GlassToastPosition.top,
    Widget? icon,
    GlassToastAction? action,
  }) =>
      show(
        context,
        message: message,
        type: ToastType.success,
        duration: duration,
        position: position,
        icon: icon,
        action: action,
      );

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    GlassToastPosition position = GlassToastPosition.top,
    Widget? icon,
    GlassToastAction? action,
  }) =>
      show(
        context,
        message: message,
        type: ToastType.error,
        duration: duration,
        position: position,
        icon: icon,
        action: action,
      );

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    GlassToastPosition position = GlassToastPosition.top,
    Widget? icon,
    GlassToastAction? action,
  }) =>
      show(
        context,
        message: message,
        type: ToastType.warning,
        duration: duration,
        position: position,
        icon: icon,
        action: action,
      );

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    GlassToastPosition position = GlassToastPosition.top,
    Widget? icon,
    GlassToastAction? action,
  }) =>
      show(
        context,
        message: message,
        type: ToastType.info,
        duration: duration,
        position: position,
        icon: icon,
        action: action,
      );
}
