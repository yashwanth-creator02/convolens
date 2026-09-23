import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'settings_glass_tile.dart';

/// A sleek liquid glass card container designed for the Settings screen,
/// with standard glass, a clean uppercase section header, and optional info tooltip.
class SettingsGlassCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final Widget child;
  final String? infoTooltip;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const SettingsGlassCard({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.trailing,
    required this.child,
    this.infoTooltip,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primaryColor = iconColor ?? scheme.primary;

    return Padding(
      padding: margin ?? const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Header displayed above the card
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, right: 4),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 14,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (infoTooltip != null && infoTooltip!.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        SettingsInfoTooltipButton(message: infoTooltip!),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          // Standard Glass Card Container
          GlassContainer(
            quality: GlassQuality.standard,
            useOwnLayer: false,
            shape: const LiquidRoundedSuperellipse(borderRadius: 20),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: child,
          ),
        ],
      ),
    );
  }
}
