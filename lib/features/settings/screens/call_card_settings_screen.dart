import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

class CallCardSettingsScreen extends StatelessWidget {
  final AppDatabase db;

  const CallCardSettingsScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Card Display')),
      body: StreamBuilder<Setting>(
        stream: db.watchSettings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data!;

          Widget toggle(
            String title,
            bool value,
            SettingsCompanion Function(bool) build,
          ) {
            return SwitchListTile(
              title: Text(title),
              value: value,
              onChanged: (v) => db.updateSetting(build(v)),
            );
          }

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Core Fields',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              toggle(
                'Show Contact Name',
                settings.showContactName,
                (v) => SettingsCompanion(showContactName: Value(v)),
              ),
              toggle(
                'Show Phone Number',
                settings.showPhoneNumber,
                (v) => SettingsCompanion(showPhoneNumber: Value(v)),
              ),
              toggle(
                'Show Call Type',
                settings.showCallType,
                (v) => SettingsCompanion(showCallType: Value(v)),
              ),
              toggle(
                'Show Duration',
                settings.showDuration,
                (v) => SettingsCompanion(showDuration: Value(v)),
              ),
              toggle(
                'Show Date',
                settings.showDate,
                (v) => SettingsCompanion(showDate: Value(v)),
              ),
              toggle(
                'Show Time',
                settings.showTime,
                (v) => SettingsCompanion(showTime: Value(v)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(
                  'Enrichment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              toggle(
                'Show Note Preview',
                settings.showNotePreview,
                (v) => SettingsCompanion(showNotePreview: Value(v)),
              ),
              toggle(
                'Show Tags',
                settings.showTags,
                (v) => SettingsCompanion(showTags: Value(v)),
              ),
              toggle(
                'Show Reminder Indicator',
                settings.showReminderIndicator,
                (v) => SettingsCompanion(showReminderIndicator: Value(v)),
              ),
              toggle(
                'Show Attachment Count',
                settings.showAttachmentCount,
                (v) => SettingsCompanion(showAttachmentCount: Value(v)),
              ),
            ],
          );
        },
      ),
    );
  }
}
