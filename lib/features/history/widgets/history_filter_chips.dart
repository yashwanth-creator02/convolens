import 'package:flutter/material.dart';

enum HistoryFilterType {
  all('All', Icons.all_inclusive_rounded),
  missed('Missed', Icons.phone_missed_rounded),
  incoming('Incoming', Icons.phone_callback_rounded),
  outgoing('Outgoing', Icons.phone_forwarded_rounded),
  unknown('Unknown', Icons.help_outline_rounded);

  final String label;
  final IconData icon;
  const HistoryFilterType(this.label, this.icon);
}

class HistoryFilterChips extends StatelessWidget {
  final HistoryFilterType currentFilter;
  final ValueChanged<HistoryFilterType> onFilterChanged;
  final Map<HistoryFilterType, int>? counts;

  const HistoryFilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: HistoryFilterType.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = HistoryFilterType.values[index];
          final isSelected = currentFilter == filter;
          final count = counts?[filter];

          return InkWell(
            onTap: () => onFilterChanged(filter),
            borderRadius: BorderRadius.circular(19),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    filter.icon,
                    size: 14,
                    color: isSelected
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                  if (count != null && count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? scheme.onPrimary.withValues(alpha: 0.22)
                            : scheme.outlineVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
