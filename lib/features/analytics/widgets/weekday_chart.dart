import 'package:flutter/material.dart';

class WeekdayChart extends StatelessWidget {
  final Map<int, int> weekdayCounts;

  const WeekdayChart({super.key, required this.weekdayCounts});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const sqliteOrder = [1, 2, 3, 4, 5, 6, 0];

    final counts = List.generate(7, (i) => weekdayCounts[sqliteOrder[i]] ?? 0);
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxCount > 0 ? maxCount : 1;

    final weekdayTotal = counts[0] + counts[1] + counts[2] + counts[3] + counts[4];
    final weekendTotal = counts[5] + counts[6];
    final grandTotal = weekdayTotal + weekendTotal;

    final weekdayPct = grandTotal > 0 ? ((weekdayTotal / grandTotal) * 100).round() : 0;
    final weekendPct = grandTotal > 0 ? 100 - weekdayPct : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final count = counts[i];
              final isPeak = count == maxCount && count > 0;
              final isWeekend = i >= 5;
              final fraction = (count / effectiveMax).clamp(0.0, 1.0);
              const barAreaHeight = 65.0;
              final fillHeight = (barAreaHeight * fraction).clamp(count > 0 ? 4.0 : 0.0, barAreaHeight);

              final barColor = isPeak
                  ? const Color(0xFFF59E0B) // Amber peak
                  : (isWeekend ? const Color(0xFF8B5CF6) : scheme.primary);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Top count
                      SizedBox(
                        height: 14,
                        child: Text(
                          count > 0 ? '$count' : '',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                            color: isPeak ? const Color(0xFFF59E0B) : scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Bar track & fill
                      Container(
                        height: barAreaHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: fillHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                barColor,
                                barColor.withValues(alpha: 0.75),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: isPeak
                                ? [
                                    BoxShadow(
                                      color: barColor.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Day label
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                          color: isPeak
                              ? const Color(0xFFF59E0B)
                              : (isWeekend
                                  ? const Color(0xFF8B5CF6)
                                  : scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // Split Summary Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Workweek: $weekdayTotal calls ($weekdayPct%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B5CF6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Weekend: $weekendTotal calls ($weekendPct%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
