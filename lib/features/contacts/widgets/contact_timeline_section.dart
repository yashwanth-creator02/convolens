import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../history/utils/call_type_label.dart';

class ContactTimelineSection extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;

  const ContactTimelineSection({
    super.key,
    required this.normalizedNumber,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Call>>(
      stream: db.watchCallsForNumber(normalizedNumber),
      builder: (context, snapshot) {
        final calls = snapshot.data ?? [];
        if (calls.isEmpty) {
          return const Text(
            'No calls yet.',
            style: TextStyle(color: Colors.grey),
          );
        }

        // watchCallsForNumber returns newest-first; timeline reads oldest-to-newest.
        final chronological = calls.reversed.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(chronological.length, (index) {
            final call = chronological[index];
            final isLast = index == chronological.length - 1;

            String? gapLabel;
            double gapHeight = 12;

            if (index > 0) {
              final previous = chronological[index - 1];
              final gapDays =
                  (call.timestamp - previous.timestamp) ~/
                  (1000 * 60 * 60 * 24);

              if (gapDays >= 1) {
                gapLabel = gapDays == 1 ? '1 day later' : '$gapDays days later';
                gapHeight = (12 + (gapDays * 2)).clamp(12, 80).toDouble();
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (gapLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 4, bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 2,
                          height: gapHeight,
                          child: ColoredBox(color: Colors.grey.shade300),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          gapLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          _buildDot(call.type),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: Colors.grey.shade300,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${callTypeLabel(call.type)} • ${call.duration}s',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                _formatDateTime(call.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildDot(int type) {
    final color = switch (type) {
      1 => Colors.green,
      2 => Colors.blue,
      3 => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }
}
