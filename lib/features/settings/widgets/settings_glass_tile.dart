import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// An interactive liquid glass setting tile for navigation or actions.
class SettingsGlassTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
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
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.showChevron = true,
    this.padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: scheme.onSurface,
                      ),
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
    required this.value,
    this.onChanged,
    this.iconColor,
    this.iconBackgroundColor,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: scheme.onSurface,
                      ),
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
                useOwnLayer: true,
                activeColor: scheme.primary,
                width: 52.0,
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
    final scheme = Theme.of(context).colorScheme;
    final badgeColor = color ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: badgeColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// A subtle divider between settings rows within a [SettingsGlassCard].
class SettingsGlassDivider extends StatelessWidget {
  final double indent;
  final double endIndent;

  const SettingsGlassDivider({
    super.key,
    this.indent = 52,
    this.endIndent = 4,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: indent,
      endIndent: endIndent,
      color: scheme.outlineVariant.withValues(alpha: 0.2),
    );
  }
}
