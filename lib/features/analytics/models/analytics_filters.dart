enum DateRangeOption { last7, last30, last6Months, lastYear, custom }

enum CallTypeFilter { all, incoming, outgoing, missed, declined }

class AnalyticsFilters {
  final DateRangeOption dateRange;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String? contactNormalizedNumber;
  final CallTypeFilter callType;
  final int? tagId;

  const AnalyticsFilters({
    this.dateRange = DateRangeOption.last30,
    this.customStart,
    this.customEnd,
    this.contactNormalizedNumber,
    this.tagId,
    this.callType = CallTypeFilter.all,
  });

  AnalyticsFilters copyWith({
    DateRangeOption? dateRange,
    DateTime? customStart,
    DateTime? customEnd,
    String? contactNormalizedNumber,
    bool clearContact = false,
    int? tagId,
    bool clearTag = false,
    CallTypeFilter? callType,
  }) {
    return AnalyticsFilters(
      dateRange: dateRange ?? this.dateRange,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      contactNormalizedNumber: clearContact
          ? null
          : (contactNormalizedNumber ?? this.contactNormalizedNumber),
      tagId: clearTag ? null : (tagId ?? this.tagId),
      callType: callType ?? this.callType,
    );
  }

  DateTime resolveStartDate() {
    final now = DateTime.now();
    switch (dateRange) {
      case DateRangeOption.last7:
        return now.subtract(const Duration(days: 6));
      case DateRangeOption.last30:
        return now.subtract(const Duration(days: 29));
      case DateRangeOption.last6Months:
        return now.subtract(const Duration(days: 182));
      case DateRangeOption.lastYear:
        return now.subtract(const Duration(days: 364));
      case DateRangeOption.custom:
        return customStart ?? now.subtract(const Duration(days: 29));
    }
  }

  DateTime resolveEndDate() {
    if (dateRange == DateRangeOption.custom && customEnd != null)
      return customEnd!;
    return DateTime.now();
  }

  int? get callTypeCode {
    switch (callType) {
      case CallTypeFilter.incoming:
        return 1;
      case CallTypeFilter.outgoing:
        return 2;
      case CallTypeFilter.missed:
        return 3;
      case CallTypeFilter.declined:
        return 5;
      case CallTypeFilter.all:
        return null;
    }
  }
}
