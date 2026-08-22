import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../../../core/toast/toast_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../models/contact_summary.dart';

class ContactSettingsSection extends StatelessWidget {
  final String normalizedNumber;
  final String displayName;
  final String displayNumber;
  final ContactDetail? detail;
  final AppDatabase db;

  const ContactSettingsSection({
    super.key,
    required this.normalizedNumber,
    required this.displayName,
    required this.displayNumber,
    required this.detail,
    required this.db,
  });

  Future<void> _exportContact(BuildContext context) async {
    final note = detail?.generalNote?.isNotEmpty == true
        ? detail!.generalNote!
        : 'None';
    final tags = await db.watchTagsForContact(normalizedNumber).first;
    final calls = await db.watchCallsForNumber(normalizedNumber).first;

    final summary =
        '''
Name: $displayName
Number: $displayNumber
Note: $note
Tags: ${tags.isEmpty ? 'None' : tags.map((t) => t.name).join(', ')}
Total calls: ${calls.length}
''';

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Contact'),
        content: SingleChildScrollView(child: Text(summary)),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: summary));
              if (context.mounted) {
                Navigator.pop(context);
                ToastService.success(context, 'Copied to clipboard.');
              }
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllNotes(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete All Notes?',
      message:
          'This will permanently delete the general note for this contact and every note on their individual calls. This cannot be undone.',
      confirmLabel: 'Delete All',
      isDestructive: true,
    );

    if (!confirmed) return;

    await db.clearAllNotesForContact(normalizedNumber);

    if (context.mounted) {
      ToastService.success(context, 'All notes deleted.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Archive Contact'),
          subtitle: const Text('Hide from the main Contacts list'),
          value: detail?.isArchived ?? false,
          onChanged: (value) => db.setContactFields(
            normalizedNumber,
            ContactDetailsCompanion(isArchived: drift.Value(value)),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ignore from Analytics'),
          value: detail?.ignoreFromAnalytics ?? false,
          onChanged: (value) => db.setContactFields(
            normalizedNumber,
            ContactDetailsCompanion(ignoreFromAnalytics: drift.Value(value)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _exportContact(context),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Export'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _deleteAllNotes(context),
              icon: const Icon(
                Icons.delete_sweep_outlined,
                size: 18,
                color: Colors.red,
              ),
              label: const Text(
                'Delete All Notes',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
