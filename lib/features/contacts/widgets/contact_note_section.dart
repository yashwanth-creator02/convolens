import 'package:flutter/material.dart';

import '../../../shared/widgets/text_input_dialog.dart';

class ContactNoteSection extends StatelessWidget {
  final String? note;
  final Future<void> Function(String note) onSave;

  const ContactNoteSection({
    super.key,
    required this.note,
    required this.onSave,
  });

  bool get _hasNote => note != null && note!.trim().isNotEmpty;

  Future<void> _editNote(BuildContext context) async {
    final result = await showTextInputDialog(
      context: context,
      title: 'Contact Note',
      initialValue: note,
      hintText: 'General notes about this contact…',
      maxLines: 4,
    );

    if (result == null) {
      return;
    }

    await onSave(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Note', style: TextStyle(fontWeight: FontWeight.bold)),
            if (!_hasNote)
              TextButton.icon(
                onPressed: () => _editNote(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_hasNote) _NoteCard(note: note!, onTap: () => _editNote(context)),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            Expanded(child: Text(note)),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
