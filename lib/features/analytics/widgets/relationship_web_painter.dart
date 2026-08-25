import 'package:flutter/material.dart';

class RelationshipWebPainter extends CustomPainter {
  final Offset center;
  final List<Offset> nodePositions;
  final List<double> strengths;
  final Color lineColor;

  RelationshipWebPainter({
    required this.center,
    required this.nodePositions,
    required this.strengths,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < nodePositions.length; i++) {
      final strength = strengths[i].clamp(0.1, 1.0);
      final paint = Paint()
        ..color = lineColor.withOpacity(0.2 + (strength * 0.6))
        ..strokeWidth = 1.5 + (strength * 5)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(center, nodePositions[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant RelationshipWebPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions ||
        oldDelegate.strengths != strengths;
  }
}