import 'package:flutter/material.dart';

/// Reveals [builder] by stretching down from the top edge of the
/// screen — the same visual whether triggered by a tap or a pull
/// gesture, so entry always feels continuous with what led to it.
class StretchRevealRoute<T> extends PageRouteBuilder<T> {
  StretchRevealRoute({required WidgetBuilder builder})
      : super(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) =>
        builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final stretch = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );

      final fade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      );

      return FadeTransition(
        opacity: fade,
        child: AnimatedBuilder(
          animation: stretch,
          child: child,
          builder: (context, child) {
            final t = stretch.value;
            return Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..translate(0.0, -40 * (1 - t))
                ..scale(1.0, 0.85 + 0.15 * t),
              child: child,
            );
          },
        ),
      );
    },
  );
}
