import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../contacts/models/contact_summary.dart';
import '../../contacts/repository/contacts_repository.dart';
import '../models/analytics_summary.dart';

class AnalyticsRepository {
  final AppDatabase _db;
  late final ContactsRepository _contactsRepository;

  AnalyticsRepository(this._db) {
    _contactsRepository = ContactsRepository(_db);
  }

  Stream<AnalyticsSummary> watchSummary(List<Contact> deviceContacts) {
    return _db.watchAllCalls().asyncMap((calls) async {
      final ignoredRows = await (_db.select(
        _db.contactDetails,
      )..where((c) => c.ignoreFromAnalytics.equals(true))).get();
      final ignoredNumbers = ignoredRows.map((r) => r.normalizedNumber).toSet();

      final allSummaries = await _contactsRepository
          .watchAllContactSummaries(deviceContacts)
          .first;

      final includedSummaries = allSummaries
          .where((s) => !ignoredNumbers.contains(s.normalizedNumber))
          .toList();

      final includedCalls = calls.where((c) {
        return true;
      }).toList();

      final totalTalkSeconds = includedCalls.fold<int>(
        0,
        (sum, c) => sum + c.duration,
      );

      final now = DateTime.now();
      final startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 13));
      final countsByDay = await _db.getCallCountsByDay(startDate);

      final callsPerDay = <int>[];
      final dayLabels = <String>[];

      for (int i = 13; i >= 0; i--) {
        final day = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        final key =
            '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}';

        callsPerDay.add(countsByDay[key] ?? 0);
        dayLabels.add('${day.day}/${day.month}');
      }

      final mostContacted = [...includedSummaries]
        ..sort((a, b) => b.callCount.compareTo(a.callCount));
      final topContacted = mostContacted
          .where((s) => s.callCount > 0)
          .take(5)
          .toList();

      final thirtyDaysAgo = now
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch;
      final silentContacts =
          includedSummaries.where((s) {
              if (s.deviceContact == null) return false;
              return s.lastCallAt == null || s.lastCallAt! < thirtyDaysAgo;
            }).toList()
            ..sort((a, b) => (a.lastCallAt ?? 0).compareTo(b.lastCallAt ?? 0));

      return AnalyticsSummary(
        totalCalls: includedCalls.length,
        totalContacts: includedSummaries.length,
        totalTalkSeconds: totalTalkSeconds,
        callsPerDay: callsPerDay,
        dayLabels: dayLabels,
        mostContacted: topContacted,
        silentContacts: silentContacts,
      );
    });
  }
}
