import 'package:flutter/material.dart';

class AnsweredMissedDeclinedBars extends StatelessWidget {
  final Map<int, int> callTypeCounts;

  const AnsweredMissedDeclinedBars({super.key, required this.callTypeCounts});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final answered = (callTypeCounts[1] ?? 0) + (callTypeCounts[2] ?? 0);
    final missed = callTypeCounts[3] ?? 0;
    final declined = (callTypeCounts[5] ?? 0) + (callTypeCounts[6] ?? 0);

    final total = answered + missed + declined;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          'No call outcome data in this period.',
          style: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 12.5,
          ),
        ),
      );
    }

    final answeredPct = ((answered / total) * 100).round();
    final missedPct = ((missed / total) * 100).round();
    final declinedPct = 100 - answeredPct - missedPct;

    const answeredColor = Color(0xFF10B981); // Emerald
    const missedColor = Color(0xFFF59E0B); // Amber
    const declinedColor = Color(0xFFEF4444); // Red

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 Outcome Metric Pills
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.check_circle_outline_rounded,
                color: answeredColor,
                label: 'Answered',
                value: '$answered',
                pct: '$answeredPct%',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.phone_missed_rounded,
                color: missedColor,
                label: 'Missed',
                value: '$missed',
                pct: '$missedPct%',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.phone_disabled_rounded,
                color: declinedColor,
                label: 'Declined',
                value: '$declined',
                pct: '${declinedPct < 0 ? 0 : declinedPct}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Segmented Visual Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (answered > 0)
                  Expanded(
                    flex: answered,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [answeredColor, Color(0xFF34D399)],
                        ),
                      ),
                    ),
                  ),
                if (answered > 0 && (missed > 0 || declined > 0))
                  Container(width: 2, color: scheme.surface),
                if (missed > 0)
                  Expanded(
                    flex: missed,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [missedColor, Color(0xFFFBBF24)],
                        ),
                      ),
                    ),
                  ),
                if (missed > 0 && declined > 0)
                  Container(width: 2, color: scheme.surface),
                if (declined > 0)
                  Expanded(
                    flex: declined,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [declinedColor, Color(0xFFF87171)],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Response Rate Summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                answeredPct >= 75
                    ? Icons.verified_rounded
                    : Icons.info_outline_rounded,
                size: 13,
                color: answeredPct >= 75 ? answeredColor : missedColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  answeredPct >= 80
                      ? 'High responsiveness: $answeredPct% of calls successfully connected.'
                      : (answeredPct >= 60
                          ? 'Moderate responsiveness: $answeredPct% connected, $missedPct% missed.'
                          : 'High miss rate: $missedPct% of calls missed in this period.'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String pct,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                pct,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
