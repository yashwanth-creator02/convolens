import 'package:flutter/material.dart';

class NetworkConcentrationMeter extends StatelessWidget {
  final double concentration; // 0.0 to 1.0

  const NetworkConcentrationMeter({
    super.key,
    required this.concentration,
  });

  @override
  Widget build(BuildContext context) {
    final value = concentration.clamp(0.0, 1.0);

    final String status;
    final String description;
    final Color badgeColor;

    if (value < 0.20) {
      status = 'Diverse';
      description = 'Calls are distributed across a wide circle of contacts without over-reliance on any single person.';
      badgeColor = const Color(0xFF10B981);
    } else if (value < 0.45) {
      status = 'Focused';
      description = 'You have a healthy core group of regular contacts while still keeping in touch with others.';
      badgeColor = const Color(0xFF06B6D4);
    } else {
      status = 'Concentrated';
      description = 'Most of your communication time is concentrated on 1 or 2 primary connections.';
      badgeColor = const Color(0xFF8B5CF6);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Network Balance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Custom Gradient Track with Marker
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final pinPosition = (trackWidth - 12) * value;

              return Column(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF10B981), // Diverse
                          Color(0xFF06B6D4), // Focused
                          Color(0xFF8B5CF6), // Concentrated
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 12,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: pinPosition.clamp(0.0, trackWidth - 12),
                          top: 0,
                          child: Icon(
                            Icons.arrow_drop_up_rounded,
                            size: 16,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diverse',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              Text(
                'Balanced',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              Text(
                'Concentrated',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
