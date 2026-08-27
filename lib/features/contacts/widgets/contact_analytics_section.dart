import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../utils/communication_strength.dart';

class ContactAnalyticsSection extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;

  const ContactAnalyticsSection({
    super.key,
    required this.normalizedNumber,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: () async {
        final stats = await db.getContactCallStats(normalizedNumber);
        final firstCallTs = await db.getFirstCallTimestamp(normalizedNumber);

        return {...stats, 'firstCallTs': firstCallTs};
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;

        final total = stats['total'] as int;

        if (total == 0) {
          return const Text(
            'No calls yet.',
            style: TextStyle(color: Colors.grey),
          );
        }

        final totalDuration = stats['totalDuration'] as int;
        final avgDuration = stats['avgDuration'] as double;
        final incoming = stats['incoming'] as int;
        final outgoing = stats['outgoing'] as int;

        final firstCallTs =
            stats['firstCallTs'] as int? ??
            DateTime.now().millisecondsSinceEpoch;

        final lastCallTs = stats['lastCallAt'] as int?;

        final strength = computeStrength(
          callCount: total,
          lastCallAt: lastCallTs,
          firstCallAt: firstCallTs,
          totalDurationSeconds: totalDuration,
        );

        final strengthColor = switch (strength.level) {
          StrengthLevel.strong => Colors.green,
          StrengthLevel.steady => Colors.blue,
          StrengthLevel.fading => Colors.orange,
          StrengthLevel.new_ => Colors.purple,
          StrengthLevel.dormant => Colors.grey,
        };

        final totalMinutes = (totalDuration / 60).round();
        final avgSeconds = avgDuration.round();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _showWhy(context, strength),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: strengthColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: strengthColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strength.label,
                      style: TextStyle(
                        color: strengthColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline, size: 14, color: strengthColor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _stat('Total Calls', '$total'),
                _stat('Talk Time', '${totalMinutes}m'),
                _stat('Avg Duration', '${avgSeconds}s'),
                _stat('Incoming', '$incoming'),
                _stat('Outgoing', '$outgoing'),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showWhy(BuildContext context, CommunicationStrength strength) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why "${strength.label}"?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 12),

            ...strength.reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• $reason'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
