import 'package:drift/drift.dart';

class ProfileMeta extends Table {
  IntColumn get id => integer()();

  TextColumn get photoPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
