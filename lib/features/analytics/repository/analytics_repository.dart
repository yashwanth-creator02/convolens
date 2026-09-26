import 'dart:math';

import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../contacts/models/contact_summary.dart';
import '../../contacts/repository/contacts_repository.dart';
import '../models/analytics_filters.dart';
import '../models/analytics_summary.dart';
import '../utils/streak_calculator.dart';

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

      final yearAgo = DateTime.now().subtract(const Duration(days: 364));

      // ============================================================
      // PARALLELIZED DATABASE QUERIES
      // ============================================================
      final results = await Future.wait([
        // 0: ignoredRows
        (_db.select(_db.contactDetails)
              ..where((c) => c.ignoreFromAnalytics.equals(true)))
            .get(),
        // 1: periodCounts
        _db.getCallCountsByPeriod(
          start,
          end,
          periodFormat,
          contactNumberSuffix: contact,
          callType: type,
          tagId: filters.tagId,
        ),
        // 2: durationByPeriod
        _db.getDurationByPeriod(
          start,
          end,
          periodFormat,
          contactNumberSuffix: contact,
          callType: type,
          tagId: filters.tagId,
        ),
        // 3: callTypeCounts
        _db.getCallCountsByType(
          since: start,
          until: end,
          contactNumberSuffix: contact,
          tagId: filters.tagId,
        ),
        // 4: hourCounts
        _db.getCallCountsByHour(
          since: start,
          until: end,
          contactNumberSuffix: contact,
          callType: type,
          tagId: filters.tagId,
        ),
        // 5: weekdayCounts
        _db.getCallCountsByWeekday(
          since: start,
          until: end,
          contactNumberSuffix: contact,
          callType: type,
          tagId: filters.tagId,
        ),
        // 6: longestCallSeconds
        _db.getLongestCallDuration(
          since: start,
          until: end,
          contactNumberSuffix: contact,
          callType: type,
          tagId: filters.tagId,
        ),
        // 7: heatmapCounts
        _db.getCallCountsByPeriod(
          yearAgo,
          DateTime.now(),
          '%Y-%m-%d',
          contactNumberSuffix: contact,
          callType: type,
          tagId: filters.tagId,
        ),
        // 8: allSummaries
        _contactsRepository.watchAllContactSummaries(deviceContacts).first,
        // 9: tagCounts
        _db.getCallCountsByTag(
          since: start,
          until: end,
          contactNumberSuffix: contact,
          callType: type,
        ),
        // 10: favoriteRows
        (_db.select(_db.contactDetails)..where((c) => c.isFavorite.equals(true)))
            .get(),
        // 11: durationDist
        _db.getCallDurationDistribution(
          start,
          end,
          contactNumberSuffix: contact,
        ),
        // 12: longestCallWith
        _db.getLongestCallWithNumber(start, end),
        // 13: newContactsByMonth
        _db.getNewContactsByMonth(start, end),
      ]);

      final ignoredRows = results[0] as List<ContactDetail>;
      final periodCounts = results[1] as Map<String, int>;
      final durationByPeriod = results[2] as Map<String, int>;
      final callTypeCounts = results[3] as Map<int, int>;
      final hourCounts = results[4] as Map<int, int>;
      final weekdayCounts = results[5] as Map<int, int>;
      final longestCallSeconds = results[6] as int;
      final heatmapCounts = results[7] as Map<String, int>;
      final allSummaries = results[8] as List<ContactSummary>;
      final tagCounts = results[9] as Map<String, int>;
      final favoriteRows = results[10] as List<ContactDetail>;
      final durationDist = results[11] as Map<String, int>;
      final longestCallWith = results[12] as Map<String, dynamic>?;
      final newContactsByMonth = results[13] as Map<String, int>;

      final ignoredNumbers = ignoredRows.map((r) => r.normalizedNumber).toSet();

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

      final withInitiationData = includedSummaries.where(
        (s) => (s.incoming + s.outgoing) > 0,
      );

      final theyInitiateMore =
          withInitiationData.where((s) => s.incoming > s.outgoing).toList()
            ..sort((a, b) => b.incoming.compareTo(a.incoming));

      final youInitiateMore =
          withInitiationData.where((s) => s.outgoing > s.incoming).toList()
            ..sort((a, b) => b.outgoing.compareTo(a.outgoing));

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

      final streaks = computeStreaks(heatmapCounts, DateTime.now());

      // ============================================================
      // BUSIEST DAY
      // ============================================================

      final busiestDayEntry = heatmapCounts.entries.isEmpty
          ? null
          : heatmapCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);

      // ============================================================
      // MISSED CALL RATE & ANSWER RATE
      // ============================================================

      final missedCount = callTypeCounts[3] ?? 0;
      final incomingCount = callTypeCounts[1] ?? 0;

      final missedRate = (incomingCount + missedCount) > 0
          ? missedCount / (incomingCount + missedCount)
          : 0.0;

      final answeredCount =
          (callTypeCounts[1] ?? 0) + (callTypeCounts[2] ?? 0);
      final answerRate = totalCalls > 0
          ? (answeredCount / totalCalls) * 100
          : 0.0;

      // ============================================================
      // FAVORITE COMPARISON
      // ============================================================

      final favoriteNumbers = favoriteRows
          .map((r) => r.normalizedNumber)
          .toSet();

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

      final avgCallsPerFavorite = favoriteContactCount > 0
          ? favoriteCallCount / favoriteContactCount
          : 0.0;
      final avgCallsPerOther = otherContactCount > 0
          ? otherCallCount / otherContactCount
          : 0.0;

      // ============================================================
      // ANOMALY DAYS
      // ============================================================

      final anomalyDays = _findAnomalyDays(heatmapCounts);

      // ============================================================
      // SOCIAL METER COMPUTATIONS
      // ============================================================

      final socialScoreData = _computeSocialScore(
        heatmapCounts: heatmapCounts,
        includedSummaries: includedSummaries,
        callTypeCounts: callTypeCounts,
        missedRate: missedRate,
        now: DateTime.now(),
      );

      final socialMomentum = _computeMomentum(heatmapCounts, DateTime.now());

      final weekendCalls = (weekdayCounts[0] ?? 0) + (weekdayCounts[6] ?? 0);
      int weekdayCalls = 0;
      for (int i = 1; i <= 5; i++) {
        weekdayCalls += weekdayCounts[i] ?? 0;
      }

      final totalWeekdayWeekend = weekendCalls + weekdayCalls;
      final weekendCallPercentage = totalWeekdayWeekend > 0
          ? (weekendCalls / totalWeekdayWeekend) * 100
          : 0.0;

      int maxWindowSum = -1;
      int bestStartHour = 9;
      for (int h = 0; h < 24; h++) {
        final nextH = (h + 1) % 24;
        final sum = (hourCounts[h] ?? 0) + (hourCounts[nextH] ?? 0);
        if (sum > maxWindowSum) {
          maxWindowSum = sum;
          bestStartHour = h;
        }
      }
      String formatHour(int hour) {
        if (hour == 0) return '12 AM';
        if (hour < 12) return '$hour AM';
        if (hour == 12) return '12 PM';
        return '${hour - 12} PM';
      }
      final endHour = (bestStartHour + 2) % 24;
      final peakHourWindow = totalCalls > 0
          ? '${formatHour(bestStartHour)} – ${formatHour(endHour)}'
          : 'None';

      final personalityLabels = _inferPersonality(
        hourCounts: hourCounts,
        weekendCalls: weekendCalls,
        weekdayCalls: weekdayCalls,
        totalCalls: totalCalls,
        totalTalkSeconds: totalTalkSeconds,
        currentStreak: streaks.current,
        longestStreak: streaks.longest,
      );

      final relationshipTiers = _buildRelationshipTiers(includedSummaries);

      final driftingContacts = silentContacts
          .where((c) => c.callCount >= 3)
          .toList()
        ..sort((a, b) => b.callCount.compareTo(a.callCount));

      final networkConcentration = _computeNetworkConcentration(
        includedSummaries,
        totalCalls,
      );

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

        currentStreak: streaks.current,
        longestStreak: streaks.longest,

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
        theyInitiateMore: theyInitiateMore.take(10).toList(),
        youInitiateMore: youInitiateMore.take(10).toList(),

        socialHealthScore: socialScoreData.score,
        socialHealthLabel: socialScoreData.label,
        scoreBreakdown: socialScoreData.breakdown,
        socialMomentum: socialMomentum,
        personalityLabels: personalityLabels,
        relationshipTiers: relationshipTiers,
        driftingContacts: driftingContacts,
        networkConcentration: networkConcentration,
        weekendCalls: weekendCalls,
        weekdayCalls: weekdayCalls,
        answerRate: answerRate,
        peakHourWindow: peakHourWindow,
        weekendCallPercentage: weekendCallPercentage,
      );
    });
  }

  // ============================================================
  // SOCIAL METER HELPERS
  // ============================================================

  _SocialScoreResult _computeSocialScore({
    required Map<String, int> heatmapCounts,
    required List<ContactSummary> includedSummaries,
    required Map<int, int> callTypeCounts,
    required double missedRate,
    required DateTime now,
  }) {
    // 1. Frequency (0-25 pts): Calls in the last 30 days
    int callsLast30 = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < 30; i++) {
      final key =
          '${cursor.year.toString().padLeft(4, '0')}-'
          '${cursor.month.toString().padLeft(2, '0')}-'
          '${cursor.day.toString().padLeft(2, '0')}';
      callsLast30 += heatmapCounts[key] ?? 0;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    final callsPerWeek = callsLast30 / 4.28;
    final freqScore = (callsPerWeek / 7.0).clamp(0.0, 1.0) * 25.0;

    // 2. Diversity (0-25 pts): Unique contacts contacted in summaries
    final activeContacts = includedSummaries.where((c) => c.callCount > 0).length;
    final divScore = (activeContacts / 10.0).clamp(0.0, 1.0) * 25.0;

    // 3. Reciprocity (0-25 pts): Incoming vs Outgoing balance
    final incoming = callTypeCounts[1] ?? 0;
    final outgoing = callTypeCounts[2] ?? 0;
    final inOutTotal = incoming + outgoing;
    double recipScore = 12.5; // neutral baseline
    if (inOutTotal > 0) {
      final ratio = incoming / inOutTotal;
      final dev = (ratio - 0.5).abs(); // 0.0 to 0.5
      recipScore = ((0.5 - dev) / 0.5).clamp(0.0, 1.0) * 25.0;
    }

    // 4. Responsiveness (0-25 pts): Missed call rate
    final respScore = (1.0 - missedRate).clamp(0.0, 1.0) * 25.0;

    final totalScore = (freqScore + divScore + recipScore + respScore).round().clamp(0, 100);

    String label;
    if (totalScore >= 80) {
      label = 'Thriving';
    } else if (totalScore >= 60) {
      label = 'Active';
    } else if (totalScore >= 40) {
      label = 'Connected';
    } else if (totalScore >= 20) {
      label = 'Quiet';
    } else {
      label = 'Isolated';
    }

    return _SocialScoreResult(
      score: totalScore,
      label: label,
      breakdown: {
        'Frequency': freqScore,
        'Diversity': divScore,
        'Reciprocity': recipScore,
        'Responsiveness': respScore,
      },
    );
  }

  double _computeMomentum(Map<String, int> heatmapCounts, DateTime now) {
    int recent14 = 0;
    int previous14 = 0;

    var cursor = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < 14; i++) {
      final key =
          '${cursor.year.toString().padLeft(4, '0')}-'
          '${cursor.month.toString().padLeft(2, '0')}-'
          '${cursor.day.toString().padLeft(2, '0')}';
      recent14 += heatmapCounts[key] ?? 0;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    for (int i = 0; i < 14; i++) {
      final key =
          '${cursor.year.toString().padLeft(4, '0')}-'
          '${cursor.month.toString().padLeft(2, '0')}-'
          '${cursor.day.toString().padLeft(2, '0')}';
      previous14 += heatmapCounts[key] ?? 0;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    if (previous14 == 0) {
      return recent14 > 0 ? 1.0 : 0.0;
    }

    return (recent14 - previous14) / previous14;
  }

  List<String> _inferPersonality({
    required Map<int, int> hourCounts,
    required int weekendCalls,
    required int weekdayCalls,
    required int totalCalls,
    required int totalTalkSeconds,
    required int currentStreak,
    required int longestStreak,
  }) {
    if (totalCalls == 0) {
      return ['Fresh Start'];
    }

    final labels = <String>[];

    // Peak hour
    if (hourCounts.isNotEmpty) {
      final peakHour = hourCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      if (peakHour >= 6 && peakHour <= 11) {
        labels.add('Morning Caller');
      } else if (peakHour >= 12 && peakHour <= 16) {
        labels.add('Afternoon Caller');
      } else if (peakHour >= 17 && peakHour <= 20) {
        labels.add('Evening Caller');
      } else {
        labels.add('Night Owl');
      }
    }

    // Weekend vs Weekday
    final totalWeek = weekendCalls + weekdayCalls;
    if (totalWeek >= 4) {
      final weekendRatio = weekendCalls / totalWeek;
      if (weekendRatio >= 0.35) {
        labels.add('Weekend Warrior');
      } else if (weekdayCalls / totalWeek >= 0.85) {
        labels.add('Weekday Pro');
      }
    }

    // Call length style
    final avgDuration = totalTalkSeconds / max(totalCalls, 1);
    if (avgDuration >= 480) {
      labels.add('Deep Talker');
    } else if (avgDuration <= 90 && totalCalls >= 3) {
      labels.add('Quick Check-in');
    }

    // Consistency
    if (currentStreak >= 5) {
      labels.add('Consistent');
    } else if (longestStreak >= 10) {
      labels.add('Streak Builder');
    }

    if (labels.isEmpty) {
      labels.add('Balanced Caller');
    }

    return labels;
  }

  Map<String, List<ContactSummary>> _buildRelationshipTiers(
    List<ContactSummary> summaries,
  ) {
    final inner = <ContactSummary>[];
    final close = <ContactSummary>[];
    final regular = <ContactSummary>[];
    final dormant = <ContactSummary>[];

    for (final c in summaries) {
      if (c.callCount >= 10) {
        inner.add(c);
      } else if (c.callCount >= 4) {
        close.add(c);
      } else if (c.callCount >= 1) {
        regular.add(c);
      } else {
        dormant.add(c);
      }
    }

    // Sort tiers by call count descending
    inner.sort((a, b) => b.callCount.compareTo(a.callCount));
    close.sort((a, b) => b.callCount.compareTo(a.callCount));
    regular.sort((a, b) => b.callCount.compareTo(a.callCount));

    return {
      'inner': inner,
      'close': close,
      'regular': regular,
      'dormant': dormant,
    };
  }

  double _computeNetworkConcentration(
    List<ContactSummary> summaries,
    int totalCalls,
  ) {
    if (totalCalls == 0) return 0.0;
    double sumSq = 0.0;
    for (final c in summaries) {
      if (c.callCount > 0) {
        final share = c.callCount / totalCalls;
        sumSq += share * share;
      }
    }
    return sumSq.clamp(0.0, 1.0);
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


}

class _SocialScoreResult {
  final int score;
  final String label;
  final Map<String, double> breakdown;

  const _SocialScoreResult({
    required this.score,
    required this.label,
    required this.breakdown,
  });
}

