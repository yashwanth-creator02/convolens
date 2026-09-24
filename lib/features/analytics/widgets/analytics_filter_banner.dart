import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/analytics_filters.dart';

class AnalyticsFilterBanner extends StatelessWidget {
  final AnalyticsFilters filters;
  final String? contactName;
  final String? tagName;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearDateRange;
  final VoidCallback onClearContact;
  final VoidCallback onClearTag;
  final VoidCallback onClearCallType;
  final VoidCallback onResetAll;

  const AnalyticsFilterBanner({
    super.key,
    required this.filters,
    this.contactName,
    this.tagName,
    required this.onOpenFilters,
    required this.onClearDateRange,
    required this.onClearContact,
    required this.onClearTag,
    required this.onClearCallType,
    required this.onResetAll,
  });

  String _dateRangeLabel(DateRangeOption option) {
    switch (option) {
      case DateRangeOption.last7:
        return 'Last 7 Days';
      case DateRangeOption.last30:
        return 'Last 30 Days';
      case DateRangeOption.last6Months:
        return 'Last 6 Months';
      case DateRangeOption.lastYear:
        return 'Last Year';
      case DateRangeOption.custom:
        return 'Custom Dates';
    }
  }

  String _callTypeLabel(CallTypeFilter type) {
    switch (type) {
      case CallTypeFilter.all:
        return 'All Calls';
      case CallTypeFilter.incoming:
        return 'Incoming Only';
      case CallTypeFilter.outgoing:
        return 'Outgoing Only';
      case CallTypeFilter.missed:
        return 'Missed Only';
      case CallTypeFilter.declined:
        return 'Declined Only';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final hasCustomDate = filters.dateRange != DateRangeOption.last30;
    final hasContact = filters.contactNormalizedNumber != null;
    final hasTag = filters.tagId != null;
    final hasCallType = filters.callType != CallTypeFilter.all;

    final hasAnyFilter = hasCustomDate || hasContact || hasTag || hasCallType;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Filter trigger pill
            GestureDetector(
              onTap: onOpenFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hasAnyFilter
                      ? scheme.primary.withValues(alpha: 0.15)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasAnyFilter
                        ? scheme.primary.withValues(alpha: 0.4)
                        : scheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 13,
                      color: hasAnyFilter ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _dateRangeLabel(filters.dateRange),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: hasAnyFilter ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (hasContact) ...[
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                icon: Icons.person_rounded,
                label: contactName ?? '1 Contact',
                onRemove: onClearContact,
              ),
            ],

            if (hasTag) ...[
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                icon: Icons.label_rounded,
                label: tagName ?? 'Tag',
                onRemove: onClearTag,
              ),
            ],

            if (hasCallType) ...[
              const SizedBox(width: 8),
              _buildFilterChip(
                context,
                icon: Icons.call_rounded,
                label: _callTypeLabel(filters.callType),
                onRemove: onClearCallType,
              ),
            ],

            if (hasAnyFilter) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onResetAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 12, color: scheme.error),
                      const SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onRemove,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 5, 5),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 10, color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
