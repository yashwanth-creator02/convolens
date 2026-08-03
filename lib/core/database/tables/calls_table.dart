import 'package:drift/drift.dart';

class Calls extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get number => text().nullable()();
  TextColumn get name => text().nullable()();
  IntColumn get type => integer()();
  IntColumn get duration => integer()();
  IntColumn get timestamp => integer()();

  BoolColumn get removedFromDevice =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {number, timestamp, duration, type},
  ];
}
