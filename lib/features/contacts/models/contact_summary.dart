class ContactSummary {
  final String? deviceContactId;
  final String normalizedNumber;
  final String displayName;
  final String displayNumber;
  final int callCount;
  final int? lastCallAt;

  const ContactSummary({
    this.deviceContactId,
    required this.normalizedNumber,
    required this.displayName,
    required this.displayNumber,
    required this.callCount,
    this.lastCallAt,
  });
}
