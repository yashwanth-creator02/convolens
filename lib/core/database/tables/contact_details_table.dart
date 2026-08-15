import 'package:drift/drift.dart';

class ContactDetails extends Table {
  TextColumn get normalizedNumber => text()();

  TextColumn get generalNote => text().nullable()();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {normalizedNumber};
}
