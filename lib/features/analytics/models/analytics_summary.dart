import '../../contacts/models/contact_summary.dart';

class AnalyticsSummary {
  final int totalCalls;
  final int totalContacts;
  final int totalTalkSeconds;
  final List<int> callsPerDay;
  final List<String> dayLabels;
  final List<ContactSummary> mostContacted;
  final List<ContactSummary> silentContacts;
  final Map<int, int> callTypeCounts;
  final Map<String, int> tagCounts;
  final String selectedRange;
  final Map<String, int> heatmapData;
  final int currentStreak;
  final int longestStreak;
  final Map<int, int> hourCounts;
  final String? longestCallSeconds;
  final String? busiestDayCount;
  final String? busiestDayDate;
  final double missedCallRate;
  final Map<int, int> weekdayCounts;

  const AnalyticsSummary({
    required this.totalCalls,
    required this.totalContacts,
    required this.totalTalkSeconds,
    required this.callsPerDay,
    required this.dayLabels,
    required this.mostContacted,
    required this.silentContacts,
    required this.callTypeCounts,
    required this.tagCounts,
    required this.selectedRange,
    required this.heatmapData,
    required this.currentStreak,
    required this.longestStreak,
    required this.hourCounts,
    this.longestCallSeconds,
    this.busiestDayCount,
    this.busiestDayDate,
    required this.missedCallRate, required this.weekdayCounts,
  });
}