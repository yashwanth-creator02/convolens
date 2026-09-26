import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

class ContactPhotoBanner extends StatelessWidget {
  final Uint8List? photo;
  final String initials;
  final Color bannerColor;
  final double height;
  final bool showAmbientBlur;
  final Widget? overlay;

  const ContactPhotoBanner({
    super.key,
    required this.photo,
    required this.initials,
    required this.bannerColor,
    required this.height,
    this.showAmbientBlur = true,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasValidPhoto = photo != null && photo!.isNotEmpty;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Photo layer or fallback gradient ──
          if (hasValidPhoto) ...[
            if (showAmbientBlur) ...[
              // Ambient blurred background filling the banner
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Image.memory(
                  photo!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildGradientFallback(scheme),
                ),
              ),
              // Subtle darkening so the uncropped picture pops
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            ],
            // Uncropped sharp photo
            Center(
              child: Image.memory(
                photo!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) =>
                    _buildGradientFallback(scheme),
              ),
            ),
          ] else ...[
            _buildGradientFallback(scheme),
          ],

          // ── Premium scrim overlay for readability ──
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // ── Custom overlays (e.g. favorite chips, controls, titles) ──
          ?overlay,
        ],
      ),
    );
  }

  Widget _buildGradientFallback(ColorScheme scheme) {
    final cleanInitials = initials.trim();
    final displayInitials =
        cleanInitials.isNotEmpty && cleanInitials != '#' ? cleanInitials : '?';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bannerColor.withValues(alpha: 0.7),
            Color.lerp(bannerColor, scheme.surface, 0.5) ?? scheme.surface,
            scheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Text(
          displayInitials,
          style: TextStyle(
            fontSize: 76,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.13),
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}
