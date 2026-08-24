import 'package:flutter/material.dart';

class ContributionHeatmap extends StatelessWidget {
  final Map<String, int> countsByDate;
  final void Function(DateTime day, int count)? onDayTap;

  const ContributionHeatmap(
      {super.key, required this.countsByDate, this.onDayTap});

  String _keyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(
          2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Color _colorFor(BuildContext context, int count, int maxCount) {
    if (count == 0) return Theme
        .of(context)
        .colorScheme
        .surfaceContainerHighest;
    final intensity = (count / maxCount).clamp(0.15, 1.0);
    return Theme
        .of(context)
        .colorScheme
        .primary
        .withOpacity(intensity);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 364));
    final firstSunday = startDate.subtract(
        Duration(days: startDate.weekday % 7));

    final maxCount = countsByDate.values.isEmpty
        ? 1
        : countsByDate.values.reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    final weeks = <List<DateTime>>[];
    var cursor = firstSunday;
    while (!cursor.isAfter(today)) {
      final week = List.generate(7, (i) => cursor.add(Duration(days: i)));
      weeks.add(week);
      cursor = cursor.add(const Duration(days: 7));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: weeks.map((week) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Column(
              children: week.map((day) {
                final isFuture = day.isAfter(today);
                final count = countsByDate[_keyFor(day)] ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: GestureDetector(
                    onTap: isFuture ? null : () => onDayTap?.call(day, count),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isFuture
                            ? Colors.transparent
                            : _colorFor(context, count, maxCount),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}