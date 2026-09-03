import 'package:flutter_contacts/flutter_contacts.dart';

class ContactSummary {
  final String? deviceContactId;
  final Contact? deviceContact;
  final String normalizedNumber;
  final String displayName;
  final String displayNumber;
  final int callCount;
  final int incoming;
  final int outgoing;
  final int? lastCallAt;
  final int totalDuration;

  const ContactSummary({
    this.deviceContactId,
    this.deviceContact,
    required this.normalizedNumber,
    required this.displayName,
    required this.displayNumber,
    required this.callCount,
    required this.incoming,
    required this.outgoing,
    this.lastCallAt,
    required this.totalDuration,
  });
}
