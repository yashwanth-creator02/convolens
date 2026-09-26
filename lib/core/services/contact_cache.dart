import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../utils/normalize_number.dart';

class ContactCacheNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// In-memory cache for device contacts to ensure O(1) synchronous lookups
/// across all screens and instant image rendering on frame 0.
class ContactCache {
  static List<Contact> _contacts = [];
  static final Map<String, Contact> _byNumber = {};
  static final Map<String, Contact> _byName = {};

  /// Global notifier that broadcasts whenever cached contacts are added,
  /// updated, or removed so any active screen can refresh instantaneously.
  static final ContactCacheNotifier changeNotifier = ContactCacheNotifier();

  static List<Contact> get contacts => List.unmodifiable(_contacts);

  /// Updates the full cached contact list and rebuilds fast lookup maps.
  static void setContacts(List<Contact> newContacts) {
    _contacts = List.from(newContacts);
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
    changeNotifier.notify();
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
    changeNotifier.notify();
  }

  /// Removes a contact and all its associations from the cache.
  static void removeContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
    _byNumber.removeWhere((_, c) => c.id == id);
    _byName.removeWhere((_, c) => c.id == id);
    changeNotifier.notify();
  }

  /// Removes a specific phone number association from the cache.
  static void removeNumber(String rawOrNormalizedNumber) {
    final normalized = normalizePhoneNumber(rawOrNormalizedNumber);
    if (normalized.isNotEmpty) {
      _byNumber.remove(normalized);
    }
    _byNumber.remove(rawOrNormalizedNumber);

    // Also update any contact in memory that held this number
    for (int i = _contacts.length - 1; i >= 0; i--) {
      final c = _contacts[i];
      c.phones.removeWhere((p) =>
          normalizePhoneNumber(p.number) == normalized ||
          p.number.replaceAll(RegExp(r'\s+'), '') ==
              rawOrNormalizedNumber.replaceAll(RegExp(r'\s+'), ''));
      if (c.phones.isEmpty) {
        _contacts.removeAt(i);
        _byName.remove(c.displayName.trim().toLowerCase());
      }
    }

    changeNotifier.notify();
  }
}

