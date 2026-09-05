import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logger/logger.dart';
import '../../../core/toast/toast_service.dart';
import '../repository/calls_repository.dart';
import '../widgets/history_call_list.dart';
import '../widgets/history_permission_view.dart';

class HistoryScreen extends StatefulWidget {
  final AppDatabase db;
  final GlassLargeTitleController titleController;

  const HistoryScreen({
    super.key,
    required this.db,
    required this.titleController,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  late final CallsRepository _repository;

  StreamSubscription<Setting>? _settingsSubscription;

  bool _isFirstLaunchLoading = false;
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _repository = CallsRepository(widget.db);

    _settingsSubscription = widget.db.watchSettings().listen((settings) {
      Logger.devModeEnabled = settings.devMode;
    });

    _requestFetchAndStore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsSubscription?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _permissionDenied) {
      Logger.debug(
        'App resumed while permission denied — retrying.',
        tag: 'Permission',
      );

      _requestFetchAndStore();
    }
  }

  Future<void> _requestFetchAndStore() async {
    final alreadyHasCalls = await widget.db.hasAnyCalls();

    if (!alreadyHasCalls && mounted) {
      setState(() {
        _isFirstLaunchLoading = true;
      });
    }

    try {
      final status = await Permission.phone.request();

      Logger.debug('Permission status: $status', tag: 'Permission');

      if (status.isPermanentlyDenied) {
        Logger.warning('Permission permanently denied.', tag: 'Permission');

        if (mounted) {
          setState(() {
            _permissionDenied = true;
            _permissionPermanentlyDenied = true;
          });
        }

        return;
      }

      if (!status.isGranted) {
        Logger.warning(
          'Permission not granted, skipping fetch.',
          tag: 'Permission',
        );

        if (mounted) {
          setState(() {
            _permissionDenied = true;
          });
        }

        return;
      }

      if (mounted && _permissionDenied) {
        setState(() {
          _permissionDenied = false;
          _permissionPermanentlyDenied = false;
        });
      }

      final archiveMode = await widget.db.getArchiveMode();

      await _repository.syncFromDevice(archiveMode: archiveMode);

      Logger.debug('Sync complete.', tag: 'Sync');
    } catch (e, stackTrace) {
      Logger.error('Sync failed: $e', tag: 'Sync');

      debugPrint('$stackTrace');

      if (mounted) {
        ToastService.error(
          context,
          alreadyHasCalls
              ? 'Sync failed. Showing your last saved data.'
              : 'Failed to import call history. Pull down to retry.',
        );
      }
    } finally {
      if (!alreadyHasCalls && mounted) {
        setState(() {
          _isFirstLaunchLoading = false;
        });
      }
    }
  }

  Widget _buildInitialLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Importing your call history…'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstLaunchLoading) {
      return _buildInitialLoadingView();
    }

    if (_permissionDenied) {
      return HistoryPermissionView(
        permanentlyDenied: _permissionPermanentlyDenied,
        onGrantPermission: _requestFetchAndStore,
        onOpenSettings: openAppSettings,
      );
    }

    return StreamBuilder<List<Call>>(
      stream: widget.db.watchAllCalls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load call history.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final calls = snapshot.data ?? [];

        return Material(
          type: MaterialType.transparency,
          child: CustomScrollView(
            controller: widget.titleController.scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight,
                ),
              ),
              GlassLargeTitle(
                text: 'History',
                controller: widget.titleController,
              ),
              SliverHistoryCallList(calls: calls, db: widget.db),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }
}
