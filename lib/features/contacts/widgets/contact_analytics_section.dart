import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

class ContactAnalyticsSection extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;

  const ContactAnalyticsSection({super.key, required this.normalizedNumber, required this.db});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: db.getContactCallStats(normalizedNumber),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final stats = snapshot.data!;
        final total = stats['total'] as int;
        if (total == 0) return const Text('No calls yet.', style: TextStyle(color: Colors.grey));

        final totalMinutes = ((stats['totalDuration'] as int) / 60).round();
        final avgSeconds = (stats['avgDuration'] as double).round();
        final incoming = stats['incoming'] as int;
        final outgoing = stats['outgoing'] as int;

        return Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _stat('Total Calls', '$total'),
            _stat('Talk Time', '${totalMinutes}m'),
            _stat('Avg Duration', '${avgSeconds}s'),
            _stat('Incoming', '$incoming'),
            _stat('Outgoing', '$outgoing'),
          ],
        );
      },
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}