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

  @override
  Widget build(BuildContext context) {
    final reminderAt = reminder?.reminderAt;
    final hasReminder = reminderAt != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reminder',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (!hasReminder)
              TextButton.icon(
                onPressed: onSet,
                icon: const Icon(Icons.alarm_add, size: 18),
                label: const Text('Set'),
              ),
          ],
        ),

        const SizedBox(height: 8),

        if (hasReminder)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.alarm, size: 18, color: Colors.orange),

                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reminder?.reminderLabel?.isNotEmpty == true)
                        Text(
                          reminder!.reminderLabel!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                      Text(
                        DateTime.fromMillisecondsSinceEpoch(
                          reminderAt,
                        ).toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
