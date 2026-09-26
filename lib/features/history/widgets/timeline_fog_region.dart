import 'dart:ui';
import 'package:flutter/material.dart';

/// An independent atmospheric visual fog region placed in the deep background.
///
/// Completely decoupled from scroll activation or drag state logic.
class TimelineFogRegion extends StatelessWidget {
  final double width;
  final BorderRadius? borderRadius;
  final bool visible;

  const TimelineFogRegion({
    super.key,
    this.width = 88.0,
    this.borderRadius,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mistBase = isDark ? const Color(0xFF94A3B8) : Colors.white;

    final radius = borderRadius ??
        const BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      opacity: visible ? 1.0 : 0.0,
      child: ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.35, 0.70, 1.0],
              colors: isDark
                  ? [
                      mistBase.withValues(alpha: 0.0),
                      mistBase.withValues(alpha: 0.02),
                      mistBase.withValues(alpha: 0.06),
                      mistBase.withValues(alpha: 0.12),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.04),
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.22),
                    ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
