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
  final Setting? settings;
  final Map<int, GlobalKey>? boundaryKeys;

  const SliverHistoryCallList({
    super.key,
    required this.items,
    required this.db,
    required this.deviceContacts,
    this.settings,
    this.boundaryKeys,
  });

  @override
  State<SliverHistoryCallList> createState() => SliverHistoryCallListState();
}

class SliverHistoryCallListState extends State<SliverHistoryCallList> {
  static const double _fallbackAverage = 72.0;

  final GlobalKey _sliverKey = GlobalKey();

  late List<String> _datesByIndex;
  String? _currentDate;
  Map<String, Contact> _contactMap = {};

  double _totalMeasuredHeight = 0;
  int _measuredCount = 0;
  final Set<int> _measuredIndices = {};

  double get averageItemHeight => _measuredCount == 0
      ? _fallbackAverage
      : _totalMeasuredHeight / _measuredCount;

  String? get visibleDate => _currentDate;

  @override
  void initState() {
    super.initState();
    _buildDateIndex();
    _buildContactMap();
  }

  @override
  void didUpdateWidget(covariant SliverHistoryCallList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _buildDateIndex();
      _measuredIndices.clear();
      _totalMeasuredHeight = 0;
      _measuredCount = 0;
    }
    if (oldWidget.deviceContacts != widget.deviceContacts) {
      _buildContactMap();
    }
  }

  void _buildContactMap() {
    final newMap = <String, Contact>{};
    for (final contact in widget.deviceContacts) {
      for (final phone in contact.phones) {
        final normalized = normalizePhoneNumber(phone.number);
        if (normalized.isNotEmpty) {
          newMap[normalized] = contact;
        }
      }
    }
    _contactMap = newMap;
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

    final firstChild = renderObject.firstChild;
    if (firstChild == null) return;

    final parentData = firstChild.parentData;
    if (parentData is! SliverMultiBoxAdaptorParentData) return;

    final foundIndex = parentData.index;
    if (foundIndex != null &&
        foundIndex >= 0 &&
        foundIndex < _datesByIndex.length) {
      final date = _datesByIndex[foundIndex];
      if (date.isNotEmpty && date != _currentDate) {
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
            settings: widget.settings,
            deviceContact: _findContact(call.number),
          );
        }

        final wrappedChild = boundaryKey != null
            ? KeyedSubtree(key: boundaryKey, child: child)
            : child;

        return _MeasuredItem(
          onMeasured: (height) {
            if (_measuredIndices.contains(index)) return;
            _measuredIndices.add(index);
            _totalMeasuredHeight += height;
            _measuredCount++;
          },
          child: wrappedChild,
        );
      }, childCount: widget.items.length),
    );
  }

  Contact? _findContact(String? number) {
    if (number == null || number.isEmpty) return null;
    final normalized = normalizePhoneNumber(number);
    return _contactMap[normalized];
  }
}

class _MeasuredItem extends StatelessWidget {
  final Widget child;
  final ValueChanged<double> onMeasured;

  const _MeasuredItem({required this.child, required this.onMeasured});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        onMeasured(renderObject.size.height);
      }
    });
    return child;
  }
}
