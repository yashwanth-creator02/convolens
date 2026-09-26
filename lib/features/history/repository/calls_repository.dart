import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/native/call_log_channel.dart';
import '../../../core/notifications/notification_service.dart';

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
    await _checkMissedCallAlerts(calls);
  }

  Future<void> _fullReconcile() async {
    final deviceCalls = await CallLogChannel.fetchCallLogs();

    await _insertAll(deviceCalls);
    await _checkMissedCallAlerts(deviceCalls);

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

  Future<void> _checkMissedCallAlerts(List<Map<String, dynamic>> calls) async {
    try {
      final settings =
          await (_db.select(_db.settings)..where((s) => s.id.equals(0))).getSingle();
      if (!settings.missedCallAlerts) return;

      final favNumbers = await _db.getFavoriteNumbers();
      if (favNumbers.isEmpty) return;

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final thirtyMinsAgo = nowMs - (30 * 60 * 1000);

      for (final call in calls) {
        final type = call['type'] as int?;
        final timestamp = call['timestamp'] as int?;
        final number = call['number'] as String?;
        final name = call['name'] as String? ?? number ?? 'Favorite Contact';

        if (type == 3 && timestamp != null && timestamp >= thirtyMinsAgo && number != null) {
          final suffix = number.length >= 7 ? number.substring(number.length - 7) : number;
          final isFav = favNumbers.any((f) => f.endsWith(suffix) || suffix.endsWith(f));

          if (isFav) {
            final callRow = await (_db.select(_db.calls)
                  ..where((c) => c.timestamp.equals(timestamp) & c.number.equals(number))
                  ..limit(1))
                .getSingleOrNull();

            final callId = callRow?.id ?? timestamp;
            await NotificationService.showMissedCallAlert(
              callId: callId,
              contactName: name,
              number: number,
            );
          }
        }
      }
    } catch (e) {
      // Non-critical background alert failure
    }
  }

  String _keyFor(Map<String, dynamic> call) {
    return '${call['number']}|${call['timestamp']}|${call['duration']}|${call['type']}';
  }

  String _keyForRow(Call row) {
    return '${row.number}|${row.timestamp}|${row.duration}|${row.type}';
  }
}
