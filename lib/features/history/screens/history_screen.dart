import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/logger/logger.dart';
import '../../../core/services/contact_cache.dart';
import '../../../core/toast/toast_service.dart';
import '../repository/calls_repository.dart';
import '../utils/build_history_items.dart';
import '../utils/year_index.dart';
import '../widgets/history_call_list.dart';
import '../widgets/history_filter_chips.dart';
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
  final ValueNotifier<bool> _showDateChipNotifier = ValueNotifier<bool>(
    false,
  );

  List<Contact> _deviceContacts = [];

  bool _isFirstLaunchLoading = false;
  bool _permissionDenied = false;
  bool _permissionPermanentlyDenied = false;

  // Cached computation of items and yearIndex to avoid recomputing on build
  HistoryFilterType _selectedFilter = HistoryFilterType.all;
  HistoryFilterType? _lastFilter;
  List<Call>? _lastCalls;
  List<Object> _cachedItems = [];
  List<YearIndexEntry> _cachedYearIndex = [];
  Map<int, GlobalKey> _cachedBoundaryKeys = {};

  late final Stream<List<Call>> _callsStream;
  late final Stream<Map<int, CallDetail>> _detailsStream;
  late final Stream<Map<int, List<Tag>>> _tagsStream;
  late final Stream<Map<int, int>> _attachmentCountsStream;

  List<Call> _filterCalls(List<Call> calls) {
    switch (_selectedFilter) {
      case HistoryFilterType.all:
        return calls;
      case HistoryFilterType.missed:
        return calls.where((c) => c.type == 3 || c.type == 5 || c.type == 6).toList();
      case HistoryFilterType.incoming:
        return calls.where((c) => c.type == 1).toList();
      case HistoryFilterType.outgoing:
        return calls.where((c) => c.type == 2).toList();
      case HistoryFilterType.unknown:
        return calls.where((c) => c.name == null || c.name!.trim().isEmpty).toList();
    }
  }

  Map<HistoryFilterType, int> _computeCounts(List<Call> calls) {
    int missed = 0;
    int incoming = 0;
    int outgoing = 0;
    int unknown = 0;
    for (final c in calls) {
      if (c.type == 3 || c.type == 5 || c.type == 6) missed++;
      if (c.type == 1) incoming++;
      if (c.type == 2) outgoing++;
      if (c.name == null || c.name!.trim().isEmpty) unknown++;
    }
    return {
      HistoryFilterType.all: calls.length,
      HistoryFilterType.missed: missed,
      HistoryFilterType.incoming: incoming,
      HistoryFilterType.outgoing: outgoing,
      HistoryFilterType.unknown: unknown,
    };
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _repository = CallsRepository(widget.db);
    _callsStream = widget.db.watchAllCalls();
    _detailsStream = widget.db.watchAllCallDetailsMap();
    _tagsStream = widget.db.watchAllCallTagsMap();
    _attachmentCountsStream = widget.db.watchAllCallAttachmentCountsMap();

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
    final offset = scrollController.hasClients ? scrollController.offset : 0.0;

    final showScrollToTop = offset > 300;
    if (showScrollToTop != _showScrollToTopNotifier.value) {
      _showScrollToTopNotifier.value = showScrollToTop;
    }

    final showDateChip = offset > 40;
    if (showDateChip != _showDateChipNotifier.value) {
      _showDateChipNotifier.value = showDateChip;
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
      ContactCache.setContacts(contacts);
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
    _showDateChipNotifier.dispose();

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
    final syncEnabled = await widget.db.getSyncEnabled();
    if (!syncEnabled) {
      Logger.debug('Sync is disabled in settings. Skipping fetch.', tag: 'Sync');
      if (mounted && _isFirstLaunchLoading) {
        setState(() {
          _isFirstLaunchLoading = false;
        });
      }
      return;
    }

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

    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;
    const largeTitleCollapseTravel = 96.0;

    final showBottomTab =
        (_currentSettings?.showCallType ?? true) ||
        (_currentSettings?.showDuration ?? true) ||
        (_currentSettings?.showTime ?? true);
    final cardHeight = showBottomTab ? 116.0 : 86.0;
    const headerHeight = 42.0;

    double offset = topInset + largeTitleCollapseTravel;
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

    if (itemIndex <= 0) {
      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final key = _cachedBoundaryKeys[itemIndex];
    final targetContext = key?.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final maxExtent = scrollController.position.maxScrollExtent;
    final targetOffset = _calculateExactOffset(itemIndex).clamp(0.0, maxExtent);

    scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _showDateJumperSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final scheme = Theme.of(context).colorScheme;

    const monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    GlassModalSheet.show(
      context: context,
      quality: GlassQuality.standard,
      detents: const {GlassSheetDetent.medium, GlassSheetDetent.large},
      initialState: GlassSheetState.half,
      builder: (sheetContext) {
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jump to Date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            Text(
                              'Select a month or year to navigate',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _onCommitYear(0);
                        },
                        child: GlassContainer(
                          quality: GlassQuality.standard,
                          useOwnLayer: false,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          shape: const LiquidRoundedSuperellipse(
                            borderRadius: 14,
                          ),
                          child: Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_cachedYearIndex.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No history entries found',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._cachedYearIndex.map((yearEntry) {
                      final months = buildMonthIndex(
                        _cachedItems,
                        yearEntry.year,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _onCommitYear(yearEntry.itemIndex);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${yearEntry.year}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: scheme.primary.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  months.map((mEntry) {
                                    final mName =
                                        (mEntry.month >= 1 &&
                                                mEntry.month <= 12)
                                            ? monthNames[mEntry.month]
                                            : 'M${mEntry.month}';
                                    return InkWell(
                                      onTap: () {
                                        Navigator.of(sheetContext).pop();
                                        _onCommitYear(mEntry.itemIndex);
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.surfaceContainerHighest
                                              .withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: scheme.outlineVariant
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Text(
                                          mName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
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
      stream: _callsStream,
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

        final allCalls = callsSnapshot.data ?? [];
        final filteredCalls = _filterCalls(allCalls);
        final counts = _computeCounts(allCalls);

        // Memoize calculation of items and yearIndex
        if (!identical(_lastCalls, filteredCalls) || _lastFilter != _selectedFilter) {
          _lastCalls = filteredCalls;
          _lastFilter = _selectedFilter;
          _cachedItems = buildHistoryItems(filteredCalls);
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

        final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;
        const bottomInset = 100.0;

        return Material(
          type: MaterialType.transparency,
          child: TimelineWaveNavigator(
            items: _cachedItems,
            yearIndex: _cachedYearIndex,
            onCommit: _onCommitYear,
            topInset: topInset,
            bottomInset: bottomInset,
            child: Stack(
              children: [
                CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                scrollCacheExtent: const ScrollCacheExtent.pixels(600.0),
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: HistoryFilterChips(
                        currentFilter: _selectedFilter,
                        counts: counts,
                        onFilterChanged: (filter) {
                          if (_selectedFilter != filter) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedFilter = filter;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  if (_cachedItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedFilter.icon,
                              size: 48,
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No ${_selectedFilter.label.toLowerCase()} calls found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    StreamBuilder<Map<int, CallDetail>>(
                      stream: _detailsStream,
                      builder: (context, detailsSnapshot) {
                        final detailsMap = detailsSnapshot.data ?? const {};
                        return StreamBuilder<Map<int, List<Tag>>>(
                          stream: _tagsStream,
                          builder: (context, tagsSnapshot) {
                            final tagsMap = tagsSnapshot.data ?? const {};
                            return StreamBuilder<Map<int, int>>(
                              stream: _attachmentCountsStream,
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
              ValueListenableBuilder<bool>(
                valueListenable: _showDateChipNotifier,
                builder: (context, showDateChip, _) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: _visibleDateNotifier,
                    builder: (context, visibleDate, _) {
                      if (visibleDate == null) {
                        return const SizedBox.shrink();
                      }

                      final isVisible = showDateChip && visibleDate.isNotEmpty;

                      return Positioned(
                        top:
                            MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            12,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          ignoring: !isVisible,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: isVisible ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: AnimatedScale(
                                scale: isVisible ? 1.0 : 0.8,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutBack,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: isVisible
                                      ? () => _showDateJumperSheet(context)
                                      : null,
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          visibleDate,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
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
        ),
      );
    },
  );
}
}
