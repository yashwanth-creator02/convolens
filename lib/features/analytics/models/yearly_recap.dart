import '../models/analytics_summary.dart';
import '../../contacts/models/contact_summary.dart';

class YearlyRecap {
  final int year;
  final int totalCalls;
  final int totalTalkHours;
  final ContactSummary? topContact;
  final int longestStreak;
  final String? busiestDay;
  final int busiestDayCount;
  final String busiestWeekday;
  final int busiestHour;
  final double missedRate;

  const YearlyRecap({
    required this.year,
    required this.totalCalls,
    required this.totalTalkHours,
    required this.topContact,
    required this.longestStreak,
    required this.busiestDay,
    required this.busiestDayCount,
    required this.busiestWeekday,
    required this.busiestHour,
    required this.missedRate,
  });

  factory YearlyRecap.fromSummary(int year, AnalyticsSummary summary) {
    const weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    String busiestWeekday = '—';
    if (summary.weekdayCounts.isNotEmpty) {
      final top = summary.weekdayCounts.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      busiestWeekday = weekdayLabels[top.key];
    }

    int busiestHour = 0;
    if (summary.hourCounts.isNotEmpty) {
      busiestHour = summary.hourCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    return YearlyRecap(
      year: year,
      totalCalls: summary.totalCalls,
      totalTalkHours: (summary.totalTalkSeconds / 3600).round(),
      topContact: summary.mostContacted.isNotEmpty
          ? summary.mostContacted.first
          : null,
      longestStreak: summary.longestStreak,
      busiestDay: summary.busiestDayDate,
      busiestDayCount: summary.busiestDayCount,
      busiestWeekday: busiestWeekday,
      busiestHour: busiestHour,
      missedRate: summary.missedCallRate,
    );
  }
}
