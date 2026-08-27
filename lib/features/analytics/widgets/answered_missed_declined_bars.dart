import 'package:flutter/material.dart';

class AnsweredMissedDeclinedBars extends StatelessWidget {
  final Map<int, int> callTypeCounts;

  const AnsweredMissedDeclinedBars({super.key, required this.callTypeCounts});

  @override
  Widget build(BuildContext context) {
    final answered = (callTypeCounts[1] ?? 0) + (callTypeCounts[2] ?? 0);
    final missed = callTypeCounts[3] ?? 0;
    final declined = (callTypeCounts[5] ?? 0) + (callTypeCounts[6] ?? 0);

    final total = answered + missed + declined;

    if (total == 0) {
      return const Text('No calls yet.', style: TextStyle(color: Colors.grey));
    }

    Widget bar(String label, int value, Color color) {
      final fraction = value / total;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label — $value', style: const TextStyle(fontSize: 12)),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar('Answered', answered, Colors.green),
        bar('Missed', missed, Colors.orange),
        bar('Declined', declined, Colors.red),
      ],
    );
  }
}
