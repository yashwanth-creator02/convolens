import 'dart:math';
import 'package:flutter/material.dart';

class HourClockFace extends StatelessWidget {
  final Map<int, int> hourCounts;

  const HourClockFace({super.key, required this.hourCounts});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final counts = List.generate(24, (h) => hourCounts[h] ?? 0);
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxCount > 0 ? maxCount : 1;
    final peakHour = maxCount > 0 ? counts.indexOf(maxCount) : -1;

    String formatHour(int h) {
      if (h == 0) return '12 AM';
      if (h == 12) return '12 PM';
      if (h > 12) return '${h - 12} PM';
      return '$h AM';
    }

    return AspectRatio(
      aspectRatio: 1.15,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = min(constraints.maxWidth, constraints.maxHeight);
          final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
          final maxRadius = (size / 2) - 22;

          return Stack(
            alignment: Alignment.center,
            children: [
              // Circular background tracks
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _ClockDialPainter(
                  center: center,
                  maxRadius: maxRadius,
                  lineColor: scheme.outlineVariant.withValues(alpha: 0.25),
                ),
              ),

              // Center Peak Summary
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        size: 20,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (peakHour >= 0 && maxCount > 0) ...[
                      Text(
                        formatHour(peakHour),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Peak • $maxCount calls',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                    ] else
                      Text(
                        '24-Hour Cycle',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Clock Markings (0h, 3h, 6h, 9h, 12h, 15h, 18h, 21h)
              ...List.generate(8, (i) {
                final hour = i * 3;
                final angle = (2 * pi * hour / 24) - (pi / 2);
                final labelRadius = maxRadius + 12;
                final pos = center + Offset(labelRadius * cos(angle), labelRadius * sin(angle));

                return Positioned(
                  left: pos.dx - 14,
                  top: pos.dy - 8,
                  child: SizedBox(
                    width: 28,
                    height: 16,
                    child: Center(
                      child: Text(
                        '$hour:00',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // 24 Hour Activity Nodes
              ...List.generate(24, (hour) {
                final count = counts[hour];
                final angle = (2 * pi * hour / 24) - (pi / 2);
                final intensity = count / effectiveMax;
                final dotRadius = 3.5 + (intensity * 9.0);
                final distance = maxRadius * 0.76;

                final pos = center + Offset(distance * cos(angle), distance * sin(angle));
                final isPeak = hour == peakHour && count > 0;

                final nodeColor = isPeak
                    ? const Color(0xFFF59E0B)
                    : (hour >= 6 && hour < 18
                        ? scheme.primary
                        : const Color(0xFF8B5CF6));

                return Positioned(
                  left: pos.dx - dotRadius,
                  top: pos.dy - dotRadius,
                  child: Container(
                    width: dotRadius * 2,
                    height: dotRadius * 2,
                    decoration: BoxDecoration(
                      color: count > 0 ? nodeColor : nodeColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: count > 0
                          ? [
                              BoxShadow(
                                color: nodeColor.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
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

class _ClockDialPainter extends CustomPainter {
  final Offset center;
  final double maxRadius;
  final Color lineColor;

  _ClockDialPainter({
    required this.center,
    required this.maxRadius,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer and inner orbital circles
    canvas.drawCircle(center, maxRadius, trackPaint);
    canvas.drawCircle(center, maxRadius * 0.76, trackPaint..color = lineColor.withValues(alpha: 0.5));
    canvas.drawCircle(center, maxRadius * 0.45, trackPaint..color = lineColor.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(covariant _ClockDialPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.maxRadius != maxRadius ||
        oldDelegate.lineColor != lineColor;
  }
}
