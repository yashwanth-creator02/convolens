import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../screens/call_details_screen.dart';
import '../utils/call_type_label.dart';
import '../utils/format_call_time.dart';

class CallCard extends StatelessWidget {
  final Call call;
  final AppDatabase db;

  const CallCard({super.key, required this.call, required this.db});

  @override
  Widget build(BuildContext context) {
    final displayName = call.name?.isNotEmpty == true
        ? call.name!
        : (call.number ?? 'Unknown');

    return StreamBuilder<Setting>(
      stream: db.watchSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data;

        final showContactName = settings?.showContactName ?? true;
        final showPhoneNumber = settings?.showPhoneNumber ?? true;
        final showCallType = settings?.showCallType ?? true;
        final showDuration = settings?.showDuration ?? true;
        final showTime = settings?.showTime ?? true;

        final detailParts = <String>[
          if (showCallType) callTypeLabel(call.type),
          if (showDuration) '${call.duration}s',
          if (showTime) formatCallTime(call.timestamp),
        ];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CallDetailScreen(call: call, db: db),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showContactName)
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  if (showPhoneNumber &&
                      call.name != null &&
                      call.name!.isNotEmpty &&
                      call.number != null)
                    Text(
                      call.number!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  if (detailParts.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      detailParts.join(' • '),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
