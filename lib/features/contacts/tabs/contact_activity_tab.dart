import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../widgets/contact_call_history_list.dart';
import '../widgets/contact_glass_card.dart';
import '../widgets/contact_note_section.dart';
import '../widgets/contact_timeline_section.dart';

class ContactActivityTab extends StatefulWidget {
  final String normalizedNumber;
  final AppDatabase db;
  final Contact? deviceContact;

  const ContactActivityTab({
    super.key,
    required this.normalizedNumber,
    required this.db,
    this.deviceContact,
  });

  @override
  State<ContactActivityTab> createState() => _ContactActivityTabState();
}

enum _ActivityFilter { all, calls, timeline, notes }

class _ContactActivityTabState extends State<ContactActivityTab> {
  _ActivityFilter _filter = _ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ================================================================
        // Activity filter pills
        // ================================================================
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _ActivityFilter.values.map((filter) {
              final isSelected = _filter == filter;
              final scheme = Theme.of(context).colorScheme;
              final label = switch (filter) {
                _ActivityFilter.all => 'All',
                _ActivityFilter.calls => 'Calls',
                _ActivityFilter.timeline => 'Timeline',
                _ActivityFilter.notes => 'Notes',
              };
              final icon = switch (filter) {
                _ActivityFilter.all => Icons.dashboard_rounded,
                _ActivityFilter.calls => Icons.call_rounded,
                _ActivityFilter.timeline => Icons.timeline_rounded,
                _ActivityFilter.notes => Icons.notes_rounded,
              };

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(label),
                  avatar: Icon(icon, size: 16),
                  selectedColor: scheme.primary.withValues(alpha: 0.15),
                  checkmarkColor: scheme.primary,
                  side: BorderSide(
                    color: isSelected
                        ? scheme.primary.withValues(alpha: 0.4)
                        : scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) =>
                      setState(() => _filter = filter),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // ================================================================
        // Timeline Section (Shown for 'all' and 'timeline')
        // ================================================================
        if (_filter == _ActivityFilter.all ||
            _filter == _ActivityFilter.timeline) ...[
          ContactGlassCard(
            title: 'Timeline',
            icon: Icons.timeline_outlined,
            child: ContactTimelineSection(
              normalizedNumber: widget.normalizedNumber,
              db: widget.db,
            ),
          ),
        ],

        // ================================================================
        // Call History Section (Shown for 'all' and 'calls')
        // ================================================================
        if (_filter == _ActivityFilter.all ||
            _filter == _ActivityFilter.calls) ...[
          ContactGlassCard(
            title: 'Call History',
            icon: Icons.call_outlined,
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: ContactCallHistoryList(
              normalizedNumber: widget.normalizedNumber,
              db: widget.db,
              deviceContact: widget.deviceContact,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
          ),
        ],

        // ================================================================
        // Notes Section (Shown for 'notes')
        // ================================================================
        if (_filter == _ActivityFilter.notes) ...[
          StreamBuilder<ContactDetail?>(
            stream: widget.db.watchContactDetails(widget.normalizedNumber),
            builder: (context, snapshot) {
              final detail = snapshot.data;
              final hasNote = detail?.generalNote != null &&
                  detail!.generalNote!.trim().isNotEmpty;
              final scheme = Theme.of(context).colorScheme;

              return ContactGlassCard(
                title: 'Note',
                icon: Icons.notes_outlined,
                trailing: hasNote
                    ? TextButton.icon(
                        onPressed: () async {
                          await widget.db
                              .saveContactNote(widget.normalizedNumber, '');
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
                  note: detail?.generalNote,
                  onSave: (note) async {
                    await widget.db.saveContactNote(
                      widget.normalizedNumber,
                      note,
                    );
                  },
                  onClear: () async {
                    await widget.db.saveContactNote(
                      widget.normalizedNumber,
                      '',
                    );
                  },
                ),
              );
            },
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }
}
