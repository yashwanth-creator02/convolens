import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/contact_cache.dart';
import '../../../core/utils/normalize_number.dart';
import '../models/search_filters.dart';
import '../widgets/call_card.dart';

class SearchScreen extends StatefulWidget {
  final AppDatabase db;
  final String? initialContactQuery;

  const SearchScreen({super.key, required this.db, this.initialContactQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _titleController = GlassLargeTitleController();
  final _searchFocusNode = FocusNode();
  late final TextEditingController _searchController;
  SearchFilters _filters = const SearchFilters();
  Timer? _debounce;

  List<Contact> _deviceContacts = [];

  @override
  void initState() {
    super.initState();

    final initial = widget.initialContactQuery?.trim();
    if (initial != null && initial.isNotEmpty) {
      _searchController = TextEditingController(text: initial);
      _filters = _filters.copyWith(query: initial);
    } else {
      _searchController = TextEditingController();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }

    if (ContactCache.contacts.isNotEmpty) {
      _deviceContacts = ContactCache.contacts;
    } else {
      _loadContacts();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _titleController.dispose();
    super.dispose();
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
        ContactCache.setContacts(contacts);
      }
    }
  }

  Contact? _findContact(String? number) {
    if (number == null || number.isEmpty) return null;
    final cached = ContactCache.findContact(number: number);
    if (cached != null) return cached;

    final normalized = normalizePhoneNumber(number);
    for (final contact in _deviceContacts) {
      for (final phone in contact.phones) {
        if (normalizePhoneNumber(phone.number) == normalized) {
          return contact;
        }
      }
    }
    return null;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _filters = _filters.copyWith(query: value.trim());
        });
      }
    });
  }

  void _resetAllFilters() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _filters = const SearchFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Search'),
        largeTitleController: _titleController,
        actions: [
          if (!_filters.isEmpty)
            GlassBarItem.icon(
              icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
              id: 'search_clear_filters',
              label: 'Reset',
              onTap: () {
                HapticFeedback.lightImpact();
                _resetAllFilters();
              },
            ),
          GlassBarItem.icon(
            icon: const Icon(Icons.close_rounded, size: 20),
            id: 'search_close_button',
            label: 'Close',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
          controller: _titleController.scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
            ),

            // ── Large Title with Integrated Glass Search Bar ─────────────────
            GlassLargeTitle(
              text: 'Search',
              controller: _titleController,
              searchBar: GlassSearchBar(
                placeholder: 'Search calls, notes, tags...',
                useOwnLayer: true,
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onCancel: () {
                  _searchController.clear();
                  setState(() => _filters = _filters.copyWith(query: ''));
                },
              ),
            ),

            // ── Filter Chips Strip with Tags Dropdown ────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: StreamBuilder<List<Tag>>(
                  stream: widget.db.watchAllTags(),
                  builder: (context, tagSnapshot) {
                    final tags = tagSnapshot.data ?? [];
                    final hasSelectedTags = _filters.selectedTags.isNotEmpty;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // 1. Attachments Filter Chip
                          GlassChip(
                            label: 'Attachments',
                            icon: const Icon(Icons.attach_file_rounded, size: 16),
                            selected: _filters.hasAttachment,
                            selectedColor: scheme.primary.withValues(alpha: 0.22),
                            labelStyle: TextStyle(
                              color: _filters.hasAttachment
                                  ? scheme.primary
                                  : scheme.onSurface,
                              fontWeight: _filters.hasAttachment
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                            quality: GlassQuality.standard,
                            useOwnLayer: false,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _filters = _filters.copyWith(
                                  hasAttachment: !_filters.hasAttachment,
                                );
                              });
                            },
                          ),
                          const SizedBox(width: 8),

                          // 2. Reminders Filter Chip
                          GlassChip(
                            label: 'Reminders',
                            icon: const Icon(Icons.alarm_rounded, size: 16),
                            selected: _filters.hasReminder,
                            selectedColor: Colors.amber.withValues(alpha: 0.22),
                            labelStyle: TextStyle(
                              color: _filters.hasReminder
                                  ? Colors.amber.shade700
                                  : scheme.onSurface,
                              fontWeight: _filters.hasReminder
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                            quality: GlassQuality.standard,
                            useOwnLayer: false,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _filters = _filters.copyWith(
                                  hasReminder: !_filters.hasReminder,
                                );
                              });
                            },
                          ),
                          const SizedBox(width: 8),

                          // 3. Has Notes Filter Chip
                          GlassChip(
                            label: 'Has Notes',
                            icon: const Icon(Icons.sticky_note_2_outlined, size: 16),
                            selected: _filters.hasNotes,
                            selectedColor: scheme.tertiary.withValues(alpha: 0.22),
                            labelStyle: TextStyle(
                              color: _filters.hasNotes
                                  ? scheme.tertiary
                                  : scheme.onSurface,
                              fontWeight: _filters.hasNotes
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                            quality: GlassQuality.standard,
                            useOwnLayer: false,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _filters = _filters.copyWith(
                                  hasNotes: !_filters.hasNotes,
                                );
                              });
                            },
                          ),
                          const SizedBox(width: 8),

                          // 4. Missed Calls Filter Chip
                          GlassChip(
                            label: 'Missed',
                            icon: const Icon(Icons.call_missed_rounded, size: 16),
                            selected: _filters.callType == 3,
                            selectedColor: Colors.red.withValues(alpha: 0.22),
                            labelStyle: TextStyle(
                              color: _filters.callType == 3
                                  ? Colors.red
                                  : scheme.onSurface,
                              fontWeight: _filters.callType == 3
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                            quality: GlassQuality.standard,
                            useOwnLayer: false,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _filters = _filters.copyWith(
                                  callType: () =>
                                      _filters.callType == 3 ? null : 3,
                                );
                              });
                            },
                          ),
                          const SizedBox(width: 8),

                          // 5. Tags Multi-Select Dropdown Menu
                          GlassPopover(
                            popoverWidth: 260,
                            popoverBorderRadius: 20.0,
                            quality: GlassQuality.standard,
                            triggerBuilder: (popoverCtx, togglePopover) {
                              return GlassChip(
                                label: hasSelectedTags
                                    ? 'Tags (${_filters.selectedTags.length})'
                                    : 'Tags',
                                icon: Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 20,
                                  color: hasSelectedTags
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                                selected: hasSelectedTags,
                                selectedColor: scheme.primary.withValues(alpha: 0.22),
                                labelStyle: TextStyle(
                                  color: hasSelectedTags
                                      ? scheme.primary
                                      : scheme.onSurface,
                                  fontWeight: hasSelectedTags
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                quality: GlassQuality.standard,
                                useOwnLayer: false,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  togglePopover();
                                },
                              );
                            },
                            contentBuilder: (popoverContext, closePopover) {
                              return StatefulBuilder(
                                builder: (context, setPopoverState) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Header
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.label_rounded,
                                                  size: 16,
                                                  color: scheme.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Select Tags',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: scheme.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (_filters.selectedTags.isNotEmpty)
                                              GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.selectionClick();
                                                  setState(() {
                                                    _filters = _filters.copyWith(
                                                      selectedTags: const {},
                                                    );
                                                  });
                                                  setPopoverState(() {});
                                                },
                                                child: Text(
                                                  'Clear (${_filters.selectedTags.length})',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: scheme.primary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Divider(
                                          height: 1,
                                          color: scheme.outlineVariant
                                              .withValues(alpha: 0.25),
                                        ),
                                        const SizedBox(height: 6),

                                        if (tags.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 20,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'No tags created yet',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: scheme.onSurfaceVariant
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxHeight: 220,
                                            ),
                                            child: SingleChildScrollView(
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: tags.map((tag) {
                                                  final isSelected = _filters
                                                      .selectedTags
                                                      .contains(tag.name);
                                                  final tagHue = (tag.name.hashCode
                                                              .abs() %
                                                          360)
                                                      .toDouble();
                                                  final tagColor =
                                                      HSLColor.fromAHSL(
                                                    1.0,
                                                    tagHue,
                                                    0.65,
                                                    0.55,
                                                  ).toColor();

                                                  return Material(
                                                    type: MaterialType
                                                        .transparency,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      onTap: () {
                                                        HapticFeedback
                                                            .selectionClick();
                                                        setState(() {
                                                          final next = Set<String>.from(
                                                            _filters.selectedTags,
                                                          );
                                                          if (isSelected) {
                                                            next.remove(tag.name);
                                                          } else {
                                                            next.add(tag.name);
                                                          }
                                                          _filters =
                                                              _filters.copyWith(
                                                            selectedTags: next,
                                                          );
                                                        });
                                                        setPopoverState(() {});
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 6,
                                                          vertical: 8,
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              width: 10,
                                                              height: 10,
                                                              decoration:
                                                                  BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: tagColor,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 10),
                                                            Expanded(
                                                              child: Text(
                                                                tag.name,
                                                                style: TextStyle(
                                                                  fontSize: 13.5,
                                                                  fontWeight:
                                                                      isSelected
                                                                          ? FontWeight
                                                                              .w700
                                                                          : FontWeight
                                                                              .w500,
                                                                  color: isSelected
                                                                      ? tagColor
                                                                      : scheme
                                                                          .onSurface,
                                                                ),
                                                              ),
                                                            ),
                                                            Icon(
                                                              isSelected
                                                                  ? Icons
                                                                      .check_circle_rounded
                                                                  : Icons
                                                                      .radio_button_unchecked_rounded,
                                                              size: 18,
                                                              color: isSelected
                                                                  ? tagColor
                                                                  : scheme
                                                                      .outlineVariant
                                                                      .withValues(
                                                                          alpha:
                                                                              0.5),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),

                                        const SizedBox(height: 8),
                                        Center(
                                          child: SizedBox(
                                            height: 34,
                                            child: GlassButton(
                                              label: 'Done',
                                              icon: const Icon(
                                                Icons.check_rounded,
                                                size: 16,
                                              ),
                                              quality: GlassQuality.standard,
                                              onTap: () {
                                                HapticFeedback.lightImpact();
                                                closePopover();
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          // 6. Selected Tag Chips (removable inline chips)
                          if (_filters.selectedTags.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            ..._filters.selectedTags.map((tagName) {
                              final tagHue =
                                  (tagName.hashCode.abs() % 360).toDouble();
                              final tagColor = HSLColor.fromAHSL(
                                1.0,
                                tagHue,
                                0.65,
                                0.55,
                              ).toColor();

                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GlassChip(
                                  label: tagName,
                                  icon: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tagColor,
                                    ),
                                  ),
                                  selected: true,
                                  selectedColor:
                                      tagColor.withValues(alpha: 0.22),
                                  labelStyle: TextStyle(
                                    color: tagColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  deleteIcon: const Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                  ),
                                  onDeleted: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      final next = Set<String>.from(
                                        _filters.selectedTags,
                                      )..remove(tagName);
                                      _filters = _filters.copyWith(
                                        selectedTags: next,
                                      );
                                    });
                                  },
                                  quality: GlassQuality.standard,
                                  useOwnLayer: false,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      final next = Set<String>.from(
                                        _filters.selectedTags,
                                      )..remove(tagName);
                                      _filters = _filters.copyWith(
                                        selectedTags: next,
                                      );
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Active Filters Summary Bar ───────────────────────────────────
            if (!_filters.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: scheme.primary.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _filters.activeFilterCount > 0
                                ? '${_filters.activeFilterCount} active ${_filters.activeFilterCount == 1 ? 'filter' : 'filters'}'
                                : 'Active search',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _resetAllFilters();
                        },
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Live Streamed Call Results ───────────────────────────────────
            StreamBuilder<List<Call>>(
              stream: widget.db.searchCalls(
                contactQuery: _filters.contactQuery,
                noteQuery: _filters.noteQuery,
                tagQuery: _filters.tagQuery,
                selectedTags: _filters.selectedTags,
                hasAttachment: _filters.hasAttachment,
                hasReminder: _filters.hasReminder,
                generalQuery: _filters.query,
                hasNotes: _filters.hasNotes,
                callType: _filters.callType,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: scheme.primary,
                      ),
                    ),
                  );
                }

                final results = snapshot.data!;
                if (results.isEmpty) {
                  return _buildNoResultsState(context, scheme);
                }

                return StreamBuilder<Setting>(
                  stream: widget.db.watchSettings(),
                  builder: (context, settingsSnapshot) {
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final call = results[index];
                            final contact =
                                ContactCache.findContact(number: call.number) ??
                                    _findContact(call.number);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: CallCard(
                                call: call,
                                db: widget.db,
                                settings: settingsSnapshot.data,
                                deviceContact: contact,
                              ),
                            );
                          },
                          childCount: results.length,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ── No Results State ───────────────────────────────────────────────────────
  Widget _buildNoResultsState(BuildContext context, ColorScheme scheme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape: const LiquidRoundedSuperellipse(borderRadius: 24),
            quality: GlassQuality.standard,
            useOwnLayer: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 28,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Matching Calls',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchController.text.trim().isNotEmpty
                      ? 'No calls match "${_searchController.text.trim()}". Try searching by another keyword or adjusting filters.'
                      : 'No calls match your active filter combination. Try resetting your filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 18),
                GlassButton(
                  label: 'Clear Filters',
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  quality: GlassQuality.standard,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _resetAllFilters();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
