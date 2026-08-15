import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../history/widgets/call_card.dart';

class ContactCallHistory extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;

  const ContactCallHistory({
    super.key,
    required this.normalizedNumber,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Call>>(
      stream: db.watchCallsForNumber(normalizedNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Failed to load call history.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final calls = snapshot.data ?? [];

        if (calls.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No calls yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final call = calls[index];

            return CallCard(call: call, db: db);
          }, childCount: calls.length),
        );
      },
    );
  }
}
