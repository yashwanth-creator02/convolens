import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Clips to only the top half of an ellipse: a flat bottom edge and a full
/// dome-shaped top.
class TopDomeClipper extends CustomClipper<Path> {
  const TopDomeClipper();

  @override
  Path getClip(Size size) {
    final ellipseBounds = Rect.fromLTWH(0, 0, size.width, size.height * 2);

    return Path()
      ..addArc(ellipseBounds, math.pi, math.pi)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// A "Share Contact" pull tab: dome-shaped and flush against the bottom.
class DomeGlassButton extends StatelessWidget {
  const DomeGlassButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
    this.width = 440,
    this.domeHeight = 64,
    this.liftPixels = 0,
  });

  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final double width;
  final double domeHeight;
  final double liftPixels;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final foregroundColor = colorScheme.onSurface;
    final glassColor = colorScheme.surface.withValues(alpha: 0.18);

    return Transform.translate(
      offset: Offset(0, -liftPixels),
      child: SizedBox(
        width: width,
        height: domeHeight,
        child: ClipPath(
          clipper: const TopDomeClipper(),
          child: GlassContainer(
            useOwnLayer: true,
            quality: GlassQuality.standard,
            settings: LiquidGlassSettings(glassColor: glassColor),
            shape: LiquidRoundedRectangle(borderRadius: domeHeight / 2),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.only(bottom: domeHeight * 0.22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconTheme(
                        data: IconThemeData(color: foregroundColor, size: 20),
                        child: icon,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: foregroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
