import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../utils/call_type_label.dart';
import '../utils/format_call_time.dart';

class CallCard extends StatelessWidget {
  final Call call;

  const CallCard({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final displayName = call.name?.isNotEmpty == true
        ? call.name!
        : (call.number ?? 'Unknown');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (call.name != null &&
                call.name!.isNotEmpty &&
                call.number != null)
              Text(call.number!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              '${callTypeLabel(call.type)} • ${call.duration}s • ${formatCallTime(call.timestamp)}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
