import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Wraps [child] so it fades, sinks slightly, and stops accepting taps as a
/// new route is pushed on top of the current one.
class RouteRevealFade extends StatelessWidget {
  const RouteRevealFade({
    super.key,
    required this.child,
    this.fadeSpeedup = 1.4,
    this.sinkPixels = 12,
  });

  final Widget child;

  /// >1 makes the fade finish before the incoming route fully covers the screen.
  final double fadeSpeedup;

  /// How far the widget drifts downward as it fades, in logical pixels.
  final double sinkPixels;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.secondaryAnimation;
    if (animation == null) return child;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(
          clampDouble(animation.value, 0.0, 1.0),
        );
        final opacity = clampDouble(1 - t * fadeSpeedup, 0.0, 1.0);
        return IgnorePointer(
          ignoring: opacity < 0.4,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, t * sinkPixels),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
