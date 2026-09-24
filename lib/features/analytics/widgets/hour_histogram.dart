import 'package:flutter/material.dart';

class HourHistogram extends StatelessWidget {
  final Map<int, int> hourCounts;

  const HourHistogram({super.key, required this.hourCounts});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final counts = List.generate(24, (h) => hourCounts[h] ?? 0);
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxCount > 0 ? maxCount : 1;

    // Time of day buckets
    int morningCalls = 0; // 6-12
    int afternoonCalls = 0; // 12-18
    int eveningCalls = 0; // 18-24
    int nightCalls = 0; // 0-6

    for (int h = 0; h < 24; h++) {
      final c = counts[h];
      if (h >= 6 && h < 12) {
        morningCalls += c;
      } else if (h >= 12 && h < 18) {
        afternoonCalls += c;
      } else if (h >= 18 && h < 24) {
        eveningCalls += c;
      } else {
        nightCalls += c;
      }
    }

    final totalCalls = morningCalls + afternoonCalls + eveningCalls + nightCalls;
    final peakHour = maxCount > 0 ? counts.indexOf(maxCount) : -1;

    String formatHour(int h) {
      if (h == 0) return '12 AM';
      if (h == 12) return '12 PM';
      if (h > 12) return '${h - 12} PM';
      return '$h AM';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Peak Hour Banner
        if (peakHour >= 0 && maxCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  'Peak Calling Window: ${formatHour(peakHour)} – ${formatHour((peakHour + 1) % 24)} ($maxCount calls)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),

        // 24 Hour Bars
        SizedBox(
          height: 85,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (hour) {
              final count = counts[hour];
              final isPeak = hour == peakHour && count > 0;
              final fraction = (count / effectiveMax).clamp(0.0, 1.0);
              const barHeight = 55.0;
              final fillHeight = (barHeight * fraction).clamp(count > 0 ? 3.0 : 0.0, barHeight);

              final color = isPeak
                  ? const Color(0xFFF59E0B)
                  : (hour >= 6 && hour < 18
                      ? scheme.primary
                      : const Color(0xFF8B5CF6));

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: barHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: fillHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: isPeak
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hour % 6 == 0 ? '$hour' : '',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
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

        // Time of Day Quadrant Pills
        if (totalCalls > 0)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuadrantChip(
                icon: Icons.wb_twilight_rounded,
                color: const Color(0xFFF59E0B),
                label: 'Morning (6-12)',
                count: morningCalls,
                pct: ((morningCalls / totalCalls) * 100).round(),
              ),
              _buildQuadrantChip(
                icon: Icons.wb_sunny_rounded,
                color: scheme.primary,
                label: 'Afternoon (12-18)',
                count: afternoonCalls,
                pct: ((afternoonCalls / totalCalls) * 100).round(),
              ),
              _buildQuadrantChip(
                icon: Icons.nights_stay_rounded,
                color: const Color(0xFF8B5CF6),
                label: 'Evening (18-24)',
                count: eveningCalls,
                pct: ((eveningCalls / totalCalls) * 100).round(),
              ),
              _buildQuadrantChip(
                icon: Icons.bedtime_outlined,
                color: const Color(0xFF64748B),
                label: 'Night (0-6)',
                count: nightCalls,
                pct: ((nightCalls / totalCalls) * 100).round(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildQuadrantChip({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
    required int pct,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count ($pct%)',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
