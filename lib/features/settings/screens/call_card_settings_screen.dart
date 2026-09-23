import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../widgets/settings_glass_card.dart';
import '../widgets/settings_glass_tile.dart';

class CallCardSettingsScreen extends StatefulWidget {
  final AppDatabase db;

  const CallCardSettingsScreen({super.key, required this.db});

  @override
  State<CallCardSettingsScreen> createState() => _CallCardSettingsScreenState();
}

class _CallCardSettingsScreenState extends State<CallCardSettingsScreen> {
  final _titleController = GlassLargeTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Call Card Display'),
        largeTitleController: _titleController,
      ),
      body: StreamBuilder<Setting>(
        stream: widget.db.watchSettings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data!;

          Widget switchTile(
            IconData icon,
            String title,
            String description,
            bool value,
            SettingsCompanion Function(bool) buildCompanion,
          ) {
            return SettingsGlassSwitchTile(
              icon: icon,
              title: title,
              infoTooltip: description,
              value: value,
              onChanged: (v) => widget.db.updateSetting(buildCompanion(v)),
            );
          }

          return Material(
            type: MaterialType.transparency,
            child: CustomScrollView(
              controller: _titleController.scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                ),
                GlassLargeTitle(
                  text: 'Call Card Display',
                  controller: _titleController,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── 1. Core Fields ──────────────────────────────────
                      SettingsGlassCard(
                        title: 'Core Information',
                        icon: Icons.badge_outlined,
                        child: Column(
                          children: [
                            switchTile(
                              Icons.person_outline_rounded,
                              'Contact Name',
                              'Display contact or caller name prominently',
                              settings.showContactName,
                              (v) =>
                                  SettingsCompanion(showContactName: Value(v)),
                            ),
                            const SettingsGlassDivider(),
                            switchTile(
                              Icons.phone_outlined,
                              'Phone Number',
                              'Show the caller or recipient phone number',
                              settings.showPhoneNumber,
                              (v) =>
                                  SettingsCompanion(showPhoneNumber: Value(v)),
                            ),
                            const SettingsGlassDivider(),
                            switchTile(
                              Icons.call_made_rounded,
                              'Call Type',
                              'Indicate incoming, outgoing, or missed status',
                              settings.showCallType,
                              (v) => SettingsCompanion(showCallType: Value(v)),
                            ),
                            const SettingsGlassDivider(),
                            switchTile(
                              Icons.timer_outlined,
                              'Duration',
                              'Show the elapsed duration of connected calls',
                              settings.showDuration,
                              (v) => SettingsCompanion(showDuration: Value(v)),
                            ),
                            const SettingsGlassDivider(),
                            switchTile(
                              Icons.calendar_today_outlined,
                              'Date',
                              'Display call date and calendar grouping',
                              settings.showDate,
                              (v) => SettingsCompanion(showDate: Value(v)),
                            ),
                            const SettingsGlassDivider(),
                            switchTile(
                              Icons.schedule_rounded,
                              'Time',
                              'Display exact timestamp for each call',
                              settings.showTime,
                              (v) => SettingsCompanion(showTime: Value(v)),
                            ),
                          ],
                        ),
                      ),

                      // ── 2. Enrichment & Context ─────────────────────────
                      SettingsGlassCard(
                        title: 'Enrichment & Context',
                        icon: Icons.auto_awesome_outlined,
                        child: Column(
                          children: [
                            switchTile(
                              Icons.notes_rounded,
                              'Note Preview',
                              'Show excerpt of custom notes on the call card',
                              settings.showNotePreview,
                              (v) =>
                                  SettingsCompanion(showNotePreview: Value(v)),
                            ),
                            const SettingsGlassDivider(),
                            switchTile(
                              Icons.local_offer_outlined,
                              'Tags',
                              'Render category and custom tag chips',
                              settings.showTags,
                              (v) => SettingsCompanion(showTags: Value(v)),
                            ),
                            const SettingsGlassDivider(),
                            switchTile(
                              Icons.alarm_rounded,
                              'Reminder Indicator',
                              'Display status badge when a reminder is active',
                              settings.showReminderIndicator,
                              (v) => SettingsCompanion(
                                  showReminderIndicator: Value(v)),
                            ),
                            const SettingsGlassDivider(),
                            switchTile(
                              Icons.attach_file_rounded,
                              'Attachment Count',
                              'Show number of attached files and recordings',
                              settings.showAttachmentCount,
                              (v) => SettingsCompanion(
                                  showAttachmentCount: Value(v)),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
