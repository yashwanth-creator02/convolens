import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// A subtle, elegant info button that displays a hover / tap tooltip
/// containing the description for a setting.
class SettingsInfoTooltipButton extends StatelessWidget {
  final String message;

  const SettingsInfoTooltipButton({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      verticalOffset: 12,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      textStyle: TextStyle(
        fontSize: 12,
        height: 1.35,
        color: scheme.onSurface,
        fontWeight: FontWeight.w400,
      ),
      child: InkResponse(
        radius: 14,
        onTap: () {
          HapticFeedback.selectionClick();
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

/// An interactive liquid glass setting tile for navigation or actions.
class SettingsGlassTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? infoTooltip;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool showChevron;
  final EdgeInsetsGeometry padding;

  const SettingsGlassTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.infoTooltip,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.showChevron = true,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primaryColor = iconColor ?? scheme.primary;
    final bgColor = iconBackgroundColor ?? primaryColor.withValues(alpha: 0.12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (infoTooltip != null && infoTooltip!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          SettingsInfoTooltipButton(message: infoTooltip!),
                        ],
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
              if (showChevron && onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An interactive liquid glass setting tile with an integrated toggle switch.
class SettingsGlassSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? infoTooltip;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final EdgeInsetsGeometry padding;

  const SettingsGlassSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.infoTooltip,
    required this.value,
    this.onChanged,
    this.iconColor,
    this.iconBackgroundColor,
    this.padding = const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primaryColor = iconColor ?? (value ? scheme.primary : scheme.onSurfaceVariant);
    final bgColor = iconBackgroundColor ?? primaryColor.withValues(alpha: value ? 0.14 : 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged != null
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (infoTooltip != null && infoTooltip!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          SettingsInfoTooltipButton(message: infoTooltip!),
                        ],
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GlassSwitch(
                value: value,
                onChanged: onChanged != null ? onChanged! : (_) {},
                useOwnLayer: false,
                quality: GlassQuality.standard,
                activeColor: scheme.primary,
                width: 50.0,
                height: 28.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A subtle, elegant glass pill badge for showing status (e.g., active theme name).
class SettingsGlassPillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const SettingsGlassPillBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primaryColor = color ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: primaryColor,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A sleek liquid glass hairline divider for separating setting rows.
class SettingsGlassDivider extends StatelessWidget {
  final double indent;
  final double endIndent;

  const SettingsGlassDivider({
    super.key,
    this.indent = 52.0,
    this.endIndent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: Divider(
        height: 1,
        thickness: 0.6,
        color: scheme.outlineVariant.withValues(alpha: 0.25),
      ),
    );
  }
}
