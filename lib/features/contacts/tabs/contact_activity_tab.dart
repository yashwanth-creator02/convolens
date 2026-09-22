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
            children: [
              FilterChip(
                selected: _filter == _ActivityFilter.all,
                label: const Text('All'),
                onSelected: (_) =>
                    setState(() => _filter = _ActivityFilter.all),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _filter == _ActivityFilter.calls,
                label: const Text('Calls'),
                onSelected: (_) =>
                    setState(() => _filter = _ActivityFilter.calls),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _filter == _ActivityFilter.timeline,
                label: const Text('Timeline'),
                onSelected: (_) =>
                    setState(() => _filter = _ActivityFilter.timeline),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _filter == _ActivityFilter.notes,
                label: const Text('Notes'),
                onSelected: (_) =>
                    setState(() => _filter = _ActivityFilter.notes),
              ),
            ],
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
              return ContactGlassCard(
                title: 'Note',
                icon: Icons.notes_outlined,
                child: ContactNoteSection(
                  note: detail?.generalNote,
                  onSave: (note) async {
                    await widget.db.saveContactNote(
                      widget.normalizedNumber,
                      note,
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
