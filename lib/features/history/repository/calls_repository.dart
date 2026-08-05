import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/native/call_log_channel.dart';

class CallsRepository {
  final AppDatabase _db;

  CallsRepository(this._db);

  Future<void> syncFromDevice({required bool archiveMode}) async {
    if (archiveMode) {
      await _incrementalSync();
    } else {
      await _fullReconcile();
    }
  }

  Future<void> _incrementalSync() async {
    final latestTimestamp = await _db.getLatestTimestamp();

    final calls = await CallLogChannel.fetchCallLogs(
      sinceTimestamp: latestTimestamp,
    );

    if (calls.isEmpty) return;

    await _insertAll(calls);
  }

  Future<void> _fullReconcile() async {
    final deviceCalls = await CallLogChannel.fetchCallLogs();

    await _insertAll(deviceCalls);

    final deviceKeys = deviceCalls.map(_keyFor).toSet();

    final localRows = await _db.select(_db.calls).get();
    final idsToDelete = localRows
        .where((row) => !deviceKeys.contains(_keyForRow(row)))
        .map((row) => row.id)
        .toList();

    if (idsToDelete.isEmpty) return;

    await (_db.delete(_db.calls)..where((t) => t.id.isIn(idsToDelete))).go();
  }

  Future<void> _insertAll(List<Map<String, dynamic>> calls) async {
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

  String _keyFor(Map<String, dynamic> call) {
    return '${call['number']}|${call['timestamp']}|${call['duration']}|${call['type']}';
  }

  String _keyForRow(Call row) {
    return '${row.number}|${row.timestamp}|${row.duration}|${row.type}';
  }
}
