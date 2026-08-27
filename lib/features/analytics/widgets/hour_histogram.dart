import 'package:flutter/material.dart';

class HourHistogram extends StatelessWidget {
  final Map<int, int> hourCounts;

  const HourHistogram({super.key, required this.hourCounts});

  @override
  Widget build(BuildContext context) {
    final maxCount =
        hourCounts.values.isEmpty
            ? 1
            : hourCounts.values.reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(24, (hour) {
          final count = hourCounts[hour] ?? 0;

          final heightFraction = (count / maxCount).clamp(0.0, 1.0);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 50 * heightFraction,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
