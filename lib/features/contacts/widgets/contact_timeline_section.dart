import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../history/utils/call_type_label.dart';

class ContactTimelineSection extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;

  const ContactTimelineSection({
    super.key,
    required this.normalizedNumber,
    required this.db,
  });

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final month = _months[date.month - 1];
    final day = date.day;
    final year = date.year;
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year • $hour:$minute $period';
  }

  Color _getColor(int type, ColorScheme scheme) {
    switch (type) {
      case 1:
        return scheme.tertiary; // Incoming
      case 2:
        return scheme.primary; // Outgoing
      case 3:
        return scheme.error; // Missed
      default:
        return scheme.onSurfaceVariant;
    }
  }

  IconData _getIcon(int type) {
    switch (type) {
      case 1:
        return Icons.call_received_rounded;
      case 2:
        return Icons.call_made_rounded;
      case 3:
        return Icons.call_missed_rounded;
      default:
        return Icons.call_rounded;
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<List<Call>>(
      stream: db.watchCallsForNumber(normalizedNumber),
      builder: (context, snapshot) {
        final calls = snapshot.data ?? [];
        if (calls.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timeline_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No timeline history yet',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calls with this contact will appear here in order',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        // watchCallsForNumber returns newest-first; timeline reads oldest-to-newest.
        final chronological = calls.reversed.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(chronological.length, (index) {
            final call = chronological[index];
            final isLast = index == chronological.length - 1;
            final callColor = _getColor(call.type, scheme);
            final callIcon = _getIcon(call.type);

            String? gapLabel;
            double gapHeight = 12;

            if (index > 0) {
              final previous = chronological[index - 1];
              final gapDays =
                  (call.timestamp - previous.timestamp) ~/
                  (1000 * 60 * 60 * 24);

              if (gapDays >= 1) {
                gapLabel = gapDays == 1 ? '1 day later' : '$gapDays days later';
                gapHeight = (12 + (gapDays * 2)).clamp(12, 60).toDouble();
              }
            }

            final formattedDate = _formatDateTime(call.timestamp);
            final isMissed = call.type == 3;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (gapLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 2,
                          height: gapHeight,
                          child: ColoredBox(
                            color: scheme.outlineVariant.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  scheme.outlineVariant.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            gapLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: callColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: callColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              callIcon,
                              size: 13,
                              color: callColor,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color:
                                    scheme.outlineVariant.withValues(alpha: 0.35),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.22),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      callTypeLabel(call.type),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: callColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!isMissed) ...[
                                      Text(
                                        _formatDuration(call.duration),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ] else ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: scheme.error
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Missed',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: scheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}
