import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../contacts/models/contact_summary.dart';
import '../../contacts/screens/contact_detail_screen.dart';
import '../models/analytics_summary.dart';
import '../repository/analytics_repository.dart';
import '../widgets/contribution_heatmap.dart';

class AnalyticsScreen extends StatefulWidget {
  final AppDatabase db;

  const AnalyticsScreen({super.key, required this.db});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsRepository _repository;
  List<Contact> _deviceContacts = [];
  bool _loading = true;
  String _selectedRange = 'week';

  @override
  void initState() {
    super.initState();
    _repository = AnalyticsRepository(widget.db);
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      _deviceContacts = await FlutterContacts.getContacts(withProperties: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openContact(ContactSummary contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(
          normalizedNumber: contact.normalizedNumber,
          displayName: contact.displayName,
          displayNumber: contact.displayNumber,
          deviceContact: contact.deviceContact,
          db: widget.db,
        ),
      ),
    );
  }

  void _showDayDetail(BuildContext context, DateTime day, int count) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${day.day}/${day.month}/${day.year}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              count == 0
                  ? 'No calls this day.'
                  : '$count call${count == 1 ? '' : 's'}',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<AnalyticsSummary>(
      stream: _repository.watchSummary(_deviceContacts, range: _selectedRange),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _statCard('Calls', '${summary.totalCalls}'),
                const SizedBox(width: 12),
                _statCard('Contacts', '${summary.totalContacts}'),
                const SizedBox(width: 12),
                _statCard(
                  'Talk Time',
                  '${(summary.totalTalkSeconds / 60).round()}m',
                ),
              ],
            ),

            const SizedBox(height: 24),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'week', label: Text('Week')),
                ButtonSegment(value: 'month', label: Text('Month')),
                ButtonSegment(value: 'year', label: Text('Year')),
              ],
              selected: {_selectedRange},
              onSelectionChanged: (selection) {
                setState(() => _selectedRange = selection.first);
              },
            ),

            const SizedBox(height: 12),
            const Text(
              'Calls — Last 14 Days',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBarChart(summary),

            const SizedBox(height: 24),
            const Text(
              'Activity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ContributionHeatmap(
              countsByDate: summary.heatmapData,
              onDayTap: (day, count) => _showDayDetail(context, day, count),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                _statCard('🔥 Streak', '${summary.currentStreak}d'),
                const SizedBox(width: 12),
                _statCard('Best Streak', '${summary.longestStreak}d'),
                const SizedBox(width: 12),
                _statCard(
                  'Longest Call',
                  '${(int.tryParse(summary.longestCallSeconds ?? '0') ?? 0) ~/ 60}m',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (summary.busiestDayDate != null)
              Text('Busiest day: ${summary.busiestDayDate} (${summary.busiestDayCount} calls)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text('Missed call rate: ${(summary.missedCallRate * 100).round()}%',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),

            const SizedBox(height: 24),
            const Text('Busiest Hours', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildHourHistogram(summary.hourCounts),

            const SizedBox(height: 24),
            const Text('Talk Ratio', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTalkRatio(summary.callTypeCounts),

            const SizedBox(height: 24),
            const Text('Answered / Missed / Declined', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildAnsweredMissedDeclined(summary.callTypeCounts),

            const SizedBox(height: 24),
            const Text('Day of Week', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildWeekdayChart(summary.weekdayCounts),

            const SizedBox(height: 24),
            const Text(
              'Call Types',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTypeBreakdown(summary.callTypeCounts),

            const SizedBox(height: 24),
            const Text('By Tag', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (summary.tagCounts.isEmpty)
              const Text(
                'No tagged calls yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...summary.tagCounts.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(entry.key), Text('${entry.value}')],
                  ),
                ),
              ),

            const SizedBox(height: 24),
            const Text(
              'Most Contacted',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (summary.mostContacted.isEmpty)
              const Text('No calls yet.', style: TextStyle(color: Colors.grey))
            else
              ...summary.mostContacted.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.displayName),
                  trailing: Text('${c.callCount} calls'),
                  onTap: () => _openContact(c),
                ),
              ),

            const SizedBox(height: 24),
            const Text(
              "Haven't Talked To In A While",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Contacts you have saved but rarely or never call',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (summary.silentContacts.isEmpty)
              const Text(
                "You're in touch with everyone!",
                style: TextStyle(color: Colors.grey),
              )
            else
              ...summary.silentContacts
                  .take(10)
                  .map(
                    (c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.displayName),
                      subtitle: Text(
                        c.lastCallAt == null
                            ? 'Never called'
                            : 'Last called ${_daysAgo(c.lastCallAt!)} days ago',
                      ),
                      onTap: () => _openContact(c),
                    ),
                  ),
          ],
        );
      },
    );
  }

  int _daysAgo(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(date).inDays;
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(AnalyticsSummary summary) {
    final maxValue = summary.callsPerDay.isEmpty
        ? 1
        : summary.callsPerDay.reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(summary.callsPerDay.length, (index) {
          final value = summary.callsPerDay[index];
          final heightFraction = value / maxValue;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$value', style: const TextStyle(fontSize: 9)),
                  Container(
                    height: 60 * heightFraction,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.dayLabels[index],
                    style: const TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTypeBreakdown(Map<int, int> counts) {
    const labels = {
      1: 'Incoming',
      2: 'Outgoing',
      3: 'Missed',
      4: 'Voicemail',
      5: 'Rejected',
      6: 'Blocked',
    };
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0)
      return const Text('No calls yet.', style: TextStyle(color: Colors.grey));

    return Column(
      children: counts.entries.map((entry) {
        final label = labels[entry.key] ?? 'Unknown';
        final fraction = entry.value / total;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label — ${entry.value} (${(fraction * 100).round()}%)',
                style: const TextStyle(fontSize: 12),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: fraction, minHeight: 6),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHourHistogram(Map<int, int> hourCounts) {
    final maxCount = hourCounts.values.isEmpty
        ? 1
        : hourCounts.values.reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(24, (hour) {
          final count = hourCounts[hour] ?? 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
              child: Container(
                height: 50 * (count / maxCount),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTalkRatio(Map<int, int> counts) {
    final outgoing = counts[2] ?? 0;
    final incoming = counts[1] ?? 0;
    final total = outgoing + incoming;

    if (total == 0) return const Text('No calls yet.', style: TextStyle(color: Colors.grey));

    final youFraction = outgoing / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Expanded(
                flex: (youFraction * 100).round().clamp(1, 99),
                child: Container(height: 20, color: Theme.of(context).colorScheme.primary),
              ),
              Expanded(
                flex: 100 - (youFraction * 100).round().clamp(1, 99),
                child: Container(height: 20, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('You initiated ${(youFraction * 100).round()}% • They initiated '
            '${(100 - youFraction * 100).round()}%'),
      ],
    );
  }

  Widget _buildAnsweredMissedDeclined(Map<int, int> counts) {
    final answered = (counts[1] ?? 0) + (counts[2] ?? 0);
    final missed = counts[3] ?? 0;
    final declined = (counts[5] ?? 0) + (counts[6] ?? 0);
    final total = answered + missed + declined;

    if (total == 0) return const Text('No calls yet.', style: TextStyle(color: Colors.grey));

    Widget bar(String label, int value, Color color) {
      final fraction = value / total;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label — $value', style: const TextStyle(fontSize: 12)),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        bar('Answered', answered, Colors.green),
        bar('Missed', missed, Colors.orange),
        bar('Declined', declined, Colors.red),
      ],
    );
  }

  Widget _buildWeekdayChart(Map<int, int> weekdayCounts) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const sqliteOrder = [1, 2, 3, 4, 5, 6, 0];

    final maxCount = weekdayCounts.values.isEmpty
        ? 1
        : weekdayCounts.values.reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final count = weekdayCounts[sqliteOrder[i]] ?? 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$count', style: const TextStyle(fontSize: 9)),
                  Container(
                    height: 50 * (count / maxCount),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(labels[i], style: const TextStyle(fontSize: 9)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
