import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../contacts/models/contact_summary.dart';
import '../../contacts/screens/contact_detail_screen.dart';
import '../models/analytics_filters.dart';
import '../models/analytics_summary.dart';
import '../models/comparison_config.dart';
import '../repository/analytics_repository.dart';
import '../widgets/contribution_heatmap.dart';
import '../widgets/relationship_web.dart';
import 'comparison_screen.dart';

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

  AnalyticsFilters _filters = const AnalyticsFilters();

  bool _showDuration = false;
  bool _rankByDuration = false;

  String? _selectedContactName;
  String? _selectedTagName;

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

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
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

  Future<void> _pickContactFilter() async {
    final allSummaries = await _repository
        .watchSummary(_deviceContacts, const AnalyticsFilters())
        .first;

    if (!mounted) return;

    final searchController = TextEditingController();

    final selected = await showModalBottomSheet<ContactSummary?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = searchController.text.toLowerCase();

          final filtered = allSummaries.mostContacted
              .where((c) => c.displayName.toLowerCase().contains(query))
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SizedBox(
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Search contact',
                    ),
                    onChanged: (_) {
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final c = filtered[index];

                        return ListTile(
                          title: Text(c.displayName),
                          subtitle: Text('${c.callCount} calls'),
                          onTap: () {
                            Navigator.pop(context, c);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    searchController.dispose();

    if (selected != null) {
      setState(() {
        _filters = _filters.copyWith(
          contactNormalizedNumber: selected.normalizedNumber,
        );

        _selectedContactName = selected.displayName;
      });
    }
  }

  Future<void> _pickTagFilter() async {
    final allTags = await widget.db.getAllTags();

    if (!mounted) return;

    final selected = await showDialog<Tag?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by tag'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('All Tags'),
          ),
          ...allTags.map(
            (tag) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, tag),
              child: Text(tag.name),
            ),
          ),
        ],
      ),
    );

    setState(() {
      if (selected == null) {
        _filters = _filters.copyWith(clearTag: true);
        _selectedTagName = null;
      } else {
        _filters = _filters.copyWith(tagId: selected.id);
        _selectedTagName = selected.name;
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );

    if (range != null) {
      setState(() {
        _filters = _filters.copyWith(
          dateRange: DateRangeOption.custom,
          customStart: range.start,
          customEnd: range.end,
        );
      });
    }
  }

  Future<void> _showComparisonOptions(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('This Month vs Last Month'),
              onTap: () => Navigator.pop(context, 'month'),
            ),
            ListTile(
              title: const Text('This Year vs Last Year'),
              onTap: () => Navigator.pop(context, 'year'),
            ),
            ListTile(
              title: const Text('Contact vs Contact'),
              onTap: () => Navigator.pop(context, 'contact'),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == 'month') {
      _openComparison(ComparisonConfig.thisMonthVsLast());
    } else if (choice == 'year') {
      _openComparison(ComparisonConfig.thisYearVsLast());
    } else if (choice == 'contact') {
      _pickTwoContactsForComparison();
    }
  }

  void _openComparison(ComparisonConfig config) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComparisonScreen(
          db: widget.db,
          deviceContacts: _deviceContacts,
          config: config,
        ),
      ),
    );
  }

  Future<void> _pickTwoContactsForComparison() async {
    final allSummaries = await _repository
        .watchSummary(_deviceContacts, const AnalyticsFilters())
        .first;
    final candidates = allSummaries.mostContacted;

    if (!mounted || candidates.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Need at least 2 contacts with calls.')),
        );
      }
      return;
    }

    final first = await showDialog<ContactSummary>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('First contact'),
        children: candidates
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, c),
                child: Text(c.displayName),
              ),
            )
            .toList(),
      ),
    );

    if (first == null || !mounted) return;

    final second = await showDialog<ContactSummary>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Second contact'),
        children: candidates
            .where((c) => c.normalizedNumber != first.normalizedNumber)
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, c),
                child: Text(c.displayName),
              ),
            )
            .toList(),
      ),
    );

    if (second == null) return;

    _openComparison(
      ComparisonConfig.contacts(
        first.normalizedNumber,
        first.displayName,
        second.normalizedNumber,
        second.displayName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<AnalyticsSummary>(
      stream: _repository.watchSummary(_deviceContacts, _filters),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showComparisonOptions(context),
                icon: const Icon(Icons.compare_arrows, size: 18),
                label: const Text('Compare'),
              ),
            ),

            _buildFilterBar(context),

            const SizedBox(height: 16),

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

            const SizedBox(height: 12),

            Row(
              children: [
                _statCard('🔥 Streak', '${summary.currentStreak}d'),
                const SizedBox(width: 12),
                _statCard('Best Streak', '${summary.longestStreak}d'),
                const SizedBox(width: 12),
                _statCard(
                  'Longest Call',
                  '${(summary.longestCallSeconds / 60).round()}m',
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (summary.busiestDayDate != null)
              Text(
                'Busiest day: ${summary.busiestDayDate} '
                '(${summary.busiestDayCount} calls)',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),

            Text(
              'Missed call rate: '
              '${(summary.missedCallRate * 100).round()}%',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const SizedBox(height: 24),

            const Text(
              'Activity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ContributionHeatmap(
              countsByDate: summary.heatmapData,
              onDayTap: (day, count) {
                _showDayDetail(context, day, count);
              },
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trend',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showDuration = !_showDuration;
                    });
                  },
                  child: Text(_showDuration ? 'Show Count' : 'Show Duration'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _buildBarChart(
              _showDuration
                  ? summary.durationTrend.map((s) => (s / 60).round()).toList()
                  : summary.callsPerDay,
              summary.dayLabels,
            ),

            const SizedBox(height: 24),

            const Text(
              'Talk Ratio',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            _buildTalkRatio(summary.callTypeCounts),

            const SizedBox(height: 24),

            const Text(
              'Answered / Missed / Declined',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            _buildAnsweredMissedDeclined(summary.callTypeCounts),

            const SizedBox(height: 24),

            const Text(
              'Day of Week',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            _buildWeekdayChart(summary.weekdayCounts),

            const SizedBox(height: 24),

            const Text(
              'Busiest Hours',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            _buildHourHistogram(summary.hourCounts),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Most Contacted',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _rankByDuration = !_rankByDuration;
                    });
                  },
                  child: Text(_rankByDuration ? 'By Calls' : 'By Talk Time'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Your Network',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            const Text(
              'Line thickness reflects how often you talk',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const SizedBox(height: 12),

            RelationshipWeb(
              contacts: summary.mostContacted,
              onContactTap: _openContact,
            ),

            const SizedBox(height: 8),

            if (summary.mostContacted.isEmpty)
              const Text('No calls yet.', style: TextStyle(color: Colors.grey))
            else
              ...(_rankByDuration
                      ? ([...summary.mostContacted]..sort(
                          (a, b) => b.totalDuration.compareTo(a.totalDuration),
                        ))
                      : summary.mostContacted)
                  .take(5)
                  .map(
                    (c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.displayName),
                      trailing: Text(
                        _rankByDuration
                            ? '${(c.totalDuration / 60).round()}m'
                            : '${c.callCount} calls',
                      ),
                      onTap: () => _openContact(c),
                    ),
                  ),

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
                            : 'Last called '
                                  '${_daysAgo(c.lastCallAt!)} '
                                  'days ago',
                      ),
                      onTap: () => _openContact(c),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('7d'),
                selected: _filters.dateRange == DateRangeOption.last7,
                onSelected: (_) {
                  setState(() {
                    _filters = _filters.copyWith(
                      dateRange: DateRangeOption.last7,
                    );
                  });
                },
              ),

              const SizedBox(width: 6),

              ChoiceChip(
                label: const Text('30d'),
                selected: _filters.dateRange == DateRangeOption.last30,
                onSelected: (_) {
                  setState(() {
                    _filters = _filters.copyWith(
                      dateRange: DateRangeOption.last30,
                    );
                  });
                },
              ),

              const SizedBox(width: 6),

              ChoiceChip(
                label: const Text('6mo'),
                selected: _filters.dateRange == DateRangeOption.last6Months,
                onSelected: (_) {
                  setState(() {
                    _filters = _filters.copyWith(
                      dateRange: DateRangeOption.last6Months,
                    );
                  });
                },
              ),

              const SizedBox(width: 6),

              ChoiceChip(
                label: const Text('1yr'),
                selected: _filters.dateRange == DateRangeOption.lastYear,
                onSelected: (_) {
                  setState(() {
                    _filters = _filters.copyWith(
                      dateRange: DateRangeOption.lastYear,
                    );
                  });
                },
              ),

              const SizedBox(width: 6),

              ChoiceChip(
                label: const Text('Custom'),
                selected: _filters.dateRange == DateRangeOption.custom,
                onSelected: (_) => _pickCustomDateRange(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickContactFilter,
                icon: const Icon(Icons.person_outline, size: 16),
                label: Text(
                  _selectedContactName ?? 'All Contacts',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            if (_filters.contactNormalizedNumber != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _filters = _filters.copyWith(clearContact: true);
                    _selectedContactName = null;
                  });
                },
              ),

            const SizedBox(width: 8),

            DropdownButton<CallTypeFilter>(
              value: _filters.callType,
              items: CallTypeFilter.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (t) {
                if (t != null) {
                  setState(() {
                    _filters = _filters.copyWith(callType: t);
                  });
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 8),

        OutlinedButton.icon(
          onPressed: _pickTagFilter,
          icon: const Icon(Icons.label_outline, size: 16),
          label: Text(_selectedTagName ?? 'All Tags'),
        ),
      ],
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<int> values, List<String> labels) {
    if (values.isEmpty) {
      return const Text('No data.', style: TextStyle(color: Colors.grey));
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final value = values[index];

          final heightFraction = (value / maxValue).clamp(0.0, 1.0);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(fontSize: 9),
                    maxLines: 1,
                  ),

                  const SizedBox(height: 2),

                  Container(
                    height: 60 * heightFraction,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    labels[index],
                    style: const TextStyle(fontSize: 8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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

    if (total == 0) {
      return const Text('No calls yet.', style: TextStyle(color: Colors.grey));
    }

    final youFraction = outgoing / total;

    final youFlex = (youFraction * 100).round().clamp(1, 99);

    final themFlex = 100 - youFlex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Expanded(
                flex: youFlex,
                child: Container(
                  height: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                flex: themFlex,
                child: Container(height: 20, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'You initiated '
          '${(youFraction * 100).round()}% • '
          'They initiated '
          '${(100 - youFraction * 100).round()}%',
        ),
      ],
    );
  }

  Widget _buildAnsweredMissedDeclined(Map<int, int> counts) {
    final answered = (counts[1] ?? 0) + (counts[2] ?? 0);

    final missed = counts[3] ?? 0;

    final declined = (counts[5] ?? 0) + (counts[6] ?? 0);

    final total = answered + missed + declined;

    if (total == 0) {
      return const Text('No calls yet.', style: TextStyle(color: Colors.grey));
    }

    Widget bar(String label, int value, Color color) {
      final fraction = value / total;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      mainAxisSize: MainAxisSize.min,
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
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final count = weekdayCounts[sqliteOrder[i]] ?? 0;

          final heightFraction = (count / maxCount).clamp(0.0, 1.0);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(fontSize: 9),
                    maxLines: 1,
                  ),

                  const SizedBox(height: 2),

                  Container(
                    height: 50 * heightFraction,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    labels[i],
                    style: const TextStyle(fontSize: 9),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
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

          final heightFraction = (count / maxCount).clamp(0.0, 1.0);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 50 * heightFraction,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
