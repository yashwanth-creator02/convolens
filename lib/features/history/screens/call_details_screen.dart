import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/toast/toast_service.dart';
import '../../../shared/widgets/text_input_dialog.dart';
import '../utils/call_type_label.dart';
import '../utils/format_call_time.dart';

class CallDetailScreen extends StatelessWidget {
  final Call call;
  final AppDatabase db;

  const CallDetailScreen({super.key, required this.call, required this.db});

  Future<void> _editNote(BuildContext context, String? currentNote) async {
    final result = await showTextInputDialog(
      context: context,
      title: 'Call Note',
      initialValue: currentNote,
      hintText: 'Add a note about this call…',
      maxLines: 4,
    );

    if (result == null) return;

    await db.saveNote(call.id, result);

    try {
      await db.saveNote(call.id, result);

      if (!context.mounted) return;
      ToastService.success(context, 'Note saved.');
    } catch (e) {
      if (!context.mounted) return;
      ToastService.error(context, 'Failed to save note.');
    }
  }

  Future<void> _addTag(BuildContext context) async {
    final existingTags = await db.getAllTags();

    if (!context.mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _AddTagDialog(existingTags: existingTags),
    );

    if (result == null || result.isEmpty) return;

    await db.addTagToCall(call.id, result);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = call.name?.isNotEmpty == true
        ? call.name!
        : (call.number ?? 'Unknown');

    return Scaffold(
      appBar: AppBar(title: const Text('Call Details')),
      body: StreamBuilder<Setting>(
        stream: db.watchSettings(),
        builder: (context, settingsSnapshot) {
          final devMode = settingsSnapshot.data?.devMode ?? false;

          return StreamBuilder<CallDetail?>(
            stream: db.watchDetailsForCall(call.id),
            builder: (context, detailSnapshot) {
              final note = detailSnapshot.data?.note;
              final hasNote = note != null && note.isNotEmpty;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 4),
                    if (call.number != null) Text(call.number!),
                    const SizedBox(height: 16),

                    _DetailRow(label: 'Type', value: callTypeLabel(call.type)),
                    _DetailRow(
                      label: 'Duration',
                      value: '${call.duration} seconds',
                    ),
                    _DetailRow(
                      label: 'Time',
                      value: formatCallTime(call.timestamp),
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
                      stream: db.watchTagsForCall(call.id),
                      builder: (context, tagSnapshot) {
                        final callTags = tagSnapshot.data ?? [];

                        if (callTags.isEmpty) {
                          return const Text(
                            'No tags yet.',
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: callTags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag.name),
                                  onDeleted: () =>
                                      db.removeTagFromCall(call.id, tag.id),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),

                    if (devMode) ...[
                      const Divider(height: 32),
                      const Text(
                        'Developer Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(label: 'Row ID', value: call.id.toString()),
                      _DetailRow(
                        label: 'Raw type code',
                        value: call.type.toString(),
                      ),
                      _DetailRow(
                        label: 'Raw timestamp (epoch ms)',
                        value: call.timestamp.toString(),
                      ),
                      _DetailRow(
                        label: 'Removed from device',
                        value: call.removedFromDevice.toString(),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _AddTagDialog extends StatefulWidget {
  final List<Tag> existingTags;

  const _AddTagDialog({required this.existingTags});

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
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
