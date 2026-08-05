import 'dart:async';

import 'package:convolens/features/history/repository/calls_repository.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logger/logger.dart';
import '../utils/group_calls_by_day.dart';
import '../widget/call_card.dart';
import '../../settings/screens/settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AppDatabase _db = AppDatabase();
  late final CallsRepository _repository = CallsRepository(_db);
  StreamSubscription<Setting>? _settingsSubscription;

  @override
  void initState() {
    super.initState();
    _settingsSubscription = _db.watchSettings().listen((settings) {
      Logger.devModeEnabled = settings.devMode;
    });
    _requestFetchAndStore();
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestFetchAndStore() async {
    final status = await Permission.phone.request();
    Logger.debug('Permission status: $status', tag: 'Permission');

    if (!status.isGranted) {
      debugPrint('Permission not granted, skipping fetch.');
      return;
    }

    final archiveMode = await _db.getArchiveMode();
    await _repository.syncFromDevice(archiveMode: archiveMode);

    final allCalls = await _db.select(_db.calls).get();
    debugPrint('Total rows in DB: ${allCalls.length}');
    debugPrint(
      'Newest timestamp in DB: ${allCalls.isEmpty ? 'none' : allCalls.map((c) => c.timestamp).reduce((a, b) => a > b ? a : b)}',
    );
    Logger.debug('Sync complete.', tag: 'Sync');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(db: _db),
                ),
              );
            },
          ),
        ],
      ),
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
              return CallCard(call: call, db: _db);
            },
          );
        },
      ),
    );
  }
}
