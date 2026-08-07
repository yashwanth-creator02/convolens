import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/toast/toast_service.dart';
import 'database_browser_screen.dart';

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
                ToastService.success(context, 'test call added. ');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Database Browser'),
            subtitle: const Text('View raw rows from any table'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DatabaseBrowserScreen(db: db),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Show Test Notification'),
            onTap: () => NotificationService.showTestNotification(),
          ),
        ],
      ),
    );
  }
}
