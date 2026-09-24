import 'package:flutter/material.dart';

class TalkRatioBar extends StatelessWidget {
  final Map<int, int> callTypeCounts;

  const TalkRatioBar({super.key, required this.callTypeCounts});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final incoming = callTypeCounts[1] ?? 0;
    final outgoing = callTypeCounts[2] ?? 0;
    final total = incoming + outgoing;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          'No connected calls recorded in this period.',
          style: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 12.5,
          ),
        ),
      );
    }

    final youPct = ((outgoing / total) * 100).round();
    final themPct = 100 - youPct;

    const youColor = Color(0xFF3B82F6); // Blue
    const themColor = Color(0xFF10B981); // Emerald

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two summary stat columns
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            // Outgoing / You
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: youColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_made_rounded,
                    size: 14,
                    color: youColor,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You Initiated',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$outgoing calls ($youPct%)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: youColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Incoming / Them
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'They Initiated',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$incoming calls ($themPct%)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: themColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: themColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_received_rounded,
                    size: 14,
                    color: themColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Split Progress Capsule
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                if (youPct > 0)
                  Expanded(
                    flex: youPct,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [youColor, Color(0xFF60A5FA)],
                        ),
                      ),
                    ),
                  ),
                if (youPct > 0 && themPct > 0)
                  Container(width: 2, color: scheme.surface),
                if (themPct > 0)
                  Expanded(
                    flex: themPct,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF34D399), themColor],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Smart insight text pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: youPct >= 55
                    ? youColor
                    : (themPct >= 55 ? themColor : scheme.primary),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  youPct > 55
                      ? 'You start more conversations than you receive ($youPct% outgoing).'
                      : (themPct > 55
                          ? 'Others reach out to you more often ($themPct% incoming).'
                          : 'Your initiation reciprocity is well balanced (~50/50 split).'),
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
}
