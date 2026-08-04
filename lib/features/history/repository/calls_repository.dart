import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/native/call_log_channel.dart';

class CallsRepository {
  final AppDatabase _db;

  CallsRepository(this._db);

  Future<void> syncFromDevice() async {
    final latestTimestamp = await _db.getLatestTimestamp();

    final calls = await CallLogChannel.fetchCallLogs(
      sinceTimestamp: latestTimestamp,
    );

    if (calls.isEmpty) return;

    final companions = calls.map((call) {
      return CallsCompanion.insert(
        number: Value(call['number'] as String?),
        name: Value(call['name'] as String?),
        type: call['type'] as int,
        duration: call['duration'] as int,
        timestamp: call['timestamp'] as int,
      );
    }).toList();

    await _db.batch((batch) {
      batch.insertAll(_db.calls, companions, mode: InsertMode.insertOrIgnore);
    });
  }
}
