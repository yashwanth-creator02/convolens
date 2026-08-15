import 'package:flutter/material.dart';

class CallNoteSection extends StatelessWidget {
  final String? note;
  final VoidCallback onAdd;
  final VoidCallback onEdit;

  const CallNoteSection({
    super.key,
    required this.note,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedNote = note?.trim();
    final hasNote = trimmedNote?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Note', style: TextStyle(fontWeight: FontWeight.bold)),
            if (!hasNote)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),

        const SizedBox(height: 8),

        if (hasNote)
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(trimmedNote!)),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, size: 18, color: Colors.grey),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
