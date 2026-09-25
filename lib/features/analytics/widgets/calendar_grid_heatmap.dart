import 'package:flutter/material.dart';

class CalendarGridHeatmap extends StatefulWidget {
  final Map<String, int> countsByDate;
  final int month;
  final int year;
  final void Function(DateTime day, int count)? onDayTap;

  const CalendarGridHeatmap({
    super.key,
    required this.countsByDate,
    required this.month,
    required this.year,
    this.onDayTap,
  });

  @override
  State<CalendarGridHeatmap> createState() => _CalendarGridHeatmapState();
}

class _CalendarGridHeatmapState extends State<CalendarGridHeatmap> {
  DateTime? _lastTapTime;

  void _handleTap(DateTime day, int count) {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 700) {
      return;
    }
    _lastTapTime = now;
    widget.onDayTap?.call(day, count);
  }

  String _keyFor(int day) =>
      '${widget.year.toString().padLeft(4, '0')}-${widget.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(widget.year, widget.month, 1);
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;
    final leadingBlanks = (firstDay.weekday - 1) % 7; // Monday = 0

    final maxCount = widget.countsByDate.values.isEmpty
        ? 1
        : widget.countsByDate.values
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 999999);

    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
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
              final count = widget.countsByDate[_keyFor(day)] ?? 0;
              final intensity = count == 0
                  ? 0.0
                  : (count / maxCount).clamp(0.15, 1.0);
              final date = DateTime(widget.year, widget.month, day);
              final isFuture = date.isAfter(DateTime.now());

              return Padding(
                padding: const EdgeInsets.all(2),
                child: GestureDetector(
                  onTap: isFuture ? null : () => _handleTap(date, count),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      color: count == 0
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: intensity),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text('$day', style: const TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
