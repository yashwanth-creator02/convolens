import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../models/contact_summary.dart';
import '../../../core/utils/normalize_number.dart';

class ContactsRepository {
  final AppDatabase db;

  ContactsRepository(this.db);

  Stream<List<ContactSummary>> watchContacts(List<Contact> deviceContacts) {
    return db.watchAllCalls().map((calls) {
      final Map<String, List<Call>> callsByNumber = {};
      for (final call in calls) {
        final key = normalizePhoneNumber(call.number);
        if (key.isEmpty) continue;
        callsByNumber.putIfAbsent(key, () => []).add(call);
      }

      final summaries = <ContactSummary>[];
      final matchedNumbers = <String>{};

      for (final contact in deviceContacts) {
        final numbers = contact.phones
            .map((p) => normalizePhoneNumber(p.number))
            .where((n) => n.isNotEmpty)
            .toSet();

        final matchedCalls = <Call>[];
        for (final num in numbers) {
          final calls = callsByNumber[num];
          if (calls != null) {
            matchedCalls.addAll(calls);
            matchedNumbers.add(num);
          }
        }
        matchedCalls.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        final displayNumber = contact.phones.isNotEmpty
            ? contact.phones.first.number
            : '';

        summaries.add(
          ContactSummary(
            deviceContactId: contact.id,
            normalizedNumber: numbers.isNotEmpty ? numbers.first : '',
            displayName: contact.displayName.isNotEmpty
                ? contact.displayName
                : displayNumber,
            displayNumber: displayNumber,
            callCount: matchedCalls.length,
            lastCallAt: matchedCalls.isNotEmpty
                ? matchedCalls.first.timestamp
                : null,
          ),
        );
      }

      for (final entry in callsByNumber.entries) {
        if (matchedNumbers.contains(entry.key)) continue;

        final callsForNumber = entry.value;
        final mostRecent = callsForNumber.first;
        final namedCall = callsForNumber.firstWhere(
          (c) => c.name != null && c.name!.isNotEmpty,
          orElse: () => mostRecent,
        );

        summaries.add(
          ContactSummary(
            deviceContactId: null,
            normalizedNumber: entry.key,
            displayName: namedCall.name?.isNotEmpty == true
                ? namedCall.name!
                : (mostRecent.number ?? 'Unknown'),
            displayNumber: mostRecent.number ?? '',
            callCount: callsForNumber.length,
            lastCallAt: mostRecent.timestamp,
          ),
        );
      }

      summaries.sort((a, b) {
        if (a.lastCallAt != null && b.lastCallAt != null) {
          return b.lastCallAt!.compareTo(a.lastCallAt!);
        }
        if (a.lastCallAt != null) return -1;
        if (b.lastCallAt != null) return 1;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });

      return summaries;
    });
  }
}
