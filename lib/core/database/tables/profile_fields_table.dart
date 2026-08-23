import 'package:drift/drift.dart';

class ProfileFieldEntries extends Table {
  TextColumn get key => text()();

  TextColumn get value => text().nullable()();

  BoolColumn get shared => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {key};
}
