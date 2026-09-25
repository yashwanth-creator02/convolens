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
        final stats = await db.getContactCallStats(normalizedNumber);
        final firstCallTs = await db.getFirstCallTimestamp(normalizedNumber);

        final now = DateTime.now();
        final yearAgo = now.subtract(const Duration(days: 364));

        final heatmap = await db.getCallCountsByPeriod(
          yearAgo,
          now,
          '%Y-%m-%d',
          contactNumberSuffix: normalizedNumber,
        );

        final hourCounts = await db.getCallCountsByHour(
          since: yearAgo,
          until: now,
          contactNumberSuffix: normalizedNumber,
        );

        final weekdayCounts = await db.getCallCountsByWeekday(
          since: yearAgo,
          until: now,
          contactNumberSuffix: normalizedNumber,
        );

        final typeCounts = await db.getCallCountsByType(
          since: yearAgo,
          until: now,
          contactNumberSuffix: normalizedNumber,
        );

        final timestamps = await db.getCallTimestampsForNumber(normalizedNumber);
        final vitals = computeVitals(timestamps);

        return {
          ...stats,
          'firstCallTs': firstCallTs,
          'heatmap': heatmap,
          'hourCounts': hourCounts,
          'weekdayCounts': weekdayCounts,
          'typeCounts': typeCounts,
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

        final vitals = stats['vitals'] as RelationshipVitals;

        final firstCallDate = stats['firstCallTs'] != null
            ? DateTime.fromMillisecondsSinceEpoch(stats['firstCallTs'] as int)
            : null;

        final firstCallDateStr = firstCallDate != null
            ? '${firstCallDate.day}/${firstCallDate.month}/${firstCallDate.year}'
            : null;

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
              ],
            ),

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
            _sectionTitle(context, 'BY HOUR OF DAY'),
            const SizedBox(height: 8),
            HourHistogram(hourCounts: stats['hourCounts'] as Map<int, int>),

            const SizedBox(height: 20),
            _sectionTitle(context, 'BY WEEKDAY'),
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
}
