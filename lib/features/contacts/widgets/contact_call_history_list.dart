import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../../history/widgets/call_card.dart';

class ContactCallHistoryList extends StatelessWidget {
  final String normalizedNumber;
  final AppDatabase db;
  final Contact? deviceContact;

  const ContactCallHistoryList({
    super.key,
    required this.normalizedNumber,
    required this.db,
    this.deviceContact,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Call>>(
      stream: db.watchCallsForNumber(normalizedNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load call history.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final calls = snapshot.data ?? [];

        if (calls.isEmpty) {
          return const Center(
            child: Text('No calls yet.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          itemCount: calls.length,
          itemBuilder: (context, index) => CallCard(
            call: calls[index],
            db: db,
            deviceContact: deviceContact,
          ),
        );
      },
    );
  }
}
