import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class CallTagsSection extends StatelessWidget {
  final List<Tag> tags;
  final VoidCallback onAdd;
  final void Function(Tag tag) onRemove;

  const CallTagsSection({
    super.key,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (tags.isEmpty)
          const Text('No tags yet.', style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: tags.map((tag) {
              return Chip(
                label: Text(tag.name),
                onDeleted: () => onRemove(tag),
              );
            }).toList(),
          ),
      ],
    );
  }
}
