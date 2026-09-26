import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import 'call_card_content.dart';

class CallCard extends StatelessWidget {
  final Call call;
  final AppDatabase db;
  final Contact? deviceContact;
  final Setting? settings;
  final CallDetail? detail;
  final List<Tag>? tags;
  final int? attachmentCount;
  final bool? hasRecording;
  final bool hasBatchMetadata;
  final bool showCallButton;
  final bool showPhoneNumber;
  final bool showName;
  final bool enableSwipeToCall;

  const CallCard({
    super.key,
    required this.call,
    required this.db,
    this.deviceContact,
    this.settings,
    this.detail,
    this.tags,
    this.attachmentCount,
    this.hasRecording,
    this.hasBatchMetadata = false,
    this.showCallButton = true,
    this.showPhoneNumber = true,
    this.showName = true,
    this.enableSwipeToCall = true,
  });

  @override
  Widget build(BuildContext context) {
    // If metadata is already provided (e.g. from parent batch stream), render
    // directly with zero StreamBuilders!
    if (hasBatchMetadata ||
        detail != null ||
        tags != null ||
        attachmentCount != null) {
      return RepaintBoundary(
        child: CallCardContent(
          call: call,
          db: db,
          settings: settings,
          detail: detail,
          tags: tags ?? const [],
          attachmentCount: attachmentCount ?? 0,
          hasRecording: hasRecording ?? false,
          deviceContact: deviceContact,
          showCallButton: showCallButton,
          showPhoneNumber: showPhoneNumber,
          showName: showName,
          enableSwipeToCall: enableSwipeToCall,
        ),
      );
    }

    final Widget cardContent = settings != null
        ? _buildContentWithSettings(settings)
        : StreamBuilder<Setting>(
            stream: db.watchSettings(),
            builder: (context, settingsSnapshot) {
              return _buildContentWithSettings(settingsSnapshot.data);
            },
          );

    return RepaintBoundary(child: cardContent);
  }

  Widget _buildContentWithSettings(Setting? settingsData) {
    return StreamBuilder<CallDetail?>(
      stream: db.watchDetailsForCall(call.id),
      builder: (context, detailSnapshot) {
        return StreamBuilder<List<Tag>>(
          stream: db.watchTagsForCall(call.id),
          builder: (context, tagsSnapshot) {
            return StreamBuilder<int>(
              stream: db.watchAttachmentCountForCall(call.id),
              builder: (context, attachmentSnapshot) {
                // Stream to check if a call_recording attachment exists
                return StreamBuilder<List<CallAttachment>>(
                  stream: db.watchAttachmentsForCall(call.id),
                  builder: (context, recordingSnapshot) {
                    final hasRec = (recordingSnapshot.data ?? const [])
                        .any((a) => a.fileType == 'call_recording');
                    return CallCardContent(
                      call: call,
                      db: db,
                      settings: settingsData,
                      detail: detailSnapshot.data,
                      tags: tagsSnapshot.data ?? const [],
                      attachmentCount: attachmentSnapshot.data ?? 0,
                      hasRecording: hasRec,
                      deviceContact: deviceContact,
                      showCallButton: showCallButton,
                      showPhoneNumber: showPhoneNumber,
                      showName: showName,
                      enableSwipeToCall: enableSwipeToCall,
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
