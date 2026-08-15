import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/add_tag_dialog.dart';
import '../../../shared/widgets/text_input_dialog.dart';
import '../../history/widgets/call_card.dart';

class ContactDetailScreen extends StatelessWidget {
  final String normalizedNumber;
  final String displayName;
  final String displayNumber;
  final AppDatabase db;

  const ContactDetailScreen({
    super.key,
    required this.normalizedNumber,
    required this.displayName,
    required this.displayNumber,
    required this.db,
  });

  Future<void> _editNote(BuildContext context, String? currentNote) async {
    final result = await showTextInputDialog(
      context: context,
      title: 'Contact Note',
      initialValue: currentNote,
      hintText: 'General notes about this contact…',
      maxLines: 4,
    );
    if (result == null) return;
    await db.saveContactNote(normalizedNumber, result);
  }

  Future<void> _addTag(BuildContext context) async {
    final existingTags = await db.getAllTags();
    if (!context.mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AddTagDialog(existingTags: existingTags),
    );
    if (result == null || result.isEmpty) return;

    await db.addTagToContact(normalizedNumber, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: StreamBuilder<ContactDetail?>(
        stream: db.watchContactDetails(normalizedNumber),
        builder: (context, detailSnapshot) {
          final detail = detailSnapshot.data;
          final isFavorite = detail?.isFavorite ?? false;
          final note = detail?.generalNote;
          final hasNote = note != null && note.isNotEmpty;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                if (displayNumber.isNotEmpty)
                                  Text(displayNumber),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              color: isFavorite ? Colors.amber : Colors.grey,
                              size: 28,
                            ),
                            onPressed: () => db.toggleContactFavorite(
                              normalizedNumber,
                              !isFavorite,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Note',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (!hasNote)
                            TextButton.icon(
                              onPressed: () => _editNote(context, note),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (hasNote)
                        InkWell(
                          onTap: () => _editNote(context, note),
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
                                const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),

                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tags',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                        builder: (context, tagSnapshot) {
                          final contactTags = tagSnapshot.data ?? [];
                          if (contactTags.isEmpty) {
                            return const Text(
                              'No tags yet.',
                              style: TextStyle(color: Colors.grey),
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: contactTags
                                .map(
                                  (tag) => Chip(
                                    label: Text(tag.name),
                                    onDeleted: () => db.removeTagFromContact(
                                      normalizedNumber,
                                      tag.id,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),

                      const Divider(height: 32),
                      const Text(
                        'Call History',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              StreamBuilder<List<Call>>(
                stream: db.watchCallsForNumber(normalizedNumber),
                builder: (context, callsSnapshot) {
                  final calls = callsSnapshot.data ?? [];
                  if (calls.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'No calls yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => CallCard(call: calls[index], db: db),
                      childCount: calls.length,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
