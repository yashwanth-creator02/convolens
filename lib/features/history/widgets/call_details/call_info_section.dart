import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/toast/toast_service.dart';
import '../../utils/call_type_label.dart';
import '../../utils/format_call_time.dart';
import '../../utils/format_duration.dart';
import 'call_detail_row.dart';

class CallInfoSection extends StatelessWidget {
  final Call call;
  final AppDatabase db;

  const CallInfoSection({super.key, required this.call, required this.db});

  String _formatFullDate(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
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
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _getCallTypeColor(int type, ColorScheme scheme) {
    switch (type) {
      case 3: // Missed
      case 5: // Rejected
      case 6: // Blocked
        return scheme.error;
      case 1: // Incoming
        return scheme.tertiary;
      case 2: // Outgoing
        return scheme.primary;
      default:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phoneNumber = call.number?.trim() ?? '';
    final typeColor = _getCallTypeColor(call.type, scheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CallDetailRow(
          icon: callTypeIcon(call.type),
          label: 'Direction',
          value: callTypeLabel(call.type),
          valueColor: typeColor,
        ),
        CallDetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Date',
          value: _formatFullDate(call.timestamp),
        ),
        CallDetailRow(
          icon: Icons.schedule_outlined,
          label: 'Time',
          value: formatCallTime(call.timestamp),
        ),
        CallDetailRow(
          icon: Icons.timer_outlined,
          label: 'Duration',
          value: call.duration > 0
              ? '${formatDuration(call.duration)} (${call.duration}s)'
              : '0 seconds',
        ),
        if (phoneNumber.isNotEmpty)
          CallDetailRow(
            icon: Icons.phone_outlined,
            label: 'Number',
            value: phoneNumber,
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              tooltip: 'Copy Number',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phoneNumber));
                ToastService.info(context, 'Number copied to clipboard');
              },
            ),
          ),
      ],
    );
  }
}

