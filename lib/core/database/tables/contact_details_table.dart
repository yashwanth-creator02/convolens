import 'package:drift/drift.dart';

class ContactDetails extends Table {
  TextColumn get normalizedNumber => text()();

  TextColumn get generalNote => text().nullable()();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  IntColumn get colorValue => integer().nullable()();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  BoolColumn get ignoreFromAnalytics =>
      boolean().withDefault(const Constant(false))();

  TextColumn get preferredMethod => text().nullable()();

  TextColumn get bestTimeToCall => text().nullable()();

  @override
  Set<Column> get primaryKey => {normalizedNumber};
}
