import 'dart:math' as math;

import 'package:flutter/material.dart';

class CosmoBackground extends StatefulWidget {
  const CosmoBackground({super.key, this.child});

  final Widget? child;

  @override
  State<CosmoBackground> createState() => _CosmoBackgroundState();
}

class _CosmoBackgroundState extends State<CosmoBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _CosmoBackgroundPainter(progress: _controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _CosmoBackgroundPainter extends CustomPainter {
  final double progress;

  _CosmoBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // -----------------------------------------------------------------------
    // Base space
    // -----------------------------------------------------------------------

    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF050816), Color(0xFF090B24), Color(0xFF100A2B)],
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    // -----------------------------------------------------------------------
    // Moving nebula clouds
    // -----------------------------------------------------------------------

    _drawNebula(
      canvas,
      size,
      progress: progress,
      basePosition: const Offset(0.18, 0.25),
      color: const Color(0xFF3155FF),
      radiusFactor: 0.42,
      phase: 0.0,
    );

    _drawNebula(
      canvas,
      size,
      progress: progress,
      basePosition: const Offset(0.78, 0.20),
      color: const Color(0xFF8A3FFC),
      radiusFactor: 0.38,
      phase: 1.8,
    );

    _drawNebula(
      canvas,
      size,
      progress: progress,
      basePosition: const Offset(0.65, 0.75),
      color: const Color(0xFFE23BFF),
      radiusFactor: 0.46,
      phase: 3.5,
    );

    _drawNebula(
      canvas,
      size,
      progress: progress,
      basePosition: const Offset(0.20, 0.82),
      color: const Color(0xFF00A8FF),
      radiusFactor: 0.36,
      phase: 5.0,
    );

    // -----------------------------------------------------------------------
    // Soft dark overlay
    // Keeps foreground content readable.
    // -----------------------------------------------------------------------

    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.18);

    canvas.drawRect(rect, overlayPaint);
  }

  void _drawNebula(
    Canvas canvas,
    Size size, {
    required double progress,
    required Offset basePosition,
    required Color color,
    required double radiusFactor,
    required double phase,
  }) {
    final angle = progress * math.pi * 2 + phase;

    final movementX = math.sin(angle) * size.width * 0.06;
    final movementY = math.cos(angle * 0.8) * size.height * 0.05;

    final center = Offset(
      size.width * basePosition.dx + movementX,
      size.height * basePosition.dy + movementY,
    );

    final radius = math.min(size.width, size.height) * radiusFactor;

    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.28),
        color.withValues(alpha: 0.13),
        color.withValues(alpha: 0.04),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.68, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CosmoBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
