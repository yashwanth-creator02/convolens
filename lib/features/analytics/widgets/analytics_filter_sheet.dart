import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../core/database/app_database.dart';
import '../models/analytics_filters.dart';
import '../repository/analytics_repository.dart';
import '../../contacts/models/contact_summary.dart';

class AnalyticsFilterSheet extends StatefulWidget {
  final AppDatabase db;
  final AnalyticsRepository repository;
  final List<Contact> deviceContacts;
  final AnalyticsFilters initialFilters;
  final String? initialContactName;
  final String? initialTagName;

  const AnalyticsFilterSheet({
    super.key,
    required this.db,
    required this.repository,
    required this.deviceContacts,
    required this.initialFilters,
    this.initialContactName,
    this.initialTagName,
  });

  @override
  State<AnalyticsFilterSheet> createState() => _AnalyticsFilterSheetState();
}

class _AnalyticsFilterSheetState extends State<AnalyticsFilterSheet> {
  late AnalyticsFilters _filters;
  String? _selectedContactName;
  String? _selectedTagName;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _selectedContactName = widget.initialContactName;
    _selectedTagName = widget.initialTagName;
  }

  Future<void> _pickContact() async {
    final allSummaries = await widget.repository
        .watchSummary(widget.deviceContacts, const AnalyticsFilters())
        .first;

    if (!mounted) return;

    final searchController = TextEditingController();

    final selected = await showModalBottomSheet<ContactSummary?>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setSheetState) {
              final query = searchController.text.toLowerCase();
              final filtered = allSummaries.mostContacted
                  .where((c) => c.displayName.toLowerCase().contains(query))
                  .toList();

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery
                      .of(context)
                      .viewInsets
                      .bottom,
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
                        onChanged: (_) => setSheetState(() {}),
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
                              onTap: () => Navigator.pop(context, c),
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
          clearContact: false,
        );
        _selectedContactName = selected.displayName;
      });
    }
  }

  Future<void> _pickTag() async {
    final allTags = await widget.db.getAllTags();

    if (!mounted) return;

    final selected = await showDialog<Tag?>(
      context: context,
      builder: (context) =>
          SimpleDialog(
            title: const Text('Filter by tag'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('All Tags'),
              ),
              ...allTags.map(
                    (tag) =>
                    SimpleDialogOption(
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
      initialDateRange:
      _filters.dateRange == DateRangeOption.custom &&
          _filters.customStart != null &&
          _filters.customEnd != null
          ? DateTimeRange(
        start: _filters.customStart!,
        end: _filters.customEnd!,
      )
          : null,
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

  @override
  Widget build(BuildContext context) {
    final isGlass = GlassModalSheetStateProvider.of(context) != null;

    final sheetContent = SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _filters),
                  child: const Text('Done'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _dateChip('7d', DateRangeOption.last7),
                  const SizedBox(width: 8),
                  _dateChip('30d', DateRangeOption.last30),
                  const SizedBox(width: 8),
                  _dateChip('6mo', DateRangeOption.last6Months),
                  const SizedBox(width: 8),
                  _dateChip('1yr', DateRangeOption.lastYear),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Custom'),
                    selected: _filters.dateRange == DateRangeOption.custom,
                    onSelected: (_) => _pickCustomDateRange(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickContact,
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: Text(_selectedContactName ?? 'All Contacts'),
                  ),
                ),
                if (_filters.contactNormalizedNumber != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _filters = _filters.copyWith(clearContact: true);
                        _selectedContactName = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Call Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<CallTypeFilter>(
              value: _filters.callType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items: CallTypeFilter.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (t) {
                if (t != null) {
                  setState(() => _filters = _filters.copyWith(callType: t));
                }
              },
            ),
            const SizedBox(height: 24),
            const Text('Tag', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickTag,
              icon: const Icon(Icons.label_outline, size: 18),
              label: Text(_selectedTagName ?? 'All Tags'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _filters),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );

    if (isGlass) {
      return Material(
        type: MaterialType.transparency,
        child: sheetContent,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: sheetContent,
    );
  }

  Widget _dateChip(String label, DateRangeOption option) {
    return ChoiceChip(
      label: Text(label),
      selected: _filters.dateRange == option,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filters = _filters.copyWith(dateRange: option));
        }
      },
    );
  }
}
