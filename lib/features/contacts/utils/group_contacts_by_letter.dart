import '../models/contact_summary.dart';

String letterFor(String name) {
  if (name.isEmpty) return '#';
  final first = name[0].toUpperCase();
  return RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
}

Map<String, List<ContactSummary>> groupContactsByLetter(
  List<ContactSummary> contacts,
) {
  final Map<String, List<ContactSummary>> grouped = {};

  for (final contact in contacts) {
    final letter = letterFor(contact.displayName);
    grouped.putIfAbsent(letter, () => []).add(contact);
  }

  return grouped;
}
