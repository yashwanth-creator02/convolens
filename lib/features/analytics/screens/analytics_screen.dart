import 'dart:async';

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
import '../widgets/analytics_bar_chart.dart';
import '../widgets/analytics_card.dart';
import '../widgets/analytics_filter_banner.dart';
import '../widgets/analytics_filter_sheet.dart';
import '../widgets/analytics_metric_card.dart';
import '../widgets/answered_missed_declined_bars.dart';
import '../widgets/calendar_grid_heatmap.dart';
import '../widgets/contribution_heatmap.dart';
import '../widgets/dunbar_rings_chart.dart';
import '../widgets/heatmap_day_detail_sheet.dart';
import '../widgets/hour_clock_face.dart';
import '../widgets/hour_histogram.dart';
import '../widgets/milestone_badges_grid.dart';
import '../widgets/network_concentration_meter.dart';
import '../widgets/personality_chips.dart';
import '../widgets/relationship_web.dart';
import '../widgets/score_breakdown_bars.dart';
import '../widgets/social_momentum_card.dart';
import '../widgets/social_score_gauge.dart';
import '../widgets/talk_ratio_bar.dart';
import '../widgets/weekday_chart.dart';
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

  bool _isActive = false;
  StreamSubscription<AnalyticsSummary>? _summarySubscription;
  AnalyticsSummary? _cachedSummary;

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

  Future<void> openFilters({GlassMorphAnchor? anchor}) =>
      _showFilters(anchor: anchor);

  void setActive(bool active) {
    if (_isActive == active) return;
    _isActive = active;
    _updateSubscription();
  }

  void _updateSubscription() {
    _summarySubscription?.cancel();
    _summarySubscription = null;

    if (!_isActive || _loading) return;

    _summarySubscription = repository
        .watchSummary(deviceContacts, filters)
        .listen((summary) {
          if (mounted) setState(() => _cachedSummary = summary);
        });
  }

  void applyFilters(AnalyticsFilters result) {
    if (!mounted) return;
    setState(() {
      filters = result;
      _updateSelectedNames();
    });
    _updateSubscription();
  }

  Future<void> _showFilters({GlassMorphAnchor? anchor}) async {
    final result = await GlassModalSheet.show<AnalyticsFilters>(
      context: context,
      quality: GlassQuality.standard,
      detents: const {GlassSheetDetent.medium, GlassSheetDetent.large},
      initialState: GlassSheetState.half,
      morphFrom: anchor,
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

  @override
  void dispose() {
    _summarySubscription?.cancel();
    super.dispose();
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
      _updateSubscription();
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
    final scheme = Theme.of(context).colorScheme;
    final choice = await GlassModalSheet.show<String>(
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compare Analytics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'Select comparison benchmark',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildComparisonOptionTile(
                  context: context,
                  icon: Icons.calendar_month_rounded,
                  title: 'This Month vs Last Month',
                  subtitle: 'Month-over-month volume and talk time shift',
                  value: 'month',
                ),
                const SizedBox(height: 8),
                _buildComparisonOptionTile(
                  context: context,
                  icon: Icons.calendar_today_rounded,
                  title: 'This Year vs Last Year',
                  subtitle: 'Year-over-year annual communication pace',
                  value: 'year',
                ),
                const SizedBox(height: 8),
                _buildComparisonOptionTile(
                  context: context,
                  icon: Icons.people_outline_rounded,
                  title: 'Contact vs Contact',
                  subtitle: 'Head-to-head comparison between two contacts',
                  value: 'contact',
                ),
              ],
            ),
          ),
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

  Widget _buildComparisonOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pop(context, value),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

    final first = await GlassDialog.show<ContactSummary>(
      context: context,
      title: 'First Contact',
      maxWidth: 320,
      content: Container(
        constraints: const BoxConstraints(maxHeight: 280),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: candidates
                .map(
                  (c) => ListTile(
                    title: Text(c.displayName),
                    subtitle: Text('${c.callCount} calls'),
                    onTap: () => Navigator.pop(context, c),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        GlassDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );

    if (first == null || !mounted) return;

    final second = await GlassDialog.show<ContactSummary>(
      context: context,
      title: 'Second Contact',
      maxWidth: 320,
      content: Container(
        constraints: const BoxConstraints(maxHeight: 280),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: candidates
                .where((c) => c.normalizedNumber != first.normalizedNumber)
                .map(
                  (c) => ListTile(
                    title: Text(c.displayName),
                    subtitle: Text('${c.callCount} calls'),
                    onTap: () => Navigator.pop(context, c),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        GlassDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
      ],
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

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remMin = minutes % 60;
    if (remMin == 0) return '${hours}h';
    return '${hours}h ${remMin}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _cachedSummary == null) {
      return Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          controller: widget.titleController.scrollController,
          physics: const BouncingScrollPhysics(),
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
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    final summary = _cachedSummary!;

    return Material(
      type: MaterialType.transparency,
      child: CustomScrollView(
        controller: widget.titleController.scrollController,
        physics: const BouncingScrollPhysics(),
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
                quality: GlassQuality.standard,
                selectedIndex: _selectedTab,
                onSegmentSelected: (index) {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                segments: const [
                  GlassSegment(label: 'Overview'),
                  GlassSegment(label: 'Social'),
                  GlassSegment(label: 'Activity'),
                  GlassSegment(label: 'People'),
                  GlassSegment(label: 'Records'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnalyticsFilterBanner(
              filters: filters,
              contactName: selectedContactName,
              tagName: selectedTagName,
              onOpenFilters: _showFilters,
              onOpenFiltersMorph: (anchor) => _showFilters(anchor: anchor),
              onClearDateRange: () => applyFilters(
                filters.copyWith(dateRange: DateRangeOption.last30),
              ),
              onClearContact: () => applyFilters(
                filters.copyWith(clearContact: true),
              ),
              onClearTag: () => applyFilters(
                filters.copyWith(clearTag: true),
              ),
              onClearCallType: () => applyFilters(
                filters.copyWith(callType: CallTypeFilter.all),
              ),
              onResetAll: () => applyFilters(const AnalyticsFilters()),
            ),
          ),
          ..._buildTabSlivers(summary),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  List<Widget> _buildTabSlivers(AnalyticsSummary summary) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewSlivers(summary);
      case 1:
        return _buildSocialSlivers(summary);
      case 2:
        return _buildActivitySlivers(summary);
      case 3:
        return _buildPeopleSlivers(summary);
      case 4:
        return _buildRecordsSlivers(summary);
      default:
        return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. OVERVIEW TAB
  // ═══════════════════════════════════════════════════════════════════════════

  List<Widget> _buildOverviewSlivers(AnalyticsSummary summary) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            // ── 0. Executive Pulse Summary ───────────────────────────────────
            _buildExecutiveSummary(summary),

            // ── 1. Hero 2x2 Metric Grid ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: AnalyticsMetricCard(
                    label: 'Total Calls',
                    value: '${summary.totalCalls}',
                    icon: Icons.phone_in_talk_rounded,
                    gradientColors: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                    subtitle:
                        '${summary.callTypeCounts[1] ?? 0} in • ${summary.callTypeCounts[2] ?? 0} out',
                    badgeText:
                        '${(summary.missedCallRate * 100).round()}% missed',
                    badgeColor: summary.missedCallRate > 0.25
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    infoDescription:
                        'Total number of call events recorded during this time period, including incoming, outgoing, missed, and rejected calls.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnalyticsMetricCard(
                    label: 'Talk Time',
                    value: _formatDuration(summary.totalTalkSeconds),
                    icon: Icons.timer_outlined,
                    gradientColors: const [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                    subtitle: summary.totalCalls > 0
                        ? 'Avg ${(summary.totalTalkSeconds / summary.totalCalls / 60).round()}m / call'
                        : 'No calls yet',
                    infoDescription:
                        'Cumulative airtime spent on connected phone calls. Excludes ring duration and unanswered calls.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AnalyticsMetricCard(
                    label: 'Unique Contacts',
                    value: '${summary.totalContacts}',
                    icon: Icons.people_alt_rounded,
                    gradientColors: const [Color(0xFF10B981), Color(0xFF14B8A6)],
                    subtitle: summary.busiestDayDate != null
                        ? 'Peak: ${summary.busiestDayCount} calls'
                        : 'Active network',
                    infoDescription:
                        'The number of distinct contacts or phone numbers with whom you communicated during this timeframe.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnalyticsMetricCard(
                    label: 'Daily Streak',
                    value: '${summary.currentStreak}d',
                    icon: Icons.local_fire_department_rounded,
                    gradientColors: const [Color(0xFFF59E0B), Color(0xFFF97316)],
                    badgeText: 'Best: ${summary.longestStreak}d',
                    badgeColor: const Color(0xFFF59E0B),
                    infoDescription:
                        'Your current consecutive days with at least one completed phone call. The badge highlights your historical record streak.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 2. Quick Actions ──────────────────────────────────────────────
            _buildQuickActionsRow(context),
            const SizedBox(height: 16),

            // ── 3. Activity Heatmap ───────────────────────────────────────────
            AnalyticsCard(
              title: 'Activity Patterns',
              icon: Icons.calendar_today_rounded,
              subtitle: 'Daily communication volume over time',
              infoDescription:
                  'A visual heat calendar mapping your daily communication volume over time.\n\nDarker color intensity represents higher call frequency. Toggle between Heatmap and Calendar modes, or tap any day to inspect specific call counts.',
              trailing: GlassChip(
                label: _useCalendarGrid ? 'Calendar' : 'Heatmap',
                icon: Icon(
                  _useCalendarGrid
                      ? Icons.calendar_month_rounded
                      : Icons.grid_view_rounded,
                  size: 13,
                ),
                quality: GlassQuality.standard,
                useOwnLayer: false,
                onTap: () =>
                    setState(() => _useCalendarGrid = !_useCalendarGrid),
              ),
              child: RepaintBoundary(
                child: _useCalendarGrid
                    ? CalendarGridHeatmap(
                        countsByDate: summary.heatmapData,
                        month: DateTime.now().month,
                        year: DateTime.now().year,
                        onDayTap: (day, count) =>
                            _showDayDetail(context, day, count),
                      )
                    : ContributionHeatmap(
                        countsByDate: summary.heatmapData,
                        onDayTap: (day, count) =>
                            _showDayDetail(context, day, count),
                      ),
              ),
            ),

            // ── 4. Key Highlights ─────────────────────────────────────────────
            if (summary.busiestDayDate != null || summary.longestCallSeconds > 0)
              AnalyticsCard(
                title: 'Quick Insights',
                icon: Icons.lightbulb_outline_rounded,
                accentColor: const Color(0xFFF59E0B),
                subtitle:
                    'Key extremes, records, and weekly communication rhythms',
                infoDescription:
                    'Highlights key extremes and rhythms in your calling history:\n\n• Busiest Day: The date with your highest single-day call count.\n• Longest Conversation: Your maximum single-call duration.\n• Weekend vs Weekday: Communication balance between workdays and weekends.',
                child: Column(
                  children: [
                    if (summary.busiestDayDate != null)
                      _buildInsightRow(
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFFF59E0B),
                        title: 'Busiest Day',
                        value:
                            '${summary.busiestDayDate} (${summary.busiestDayCount} calls)',
                      ),
                    if (summary.longestCallSeconds > 0)
                      _buildInsightRow(
                        icon: Icons.emoji_events_outlined,
                        color: const Color(0xFF8B5CF6),
                        title: 'Longest Conversation',
                        value: _formatDuration(summary.longestCallSeconds),
                      ),
                    _buildInsightRow(
                      icon: Icons.wb_sunny_outlined,
                      color: const Color(0xFF06B6D4),
                      title: 'Weekend vs Weekday',
                      value:
                          '${summary.weekdayCalls} weekday • ${summary.weekendCalls} weekend',
                    ),
                    const SizedBox(height: 10),
                    _buildWeekdayWeekendSplitBar(summary),
                  ],
                ),
              ),
          ]),
        ),
      ),
    ];
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showComparisonOptions(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.compare_arrows_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compare',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'Periods / Contacts',
                          style: TextStyle(
                            fontSize: 10.5,
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    const Color(0xFFEC4899).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateTime.now().year} Recap',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'Your year in calls',
                          style: TextStyle(
                            fontSize: 10.5,
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. SOCIAL TAB
  // ═══════════════════════════════════════════════════════════════════════════

  List<Widget> _buildSocialSlivers(AnalyticsSummary summary) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            // 1. Social Score Gauge & Momentum
            AnalyticsCard(
              title: 'Social Connectivity Meter',
              icon: Icons.favorite_rounded,
              accentColor: const Color(0xFF10B981),
              subtitle: 'Overall health of your phone connection network',
              infoDescription:
                  'A composite connectivity score (0–100) reflecting the vitality, balance, and reach of your phone relationships.\n\nFactors evaluated:\n• Consistency (30%): Frequency and regularity of contacts.\n• Reciprocity (30%): Balance between incoming and outgoing calls.\n• Network Breadth (20%): Total active relationships maintained.\n• Interaction Depth (20%): Time invested in meaningful conversations.',
              child: Column(
                children: [
                  SocialScoreGauge(
                    score: summary.socialHealthScore,
                    label: summary.socialHealthLabel,
                  ),
                  const SizedBox(height: 16),
                  SocialMomentumCard(momentum: summary.socialMomentum),
                ],
              ),
            ),

            // 2. Score Breakdown
            AnalyticsCard(
              title: 'Score Breakdown',
              icon: Icons.bar_chart_rounded,
              accentColor: const Color(0xFF3B82F6),
              subtitle:
                  'The four pillars determining your social connectivity score',
              infoDescription:
                  'The four core pillars contributing to your social connectivity score:\n\n• Consistency: Keeping in touch at steady intervals without prolonged radio silence.\n• Reciprocity: Maintaining a balanced 2-way dialogue rather than one-sided calling.\n• Network Breadth: Maintaining connections across a diverse circle of contacts.\n• Interaction Depth: Engaging in quality, extended discussions beyond quick transactional calls.',
              child: ScoreBreakdownBars(breakdown: summary.scoreBreakdown),
            ),

            // 3. Communication Style
            AnalyticsCard(
              title: 'Communication Style',
              icon: Icons.psychology_rounded,
              accentColor: const Color(0xFF8B5CF6),
              subtitle:
                  'Habits and rhythms detected from your calling patterns',
              infoDescription:
                  'Behavioral archetypes and conversational habits inferred from your call history:\n\n• Night Owl / Early Bird: Inferred from peak call hours.\n• Marathoner / Quick Touch: Inferred from average conversation length.\n• High Reciprocity: Inferred from balanced incoming vs outgoing volume.\n• Weekend Reconnector: Inferred from weekend communication spikes.',
              child: PersonalityChips(labels: summary.personalityLabels),
            ),

            // 4. Network Concentration
            AnalyticsCard(
              title: 'Network Balance',
              icon: Icons.hub_rounded,
              accentColor: const Color(0xFF06B6D4),
              subtitle:
                  'Distribution of calls across regular vs primary contacts',
              infoDescription:
                  'Evaluates whether your calling time is distributed across multiple contacts or concentrated heavily in 1–2 individuals.\n\n• High Concentration: Most conversation time is spent with a single primary contact.\n• Balanced: Conversations are distributed harmoniously across your social circle.',
              child: NetworkConcentrationMeter(
                concentration: summary.networkConcentration,
              ),
            ),

            // 5. Relationship Layers
            AnalyticsCard(
              title: 'Relationship Layers',
              icon: Icons.blur_circular_rounded,
              accentColor: const Color(0xFFEC4899),
              subtitle:
                  'Concentric circles of connection based on call frequency',
              infoDescription:
                  'Visualizes your connections using Dunbar\'s Social Brain Theory:\n\n• Inner Circle (Top 5): Your closest core circle and frequent daily confidants.\n• Close Friends (Next 10): Good friends reached weekly or bi-weekly.\n• Casual Network (Next 35+): Acquaintances and periodic catch-ups.',
              child: DunbarRingsChart(
                tiers: summary.relationshipTiers,
                onContactTap: _openContact,
              ),
            ),

            // 6. Drifting Connections
            AnalyticsCard(
              title: 'Drifting Connections',
              icon: Icons.sync_problem_rounded,
              accentColor: const Color(0xFFF59E0B),
              subtitle:
                  'Contacts you used to call regularly who haven\'t been reached in 30+ days',
              infoDescription:
                  'Highlights valuable relationships that may be growing distant.\n\nSurfaces contacts with at least 3 historical calls who haven\'t been reached in 30+ days, making it easy to tap Reach Out and reconnect.',
              child: summary.driftingContacts.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'None! You have kept your close relationships well attended.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: summary.driftingContacts.take(5).map((c) {
                        return _buildContactTile(
                          contact: c,
                          subtitle: c.lastCallAt == null
                              ? '${c.callCount} calls total'
                              : '${c.callCount} calls total • Last active ${_daysAgo(c.lastCallAt!)}d ago',
                          trailing: GlassChip(
                            label: 'Reach Out',
                            icon: const Icon(Icons.call_outlined, size: 13),
                            quality: GlassQuality.standard,
                            useOwnLayer: false,
                            onTap: () => _openContact(c),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ]),
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. ACTIVITY TAB
  // ═══════════════════════════════════════════════════════════════════════════

  List<Widget> _buildActivitySlivers(AnalyticsSummary summary) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            // 1. Calling Trend
            AnalyticsCard(
              title: 'Activity Trend',
              icon: Icons.show_chart_rounded,
              subtitle: 'Daily call distribution over the selected period',
              infoDescription:
                  'Daily distribution of your phone communications over the selected filter period.\n\nUse the toggle in the upper right to switch between total call counts and cumulative talk duration in minutes.',
              trailing: GlassChip(
                label: _showDuration ? 'Duration' : 'Count',
                icon: Icon(
                  _showDuration ? Icons.timer_outlined : Icons.call_rounded,
                  size: 13,
                ),
                quality: GlassQuality.standard,
                useOwnLayer: false,
                onTap: () => setState(() => _showDuration = !_showDuration),
              ),
              child: AnalyticsBarChart(
                values: _showDuration
                    ? summary.durationTrend
                        .map((s) => (s / 60).round())
                        .toList()
                    : summary.callsPerDay,
                labels: summary.dayLabels,
                unit: _showDuration ? 'm' : '',
              ),
            ),

            // 2. Talk Ratio
            AnalyticsCard(
              title: 'Talk Ratio',
              icon: Icons.sync_alt_rounded,
              subtitle: 'Balance between incoming and outgoing call time',
              infoDescription:
                  'Compares total incoming call duration against outgoing call duration.\n\nA 50/50 balance reflects mutual outreach. When incoming dominates (>60%), others reach out to you more. When outgoing dominates (>60%), you initiate most conversations.',
              child: TalkRatioBar(callTypeCounts: summary.callTypeCounts),
            ),

            // 3. Outcomes
            AnalyticsCard(
              title: 'Call Outcomes',
              icon: Icons.phone_callback_rounded,
              subtitle: 'Answered, missed, and rejected calls',
              infoDescription:
                  'Categorizes all phone call events into:\n\n• Answered: Calls that successfully connected.\n• Missed: Incoming calls that went unanswered.\n• Declined: Inbound calls rejected or dismissed.\n\nA high answer rate (>80%) indicates strong phone availability.',
              child: AnsweredMissedDeclinedBars(
                callTypeCounts: summary.callTypeCounts,
              ),
            ),

            // 4. Day of Week
            AnalyticsCard(
              title: 'Day of Week Distribution',
              icon: Icons.calendar_view_week_rounded,
              subtitle: 'Call volume patterns by weekday',
              infoDescription:
                  'Aggregates your call history by day of the week (Monday through Sunday).\n\nReveals your weekly communication rhythms, your single busiest calling day, and contrasts workweek versus weekend calling volume.',
              child: WeekdayChart(weekdayCounts: summary.weekdayCounts),
            ),

            // 5. Busiest Hours
            AnalyticsCard(
              title: 'Busiest Hours',
              icon: Icons.access_time_rounded,
              subtitle: 'Time of day when calls occur most often',
              infoDescription:
                  'Visualizes your 24-hour diurnal calling rhythm.\n\nHelps identify your peak communication window and categorizes activity into four time-of-day segments: Morning (6 AM–12 PM), Afternoon (12 PM–5 PM), Evening (5 PM–9 PM), and Night (9 PM–6 AM).',
              trailing: GlassChip(
                label: _useClockFace ? 'Clock' : 'Bars',
                icon: Icon(
                  _useClockFace
                      ? Icons.schedule_rounded
                      : Icons.bar_chart_rounded,
                  size: 13,
                ),
                quality: GlassQuality.standard,
                useOwnLayer: false,
                onTap: () => setState(() => _useClockFace = !_useClockFace),
              ),
              child: _useClockFace
                  ? HourClockFace(hourCounts: summary.hourCounts)
                  : HourHistogram(hourCounts: summary.hourCounts),
            ),

            // 6. Call Length Distribution
            AnalyticsCard(
              title: 'Call Length Distribution',
              icon: Icons.timelapse_rounded,
              accentColor: const Color(0xFF8B5CF6),
              subtitle: 'Breakdown of short check-ins vs deep conversations',
              infoDescription:
                  'Breaks down your phone calls into four duration tiers:\n\n• Quick (<30s): Brief status updates and quick coordination.\n• Short (30s–3m): Standard everyday catch-ups.\n• Medium (3–10m): Substantial conversations.\n• Long (10m+): Deep, extended discussions.',
              child: _buildDurationDistribution(
                summary.durationDistribution,
              ),
            ),

            // 7. Unusual Activity
            if (summary.anomalyDays.isNotEmpty)
              AnalyticsCard(
                title: 'Activity Spikes',
                icon: Icons.bolt_rounded,
                accentColor: const Color(0xFFF59E0B),
                subtitle:
                    'Days that stood out sharply from your normal communication volume',
                infoDescription:
                    'Flags specific calendar days where your call volume was abnormally high compared to your typical daily baseline.\n\nUseful for identifying event-heavy days, emergencies, celebrations, or unusually busy periods.',
                child: Column(
                  children: summary.anomalyDays.map((e) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${e.value} calls',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ]),
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. PEOPLE TAB
  // ═══════════════════════════════════════════════════════════════════════════

  List<Widget> _buildPeopleSlivers(AnalyticsSummary summary) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            // 1. Relationship Web
            AnalyticsCard(
              title: 'Your Network Web',
              icon: Icons.hub_outlined,
              subtitle: 'Line thickness reflects how frequently you talk',
              infoDescription:
                  'An interactive topological graph of your core social network.\n\nYou are positioned at the center, surrounded by your most frequent contacts. Node proximity and connection line thickness illustrate relative call volume and relationship intimacy.',
              child: RepaintBoundary(
                child: RelationshipWeb(
                  contacts: summary.mostContacted,
                  onContactTap: _openContact,
                ),
              ),
            ),

            // 2. Most Contacted
            AnalyticsCard(
              title: 'Most Contacted',
              icon: Icons.star_rounded,
              accentColor: const Color(0xFFF59E0B),
              subtitle: 'Your top connections ranked by activity',
              infoDescription:
                  'Your top contacts ranked by total interaction volume.\n\nUse the toggle to switch rankings between total call count and total talk time in minutes. The top 3 contacts feature special podium medals.',
              trailing: GlassChip(
                label: _rankByDuration ? 'By Time' : 'By Calls',
                icon: Icon(
                  _rankByDuration ? Icons.schedule_rounded : Icons.call_rounded,
                  size: 13,
                ),
                quality: GlassQuality.standard,
                useOwnLayer: false,
                onTap: () =>
                    setState(() => _rankByDuration = !_rankByDuration),
              ),
              child: summary.mostContacted.isEmpty
                  ? const Text(
                      'No calls yet.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Column(
                      children: (_rankByDuration
                              ? ([...summary.mostContacted]..sort(
                                  (a, b) => b.totalDuration
                                      .compareTo(a.totalDuration),
                                ))
                              : summary.mostContacted)
                          .take(5)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key + 1;
                            final c = entry.value;
                            return _buildContactTile(
                              contact: c,
                              rank: index,
                              subtitle: _rankByDuration
                                  ? '${c.callCount} calls total'
                                  : '${(c.totalDuration / 60).round()}m total talk time',
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _rankByDuration
                                      ? '${(c.totalDuration / 60).round()}m'
                                      : '${c.callCount} calls',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
            ),

            // 3. Initiation Dynamics
            AnalyticsCard(
              title: 'Initiation Dynamics',
              icon: Icons.swap_calls_rounded,
              accentColor: const Color(0xFF3B82F6),
              subtitle: 'Who starts phone calls more often across your network',
              infoDescription:
                  'Analyzes conversational asymmetry across your contacts.\n\nDistinguishes between contacts who call you more often (incoming dominant) versus contacts you reach out to more often (outgoing dominant), helping you see who drives your relationships.',
              child: _buildInitiationDynamicsSection(summary),
            ),

            // 4. Favorites vs Everyone Else
            AnalyticsCard(
              title: 'Favorites vs Everyone Else',
              icon: Icons.star_border_rounded,
              accentColor: const Color(0xFFF59E0B),
              subtitle:
                  'Comparing calling frequency to your starred favorites',
              infoDescription:
                  'Compares average call volume per starred favorite contact against all other contacts in your address book.\n\nReveals how much more attention and airtime your inner favorites receive compared to general acquaintances.',
              child: _buildFavoritesComparison(summary),
            ),

            // 5. Calls by Tag
            if (summary.tagCounts.isNotEmpty)
              AnalyticsCard(
                title: 'Calls by Tag',
                icon: Icons.label_outline_rounded,
                subtitle: 'Categorized conversation volume',
                infoDescription:
                    'Aggregates your call volume categorized by custom tags (e.g., Family, Work, Friends) assigned to contacts in Convolens.',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: summary.tagCounts.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${entry.value}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // 6. Keep In Touch
            AnalyticsCard(
              title: 'Keep In Touch',
              icon: Icons.hourglass_empty_rounded,
              accentColor: const Color(0xFFF59E0B),
              subtitle:
                  'Contacts you used to call regularly who haven\'t been reached lately',
              infoDescription:
                  'A proactive relationship health reminder.\n\nLists saved contacts who have had no call activity in 30+ days. Tap the Call action chip to immediately dial or view their contact details.',
              child: summary.silentContacts.isEmpty
                  ? const Text(
                      "You're in touch with everyone!",
                      style: TextStyle(color: Colors.grey),
                    )
                  : Column(
                      children: summary.silentContacts.take(8).map((c) {
                        return _buildContactTile(
                          contact: c,
                          subtitle: c.lastCallAt == null
                              ? 'Never called from this phone'
                              : 'Last called ${_daysAgo(c.lastCallAt!)} days ago',
                          trailing: GlassChip(
                            label: 'Call',
                            icon: const Icon(Icons.call_outlined, size: 12),
                            quality: GlassQuality.standard,
                            useOwnLayer: false,
                            onTap: () => _openContact(c),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ]),
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. RECORDS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  List<Widget> _buildRecordsSlivers(AnalyticsSummary summary) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            // 1. All-Time Record Call
            if (summary.longestCallWith != null) ...[
              AnalyticsCard(
                title: 'All-Time Record Call',
                icon: Icons.emoji_events_rounded,
                accentColor: const Color(0xFFF59E0B),
                subtitle: 'Your longest recorded telephone conversation',
                infoDescription:
                    'Celebrates your single longest uninterrupted telephone conversation recorded in your device history, showing duration and contact.',
                child: _buildLongestCallCard(summary.longestCallWith!),
              ),
            ],

            // 2. Hall of Fame Milestones Bento
            AnalyticsCard(
              title: 'Hall of Fame',
              icon: Icons.military_tech_rounded,
              accentColor: const Color(0xFFF59E0B),
              subtitle: 'All-time bests and personal communication records',
              infoDescription:
                  'Your all-time personal communication record book:\n\n• Peak Day: Single day with the most calls ever logged.\n• Best Streak: Longest consecutive daily calling streak.\n• Top Contact: All-time #1 contact by call count and duration.\n• Total Time: Lifetime connected call time.',
              child: _buildHallOfFameBento(summary),
            ),

            // 3. Milestones & Badges
            AnalyticsCard(
              title: 'Milestones & Badges',
              icon: Icons.workspace_premium_rounded,
              accentColor: const Color(0xFF8B5CF6),
              subtitle: 'Unlock communication achievements by hitting milestones',
              infoDescription:
                  'Unlockable achievements celebrating your communication milestones:\n\n• Century Club: 100+ total calls.\n• Marathon Talker: 30+ min single call.\n• Consistency Star: 7-day streak.\n• Broad Network: 20+ contacts.\n• Deep Listener: 10+ hours talk time.\n• Loyal Companion: 20+ calls with one person.',
              child: MilestoneBadgesGrid(summary: summary),
            ),

            // 4. Network Expansion
            AnalyticsCard(
              title: 'New Connections',
              icon: Icons.person_add_alt_1_rounded,
              accentColor: const Color(0xFF10B981),
              subtitle: 'First-time callers appearing in your call log by month',
              infoDescription:
                  'Tracks the monthly pace at which new, first-time phone numbers appear in your call history, illustrating how quickly your network is growing.',
              child: AnalyticsBarChart(
                values: summary.newContactsByMonth.values.toList(),
                labels: summary.newContactsByMonth.keys
                    .map((k) => k.contains('-') ? k.split('-')[1] : k)
                    .toList(),
                barColor: const Color(0xFF10B981),
              ),
            ),
          ]),
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContactTile({
    required ContactSummary contact,
    String? subtitle,
    Widget? trailing,
    int? rank,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final initials = contact.displayName.isNotEmpty
        ? (contact.displayName.length >= 2
            ? contact.displayName.substring(0, 2).toUpperCase()
            : contact.displayName[0].toUpperCase())
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap ?? () => _openContact(contact),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                if (rank != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: rank == 1
                          ? const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                            )
                          : (rank == 2
                              ? const LinearGradient(
                                  colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                                )
                              : (rank == 3
                                  ? const LinearGradient(
                                      colors: [Color(0xFFD97706), Color(0xFFB45309)],
                                    )
                                  : null)),
                      color: rank > 3
                          ? scheme.surfaceContainerHighest.withValues(alpha: 0.4)
                          : null,
                      shape: BoxShape.circle,
                      boxShadow: rank <= 3
                          ? [
                              BoxShadow(
                                color: (rank == 1
                                        ? const Color(0xFFF59E0B)
                                        : (rank == 2
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFFD97706)))
                                    .withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: rank <= 3 ? Colors.white : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: rank != null && rank <= 3
                        ? Border.all(
                            color: rank == 1
                                ? const Color(0xFFF59E0B)
                                : (rank == 2
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFFD97706)),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    backgroundImage: contact.deviceContact?.thumbnail != null
                        ? MemoryImage(contact.deviceContact!.thumbnail!)
                        : null,
                    child: contact.deviceContact?.thumbnail == null
                        ? Text(
                            initials,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesComparison(AnalyticsSummary summary) {
    final scheme = Theme.of(context).colorScheme;

    if (summary.favoriteContactCount == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.star_border_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Star your close friends as Favorites in Contacts to see this comparison.',
                style:
                    TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final ratio = summary.avgCallsPerOther > 0
        ? summary.avgCallsPerFavorite / summary.avgCallsPerOther
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Favorites (${summary.favoriteContactCount})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.avgCallsPerFavorite.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF59E0B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'avg calls each',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Others (${summary.otherContactCount})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.avgCallsPerOther.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'avg calls each',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (ratio > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (ratio >= 1
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF3B82F6))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  ratio >= 1
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: ratio >= 1
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ratio >= 1
                        ? 'You call your Favorites ${ratio.toStringAsFixed(1)}x more than others'
                        : 'You call your Favorites less often than other contacts',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ratio >= 1
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLongestCallCard(Map<String, dynamic> longest) {
    final scheme = Theme.of(context).colorScheme;
    final name = longest['name'] as String?;
    final number = longest['number'] as String;
    final duration = longest['duration'] as int;
    final displayName = (name != null && name.isNotEmpty) ? name : number;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.12),
            const Color(0xFFF97316).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECORD CALL DURATION',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'with $displayName',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetail(BuildContext context, DateTime day, int count) {
    GlassModalSheet.show(
      context: context,
      quality: GlassQuality.standard,
      detents: const {GlassSheetDetent.medium, GlassSheetDetent.large},
      initialState: GlassSheetState.half,
      builder: (context) => HeatmapDayDetailSheet(
        day: day,
        count: count,
        db: widget.db,
        deviceContacts: deviceContacts,
        filters: filters,
      ),
    );
  }

  int _daysAgo(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(date).inDays;
  }

  Widget _buildExecutiveSummary(AnalyticsSummary summary) {
    final scheme = Theme.of(context).colorScheme;
    final answeredRate = (1.0 - summary.missedCallRate).clamp(0.0, 1.0);
    final avgDurationMins = summary.totalCalls > 0
        ? (summary.totalTalkSeconds / summary.totalCalls / 60).round()
        : 0;

    String pulseStatus;
    Color pulseColor;
    String pulseDescription;

    if (summary.totalCalls == 0) {
      pulseStatus = 'Dormant';
      pulseColor = Colors.grey;
      pulseDescription = 'No call activity detected during this time window.';
    } else if (summary.currentStreak >= 3 || summary.totalCalls >= 20) {
      pulseStatus = 'Vibrant Pulse';
      pulseColor = const Color(0xFF10B981);
      pulseDescription =
          'High communication momentum with ${(answeredRate * 100).round()}% connection rate across ${summary.totalContacts} active contacts.';
    } else if (summary.missedCallRate > 0.4) {
      pulseStatus = 'Attention Needed';
      pulseColor = const Color(0xFFF59E0B);
      pulseDescription =
          'Elevated missed call rate (${(summary.missedCallRate * 100).round()}%). Follow-ups could restore balance.';
    } else {
      pulseStatus = 'Steady Rhythm';
      pulseColor = const Color(0xFF3B82F6);
      pulseDescription =
          'Consistent call cadence averaging $avgDurationMins min per conversation.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pulseColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: pulseColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: pulseColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: pulseColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NETWORK PULSE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: pulseColor,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: pulseColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pulseStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: pulseColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      showAnalyticsInfoSheet(
                        context,
                        title: 'Network Pulse',
                        description:
                            'Network Pulse evaluates real-time communication momentum by synthesizing call frequency, talk time velocity, and connection balance.\n\n'
                            '• Vibrant Pulse: High activity (>20 calls or 3+ day streak) with healthy connection rates.\n'
                            '• Attention Needed: High missed call rate (>40%), indicating missed connection opportunities.\n'
                            '• Steady Rhythm: Consistent, regular calling cadence with balanced talk duration.\n'
                            '• Dormant: No logged call activity detected in this timeframe.',
                        icon: Icons.monitor_heart_rounded,
                        accentColor: pulseColor,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pulseDescription,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniIndicator(
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                  label: 'Success Rate',
                  value: '${(answeredRate * 100).round()}%',
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
                _buildMiniIndicator(
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF8B5CF6),
                  label: 'Avg Length',
                  value: '${avgDurationMins}m',
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
                _buildMiniIndicator(
                  icon: Icons.people_outline_rounded,
                  color: const Color(0xFF06B6D4),
                  label: 'Contacts',
                  value: '${summary.totalContacts}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIndicator({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayWeekendSplitBar(AnalyticsSummary summary) {
    final scheme = Theme.of(context).colorScheme;
    final total = summary.weekdayCalls + summary.weekendCalls;
    if (total == 0) return const SizedBox.shrink();

    final weekdayPct = (summary.weekdayCalls / total).clamp(0.0, 1.0);
    final weekendPct = (summary.weekendCalls / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Workweek (${(weekdayPct * 100).round()}%)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Weekend (${(weekendPct * 100).round()}%)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: summary.weekdayCalls > 0 ? summary.weekdayCalls : 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: summary.weekendCalls > 0 ? summary.weekendCalls : 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitiationDynamicsSection(AnalyticsSummary summary) {
    final scheme = Theme.of(context).colorScheme;
    final totalIn =
        summary.theyInitiateMore.fold<int>(0, (acc, c) => acc + c.incoming);
    final totalOut =
        summary.youInitiateMore.fold<int>(0, (acc, c) => acc + c.outgoing);
    final sum = totalIn + totalOut;

    final inPct = sum > 0 ? (totalIn / sum) : 0.5;
    final outPct = sum > 0 ? (totalOut / sum) : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sum > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'They Reach Out (${(inPct * 100).round()}%)',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'You Reach Out (${(outPct * 100).round()}%)',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(
                          flex: totalIn > 0 ? totalIn : 1,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: totalOut > 0 ? totalOut : 1,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                              ),
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
          const SizedBox(height: 14),
        ],

        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.call_received_rounded,
                size: 13,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'THEY CALL YOU MORE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (summary.theyInitiateMore.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'No asymmetric incoming calls detected.',
              style: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          )
        else
          ...summary.theyInitiateMore.take(4).map(
                (c) => _buildContactTile(
                  contact: c,
                  subtitle: '${c.incoming} incoming • ${c.outgoing} outgoing',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${c.incoming > 0 && (c.incoming + c.outgoing) > 0 ? ((c.incoming / (c.incoming + c.outgoing)) * 100).round() : 0}% in',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
              ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1),
        ),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.call_made_rounded,
                size: 13,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'YOU CALL THEM MORE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (summary.youInitiateMore.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'No asymmetric outgoing calls detected.',
              style: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          )
        else
          ...summary.youInitiateMore.take(4).map(
                (c) => _buildContactTile(
                  contact: c,
                  subtitle: '${c.outgoing} outgoing • ${c.incoming} incoming',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${c.outgoing > 0 && (c.incoming + c.outgoing) > 0 ? ((c.outgoing / (c.incoming + c.outgoing)) * 100).round() : 0}% out',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildHallOfFameBento(AnalyticsSummary summary) {
    final topContact = summary.mostContacted.firstOrNull;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHallOfFameItem(
                icon: Icons.bolt_rounded,
                color: const Color(0xFFF59E0B),
                label: 'PEAK DAY',
                value: summary.busiestDayDate != null
                    ? '${summary.busiestDayCount} calls'
                    : '0 calls',
                subtitle: summary.busiestDayDate ?? 'No calls recorded',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildHallOfFameItem(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFEF4444),
                label: 'BEST STREAK',
                value: '${summary.longestStreak} days',
                subtitle: 'Current: ${summary.currentStreak}d',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildHallOfFameItem(
                icon: Icons.military_tech_rounded,
                color: const Color(0xFF8B5CF6),
                label: 'TOP CONTACT',
                value: topContact?.displayName ?? 'None',
                subtitle: topContact != null
                    ? '${topContact.callCount} calls • ${(topContact.totalDuration / 60).round()}m'
                    : 'No contacts',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildHallOfFameItem(
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFF10B981),
                label: 'TOTAL TIME',
                value: _formatDuration(summary.totalTalkSeconds),
                subtitle: '${summary.totalCalls} calls logged',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHallOfFameItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String subtitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: scheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDurationDistribution(Map<String, int> dist) {
    final scheme = Theme.of(context).colorScheme;
    final total = dist.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return Text(
        'No call duration data yet.',
        style: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      );
    }

    final categoryMeta = {
      'Quick (<30s)': (
        color: const Color(0xFF06B6D4),
        icon: Icons.bolt_rounded,
        desc: 'Quick check-ins & status updates'
      ),
      'Short (30s–3m)': (
        color: const Color(0xFF3B82F6),
        icon: Icons.chat_bubble_outline_rounded,
        desc: 'Concise daily conversations'
      ),
      'Medium (3–10m)': (
        color: const Color(0xFF8B5CF6),
        icon: Icons.forum_outlined,
        desc: 'Substantial catch-ups'
      ),
      'Long (10m+)': (
        color: const Color(0xFFEC4899),
        icon: Icons.timer_outlined,
        desc: 'Deep discussions & catch-ups'
      ),
    };

    String maxKey = '';
    int maxVal = -1;
    for (final entry in dist.entries) {
      if (entry.value > maxVal) {
        maxVal = entry.value;
        maxKey = entry.key;
      }
    }

    String insightText;
    if (maxKey == 'Quick (<30s)' || maxKey == 'Short (30s–3m)') {
      insightText =
          '⚡ Most calls are brief check-ins under 3 minutes, reflecting efficient communication.';
    } else if (maxKey == 'Long (10m+)') {
      insightText =
          '🎙️ Extended calls dominate your profile, showing high conversational depth.';
    } else {
      insightText =
          '✨ Balanced blend of brief check-ins and meaningful medium conversations.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...dist.entries.map((entry) {
          final fraction = total > 0 ? (entry.value / total) : 0.0;
          final pct = (fraction * 100).round();
          final meta = categoryMeta[entry.key] ??
              (
                color: scheme.primary,
                icon: Icons.schedule_rounded,
                desc: 'Call segment'
              );

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: meta.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(meta.icon, size: 14, color: meta.color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            meta.desc,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: meta.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${entry.value} ($pct%)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: meta.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Container(
                        height: 7,
                        width: double.infinity,
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0.0, 1.0),
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                meta.color.withValues(alpha: 0.7),
                                meta.color,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  insightText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
