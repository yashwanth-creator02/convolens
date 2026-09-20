import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import 'call_detail_row.dart';

class CallDeveloperInfo extends StatelessWidget {
  final Call call;

  const CallDeveloperInfo({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CallDetailRow(
          icon: Icons.tag_rounded,
          label: 'Database ID',
          value: '#${call.id}',
        ),
        CallDetailRow(
          icon: Icons.code_rounded,
          label: 'Type Code',
          value: 'code ${call.type}',
        ),
        CallDetailRow(
          icon: Icons.access_time_rounded,
          label: 'Epoch (ms)',
          value: '${call.timestamp}',
        ),
        CallDetailRow(
          icon: Icons.sync_rounded,
          label: 'Device Status',
          value: call.removedFromDevice ? 'Removed from system' : 'Active in system',
          valueColor: call.removedFromDevice ? Colors.redAccent : Colors.greenAccent,
        ),
      ],
    );
  }
}

