import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class CallReminderSection extends StatelessWidget {
  final CallDetail? reminder;
  final VoidCallback onSet;
  final VoidCallback onClear;

  const CallReminderSection({
    super.key,
    required this.reminder,
    required this.onSet,
    required this.onClear,
  });

  String _formatReminderTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDay = DateTime(dt.year, dt.month, dt.day);

    final hour24 = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final timeStr = '$hour12:$minute $period';

    final difference = reminderDay.difference(today).inDays;
    if (difference == 0) return 'Today at $timeStr';
    if (difference == 1) return 'Tomorrow at $timeStr';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} at $timeStr';
  }

  String _relativeRemaining(DateTime dt) {
    final remaining = dt.difference(DateTime.now());
    if (remaining.isNegative) return 'Past due';
    if (remaining.inDays > 0) {
      final days = remaining.inDays;
      return 'in $days ${days == 1 ? 'day' : 'days'}';
    }
    if (remaining.inHours > 0) {
      final hours = remaining.inHours;
      return 'in $hours ${hours == 1 ? 'hr' : 'hrs'}';
    }
    final mins = remaining.inMinutes;
    if (mins <= 1) return 'in 1 min';
    return 'in $mins mins';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reminderAt = reminder?.reminderAt;
    final hasReminder = reminderAt != null;

    if (hasReminder) {
      final dt = DateTime.fromMillisecondsSinceEpoch(reminderAt);
      final label = reminder?.reminderLabel?.trim();
      final hasLabel = label != null && label.isNotEmpty;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.alarm_on_rounded,
                size: 20,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasLabel)
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: scheme.onSurface,
                      ),
                    ),
                  Row(
                    children: [
                      Text(
                        _formatReminderTime(dt),
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                          fontWeight:
                              hasLabel ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _relativeRemaining(dt),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              tooltip: 'Clear Reminder',
              onPressed: onClear,
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onSet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.alarm_add_outlined,
              size: 20,
              color: scheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Schedule a follow-up reminder…',
                style: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 13.5,
                ),
              ),
            ),
            Icon(
              Icons.add_rounded,
              size: 18,
              color: scheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

