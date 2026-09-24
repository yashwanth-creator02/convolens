import 'package:flutter/material.dart';

class SocialMomentumCard extends StatelessWidget {
  final double momentum; // e.g. 0.25 is +25%, -0.15 is -15%

  const SocialMomentumCard({
    super.key,
    required this.momentum,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (momentum * 100).round();
    final isPositive = pct > 0;
    final isNeutral = pct == 0;

    final Color statusColor;
    final IconData statusIcon;
    final String title;
    final String description;

    if (isPositive) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.trending_up_rounded;
      title = '+$pct% Velocity';
      description = 'Your phone connections are growing compared to the previous 14 days.';
    } else if (isNeutral) {
      statusColor = const Color(0xFF06B6D4);
      statusIcon = Icons.trending_flat_rounded;
      title = 'Steady Pace';
      description = 'Your communication rhythm has remained perfectly stable over the last month.';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.trending_down_rounded;
      title = '$pct% Cooldown';
      description = 'You have reached out less frequently in the past two weeks.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Social Momentum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
