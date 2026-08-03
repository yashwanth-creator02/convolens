import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/native/call_log_channel.dart';
import '../utils/group_calls_by_day.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AppDatabase _db = AppDatabase();

  @override
  void initState() {
    super.initState();
    _requestFetchAndStore();
  }

  Future<void> _requestFetchAndStore() async {
    final status = await Permission.phone.request();
    debugPrint('Permission status: $status');

    if (!status.isGranted) {
      debugPrint('Permission not granted, skipping fetch.');
      return;
    }

    final calls = await CallLogChannel.fetchCallLogs();
    debugPrint('Fetched ${calls.length} calls from device');

    final companions = calls.map((call) {
      return CallsCompanion.insert(
        number: Value(call['number'] as String?),
        name: Value(call['name'] as String?),
        type: call['type'] as int,
        duration: call['duration'] as int,
        timestamp: call['timestamp'] as int,
      );
    }).toList();

    await _db.batch((batch) {
      batch.insertAll(_db.calls, companions, mode: InsertMode.insertOrIgnore);
    });

    debugPrint('Insert complete.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: StreamBuilder<List<Call>>(
        stream: _db.watchAllCalls(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final calls = snapshot.data!;

          if (calls.isEmpty) {
            return const Center(child: Text('No calls yet.'));
          }

          final grouped = groupCallsByDay(calls);

          final List<Object> flatItems = [];
          grouped.forEach((label, callsInGroup) {
            flatItems.add(label);
            flatItems.addAll(callsInGroup);
          });

          return ListView.builder(
            itemCount: flatItems.length,
            itemBuilder: (context, index) {
              final item = flatItems[index];

              if (item is String) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              final call = item as Call;
              return ListTile(
                title: Text(call.name ?? call.number ?? 'Unknown'),
                subtitle: Text('type:${call.type} • ${call.duration}s'),
              );
            },
          );
        },
      ),
    );
  }
}
