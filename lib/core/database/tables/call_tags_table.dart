import 'package:drift/drift.dart';

import 'calls_table.dart';
import 'tags_table.dart';

class CallTags extends Table {
  IntColumn get callId =>
      integer().references(Calls, #id, onDelete: KeyAction.cascade)();

  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {callId, tagId};
}