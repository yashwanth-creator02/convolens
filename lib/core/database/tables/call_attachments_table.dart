import 'package:drift/drift.dart';

import 'calls_table.dart';

class CallAttachments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get callId =>
      integer().references(Calls, #id, onDelete: KeyAction.cascade)();

  TextColumn get filePath => text()();

  TextColumn get originalFileName => text()();

  TextColumn get fileType => text()();

  IntColumn get addedAt => integer()();
}
