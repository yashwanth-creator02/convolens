import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

class DeveloperScreen extends StatelessWidget {
  final AppDatabase db;

  const DeveloperScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Tools')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Test Call Entry'),
            subtitle: const Text(
              'Inserts a fake call not present on your real device',
            ),
            onTap: () async {
              await db
                  .into(db.calls)
                  .insert(
                    CallsCompanion.insert(
                      number: const drift.Value('+10000000000'),
                      name: const drift.Value('Test Entry'),
                      type: 1,
                      duration: 1,
                      timestamp: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test call added.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
