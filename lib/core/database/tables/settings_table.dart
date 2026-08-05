import 'package:drift/drift.dart';

class Settings extends Table {
  IntColumn get id => integer()();

  BoolColumn get syncEnabled => boolean().withDefault(const Constant(true))();

  BoolColumn get archiveMode => boolean().withDefault(const Constant(true))();

  BoolColumn get devMode => boolean().withDefault(const Constant(false))();

  BoolColumn get showContactName =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get showPhoneNumber =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get showCallType => boolean().withDefault(const Constant(true))();

  BoolColumn get showDuration => boolean().withDefault(const Constant(true))();

  BoolColumn get showDate => boolean().withDefault(const Constant(true))();

  BoolColumn get showTime => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
