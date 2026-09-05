import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/toast/toast_service.dart';
import 'database_browser_screen.dart';

class DeveloperScreen extends StatefulWidget {
  final AppDatabase db;

  const DeveloperScreen({super.key, required this.db});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  final _titleController = GlassLargeTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Developer Tools'),
        largeTitleController: _titleController,
      ),
      body: Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          controller: _titleController.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
            ),
            GlassLargeTitle(
              text: 'Developer Tools',
              controller: _titleController,
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Add Test Call Entry'),
                  subtitle: const Text(
                    'Inserts a fake call not present on your real device',
                  ),
                  onTap: () async {
                    await widget.db
                        .into(widget.db.calls)
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
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) =>
                            DatabaseBrowserScreen(db: widget.db),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Show Test Notification'),
                  onTap: () => NotificationService.showTestNotification(),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
