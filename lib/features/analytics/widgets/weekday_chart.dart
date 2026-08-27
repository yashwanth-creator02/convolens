import 'package:flutter/material.dart';

class WeekdayChart extends StatelessWidget {
  final Map<int, int> weekdayCounts;

  const WeekdayChart({super.key, required this.weekdayCounts});

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const sqliteOrder = [1, 2, 3, 4, 5, 6, 0];

    final maxCount =
        weekdayCounts.values.isEmpty
            ? 1
            : weekdayCounts.values
                .reduce((a, b) => a > b ? a : b)
                .clamp(1, 999999);

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final count = weekdayCounts[sqliteOrder[i]] ?? 0;
          final heightFraction = (count / maxCount).clamp(0.0, 1.0);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(fontSize: 9),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 50 * heightFraction,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    labels[i],
                    style: const TextStyle(fontSize: 9),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
