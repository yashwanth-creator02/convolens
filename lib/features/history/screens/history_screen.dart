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

  bool _isFirstLaunchLoading = false;

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
    final alreadyHasCalls = await _db.hasAnyCalls();

    if (!alreadyHasCalls) {
      setState(() {
        _isFirstLaunchLoading = true;
      });
    }

    final status = await Permission.phone.request();
    Logger.debug('Permission status: $status', tag: 'Permission');

    if (!status.isGranted) {
      Logger.warning(
        'Permission not granted, skipping fetch.',
        tag: 'Permission',
      );
      if (!alreadyHasCalls) {
        setState(() {
          _isFirstLaunchLoading = false;
        });
      }
      return;
    }

    final archiveMode = await _db.getArchiveMode();
    await _repository.syncFromDevice(archiveMode: archiveMode);
    Logger.debug('Sync complete.', tag: 'Sync');

    if (!alreadyHasCalls) {
      setState(() {
        _isFirstLaunchLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstLaunchLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Importing your call history…'),
            ],
          ),
        ),
      );
    }

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
