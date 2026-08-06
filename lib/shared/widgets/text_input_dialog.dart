import 'package:flutter/material.dart';

Future<String?> showTextInputDialog({
  required BuildContext context,
  required String title,
  String? initialValue,
  String hintText = '',
  int maxLines = 1,
  String confirmLabel = 'Save',
  String cancelLabel = 'Cancel',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextInputDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      maxLines: maxLines,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String hintText;
  final int maxLines;
  final String confirmLabel;
  final String cancelLabel;

  const _TextInputDialog({
    required this.title,
    this.initialValue,
    required this.hintText,
    required this.maxLines,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: widget.maxLines,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        TextButton(onPressed: _save, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
