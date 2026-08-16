import 'package:flutter_contacts/flutter_contacts.dart';

class ContactSummary {
  final String? deviceContactId;
  final Contact? deviceContact;
  final String normalizedNumber;
  final String displayName;
  final String displayNumber;
  final int callCount;
  final int? lastCallAt;

  const ContactSummary({
    this.deviceContactId,
    this.deviceContact,
    required this.normalizedNumber,
    required this.displayName,
    required this.displayNumber,
    required this.callCount,
    this.lastCallAt,
  });
}
