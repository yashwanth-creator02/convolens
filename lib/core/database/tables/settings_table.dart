import 'package:drift/drift.dart';

class Settings extends Table {
  IntColumn get id => integer()();

  BoolColumn get syncEnabled => boolean().withDefault(const Constant(true))();

  BoolColumn get archiveMode => boolean().withDefault(const Constant(true))();

  BoolColumn get devMode => boolean().withDefault(const Constant(false))();

  TextColumn get theme => text().withDefault(const Constant('dark'))();

  BoolColumn get showContactName =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get showPhoneNumber =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get showCallType => boolean().withDefault(const Constant(true))();

  BoolColumn get showDuration => boolean().withDefault(const Constant(true))();

  BoolColumn get showDate => boolean().withDefault(const Constant(true))();

  BoolColumn get showTime => boolean().withDefault(const Constant(true))();

  BoolColumn get showNotePreview =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get showTags => boolean().withDefault(const Constant(true))();

  BoolColumn get showReminderIndicator =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get showAttachmentCount =>
      boolean().withDefault(const Constant(true))();

  IntColumn get lastNotifiedStreak =>
      integer().withDefault(const Constant(0))();

  IntColumn get lastWeeklySummaryTimestamp => integer().nullable()();

  BoolColumn get streakNotifications =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get weeklySummaryNotifications =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get favoriteInactivityNotifications =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get missedCallAlerts =>
      boolean().withDefault(const Constant(true))();

  IntColumn get lastFavoriteInactivityTimestamp => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
