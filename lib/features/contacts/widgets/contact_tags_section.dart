import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/add_tag_dialog.dart';

class ContactTagsSection extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;

  const ContactTagsSection({
    super.key,
    required this.normalizedNumber,
    required this.db,
  });

  Future<void> _addTag(BuildContext context) async {
    final existingTags = await db.getAllTags();

    if (!context.mounted) {
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AddTagDialog(existingTags: existingTags);
      },
    );

    if (result == null || result.trim().isEmpty) {
      return;
    }

    await db.addTagToContact(normalizedNumber, result.trim());
  }

  Future<void> _removeTag(Tag tag) async {
    await db.removeTagFromContact(normalizedNumber, tag.id);
  }

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
              onPressed: () => _addTag(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Tag>>(
          stream: db.watchTagsForContact(normalizedNumber),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SizedBox(
                height: 24,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            if (snapshot.hasError) {
              return const Text(
                'Failed to load tags.',
                style: TextStyle(color: Colors.grey),
              );
            }

            final tags = snapshot.data ?? [];

            if (tags.isEmpty) {
              return const Text(
                'No tags yet.',
                style: TextStyle(color: Colors.grey),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags.map((tag) {
                return Chip(
                  label: Text(tag.name),
                  onDeleted: () => _removeTag(tag),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
