import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class AddTagDialog extends StatefulWidget {
  final List<Tag> existingTags;

  const AddTagDialog({super.key, required this.existingTags});

  @override
  State<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<AddTagDialog> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      setState(() {
        _query = _controller.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTags = widget.existingTags
        .where((tag) => tag.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final exactMatchExists = widget.existingTags.any(
      (tag) => tag.name.toLowerCase() == _query.toLowerCase(),
    );

    final buttonLabel = _query.isEmpty
        ? 'Add'
        : (exactMatchExists ? 'Add' : 'Create & Add');

    return AlertDialog(
      title: const Text('Add Tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Type to search or create…',
              border: OutlineInputBorder(),
            ),
          ),
          if (filteredTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Tap to select:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: filteredTags
                  .map(
                    (tag) => ActionChip(
                      label: Text(tag.name),
                      onPressed: () => Navigator.pop(context, tag.name),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _query.isEmpty
              ? null
              : () => Navigator.pop(context, _query),
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}
