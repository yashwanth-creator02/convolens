import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  Widget? content,
  double maxWidth = 300,
}) async {
  final result = await GlassDialog.show<bool>(
    context: context,
    title: title,
    message: message,
    content: content,
    maxWidth: maxWidth,
    barrierDismissible: true,
    actions: [
      GlassDialogAction(
        label: cancelLabel,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
      ),
      GlassDialogAction(
        label: confirmLabel,
        isDestructive: isDestructive,
        isPrimary: !isDestructive,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
      ),
    ],
  );

  return result ?? false;
}
