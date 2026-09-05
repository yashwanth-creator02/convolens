import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../utils/call_type_label.dart';
import '../../utils/format_call_time.dart';
import 'call_detail_row.dart';

class CallInfoSection extends StatelessWidget {
  final Call call;
  final AppDatabase db;

  const CallInfoSection({super.key, required this.call, required this.db});

  @override
  Widget build(BuildContext context) {
    final displayName = call.name?.trim().isNotEmpty == true
        ? call.name!.trim()
        : (call.number?.trim().isNotEmpty == true
              ? call.number!.trim()
              : 'Unknown');

    final phoneNumber = call.number?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),

        if (phoneNumber?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(phoneNumber!, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],

        const SizedBox(height: 16),

        CallDetailRow(label: 'Type', value: callTypeLabel(call.type)),

        CallDetailRow(label: 'Duration', value: '${call.duration} seconds'),

        CallDetailRow(label: 'Time', value: formatCallTime(call.timestamp)),
      ],
    );
  }
}
