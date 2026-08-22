import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

const List<String> communicationMethods = [
  'Call',
  'Message',
  'WhatsApp',
  'Email',
];

class ContactPreferencesSection extends StatelessWidget {
  final String normalizedNumber;
  final ContactDetail? detail;
  final AppDatabase db;

  const ContactPreferencesSection({
    super.key,
    required this.normalizedNumber,
    required this.detail,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred Communication Method',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: communicationMethods.map((method) {
            return ChoiceChip(
              label: Text(method),
              selected: detail?.preferredMethod == method,
              onSelected: (_) => db.setContactFields(
                normalizedNumber,
                ContactDetailsCompanion(preferredMethod: Value(method)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text('Best Time to Call', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: detail?.bestTimeToCall,
          decoration: const InputDecoration(
            hintText: 'e.g. Evenings after 6 PM',
            border: OutlineInputBorder(),
          ),
          onFieldSubmitted: (value) => db.setContactFields(
            normalizedNumber,
            ContactDetailsCompanion(bestTimeToCall: Value(value.trim())),
          ),
        ),
      ],
    );
  }
}
