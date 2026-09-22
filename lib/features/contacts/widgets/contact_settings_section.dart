import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../../core/toast/toast_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ignore from Analytics',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Exclude calls with this contact from graphs & stats',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GlassSwitch(
                  value: detail?.ignoreFromAnalytics ?? false,
                  useOwnLayer: false,
                  quality: GlassQuality.standard,
                  activeColor: scheme.primary,
                  width: 50.0,
                  height: 28.0,
                  onChanged: (value) => db.setContactFields(
                    normalizedNumber,
                    ContactDetailsCompanion(ignoreFromAnalytics: drift.Value(value)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _exportContact(context),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Export'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _deleteAllNotes(context),
                icon: Icon(
                  Icons.delete_sweep_rounded,
                  size: 16,
                  color: scheme.error,
                ),
                label: Text(
                  'Delete Notes',
                  style: TextStyle(color: scheme.error),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.errorContainer.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
