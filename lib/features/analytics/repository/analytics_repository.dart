import 'dart:math';

import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../contacts/repository/contacts_repository.dart';
import '../models/analytics_filters.dart';
import '../models/analytics_summary.dart';

class AnalyticsRepository {
  final AppDatabase _db;
  late final ContactsRepository _contactsRepository;

  AnalyticsRepository(this._db) {
    _contactsRepository = ContactsRepository(_db);
  }

  String _periodFormatFor(DateRangeOption range) {
    switch (range) {
      case DateRangeOption.last7:
      case DateRangeOption.last30:
        return '%Y-%m-%d';

      case DateRangeOption.last6Months:
      case DateRangeOption.lastYear:
      case DateRangeOption.custom:
        return '%Y-%m';
    }
  }

  Stream<AnalyticsSummary> watchSummary(
    List<Contact> deviceContacts,
    AnalyticsFilters filters,
  ) {
    return _db.watchAllCalls().asyncMap((_) async {
      final start = filters.resolveStartDate();
      final end = filters.resolveEndDate();
      final contact = filters.contactNormalizedNumber;
      final type = filters.callTypeCode;
      final periodFormat = _periodFormatFor(filters.dateRange);

      // ============================================================
      // IGNORED CONTACTS
      // ============================================================

      final ignoredRows = await (_db.select(
        _db.contactDetails,
      )..where((c) => c.ignoreFromAnalytics.equals(true))).get();

      final ignoredNumbers = ignoredRows.map((r) => r.normalizedNumber).toSet();

      // ============================================================
      // PERIOD ANALYTICS
      // ============================================================

      final periodCounts = await _db.getCallCountsByPeriod(
        start,
        end,
        periodFormat,
        contactNumberSuffix: contact,
        callType: type,
        tagId: filters.tagId,
      );

      final durationByPeriod = await _db.getDurationByPeriod(
        start,
        end,
        periodFormat,
        contactNumberSuffix: contact,
        callType: type,
        tagId: filters.tagId,
      );

      // ============================================================
      // CALL TYPE ANALYTICS
      // ============================================================

      // Do NOT pass callType here.
      //
      // This method groups by type, so passing callType would filter
      // the result to one type before grouping.
      final callTypeCounts = await _db.getCallCountsByType(
        since: start,
        until: end,
        contactNumberSuffix: contact,
        tagId: filters.tagId,
      );

      // ============================================================
      // HOURLY ANALYTICS
      // ============================================================

      final hourCounts = await _db.getCallCountsByHour(
        since: start,
        until: end,
        contactNumberSuffix: contact,
        callType: type,
        tagId: filters.tagId,
      );

      // ============================================================
      // WEEKDAY ANALYTICS
      // ============================================================

      final weekdayCounts = await _db.getCallCountsByWeekday(
        since: start,
        until: end,
        contactNumberSuffix: contact,
        callType: type,
        tagId: filters.tagId,
      );

      // ============================================================
      // LONGEST CALL
      // ============================================================

      final longestCallSeconds = await _db.getLongestCallDuration(
        since: start,
        until: end,
        contactNumberSuffix: contact,
        callType: type,
        tagId: filters.tagId,
      );

      // ============================================================
      // HEATMAP
      // ============================================================

      final yearAgo = DateTime.now().subtract(const Duration(days: 364));

      final heatmapCounts = await _db.getCallCountsByPeriod(
        yearAgo,
        DateTime.now(),
        '%Y-%m-%d',
        contactNumberSuffix: contact,
        callType: type,
        tagId: filters.tagId,
      );

      // ============================================================
      // CHART DATA
      // ============================================================

      final periodKeys = periodCounts.keys.toList()..sort();

      final callsPerDay = periodKeys
          .map((key) => periodCounts[key] ?? 0)
          .toList();

      final durationTrend = periodKeys
          .map((key) => durationByPeriod[key] ?? 0)
          .toList();

      final dayLabels = periodKeys.map((key) {
        final parts = key.split('-');

        if (parts.length == 3) {
          // YYYY-MM-DD
          return '${parts[2]}/${parts[1]}';
        }

        // YYYY-MM
        return '${parts[1]}/${parts[0].substring(2)}';
      }).toList();

      // ============================================================
      // CONTACT STATS
      // ============================================================

      final stats = await _db.getCallStatsByNumber(
        since: start,
        until: end,
        callType: type,
        tagId: filters.tagId,
      );

      // ============================================================
      // CONTACT SUMMARIES
      // ============================================================

      final allSummaries = await _contactsRepository
          .watchAllContactSummaries(deviceContacts)
          .first;

      final includedSummaries = allSummaries
          .where(
            (summary) => !ignoredNumbers.contains(summary.normalizedNumber),
          )
          .toList();

      // ============================================================
      // TOTALS
      // ============================================================

      final totalCalls = callTypeCounts.values.fold<int>(
        0,
        (total, count) => total + count,
      );

      final totalTalkSeconds = durationByPeriod.values.fold<int>(
        0,
        (total, duration) => total + duration,
      );

      // ============================================================
      // MOST CONTACTED
      // ============================================================

      final mostContacted = [...includedSummaries]
        ..sort((a, b) => b.callCount.compareTo(a.callCount));

      final topContacted = mostContacted
          .where((summary) => summary.callCount > 0)
          .take(10)
          .toList();

      // ============================================================
      // SILENT CONTACTS
      // ============================================================

      final thirtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch;

      final silentContacts =
          includedSummaries.where((summary) {
              if (summary.deviceContact == null) {
                return false;
              }

              return summary.lastCallAt == null ||
                  summary.lastCallAt! < thirtyDaysAgo;
            }).toList()
            ..sort((a, b) => (a.lastCallAt ?? 0).compareTo(b.lastCallAt ?? 0));

      // ============================================================
      // STREAKS
      // ============================================================

      final streaks = _computeStreaks(heatmapCounts, DateTime.now());

      // ============================================================
      // BUSIEST DAY
      // ============================================================

      final busiestDayEntry = heatmapCounts.entries.isEmpty
          ? null
          : heatmapCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);

      // ============================================================
      // MISSED CALL RATE
      // ============================================================

      final missedCount = callTypeCounts[3] ?? 0;
      final incomingCount = callTypeCounts[1] ?? 0;

      final missedRate = (incomingCount + missedCount) > 0
          ? missedCount / (incomingCount + missedCount)
          : 0.0;

      // ============================================================
      // TAG ANALYTICS
      // ============================================================

      final tagCounts = await _db.getCallCountsByTag(
        since: start,
        until: end,
        contactNumberSuffix: contact,
        callType: type,
      );

      // ============================================================
      // FAVORITE COMPARISON
      // ============================================================

      final favoriteRows =
          await (_db.select(_db.contactDetails)
                ..where((c) => c.isFavorite.equals(true)))
              .get();
      final favoriteNumbers =
          favoriteRows.map((r) => r.normalizedNumber).toSet();

      int favoriteCallCount = 0;
      int otherCallCount = 0;

      for (final summary in includedSummaries) {
        if (favoriteNumbers.contains(summary.normalizedNumber)) {
          favoriteCallCount += summary.callCount;
        } else {
          otherCallCount += summary.callCount;
        }
      }

      final favoriteContactCount = favoriteNumbers.length;
      final otherContactCount = includedSummaries.length - favoriteContactCount;

      final avgCallsPerFavorite =
          favoriteContactCount > 0
              ? favoriteCallCount / favoriteContactCount
              : 0.0;
      final avgCallsPerOther =
          otherContactCount > 0 ? otherCallCount / otherContactCount : 0.0;

      // ============================================================
      // DURATION DISTRIBUTION
      // ============================================================

      final durationDist = await _db.getCallDurationDistribution(
        start,
        end,
        contactNumberSuffix: contact,
      );

      final longestCallWith = await _db.getLongestCallWithNumber(start, end);

      // ============================================================
      // NEW CONTACTS BY MONTH
      // ============================================================

      final newContactsByMonth = await _db.getNewContactsByMonth(start, end);

      // ============================================================
      // ANOMALY DAYS
      // ============================================================

      final anomalyDays = _findAnomalyDays(heatmapCounts);

      // ============================================================
      // RESULT
      // ============================================================

      return AnalyticsSummary(
        totalCalls: totalCalls,
        totalContacts: includedSummaries.length,
        totalTalkSeconds: totalTalkSeconds,

        callsPerDay: callsPerDay,
        durationTrend: durationTrend,
        dayLabels: dayLabels,

        mostContacted: topContacted,
        silentContacts: silentContacts,

        callTypeCounts: callTypeCounts,
        weekdayCounts: weekdayCounts,
        hourCounts: hourCounts,
        tagCounts: tagCounts,

        heatmapData: heatmapCounts,

        currentStreak: streaks['current']!,
        longestStreak: streaks['longest']!,

        longestCallSeconds: longestCallSeconds,

        busiestDayDate: busiestDayEntry?.key,
        busiestDayCount: busiestDayEntry?.value ?? 0,

        missedCallRate: missedRate,

        avgCallsPerFavorite: avgCallsPerFavorite,
        avgCallsPerOther: avgCallsPerOther,
        favoriteContactCount: favoriteContactCount,
        otherContactCount: otherContactCount,

        durationDistribution: durationDist,
        longestCallWith: longestCallWith,
        newContactsByMonth: newContactsByMonth,
        anomalyDays: anomalyDays,
      );
    });
  }

  List<MapEntry<String, int>> _findAnomalyDays(Map<String, int> heatmapCounts) {
    if (heatmapCounts.length < 7) return [];

    final values = heatmapCounts.values.where((v) => v > 0).toList();
    if (values.isEmpty) return [];

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        values.length;
    final stdDev = variance > 0 ? sqrt(variance) : 0;

    if (stdDev == 0) return [];

    return heatmapCounts.entries
        .where((e) => (e.value - mean).abs() > stdDev * 2)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  Map<String, int> _computeStreaks(
    Map<String, int> heatmapCounts,
    DateTime now,
  ) {
    int currentStreak = 0;
    int longestStreak = 0;
    int runningStreak = 0;

    var cursor = DateTime(now.year, now.month, now.day);

    bool stillCountingCurrent = true;

    for (int i = 0; i < 365; i++) {
      final key =
          '${cursor.year.toString().padLeft(4, '0')}-'
          '${cursor.month.toString().padLeft(2, '0')}-'
          '${cursor.day.toString().padLeft(2, '0')}';

      final hasCalls = (heatmapCounts[key] ?? 0) > 0;

      if (hasCalls) {
        runningStreak++;

        if (stillCountingCurrent) {
          currentStreak++;
        }
      } else if (i != 0) {
        stillCountingCurrent = false;
        runningStreak = 0;
      }

      if (runningStreak > longestStreak) {
        longestStreak = runningStreak;
      }

      cursor = cursor.subtract(const Duration(days: 1));
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }
}
