import 'package:flutter_contacts/flutter_contacts.dart';

import '../utils/normalize_number.dart';

/// In-memory cache for device contacts to ensure O(1) synchronous lookups
/// across all screens and instant image rendering on frame 0.
class ContactCache {
  static List<Contact> _contacts = [];
  static final Map<String, Contact> _byNumber = {};
  static final Map<String, Contact> _byName = {};

  static List<Contact> get contacts => _contacts;

  /// Updates the full cached contact list and rebuilds fast lookup maps.
  static void setContacts(List<Contact> newContacts) {
    _contacts = newContacts;
    _byNumber.clear();
    _byName.clear();

    for (final contact in newContacts) {
      for (final phone in contact.phones) {
        final normalized = normalizePhoneNumber(phone.number);
        if (normalized.isNotEmpty) {
          _byNumber[normalized] = contact;
        }
      }
      final name = contact.displayName.trim().toLowerCase();
      if (name.isNotEmpty) {
        _byName[name] = contact;
      }
    }
  }

  /// Finds a cached contact by normalized phone number or display name.
  static Contact? findContact({String? number, String? name}) {
    if (number != null && number.isNotEmpty) {
      final normalized = normalizePhoneNumber(number);
      final found = _byNumber[normalized];
      if (found != null) return found;
    }
    if (name != null && name.trim().isNotEmpty) {
      final lower = name.trim().toLowerCase();
      final found = _byName[lower];
      if (found != null) return found;
    }
    return null;
  }

  /// Updates a single contact in the cache (e.g. after fetching full-res photo).
  static void updateContact(Contact updated) {
    final idx = _contacts.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _contacts[idx] = updated;
    } else {
      _contacts.add(updated);
    }
    for (final phone in updated.phones) {
      final normalized = normalizePhoneNumber(phone.number);
      if (normalized.isNotEmpty) {
        _byNumber[normalized] = updated;
      }
    }
    final name = updated.displayName.trim().toLowerCase();
    if (name.isNotEmpty) {
      _byName[name] = updated;
    }
  }
}
