import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/database/app_database.dart';
import '../utils/group_calls_by_day.dart';
import 'call_card.dart';

class SliverHistoryCallList extends StatefulWidget {
  final List<Call> calls;
  final AppDatabase db;

  const SliverHistoryCallList({
    super.key,
    required this.calls,
    required this.db,
  });

  @override
  State<SliverHistoryCallList> createState() => SliverHistoryCallListState();
}

class SliverHistoryCallListState extends State<SliverHistoryCallList> {
  final GlobalKey _sliverKey = GlobalKey();

  late List<String> _datesByIndex;

  String? _currentDate;

  String? get visibleDate => _currentDate;

  @override
  void initState() {
    super.initState();
    _buildDateIndex();
  }

  @override
  void didUpdateWidget(covariant SliverHistoryCallList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.calls != widget.calls) {
      _buildDateIndex();
    }
  }

  void _buildDateIndex() {
    final grouped = groupCallsByDay(widget.calls);

    _datesByIndex = [];

    for (final entry in grouped.entries) {
      // Date header.
      _datesByIndex.add(entry.key);

      // Every call belonging to this date.
      for (int i = 0; i < entry.value.length; i++) {
        _datesByIndex.add(entry.key);
      }
    }

    if (_datesByIndex.isNotEmpty) {
      _currentDate = _datesByIndex.first;
    } else {
      _currentDate = null;
    }
  }

  void updateVisibleDate() {
    final context = _sliverKey.currentContext;
    if (context == null || !mounted || _datesByIndex.isEmpty) return;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderSliverMultiBoxAdaptor) return;

    final mediaQuery = MediaQuery.of(context);
    // Boundary line: The vertical point where we want the date to switch.
    // We'll place it at the center of where the floating glass header sits.
    final stickyHeaderTop = mediaQuery.padding.top + kToolbarHeight + 12;
    const stickyHeaderHeight = 32.0;
    final threshold = stickyHeaderTop + (stickyHeaderHeight / 2);

    int foundIndex = -1;
    RenderBox? child = renderObject.firstChild;

    while (child != null) {
      final y = child.localToGlobal(Offset.zero).dy;
      final height = child.size.height;

      // Check if this child's vertical span covers the threshold line
      if (y <= threshold && y + height >= threshold) {
        final SliverMultiBoxAdaptorParentData parentData =
            child.parentData! as SliverMultiBoxAdaptorParentData;
        foundIndex = parentData.index!;
        break;
      }

      // If the child is already below the threshold, it means the threshold
      // is currently in a "gap" before the first child (e.g. under the title).
      if (y > threshold) {
        foundIndex = renderObject.indexOf(child);
        break;
      }

      child = renderObject.childAfter(child);
    }

    if (foundIndex != -1 && foundIndex < _datesByIndex.length) {
      final date = _datesByIndex[foundIndex];
      if (date != _currentDate) {
        setState(() {
          _currentDate = date;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.calls.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No calls yet.')),
      );
    }

    final grouped = groupCallsByDay(widget.calls);

    final List<Object> items = [];

    for (final entry in grouped.entries) {
      items.add(entry.key);
      items.addAll(entry.value);
    }

    return SliverList(
      key: _sliverKey,
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];

        if (item is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              item,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          );
        }

        return CallCard(call: item as Call, db: widget.db);
      }, childCount: items.length),
    );
  }
}
