import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../analytics/models/analytics_filters.dart';
import '../../analytics/widgets/contribution_heatmap.dart';
import '../../analytics/widgets/heatmap_day_detail_sheet.dart';
import '../../analytics/widgets/hour_histogram.dart';
import '../../analytics/widgets/talk_ratio_bar.dart';
import '../../analytics/widgets/weekday_chart.dart';
import '../utils/communication_strength.dart';
import '../utils/relationship_vitals.dart';

class ContactAnalyticsSection extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;

  const ContactAnalyticsSection({
    super.key,
    required this.normalizedNumber,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: () async {
        final now = DateTime.now();
        final yearAgo = now.subtract(const Duration(days: 364));

        final statsFuture = db.getContactCallStats(normalizedNumber);
        final firstCallTsFuture = db.getFirstCallTimestamp(normalizedNumber);
        final heatmapFuture = db.getCallCountsByPeriod(
          yearAgo,
          now,
          '%Y-%m-%d',
          contactNumberSuffix: normalizedNumber,
        );
        final hourCountsFuture = db.getCallCountsByHour(
          since: yearAgo,
          until: now,
          contactNumberSuffix: normalizedNumber,
        );
        final weekdayCountsFuture = db.getCallCountsByWeekday(
          since: yearAgo,
          until: now,
          contactNumberSuffix: normalizedNumber,
        );
        final typeCountsFuture = db.getCallCountsByType(
          since: yearAgo,
          until: now,
          contactNumberSuffix: normalizedNumber,
        );
        final timestampsFuture = db.getCallTimestampsForNumber(normalizedNumber);
        final callbackFuture = db.getCallbackLatencyStats(
          contactNumberSuffix: normalizedNumber,
        );

        final results = await Future.wait([
          statsFuture,
          firstCallTsFuture,
          heatmapFuture,
          hourCountsFuture,
          weekdayCountsFuture,
          typeCountsFuture,
          timestampsFuture,
          callbackFuture,
        ]);

        final stats = results[0] as Map<String, dynamic>;
        final firstCallTs = results[1] as int?;
        final heatmap = results[2] as Map<String, int>;
        final hourCounts = results[3] as Map<int, int>;
        final weekdayCounts = results[4] as Map<int, int>;
        final typeCounts = results[5] as Map<int, int>;
        final timestamps = results[6] as List<int>;
        final callbackStats = results[7] as Map<String, dynamic>;
        final vitals = computeVitals(timestamps);

        return {
          ...stats,
          'firstCallTs': firstCallTs,
          'heatmap': heatmap,
          'hourCounts': hourCounts,
          'weekdayCounts': weekdayCounts,
          'typeCounts': typeCounts,
          'timestamps': timestamps,
          'callbackStats': callbackStats,
          'vitals': vitals,
        };
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final total = stats['total'] as int;

        if (total == 0) {
          final scheme = Theme.of(context).colorScheme;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No analytics data yet',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Call stats and charts will generate as you communicate',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        final totalDuration = stats['totalDuration'] as int;
        final avgDuration = stats['avgDuration'] as double;
        final incoming = stats['incoming'] as int;
        final outgoing = stats['outgoing'] as int;

        final firstCallTs =
            stats['firstCallTs'] as int? ??
            DateTime.now().millisecondsSinceEpoch;

        final lastCallTs = stats['lastCallAt'] as int?;

        final strength = computeStrength(
          callCount: total,
          lastCallAt: lastCallTs,
          firstCallAt: firstCallTs,
          totalDurationSeconds: totalDuration,
        );

        final strengthColor = switch (strength.level) {
          StrengthLevel.strong => Colors.green,
          StrengthLevel.steady => Colors.blue,
          StrengthLevel.fading => Colors.orange,
          StrengthLevel.new_ => Colors.purple,
          StrengthLevel.dormant => Colors.grey,
        };

        final totalMinutes = (totalDuration / 60).round();
        final avgSeconds = avgDuration.round();

        final typeCounts = stats['typeCounts'] as Map<int, int>? ?? const {};
        final answeredCalls = (typeCounts[1] ?? 0) + (typeCounts[2] ?? 0);
        final answerRate = total > 0 ? ((answeredCalls / total) * 100).round() : 0;

        final hourCounts = stats['hourCounts'] as Map<int, int>? ?? const {};
        String peakHourWindow = '';
        int bestHourCount = 0;
        int bestStartHour = -1;
        for (int h = 0; h < 24; h++) {
          final count = (hourCounts[h] ?? 0) + (hourCounts[(h + 1) % 24] ?? 0);
          if (count > bestHourCount && count > 0) {
            bestHourCount = count;
            bestStartHour = h;
          }
        }
        if (bestStartHour != -1 && bestHourCount > 0) {
          final endHour = (bestStartHour + 2) % 24;
          final startStr = _formatHour(bestStartHour);
          final endStr = _formatHour(endHour);
          peakHourWindow = '$startStr – $endStr';
        }

        final weekdayCounts = stats['weekdayCounts'] as Map<int, int>? ?? const {};
        int weekdayCalls = 0;
        int weekendCalls = 0;
        weekdayCounts.forEach((weekday, count) {
          if (weekday >= 1 && weekday <= 5) {
            weekdayCalls += count;
          } else {
            weekendCalls += count;
          }
        });
        final totalDays = weekdayCalls + weekendCalls;
        final weekendPct = totalDays > 0 ? ((weekendCalls / totalDays) * 100).round() : 0;

        final callbackStats =
            stats['callbackStats'] as Map<String, dynamic>? ?? const {};
        final totalMissed = (callbackStats['totalMissed'] as int?) ?? 0;
        final returnedCount = (callbackStats['returnedCount'] as int?) ?? 0;
        final returnRate =
            (callbackStats['returnRate'] as num?)?.toDouble() ?? 100.0;
        final latencyMinutes =
            (callbackStats['avgLatencyMinutes'] as num?)?.toDouble() ?? 0.0;
        final latencyStr =
            totalMissed == 0
                ? 'Instant'
                : (returnedCount == 0
                    ? 'N/A'
                    : (latencyMinutes < 1
                        ? '< 1m'
                        : (latencyMinutes < 60
                            ? '${latencyMinutes.round()}m'
                            : '${(latencyMinutes / 60).toStringAsFixed(1)}h')));

        final connected = incoming + outgoing;
        final youInitiatedPct =
            connected > 0 ? ((outgoing / connected) * 100).round() : 50;

        int bestWeekday = -1;
        int maxWeekdayCount = 0;
        weekdayCounts.forEach((weekday, count) {
          if (count > maxWeekdayCount) {
            maxWeekdayCount = count;
            bestWeekday = weekday;
          }
        });
        const weekdayNames = [
          'Sundays',
          'Mondays',
          'Tuesdays',
          'Wednesdays',
          'Thursdays',
          'Fridays',
          'Saturdays',
        ];
        final bestDayName =
            (bestWeekday >= 0 && bestWeekday < 7)
                ? weekdayNames[bestWeekday]
                : '';
        final recommendedTime =
            (bestDayName.isNotEmpty && peakHourWindow.isNotEmpty)
                ? '$bestDayName, $peakHourWindow'
                : (peakHourWindow.isNotEmpty ? peakHourWindow : '');

        final vitals = stats['vitals'] as RelationshipVitals;

        final firstCallDate = stats['firstCallTs'] != null
            ? DateTime.fromMillisecondsSinceEpoch(stats['firstCallTs'] as int)
            : null;

        final firstCallDateStr = firstCallDate != null
            ? '${firstCallDate.day}/${firstCallDate.month}/${firstCallDate.year}'
            : null;

        final scheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _showWhy(context, strength),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: strengthColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: strengthColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strength.label,
                      style: TextStyle(
                        color: strengthColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline, size: 14, color: strengthColor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _stat(context, 'Total Calls', '$total'),
                _stat(context, 'Talk Time', '${totalMinutes}m'),
                _stat(context, 'Avg Duration', '${avgSeconds}s'),
                _stat(context, 'Incoming', '$incoming'),
                _stat(context, 'Outgoing', '$outgoing'),
                _stat(context, 'Answer Rate', '$answerRate%'),
                _stat(context, 'You Initiated', '$youInitiatedPct%'),
                _stat(context, 'Callback Latency', latencyStr),
                _stat(context, 'Return Rate', '${returnRate.round()}%'),
                if (peakHourWindow.isNotEmpty)
                  _stat(context, 'Peak Time', peakHourWindow),
                if (totalDays > 0)
                  _stat(context, 'Weekend Calls', '$weekendPct%'),
              ],
            ),

            if (recommendedTime.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.12),
                      scheme.secondary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BEST TIME TO CALL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            recommendedTime,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            _sectionTitle(context, 'RELATIONSHIP VITALS'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _stat(
                  context,
                  'Relationship Age',
                  '${(vitals.relationshipDays / 30).round()}mo',
                ),
                _stat(context, 'Avg Gap', '${vitals.averageGapDays.toStringAsFixed(1)}d'),
                _stat(context, 'Longest Gap', '${vitals.longestGapDays}d'),
                if (firstCallDateStr != null)
                  _stat(context, 'First Called', firstCallDateStr),
              ],
            ),

            const SizedBox(height: 24),
            _sectionTitle(context, 'ACTIVITY HEATMAP'),
            const SizedBox(height: 8),
            ContributionHeatmap(
              countsByDate: stats['heatmap'] as Map<String, int>,
              onDayTap: (day, count) async {
                await GlassModalSheet.show(
                  context: context,
                  quality: GlassQuality.standard,
                  detents: const {
                    GlassSheetDetent.medium,
                    GlassSheetDetent.large,
                  },
                  initialState: GlassSheetState.half,
                  builder: (context) => HeatmapDayDetailSheet(
                    day: day,
                    count: count,
                    db: db,
                    filters: AnalyticsFilters(
                      contactNormalizedNumber: normalizedNumber,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            _sectionTitle(context, 'TALK RATIO'),
            const SizedBox(height: 8),
            TalkRatioBar(callTypeCounts: stats['typeCounts'] as Map<int, int>),

            const SizedBox(height: 20),
            _sectionTitle(
              context,
              peakHourWindow.isNotEmpty
                  ? 'BY HOUR OF DAY • PEAK: $peakHourWindow'
                  : 'BY HOUR OF DAY',
            ),
            const SizedBox(height: 8),
            HourHistogram(hourCounts: stats['hourCounts'] as Map<int, int>),

            const SizedBox(height: 20),
            _sectionTitle(
              context,
              totalDays > 0
                  ? 'BY WEEKDAY • $weekdayCalls WORKDAY / $weekendCalls WEEKEND'
                  : 'BY WEEKDAY',
            ),
            const SizedBox(height: 8),
            WeekdayChart(weekdayCounts: stats['weekdayCounts'] as Map<int, int>),
          ],
        );
      },
    );
  }

  void _showWhy(BuildContext context, CommunicationStrength strength) {
    final scheme = Theme.of(context).colorScheme;
    GlassModalSheet.show(
      context: context,
      quality: GlassQuality.standard,
      detents: const {GlassSheetDetent.medium},
      initialState: GlassSheetState.half,
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.insights_rounded,
                          size: 20,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Why "${strength.label}"?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              'Connection strength breakdown',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...strength.reasons.map(
                    (reason) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: scheme.onSurface,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _sectionTitle(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatHour(int h) {
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    final period = h < 12 ? 'AM' : 'PM';
    return '$hour12 $period';
  }
}
