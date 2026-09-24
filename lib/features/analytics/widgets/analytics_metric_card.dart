import 'package:flutter/material.dart';

import 'analytics_card.dart';

class AnalyticsMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final String? infoDescription;
  final VoidCallback? onTap;

  const AnalyticsMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradientColors,
    this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.infoDescription,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primaryGradient = gradientColors.first;

    final content = Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGradient.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGradient.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (badgeText != null && badgeText!.isNotEmpty)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? primaryGradient)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: badgeColor ?? primaryGradient,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    if (infoDescription != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => showAnalyticsInfoSheet(
                          context,
                          title: label,
                          description: infoDescription!,
                          icon: icon,
                          accentColor: primaryGradient,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            color: primaryGradient.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: primaryGradient,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    } else if (infoDescription != null) {
      return GestureDetector(
        onTap: () => showAnalyticsInfoSheet(
          context,
          title: label,
          description: infoDescription!,
          icon: icon,
          accentColor: primaryGradient,
        ),
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
