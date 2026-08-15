import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/normalize_number.dart';
import '../models/contact_summary.dart';

class ContactsRepository {
  final AppDatabase _db;

  ContactsRepository(this._db);

  Stream<List<ContactSummary>> watchContacts(List<Contact> deviceContacts) {
    return _db.watchAllCalls().map((calls) {
      final callsByNumber = _groupCallsByNumber(calls);
      final summaries = <ContactSummary>[];
      final matchedNumbers = <String>{};

      for (final contact in deviceContacts) {
        final summary = _buildDeviceContactSummary(
          contact,
          callsByNumber,
          matchedNumbers,
        );

        summaries.add(summary);
      }

      summaries.addAll(
        _buildUnknownContactSummaries(callsByNumber, matchedNumbers),
      );

      summaries.sort(_compareContactSummaries);

      return summaries;
    });
  }

  Map<String, List<Call>> _groupCallsByNumber(List<Call> calls) {
    final callsByNumber = <String, List<Call>>{};

    for (final call in calls) {
      final number = normalizePhoneNumber(call.number);

      if (number.isEmpty) {
        continue;
      }

      callsByNumber.putIfAbsent(number, () => []).add(call);
    }

    return callsByNumber;
  }

  ContactSummary _buildDeviceContactSummary(
    Contact contact,
    Map<String, List<Call>> callsByNumber,
    Set<String> matchedNumbers,
  ) {
    final numbers = contact.phones
        .map((phone) => normalizePhoneNumber(phone.number))
        .where((number) => number.isNotEmpty)
        .toSet();

    final matchedCalls = <Call>[];

    for (final number in numbers) {
      final calls = callsByNumber[number];

      if (calls == null) {
        continue;
      }

      matchedCalls.addAll(calls);
      matchedNumbers.add(number);
    }

    matchedCalls.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final displayNumber = contact.phones.isNotEmpty
        ? contact.phones.first.number
        : '';

    final displayName = contact.displayName.isNotEmpty
        ? contact.displayName
        : displayNumber;

    return ContactSummary(
      deviceContactId: contact.id,
      normalizedNumber: numbers.isNotEmpty ? numbers.first : '',
      displayName: displayName,
      displayNumber: displayNumber,
      callCount: matchedCalls.length,
      lastCallAt: matchedCalls.isNotEmpty ? matchedCalls.first.timestamp : null,
    );
  }

  List<ContactSummary> _buildUnknownContactSummaries(
    Map<String, List<Call>> callsByNumber,
    Set<String> matchedNumbers,
  ) {
    final summaries = <ContactSummary>[];

    for (final entry in callsByNumber.entries) {
      if (matchedNumbers.contains(entry.key)) {
        continue;
      }

      final calls = entry.value;
      final mostRecent = calls.first;

      final namedCall = calls.firstWhere(
        (call) => call.name != null && call.name!.isNotEmpty,
        orElse: () => mostRecent,
      );

      final displayName = namedCall.name?.isNotEmpty == true
          ? namedCall.name!
          : (mostRecent.number ?? 'Unknown');

      summaries.add(
        ContactSummary(
          deviceContactId: null,
          normalizedNumber: entry.key,
          displayName: displayName,
          displayNumber: mostRecent.number ?? '',
          callCount: calls.length,
          lastCallAt: mostRecent.timestamp,
        ),
      );
    }

    return summaries;
  }

  int _compareContactSummaries(ContactSummary a, ContactSummary b) {
    if (a.lastCallAt != null && b.lastCallAt != null) {
      return b.lastCallAt!.compareTo(a.lastCallAt!);
    }

    if (a.lastCallAt != null) {
      return -1;
    }

    if (b.lastCallAt != null) {
      return 1;
    }

    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  }
}
