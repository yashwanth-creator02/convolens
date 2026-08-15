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
        const Text(
          'Developer Info',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
        ),

        const SizedBox(height: 8),

        CallDetailRow(label: 'Row ID', value: call.id.toString()),

        CallDetailRow(label: 'Raw type code', value: call.type.toString()),

        CallDetailRow(
          label: 'Raw timestamp (epoch ms)',
          value: call.timestamp.toString(),
        ),

        CallDetailRow(
          label: 'Removed from device',
          value: call.removedFromDevice.toString(),
        ),
      ],
    );
  }
}
