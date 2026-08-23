import '../../contacts/models/contact_summary.dart';

class AnalyticsSummary {
  final int totalCalls;
  final int totalContacts;
  final int totalTalkSeconds;
  final List<int> callsPerDay;
  final List<String> dayLabels;
  final List<ContactSummary> mostContacted;
  final List<ContactSummary> silentContacts;

  const AnalyticsSummary({
    required this.totalCalls,
    required this.totalContacts,
    required this.totalTalkSeconds,
    required this.callsPerDay,
    required this.dayLabels,
    required this.mostContacted,
    required this.silentContacts,
  });
}
