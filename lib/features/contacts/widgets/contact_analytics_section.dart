import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../analytics/widgets/contribution_heatmap.dart';
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
          return const Text(
            'No calls yet.',
            style: TextStyle(color: Colors.grey),
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
                  color: strengthColor.withOpacity(0.15),
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
              spacing: 16,
              runSpacing: 8,
              children: [
                _stat('Total Calls', '$total'),
                _stat('Talk Time', '${totalMinutes}m'),
                _stat('Avg Duration', '${avgSeconds}s'),
                _stat('Incoming', '$incoming'),
                _stat('Outgoing', '$outgoing'),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Relationship',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _stat(
                  'Relationship Age',
                  '${(vitals.relationshipDays / 30).round()}mo',
                ),
                _stat('Avg Gap', '${vitals.averageGapDays.toStringAsFixed(1)}d'),
                _stat('Longest Gap', '${vitals.longestGapDays}d'),
                if (firstCallDateStr != null)
                  _stat('First Called', firstCallDateStr),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Activity',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ContributionHeatmap(countsByDate: stats['heatmap'] as Map<String, int>),

            const SizedBox(height: 16),
            const Text(
              'Talk Ratio',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TalkRatioBar(callTypeCounts: stats['typeCounts'] as Map<int, int>),

            const SizedBox(height: 16),
            const Text(
              'By Hour',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            HourHistogram(hourCounts: stats['hourCounts'] as Map<int, int>),

            const SizedBox(height: 16),
            const Text(
              'By Weekday',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            WeekdayChart(weekdayCounts: stats['weekdayCounts'] as Map<int, int>),
          ],
        );
      },
    );
  }

  void _showWhy(BuildContext context, CommunicationStrength strength) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why "${strength.label}"?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 12),

            ...strength.reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• $reason'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
