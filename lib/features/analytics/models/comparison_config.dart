import 'analytics_filters.dart';

enum ComparisonMode { monthVsMonth, yearVsYear, contactVsContact, custom }

class ComparisonConfig {
  final AnalyticsFilters left;
  final AnalyticsFilters right;
  final String leftLabel;
  final String rightLabel;

  const ComparisonConfig({
    required this.left,
    required this.right,
    required this.leftLabel,
    required this.rightLabel,
  });

  factory ComparisonConfig.thisMonthVsLast() {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart.subtract(const Duration(seconds: 1));

    return ComparisonConfig(
      left: AnalyticsFilters(
        dateRange: DateRangeOption.custom,
        customStart: lastMonthStart,
        customEnd: lastMonthEnd,
      ),
      right: AnalyticsFilters(
        dateRange: DateRangeOption.custom,
        customStart: thisMonthStart,
        customEnd: now,
      ),
      leftLabel: 'Last Month',
      rightLabel: 'This Month',
    );
  }

  factory ComparisonConfig.thisYearVsLast() {
    final now = DateTime.now();
    final thisYearStart = DateTime(now.year, 1, 1);
    final lastYearStart = DateTime(now.year - 1, 1, 1);
    final lastYearEnd = thisYearStart.subtract(const Duration(seconds: 1));

    return ComparisonConfig(
      left: AnalyticsFilters(
        dateRange: DateRangeOption.custom,
        customStart: lastYearStart,
        customEnd: lastYearEnd,
      ),
      right: AnalyticsFilters(
        dateRange: DateRangeOption.custom,
        customStart: thisYearStart,
        customEnd: now,
      ),
      leftLabel: 'Last Year',
      rightLabel: 'This Year',
    );
  }

  factory ComparisonConfig.contacts(String leftNumber,
      String leftName,
      String rightNumber,
      String rightName,) {
    return ComparisonConfig(
      left: AnalyticsFilters(contactNormalizedNumber: leftNumber),
      right: AnalyticsFilters(contactNormalizedNumber: rightNumber),
      leftLabel: leftName,
      rightLabel: rightName,
    );
  }
}