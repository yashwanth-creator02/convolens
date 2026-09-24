import 'dart:math';
import 'package:flutter/material.dart';

class SocialScoreGauge extends StatelessWidget {
  final int score;
  final String label;

  const SocialScoreGauge({
    super.key,
    required this.score,
    required this.label,
  });

  Color _getScoreColor(BuildContext context, int val) {
    if (val >= 80) return const Color(0xFF10B981); // Emerald
    if (val >= 60) return const Color(0xFF06B6D4); // Cyan
    if (val >= 40) return const Color(0xFFF59E0B); // Amber
    if (val >= 20) return const Color(0xFFF97316); // Orange
    return const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    final targetColor = _getScoreColor(context, score);
    final clampedScore = score.clamp(0, 100);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: clampedScore.toDouble()),
      builder: (context, animatedValue, child) {
        return Center(
          child: SizedBox(
            width: 200,
            height: 175,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 175),
                  painter: _GaugeArcPainter(
                    progress: animatedValue / 100.0,
                    scoreColor: targetColor,
                    trackColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
                Positioned(
                  bottom: 18,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${animatedValue.round()}',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: targetColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: targetColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: targetColor.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: targetColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Social Health Meter',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GaugeArcPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color scoreColor;
  final Color trackColor;

  _GaugeArcPainter({
    required this.progress,
    required this.scoreColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 14.0;
    final center = Offset(size.width / 2, size.height * 0.58);
    final radius = (size.width - strokeWidth) / 2 - 10;

    // Start at 135 deg (3*pi/4), sweep 270 deg (3*pi/2)
    const startAngle = 3 * pi / 4;
    const totalSweep = 3 * pi / 2;

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    if (progress > 0) {
      final sweepAngle = totalSweep * progress.clamp(0.0, 1.0);

      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + totalSweep,
          colors: [
            scoreColor.withValues(alpha: 0.6),
            scoreColor,
          ],
          transform: GradientRotation(startAngle),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugeArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.scoreColor != scoreColor ||
        oldDelegate.trackColor != trackColor;
  }
}
