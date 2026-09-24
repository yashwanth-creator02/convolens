import 'package:flutter/material.dart';

/// Wraps any profile avatar widget with a golden gradient ring and a star badge
/// at the bottom-right corner when [isFavorite] is true, matching the style in [FavoritesCarousel].
class FavoriteAvatarRing extends StatelessWidget {
  final Widget child;
  final bool isFavorite;
  final ColorScheme scheme;
  final double ringPadding;
  final double starSize;
  final Offset starOffset;

  const FavoriteAvatarRing({
    super.key,
    required this.child,
    required this.isFavorite,
    required this.scheme,
    this.ringPadding = 2.0,
    this.starSize = 9.0,
    this.starOffset = const Offset(-1, -1),
  });

  @override
  Widget build(BuildContext context) {
    if (!isFavorite) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.all(ringPadding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade400,
                Colors.amber.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.28),
                blurRadius: 6,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: child,
        ),
        Positioned(
          right: starOffset.dx,
          bottom: starOffset.dy,
          child: Container(
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.surface,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.star_rounded,
              size: starSize,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
