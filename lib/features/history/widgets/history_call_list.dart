import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../utils/group_calls_by_day.dart';
import 'call_card.dart';

class SliverHistoryCallList extends StatelessWidget {
  final List<Call> calls;
  final AppDatabase db;

  const SliverHistoryCallList({
    super.key,
    required this.calls,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    if (calls.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No calls yet.')),
      );
    }

    final grouped = groupCallsByDay(calls);

    final List<Object> items = [];

    grouped.forEach((label, callsInGroup) {
      items.add(label);
      items.addAll(callsInGroup);
    });

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];

        if (item is String) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              item,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          );
        }

        final call = item as Call;

        return CallCard(call: call, db: db);
      }, childCount: items.length),
    );
  }
}
