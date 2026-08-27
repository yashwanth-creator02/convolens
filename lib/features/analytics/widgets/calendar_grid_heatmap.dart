import 'package:flutter/material.dart';

class CalendarGridHeatmap extends StatelessWidget {
  final Map<String, int> countsByDate;
  final int month;
  final int year;

  const CalendarGridHeatmap({
    super.key,
    required this.countsByDate,
    required this.month,
    required this.year,
  });

  String _keyFor(int day) =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingBlanks = (firstDay.weekday - 1) % 7; // Monday = 0

    final maxCount =
        countsByDate.values.isEmpty
            ? 1
            : countsByDate.values
                .reduce((a, b) => a > b ? a : b)
                .clamp(1, 999999);

    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              weekdays
                  .map(
                    (w) => Text(
                      w,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox();

            final day = index - leadingBlanks + 1;
            final count = countsByDate[_keyFor(day)] ?? 0;
            final intensity =
                count == 0 ? 0.0 : (count / maxCount).clamp(0.15, 1.0);

            return Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      count == 0
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                          : Theme.of(context).colorScheme.primary.withOpacity(
                            intensity,
                          ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text('$day', style: const TextStyle(fontSize: 9)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
