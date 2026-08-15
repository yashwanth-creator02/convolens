import 'package:drift/drift.dart';

import 'tags_table.dart';

class ContactTags extends Table {
  TextColumn get normalizedNumber => text()();

  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {normalizedNumber, tagId};
}
