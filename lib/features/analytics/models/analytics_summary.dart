import '../../contacts/models/contact_summary.dart';

class AnalyticsSummary {
  final int totalCalls;
  final int totalContacts;
  final int totalTalkSeconds;
  final List<int> callsPerDay;
  final List<int> durationTrend;
  final List<String> dayLabels;
  final List<ContactSummary> mostContacted;
  final List<ContactSummary> silentContacts;
  final Map<int, int> callTypeCounts;
  final Map<int, int> weekdayCounts;
  final Map<int, int> hourCounts;
  final Map<String, int> tagCounts;
  final Map<String, int> heatmapData;
  final int currentStreak;
  final int longestStreak;
  final int longestCallSeconds;
  final String? busiestDayDate;
  final int busiestDayCount;
  final double missedCallRate;

  final double avgCallsPerFavorite;
  final double avgCallsPerOther;
  final int favoriteContactCount;
  final int otherContactCount;

  const AnalyticsSummary({
    required this.totalCalls,
    required this.totalContacts,
    required this.totalTalkSeconds,
    required this.callsPerDay,
    required this.durationTrend,
    required this.dayLabels,
    required this.mostContacted,
    required this.silentContacts,
    required this.callTypeCounts,
    required this.weekdayCounts,
    required this.hourCounts,
    required this.tagCounts,
    required this.heatmapData,
    required this.currentStreak,
    required this.longestStreak,
    required this.longestCallSeconds,
    this.busiestDayDate,
    required this.busiestDayCount,
    required this.missedCallRate,
    required this.avgCallsPerFavorite,
    required this.avgCallsPerOther,
    required this.favoriteContactCount,
    required this.otherContactCount,
  });
}
