import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../history/widgets/call_details/tag_selection_glass_sheet.dart';
import '../widgets/contact_glass_card.dart';
import '../widgets/contact_links_section.dart';
import '../widgets/contact_note_section.dart';
import '../widgets/contact_phone_numbers_section.dart';
import '../widgets/contact_tags_section.dart';

class ContactOverviewTab extends StatelessWidget {
  final String normalizedNumber;
  final String displayNumber;
  final Contact? deviceContact;
  final ContactDetail? detail;
  final AppDatabase db;

  const ContactOverviewTab({
    super.key,
    required this.normalizedNumber,
    required this.displayNumber,
    required this.deviceContact,
    required this.detail,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ================================================================
        // Quick Stats
        // ================================================================
        ContactGlassCard(
          title: 'Quick Stats',
          icon: Icons.bar_chart_rounded,
          child: _QuickStatsContent(
            normalizedNumber: normalizedNumber,
            db: db,
          ),
        ),

        // ================================================================
        // Phone Numbers
        // ================================================================
        ContactGlassCard(
          title: 'Phone Numbers',
          icon: Icons.phone_outlined,
          child: ContactPhoneNumbersSection(
            deviceContact: deviceContact,
            fallbackNumber: displayNumber,
          ),
        ),

        // ================================================================
        // Note (live via StreamBuilder, with Clear trailing action)
        // ================================================================
        StreamBuilder<ContactDetail?>(
          stream: db.watchContactDetails(normalizedNumber),
          initialData: detail,
          builder: (context, snapshot) {
            final liveDetail = snapshot.data ?? detail;
            final hasNote = liveDetail?.generalNote != null &&
                liveDetail!.generalNote!.trim().isNotEmpty;

            return ContactGlassCard(
              title: 'Note',
              icon: Icons.edit_note_rounded,
              trailing: hasNote
                  ? TextButton.icon(
                      onPressed: () async {
                        await db.saveContactNote(normalizedNumber, '');
                      },
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 14, color: scheme.error),
                      label: Text(
                        'Clear',
                        style: TextStyle(
                          color: scheme.error,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    )
                  : null,
              child: ContactNoteSection(
                note: liveDetail?.generalNote,
                onSave: (note) async {
                  await db.saveContactNote(normalizedNumber, note);
                },
                onClear: () async {
                  await db.saveContactNote(normalizedNumber, '');
                },
              ),
            );
          },
        ),

        // ================================================================
        // Tags (with Edit trailing action)
        // ================================================================
        StreamBuilder<List<Tag>>(
          stream: db.watchTagsForContact(normalizedNumber),
          builder: (context, snapshot) {
            final tags = snapshot.data ?? const [];

            return ContactGlassCard(
              title: 'Tags',
              icon: Icons.local_offer_outlined,
              trailing: tags.isNotEmpty
                  ? TextButton.icon(
                      onPressed: () => TagSelectionGlassSheet.showForContact(
                        context: context,
                        db: db,
                        normalizedNumber: normalizedNumber,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    )
                  : null,
              child: ContactTagsSection(
                tags: tags,
                onAdd: () => TagSelectionGlassSheet.showForContact(
                  context: context,
                  db: db,
                  normalizedNumber: normalizedNumber,
                ),
                onRemove: (tag) =>
                    db.removeTagFromContact(normalizedNumber, tag.id),
              ),
            );
          },
        ),

        // ================================================================
        // Links
        // ================================================================
        ContactGlassCard(
          title: 'Links',
          icon: Icons.link_outlined,
          trailing: TextButton.icon(
            onPressed: () => ContactLinksSection.showAddLinkSheet(
              context,
              db: db,
              normalizedNumber: normalizedNumber,
            ),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text('Add'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ),
          child: ContactLinksSection(
            normalizedNumber: normalizedNumber,
            db: db,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

/// Compact stats row showing total calls, last contacted, and call frequency.
class _QuickStatsContent extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;

  const _QuickStatsContent({
    required this.normalizedNumber,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<Call>>(
      stream: db.watchCallsForNumber(normalizedNumber),
      builder: (context, snapshot) {
        final calls = snapshot.data ?? const [];

        if (calls.isEmpty) {
          return Row(
            children: [
              Icon(Icons.info_outline, size: 16,
                  color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'No call history yet',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }

        final totalCalls = calls.length;
        final incomingCalls = calls.where((c) => c.type == 1).length;
        final outgoingCalls = calls.where((c) => c.type == 2).length;
        final missedCalls = calls.where((c) => c.type == 3).length;

        // Last contacted
        final lastCall = calls.first;
        final lastContactedDate = DateTime.fromMillisecondsSinceEpoch(
            lastCall.timestamp);
        final daysSince =
            DateTime.now().difference(lastContactedDate).inDays;
        final lastContactedText = daysSince == 0
            ? 'Today'
            : daysSince == 1
                ? 'Yesterday'
                : '$daysSince days ago';

        // Total duration
        final totalSeconds =
            calls.fold<int>(0, (sum, c) => sum + c.duration);
        final totalMinutes = (totalSeconds / 60).round();
        final durationText = totalMinutes < 60
            ? '${totalMinutes}m'
            : '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';

        return Column(
          children: [
            Row(
              children: [
                _StatChip(
                  icon: Icons.call_rounded,
                  label: '$totalCalls',
                  subtitle: 'Total',
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.call_received_rounded,
                  label: '$incomingCalls',
                  subtitle: 'In',
                  color: scheme.tertiary,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.call_made_rounded,
                  label: '$outgoingCalls',
                  subtitle: 'Out',
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.call_missed_rounded,
                  label: '$missedCalls',
                  subtitle: 'Missed',
                  color: scheme.error,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14,
                    color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Last: $lastContactedText',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timer_outlined, size: 14,
                    color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Total: $durationText',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
