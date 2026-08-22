import 'package:drift/drift.dart';

class ContactLinks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get normalizedNumber => text()();

  TextColumn get platform => text()();

  TextColumn get url => text()();
}
