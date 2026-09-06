import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../widgets/contact_call_history_list.dart';
import '../widgets/contact_timeline_section.dart';

class ContactActivityTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ================================================================
        // Activity filter
        // ================================================================

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                selected: true,
                label: const Text('All'),
                onSelected: (_) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: false,
                label: const Text('Calls'),
                onSelected: (_) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: false,
                label: const Text('Notes'),
                onSelected: (_) {},
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: false,
                label: const Text('Reminders'),
                onSelected: (_) {},
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ================================================================
        // Timeline
        // ================================================================

        _Section(
          title: 'Timeline',
          icon: Icons.timeline_outlined,
          child: SizedBox(
            height: 300,
            child: SingleChildScrollView(
              child: ContactTimelineSection(
                normalizedNumber: normalizedNumber,
                db: db,
              ),
            ),
          ),
        ),

        // ================================================================
        // Call history
        // ================================================================

        _Section(
          title: 'Call History',
          icon: Icons.call_outlined,
          child: SizedBox(
            height: 300,
            child: ContactCallHistoryList(
              normalizedNumber: normalizedNumber,
              db: db,
              deviceContact: deviceContact,
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
