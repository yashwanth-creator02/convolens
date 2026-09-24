import 'package:flutter/material.dart';

class ScoreBreakdownBars extends StatelessWidget {
  final Map<String, double> breakdown; // e.g. 'Frequency': 20.0, etc.

  const ScoreBreakdownBars({
    super.key,
    required this.breakdown,
  });

  static const _details = {
    'Frequency': (
      icon: Icons.repeat_rounded,
      color: Color(0xFF3B82F6), // Blue
      desc: 'Regularity of staying in touch',
    ),
    'Diversity': (
      icon: Icons.diversity_3_rounded,
      color: Color(0xFF8B5CF6), // Purple
      desc: 'Breadth of active relationships',
    ),
    'Reciprocity': (
      icon: Icons.sync_alt_rounded,
      color: Color(0xFF10B981), // Emerald
      desc: 'Balance of who reaches out',
    ),
    'Responsiveness': (
      icon: Icons.phone_callback_rounded,
      color: Color(0xFFF59E0B), // Amber
      desc: 'Consistency in answering calls',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...breakdown.entries.map((entry) {
          final detail = _details[entry.key] ?? (
            icon: Icons.bubble_chart_rounded,
            color: Theme.of(context).colorScheme.primary,
            desc: '',
          );
          final value = entry.value.clamp(0.0, 25.0);
          final fraction = value / 25.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: detail.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(detail.icon, size: 16, color: detail.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (detail.desc.isNotEmpty)
                              Text(
                                detail.desc,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${value.round()}/25',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: detail.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0.0, end: fraction),
                      builder: (context, animVal, _) {
                        return LinearProgressIndicator(
                          value: animVal,
                          minHeight: 6,
                          backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(detail.color),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
