import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/contact_cache.dart';
import '../../../core/utils/normalize_number.dart';
import 'call_card.dart';

class SliverHistoryCallList extends StatefulWidget {
  final List<Object> items;
  final AppDatabase db;
  final List<Contact> deviceContacts;
  final Setting? settings;
  final Map<int, GlobalKey>? boundaryKeys;
  final Map<int, CallDetail> callDetailsMap;
  final Map<int, List<Tag>> callTagsMap;
  final Map<int, int> attachmentCountsMap;

  const SliverHistoryCallList({
    super.key,
    required this.items,
    required this.db,
    required this.deviceContacts,
    this.settings,
    this.boundaryKeys,
    this.callDetailsMap = const {},
    this.callTagsMap = const {},
    this.attachmentCountsMap = const {},
  });

  @override
  State<SliverHistoryCallList> createState() => SliverHistoryCallListState();
}

class SliverHistoryCallListState extends State<SliverHistoryCallList> {
  final GlobalKey _sliverKey = GlobalKey();

  late List<String> _datesByIndex;
  String? _currentDate;
  Map<String, Contact> _contactMap = {};

  double get averageItemHeight {
    final showTabs =
        (widget.settings?.showCallType ?? true) ||
        (widget.settings?.showDuration ?? true) ||
        (widget.settings?.showTime ?? true);
    return showTabs ? 116.0 : 88.0;
  }

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

    final sliverScrollOffset = renderObject.constraints.scrollOffset;

    RenderBox? child = renderObject.firstChild;
    while (child != null) {
      final parentData = child.parentData;
      if (parentData is SliverMultiBoxAdaptorParentData) {
        final layoutOffset = parentData.layoutOffset ?? 0.0;
        final height = child.hasSize ? child.size.height : 0.0;
        final childBottom = layoutOffset + height;

        // Find the first child whose bottom is within or below the top visible threshold
        if (childBottom > sliverScrollOffset + 10) {
          final foundIndex = parentData.index;
          if (foundIndex != null &&
              foundIndex >= 0 &&
              foundIndex < _datesByIndex.length) {
            final date = _datesByIndex[foundIndex];
            if (date.isNotEmpty && date != _currentDate) {
              _currentDate = date;
            }
          }
          break;
        }
      }
      child = renderObject.childAfter(child);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      final scheme = Theme.of(context).colorScheme;
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 28,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Call History Yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Calls recorded on your device will automatically appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      key: _sliverKey,
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = widget.items[index];
          final boundaryKey = widget.boundaryKeys?[index];

          Widget child;
          if (item is String) {
            child = Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                item,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          } else {
            final call = item as Call;
            child = CallCard(
              call: call,
              db: widget.db,
              settings: widget.settings,
              deviceContact: _findContact(call.number, name: call.name),
              detail: widget.callDetailsMap[call.id],
              tags: widget.callTagsMap[call.id] ?? const [],
              attachmentCount: widget.attachmentCountsMap[call.id] ?? 0,
              hasBatchMetadata: true,
            );
          }

          return boundaryKey != null
              ? KeyedSubtree(key: boundaryKey, child: child)
              : child;
        },
        childCount: widget.items.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
      ),
    );
  }

  Contact? _findContact(String? number, {String? name}) {
    if (number != null && number.isNotEmpty) {
      final normalized = normalizePhoneNumber(number);
      final found = _contactMap[normalized];
      if (found != null) return found;
    }
    return ContactCache.findContact(number: number, name: name);
  }
}
