import 'dart:math';
import 'package:flutter/material.dart';

class HourClockFace extends StatelessWidget {
  final Map<int, int> hourCounts;

  const HourClockFace({super.key, required this.hourCounts});

  @override
  Widget build(BuildContext context) {
    final maxCount =
        hourCounts.values.isEmpty
            ? 1
            : hourCounts.values.reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final center = Offset(size / 2, size / 2);
          final maxRadius = size / 2 - 20;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Clock markings
              ...List.generate(12, (i) {
                final hour = i * 2;
                final angle = (2 * pi * hour / 24) - (pi / 2);
                final pos =
                    center + Offset(maxRadius * cos(angle), maxRadius * sin(angle));
                return Positioned(
                  left: pos.dx - 10,
                  top: pos.dy - 10,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: Text(
                        '$hour',
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }),
              // Data points
              ...List.generate(24, (hour) {
                final count = hourCounts[hour] ?? 0;
                final angle = (2 * pi * hour / 24) - (pi / 2);
                final intensity = count / maxCount;
                final dotRadius = 3 + (intensity * 12);
                final distance = maxRadius * 0.75;

                final pos =
                    center +
                    Offset(distance * cos(angle), distance * sin(angle));

                return Positioned(
                  left: pos.dx - dotRadius,
                  top: pos.dy - dotRadius,
                  child: Container(
                    width: dotRadius * 2,
                    height: dotRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary.withOpacity(
                        0.2 + (intensity * 0.8),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
