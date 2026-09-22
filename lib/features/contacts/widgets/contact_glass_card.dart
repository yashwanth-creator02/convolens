import 'package:flutter/material.dart';

class ContactGlassCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  const ContactGlassCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.iconColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? scheme.primary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
