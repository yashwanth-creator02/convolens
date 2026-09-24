import 'package:flutter/material.dart';

enum ContactFilterMode {
  all,
  archived,
}

class ContactsFilterChips extends StatelessWidget {
  final ContactFilterMode currentMode;
  final ValueChanged<ContactFilterMode> onModeChanged;
  final int allCount;
  final int archivedCount;

  const ContactsFilterChips({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.allCount,
    required this.archivedCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final filters = [
      (
        mode: ContactFilterMode.all,
        label: 'All Contacts',
        count: allCount,
        icon: Icons.people_outline_rounded,
      ),
      (
        mode: ContactFilterMode.archived,
        label: 'Archived',
        count: archivedCount,
        icon: Icons.archive_outlined,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((item) {
          final isSelected = currentMode == item.mode;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onModeChanged(item.mode),
              borderRadius: BorderRadius.circular(19),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primary
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: isSelected
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 14,
                      color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? scheme.onPrimary : scheme.onSurface,
                      ),
                    ),
                    if (item.count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.onPrimary.withValues(alpha: 0.22)
                              : scheme.outlineVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.count}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
