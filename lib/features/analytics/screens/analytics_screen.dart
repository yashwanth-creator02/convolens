import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../contacts/models/contact_summary.dart';
import '../../contacts/screens/contact_detail_screen.dart';
import '../models/analytics_filters.dart';
import '../models/analytics_summary.dart';
import '../models/comparison_config.dart';
import '../repository/analytics_repository.dart';
import '../widgets/answered_missed_declined_bars.dart';
import '../widgets/calendar_grid_heatmap.dart';
import '../widgets/contribution_heatmap.dart';
import '../widgets/hour_clock_face.dart';
import '../widgets/hour_histogram.dart';
import '../widgets/relationship_web.dart';
import '../widgets/talk_ratio_bar.dart';
import '../widgets/weekday_chart.dart';
import '../widgets/analytics_filter_sheet.dart';
import 'comparison_screen.dart';
import 'yearly_recap_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  final AppDatabase db;
  final GlassLargeTitleController titleController;

  const AnalyticsScreen({
    super.key,
    required this.db,
    required this.titleController,
  });

  @override
  State<AnalyticsScreen> createState() => AnalyticsScreenState();
}

class AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsRepository repository;

  List<Contact> deviceContacts = [];
  bool _loading = true;

  AnalyticsFilters filters = const AnalyticsFilters();

  int _selectedTab = 0;

  bool _showDuration = false;
  bool _rankByDuration = false;
  bool _useClockFace = false;
  bool _useCalendarGrid = false;

  String? selectedContactName;
  String? selectedTagName;

  @override
  void initState() {
    super.initState();

    repository = AnalyticsRepository(widget.db);

    _loadContacts();
  }

  Future<void> openFilters() => _showFilters();

  void applyFilters(AnalyticsFilters result) {
    if (!mounted) return;
    setState(() {
      filters = result;
      _updateSelectedNames();
    });
  }

  Future<void> _showFilters() async {
    final result = await showModalBottomSheet<AnalyticsFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnalyticsFilterSheet(
        db: widget.db,
        repository: repository,
        deviceContacts: deviceContacts,
        initialFilters: filters,
        initialContactName: selectedContactName,
        initialTagName: selectedTagName,
      ),
    );

    if (result != null) {
      applyFilters(result);
    }
  }

  Future<void> _updateSelectedNames() async {
    if (filters.contactNormalizedNumber != null) {
      final summary = await repository
          .watchSummary(
            deviceContacts,
            AnalyticsFilters(
              contactNormalizedNumber: filters.contactNormalizedNumber,
            ),
          )
          .first;
      if (mounted) {
        setState(() {
          selectedContactName = summary.mostContacted.firstOrNull?.displayName;
        });
      }
    } else {
      setState(() {
        selectedContactName = null;
      });
    }

    if (filters.tagId != null) {
      final tags = await widget.db.getAllTags();
      final tag = tags.where((t) => t.id == filters.tagId).firstOrNull;
      if (mounted) {
        setState(() {
          selectedTagName = tag?.name;
        });
      }
    } else {
      setState(() {
        selectedTagName = null;
      });
    }
  }

  Future<void> _loadContacts() async {
    final status = await Permission.contacts.status;

    if (status.isGranted) {
      deviceContacts = await FlutterContacts.getContacts(withProperties: true);
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openContact(ContactSummary contact) {
    Navigator.of(context).push(
      CupertinoPageRoute(
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
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ComparisonScreen(
          db: widget.db,
          deviceContacts: deviceContacts,
          config: config,
        ),
      ),
    );
  }

  Future<void> _pickTwoContactsForComparison() async {
    final allSummaries = await repository
        .watchSummary(deviceContacts, const AnalyticsFilters())
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
      stream: repository.watchSummary(deviceContacts, filters),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = snapshot.data!;

        return Material(
          type: MaterialType.transparency,
          child: CustomScrollView(
            controller: widget.titleController.scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight,
                ),
              ),
              GlassLargeTitle(
                text: 'Analytics',
                controller: widget.titleController,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassSegmentedControl.scrollable(
                    quality: GlassQuality.premium,
                    selectedIndex: _selectedTab,
                    onSegmentSelected: (index) {
                      setState(() {
                        _selectedTab = index;
                      });
                    },
                    segments: const [
                      GlassSegment(label: 'Overview'),
                      GlassSegment(label: 'Activity'),
                      GlassSegment(label: 'People'),
                      GlassSegment(label: 'Records'),
                    ],
                  ),
                ),
              ),
              ..._buildTabSlivers(summary),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTabSlivers(AnalyticsSummary summary) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewSlivers(summary);
      case 1:
        return _buildActivitySlivers(summary);
      case 2:
        return _buildPeopleSlivers(summary);
      case 3:
        return _buildRecordsSlivers(summary);
      default:
        return [];
    }
  }

  List<Widget> _buildOverviewSlivers(AnalyticsSummary summary) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _useCalendarGrid = !_useCalendarGrid),
                  child: Text(
                    _useCalendarGrid ? 'Heatmap View' : 'Calendar View',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            _useCalendarGrid
                ? CalendarGridHeatmap(
                    countsByDate: summary.heatmapData,
                    month: DateTime.now().month,
                    year: DateTime.now().year,
                  )
                : ContributionHeatmap(
                    countsByDate: summary.heatmapData,
                    onDayTap: (day, count) =>
                        _showDayDetail(context, day, count),
                  ),

            const SizedBox(height: 24),

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showComparisonOptions(context),
                  icon: const Icon(Icons.compare_arrows, size: 18),
                  label: const Text('Compare'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => YearlyRecapScreen(
                          db: widget.db,
                          deviceContacts: deviceContacts,
                          year: DateTime.now().year,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text('${DateTime.now().year} Recap'),
                ),
              ],
            ),
          ]),
        ),
      ),
    ];
  }

  List<Widget> _buildActivitySlivers(AnalyticsSummary summary) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trend',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _showDuration = !_showDuration),
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
            TalkRatioBar(callTypeCounts: summary.callTypeCounts),

            const SizedBox(height: 24),
            const Text(
              'Answered / Missed / Declined',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AnsweredMissedDeclinedBars(callTypeCounts: summary.callTypeCounts),

            const SizedBox(height: 24),
            const Text(
              'Day of Week',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            WeekdayChart(weekdayCounts: summary.weekdayCounts),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Busiest Hours',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _useClockFace = !_useClockFace),
                  child: Text(_useClockFace ? 'Bar View' : 'Clock View'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _useClockFace
                ? HourClockFace(hourCounts: summary.hourCounts)
                : HourHistogram(hourCounts: summary.hourCounts),

            const SizedBox(height: 24),
            const Text(
              'Call Length Distribution',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._buildDurationDistribution(summary.durationDistribution),

            if (summary.anomalyDays.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Unusual Days',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Days that stood out from your normal pattern',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...summary.anomalyDays.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 12)),
                      Text(
                        '${e.value} calls',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    ];
  }

  List<Widget> _buildPeopleSlivers(AnalyticsSummary summary) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
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

            const SizedBox(height: 24),
            const Text(
              'People Who Call You',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Contacts who initiate more often than you do',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (summary.theyInitiateMore.isEmpty)
              const Text('No one yet.', style: TextStyle(color: Colors.grey))
            else
              ...summary.theyInitiateMore.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.displayName),
                  trailing: Text('${c.incoming} calls from them'),
                  onTap: () => _openContact(c),
                ),
              ),

            const SizedBox(height: 24),
            const Text(
              'People You Call',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Contacts you initiate more often than they do',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (summary.youInitiateMore.isEmpty)
              const Text('No one yet.', style: TextStyle(color: Colors.grey))
            else
              ...summary.youInitiateMore.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.displayName),
                  trailing: Text('${c.outgoing} calls from you'),
                  onTap: () => _openContact(c),
                ),
              ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Most Contacted',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _rankByDuration = !_rankByDuration),
                  child: Text(_rankByDuration ? 'By Calls' : 'By Talk Time'),
                ),
              ],
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
            const Text(
              'Favorites vs Everyone Else',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFavoritesComparison(summary),

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
                            : 'Last called ${_daysAgo(c.lastCallAt!)} days ago',
                      ),
                      onTap: () => _openContact(c),
                    ),
                  ),
          ]),
        ),
      ),
    ];
  }

  List<Widget> _buildRecordsSlivers(AnalyticsSummary summary) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            if (summary.longestCallWith != null)
              _buildLongestCallCard(summary.longestCallWith!),
            const SizedBox(height: 24),
            const Text(
              'New Relationships',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Genuinely new contacts appearing in your call log by month',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildBarChart(
              summary.newContactsByMonth.values.toList(),
              summary.newContactsByMonth.keys
                  .map((k) => k.split('-')[1])
                  .toList(),
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ]),
        ),
      ),
    ];
  }

  Widget _buildFavoritesComparison(AnalyticsSummary summary) {
    if (summary.favoriteContactCount == 0) {
      return const Text(
        'Star some contacts as Favorites to see this comparison.',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    final ratio = summary.avgCallsPerOther > 0
        ? summary.avgCallsPerFavorite / summary.avgCallsPerOther
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    summary.avgCallsPerFavorite.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'avg calls per Favorite (${summary.favoriteContactCount})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    summary.avgCallsPerOther.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'avg calls per other contact (${summary.otherContactCount})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (ratio > 0)
          Center(
            child: Text(
              ratio >= 1
                  ? 'You call your Favorites ${ratio.toStringAsFixed(1)}x more than others.'
                  : 'You actually call your Favorites less than everyone else.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
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

  List<Widget> _buildDurationDistribution(Map<String, int> dist) {
    final total = dist.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return [
        const Text('No calls yet.', style: TextStyle(color: Colors.grey)),
      ];
    }

    return dist.entries.map((entry) {
      final fraction = entry.value / total;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.key} — ${entry.value} (${(fraction * 100).round()}%)',
              style: const TextStyle(fontSize: 12),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLongestCallCard(Map<String, dynamic> longest) {
    final name = longest['name'] as String?;
    final number = longest['number'] as String;
    final duration = longest['duration'] as int;
    final displayName = (name != null && name.isNotEmpty) ? name : number;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: Colors.amber),
        title: Text('Longest call: ${(duration / 60).toStringAsFixed(1)} min'),
        subtitle: Text('with $displayName'),
      ),
    );
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

  Widget _buildBarChart(List<int> values, List<String> labels, {Color? color}) {
    if (values.isEmpty) {
      return const Text('No data.', style: TextStyle(color: Colors.grey));
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b).clamp(1, 999999);
    final barColor = color ?? Theme.of(context).colorScheme.primary;

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
                      color: barColor,
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
}
