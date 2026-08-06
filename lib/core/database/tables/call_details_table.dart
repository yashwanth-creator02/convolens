import 'package:drift/drift.dart';

import 'calls_table.dart';

class CallDetails extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get callId =>
      integer().references(Calls, #id, onDelete: KeyAction.cascade)();

  TextColumn get note => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {callId},
  ];
}
