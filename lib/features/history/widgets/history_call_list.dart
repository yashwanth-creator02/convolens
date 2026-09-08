import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/normalize_number.dart';
import 'call_card.dart';

class SliverHistoryCallList extends StatefulWidget {
  final List<Object> items;
  final AppDatabase db;
  final List<Contact> deviceContacts;
  final Map<int, GlobalKey>? boundaryKeys;

  const SliverHistoryCallList({
    super.key,
    required this.items,
    required this.db,
    required this.deviceContacts,
    this.boundaryKeys,
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
    if (oldWidget.items != widget.items) {
      _buildDateIndex();
    }
  }

  void _buildDateIndex() {
    _datesByIndex = [];
    String? lastDate;
    for (final item in widget.items) {
      if (item is String) {
        lastDate = item;
      }
      _datesByIndex.add(lastDate ?? '');
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
    final stickyHeaderTop = mediaQuery.padding.top + kToolbarHeight + 12;
    const stickyHeaderHeight = 32.0;
    final threshold = stickyHeaderTop + (stickyHeaderHeight / 2);

    int foundIndex = -1;
    RenderBox? child = renderObject.firstChild;

    while (child != null) {
      final y = child.localToGlobal(Offset.zero).dy;
      final height = child.size.height;

      if (y <= threshold && y + height >= threshold) {
        final SliverMultiBoxAdaptorParentData parentData =
            child.parentData! as SliverMultiBoxAdaptorParentData;
        foundIndex = parentData.index!;
        break;
      }

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
    if (widget.items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No calls yet.')),
      );
    }

    return SliverList(
      key: _sliverKey,
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = widget.items[index];
        final boundaryKey = widget.boundaryKeys?[index];

        Widget child;
        if (item is String) {
          child = Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              item,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          );
        } else {
          final call = item as Call;
          child = CallCard(
            call: call,
            db: widget.db,
            deviceContact: _findContact(call.number),
          );
        }

        return boundaryKey != null
            ? KeyedSubtree(key: boundaryKey, child: child)
            : child;
      }, childCount: widget.items.length),
    );
  }

  Contact? _findContact(String? number) {
    if (number == null || number.isEmpty) return null;
    final normalized = normalizePhoneNumber(number);
    for (final contact in widget.deviceContacts) {
      for (final phone in contact.phones) {
        if (normalizePhoneNumber(phone.number) == normalized) {
          return contact;
        }
      }
    }
    return null;
  }
}
