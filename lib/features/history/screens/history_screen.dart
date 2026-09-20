import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logger/logger.dart';
import '../../../core/toast/toast_service.dart';
import '../repository/calls_repository.dart';
import '../utils/build_history_items.dart';
import '../utils/year_index.dart';
import '../widgets/history_call_list.dart';
import '../widgets/history_permission_view.dart';
import '../widgets/timeline_wave_navigator.dart';

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
  Setting? _currentSettings;

  final GlobalKey<SliverHistoryCallListState> _historyListKey =
      GlobalKey<SliverHistoryCallListState>();

  final Map<int, GlobalKey> _yearBoundaryKeys = {};

  final ValueNotifier<String?> _visibleDateNotifier = ValueNotifier<String?>(
    null,
  );
  final ValueNotifier<bool> _showScrollToTopNotifier = ValueNotifier<bool>(
    false,
  );

  List<Contact> _deviceContacts = [];

  bool _isFirstLaunchLoading = false;
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;

  // Cached computation of items and yearIndex to avoid recomputing on build
  List<Call>? _lastCalls;
  List<Object> _cachedItems = [];
  List<YearIndexEntry> _cachedYearIndex = [];
  Map<int, GlobalKey> _cachedBoundaryKeys = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _repository = CallsRepository(widget.db);

    _settingsSubscription = widget.db.watchSettings().listen((settings) {
      Logger.devModeEnabled = settings.devMode;
      if (mounted && _currentSettings != settings) {
        setState(() {
          _currentSettings = settings;
        });
      }
    });

    _loadContacts();

    widget.titleController.scrollController.addListener(_updateVisibleDate);

    _requestFetchAndStore();
  }

  void _updateVisibleDate() {
    if (!mounted) return;

    final scrollController = widget.titleController.scrollController;
    final showScrollToTop = scrollController.offset > 300;
    if (showScrollToTop != _showScrollToTopNotifier.value) {
      _showScrollToTopNotifier.value = showScrollToTop;
    }

    final listState = _historyListKey.currentState;
    if (listState == null) return;

    listState.updateVisibleDate();

    final date = listState.visibleDate;
    if (date != null && date != _visibleDateNotifier.value) {
      _visibleDateNotifier.value = date;
    }
  }

  Future<void> _loadContacts() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: true,
      );
      if (mounted) {
        setState(() {
          _deviceContacts = contacts;
        });
      }
    }
  }

  @override
  void dispose() {
    widget.titleController.scrollController.removeListener(_updateVisibleDate);
    WidgetsBinding.instance.removeObserver(this);
    _settingsSubscription?.cancel();
    _visibleDateNotifier.dispose();
    _showScrollToTopNotifier.dispose();

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

  double _calculateExactOffset(int targetIndex) {
    if (targetIndex <= 0 || _cachedItems.isEmpty) return 0.0;

    final showBottomTab =
        (_currentSettings?.showCallType ?? true) ||
        (_currentSettings?.showDuration ?? true) ||
        (_currentSettings?.showTime ?? true);
    final cardHeight = showBottomTab ? 116.0 : 86.0;
    const headerHeight = 42.0;

    double offset = 0.0;
    final limit = targetIndex.clamp(0, _cachedItems.length);
    for (int i = 0; i < limit; i++) {
      final item = _cachedItems[i];
      if (item is String) {
        offset += headerHeight;
      } else {
        offset += cardHeight;
      }
    }
    return offset;
  }

  void _onCommitYear(int itemIndex) {
    if (!mounted || _cachedItems.isEmpty) return;
    final scrollController = widget.titleController.scrollController;
    if (!scrollController.hasClients) return;

    final key = _cachedBoundaryKeys[itemIndex];
    final targetContext = key?.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final maxExtent = scrollController.position.maxScrollExtent;
    final targetOffset = _calculateExactOffset(itemIndex).clamp(0.0, maxExtent);

    scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
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
      builder: (context, callsSnapshot) {
        if (callsSnapshot.connectionState == ConnectionState.waiting &&
            !callsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (callsSnapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load call history.\n${callsSnapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final calls = callsSnapshot.data ?? [];

        // Memoize calculation of items and yearIndex
        if (!identical(_lastCalls, calls)) {
          _lastCalls = calls;
          _cachedItems = buildHistoryItems(calls);
          _cachedYearIndex = buildYearIndex(_cachedItems);
          _cachedBoundaryKeys = <int, GlobalKey>{
            for (final entry in _cachedYearIndex)
              entry.itemIndex: _yearBoundaryKeys.putIfAbsent(
                entry.itemIndex,
                () => GlobalKey(),
              ),
          };

          final String? firstDate =
              _cachedItems.isNotEmpty && _cachedItems.first is String
              ? _cachedItems.first as String
              : null;

          if (_visibleDateNotifier.value == null && firstDate != null) {
            _visibleDateNotifier.value = firstDate;
          }
        }

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                scrollCacheExtent: const ScrollCacheExtent.pixels(250.0),
                controller: widget.titleController.scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          MediaQuery.of(context).padding.top + kToolbarHeight,
                    ),
                  ),
                  GlassLargeTitle(
                    text: 'History',
                    controller: widget.titleController,
                  ),
                  StreamBuilder<Map<int, CallDetail>>(
                    stream: widget.db.watchAllCallDetailsMap(),
                    builder: (context, detailsSnapshot) {
                      final detailsMap = detailsSnapshot.data ?? const {};
                      return StreamBuilder<Map<int, List<Tag>>>(
                        stream: widget.db.watchAllCallTagsMap(),
                        builder: (context, tagsSnapshot) {
                          final tagsMap = tagsSnapshot.data ?? const {};
                          return StreamBuilder<Map<int, int>>(
                            stream: widget.db.watchAllCallAttachmentCountsMap(),
                            builder: (context, attachmentsSnapshot) {
                              final attachmentCountsMap =
                                  attachmentsSnapshot.data ?? const {};
                              return SliverHistoryCallList(
                                key: _historyListKey,
                                items: _cachedItems,
                                db: widget.db,
                                settings: _currentSettings,
                                deviceContacts: _deviceContacts,
                                boundaryKeys: _cachedBoundaryKeys,
                                callDetailsMap: detailsMap,
                                callTagsMap: tagsMap,
                                attachmentCountsMap: attachmentCountsMap,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
              ValueListenableBuilder<String?>(
                valueListenable: _visibleDateNotifier,
                builder: (context, visibleDate, _) {
                  if (visibleDate == null) {
                    return const SizedBox.shrink();
                  }

                  final String? firstDate =
                      _cachedItems.isNotEmpty && _cachedItems.first is String
                      ? _cachedItems.first as String
                      : null;
                  final bool isAtTopDate = visibleDate == firstDate;

                  return Positioned(
                    top:
                        MediaQuery.of(context).padding.top +
                        kToolbarHeight +
                        12,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: isAtTopDate ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: AnimatedScale(
                            scale: isAtTopDate ? 0.8 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutBack,
                            child: GlassContainer(
                              quality: GlassQuality.standard,
                              useOwnLayer: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              shape: const LiquidRoundedSuperellipse(
                                borderRadius: 18,
                              ),
                              child: Text(
                                visibleDate,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: 0,
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
                bottom: 100,
                child: TimelineWaveNavigator(
                  items: _cachedItems,
                  yearIndex: _cachedYearIndex,
                  onCommit: _onCommitYear,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _showScrollToTopNotifier,
                builder: (context, showScrollToTop, _) {
                  return Positioned(
                    right: 21,
                    bottom: 100,
                    child: AnimatedSlide(
                      offset: showScrollToTop
                          ? Offset.zero
                          : const Offset(2, 0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        opacity: showScrollToTop ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: GlassContainer(
                          quality: GlassQuality.standard,
                          useOwnLayer: false,
                          shape: const LiquidOval(),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: () {
                              widget.titleController.scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
