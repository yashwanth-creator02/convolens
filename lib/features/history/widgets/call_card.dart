import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import 'call_card_content.dart';

class CallCard extends StatelessWidget {
  final Call call;
  final AppDatabase db;
  final Contact? deviceContact;

  const CallCard({
    super.key,
    required this.call,
    required this.db,
    this.deviceContact,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Setting>(
      stream: db.watchSettings(),
      builder: (context, settingsSnapshot) {
        return StreamBuilder<CallDetail?>(
          stream: db.watchDetailsForCall(call.id),
          builder: (context, detailSnapshot) {
            return StreamBuilder<List<Tag>>(
              stream: db.watchTagsForCall(call.id),
              builder: (context, tagsSnapshot) {
                return StreamBuilder<int>(
                  stream: db.watchAttachmentCountForCall(call.id),
                  builder: (context, attachmentSnapshot) {
                    return CallCardContent(
                      call: call,
                      db: db,
                      settings: settingsSnapshot.data,
                      detail: detailSnapshot.data,
                      tags: tagsSnapshot.data ?? const [],
                      attachmentCount: attachmentSnapshot.data ?? 0,
                      deviceContact: deviceContact,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
