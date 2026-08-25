import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/call_number_stat.dart';
import '../../../core/utils/normalize_number.dart';
import '../models/contact_summary.dart';

class ContactsRepository {
  final AppDatabase _db;

  ContactsRepository(this._db);

  Stream<List<ContactSummary>> watchContacts(List<Contact> deviceContacts) {
    return _watchAllSummaries(deviceContacts).asyncMap((summaries) async {
      final archivedNumbers = await _archivedNumbers();
      return summaries
          .where((s) => !archivedNumbers.contains(s.normalizedNumber))
          .toList();
    });
  }

  Stream<List<ContactSummary>> watchArchivedContacts(
    List<Contact> deviceContacts,
  ) {
    return _watchAllSummaries(deviceContacts).asyncMap((summaries) async {
      final archivedNumbers = await _archivedNumbers();
      return summaries
          .where((s) => archivedNumbers.contains(s.normalizedNumber))
          .toList();
    });
  }

  Future<Set<String>> _archivedNumbers() async {
    final rows = await (_db.select(
      _db.contactDetails,
    )..where((c) => c.isArchived.equals(true))).get();
    return rows.map((row) => row.normalizedNumber).toSet();
  }

  Future<List<CallNumberStat>> _getCallStats() {
    return _db.getCallStatsByNumber();
  }

  Stream<List<ContactSummary>> _watchAllSummaries(
    List<Contact> deviceContacts,
  ) {
    return _db.watchAllCalls().asyncMap((_) async {
      final stats = await _getCallStats();
      return compute(_mergeContactsIsolate, _MergeInput(deviceContacts, stats));
    });
  }

  Stream<List<ContactSummary>> watchAllContactSummaries(
    List<Contact> deviceContacts,
  ) {
    return _watchAllSummaries(deviceContacts);
  }
}

class _MergeInput {
  final List<Contact> deviceContacts;
  final List<CallNumberStat> stats;

  const _MergeInput(this.deviceContacts, this.stats);
}

List<ContactSummary> _mergeContactsIsolate(_MergeInput input) {
  final statsByNormalized = <String, List<CallNumberStat>>{};

  for (final stat in input.stats) {
    final key = normalizePhoneNumber(stat.number);
    if (key.isEmpty) continue;
    statsByNormalized.putIfAbsent(key, () => []).add(stat);
  }

  final summaries = <ContactSummary>[];
  final matchedNumbers = <String>{};

  for (final contact in input.deviceContacts) {
    summaries.add(
      _buildDeviceContactSummaryStatic(
        contact,
        statsByNormalized,
        matchedNumbers,
      ),
    );
  }

  summaries.addAll(
    _buildUnknownContactSummariesStatic(statsByNormalized, matchedNumbers),
  );

  summaries.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );

  return summaries;
}

ContactSummary _buildDeviceContactSummaryStatic(
  Contact contact,
  Map<String, List<CallNumberStat>> statsByNormalized,
  Set<String> matchedNumbers,
) {
  final numbers = contact.phones
      .map((phone) => normalizePhoneNumber(phone.number))
      .where((number) => number.isNotEmpty)
      .toSet();

  int totalCount = 0;
  int? latestTimestamp;
  int totalDuration = 0;

  for (final number in numbers) {
    final matches = statsByNormalized[number];
    if (matches == null) continue;

    matchedNumbers.add(number);
    for (final stat in matches) {
      totalCount += stat.count;
      totalDuration += stat.totalDuration;
      if (latestTimestamp == null || stat.lastTimestamp > latestTimestamp) {
        latestTimestamp = stat.lastTimestamp;
      }
    }
  }

  final displayNumber = contact.phones.isNotEmpty
      ? contact.phones.first.number
      : '';
  final displayName = contact.displayName.isNotEmpty
      ? contact.displayName
      : displayNumber;

  return ContactSummary(
    deviceContactId: contact.id,
    deviceContact: contact,
    normalizedNumber: numbers.isNotEmpty ? numbers.first : '',
    displayName: displayName,
    displayNumber: displayNumber,
    callCount: totalCount,
    lastCallAt: latestTimestamp,
    totalDuration: totalDuration,
  );
}

List<ContactSummary> _buildUnknownContactSummariesStatic(
  Map<String, List<CallNumberStat>> statsByNormalized,
  Set<String> matchedNumbers,
) {
  final summaries = <ContactSummary>[];

  for (final entry in statsByNormalized.entries) {
    if (matchedNumbers.contains(entry.key)) continue;

    int totalCount = 0;
    int latestTimestamp = 0;
    String? name;
    int totalDuration = 0;

    for (final stat in entry.value) {
      totalCount += stat.count;
      totalDuration += stat.totalDuration;
      if (stat.lastTimestamp > latestTimestamp) {
        latestTimestamp = stat.lastTimestamp;
        name = stat.name?.isNotEmpty == true ? stat.name : name;
      }
    }

    summaries.add(
      ContactSummary(
        deviceContactId: null,
        normalizedNumber: entry.key,
        displayName: name?.isNotEmpty == true
            ? name!
            : entry.value.first.number,
        displayNumber: entry.value.first.number,
        callCount: totalCount,
        lastCallAt: latestTimestamp,
        totalDuration: totalDuration,
      ),
    );
  }

  return summaries;
}
