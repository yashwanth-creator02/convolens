import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/contact_cache.dart';
import '../../../shared/glass_action_ids.dart';
import '../models/contact_summary.dart';
import '../repository/contacts_repository.dart';
import '../widgets/contact_card.dart';
import 'contact_detail_screen.dart';

class ContactSearchScreen extends StatefulWidget {
  final AppDatabase db;

  const ContactSearchScreen({super.key, required this.db});

  @override
  State<ContactSearchScreen> createState() => _ContactSearchScreenState();
}

class _ContactSearchScreenState extends State<ContactSearchScreen> {
  late final ContactsRepository _repository;
  final _titleController = GlassLargeTitleController();
  final _searchFocusNode = FocusNode();
  late final TextEditingController _searchController;
  Timer? _debounce;

  String _query = '';
  final Set<int> _selectedTagIds = {};
  bool _onlyFavorites = false;
  List<Contact> _deviceContacts = [];
  bool _loading = true;

  bool get _hasActiveFilters =>
      _query.isNotEmpty || _selectedTagIds.isNotEmpty || _onlyFavorites;

  @override
  void initState() {
    super.initState();
    _repository = ContactsRepository(widget.db);
    _searchController = TextEditingController();

    if (ContactCache.contacts.isNotEmpty) {
      _deviceContacts = ContactCache.contacts;
      _loading = false;
    } else {
      _load();
    }

    // Land already focused with keyboard up, continuing gesture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  Future<void> _load() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: true,
      );
      if (mounted) {
        setState(() {
          _deviceContacts = contacts;
          _loading = false;
        });
        ContactCache.setContacts(contacts);
      }
    } else {
      if (mounted) {
        setState(() => _loading = false);
      }
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

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _query = value.trim().toLowerCase());
      }
    });
  }

  void _resetAll() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedTagIds.clear();
      _onlyFavorites = false;
    });
  }

  void _openContact(ContactSummary contact) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ContactDetailScreen(
          normalizedNumber: contact.normalizedNumber,
          displayName: contact.displayName,
          displayNumber: contact.displayNumber,
          deviceContact: contact.deviceContact,
          db: widget.db,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GlassScaffold(
      appBar: GlassAppBar.pinned(
        title: const Text('Search Contacts'),
        largeTitleController: _titleController,
        actions: [
          if (_hasActiveFilters)
            GlassBarItem.icon(
              icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
              id: 'contact_search_reset',
              label: 'Reset',
              onTap: () {
                HapticFeedback.lightImpact();
                _resetAll();
              },
            ),
          GlassBarItem.icon(
            icon: const Icon(Icons.close_rounded, size: 20),
            id: GlassActionIds.settings,
            label: 'Close',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Material(
        type: MaterialType.transparency,
        child: _loading
            ? Center(
                child: CircularProgressIndicator(color: scheme.primary),
              )
            : CustomScrollView(
                controller: _titleController.scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          MediaQuery.of(context).padding.top + kToolbarHeight,
                    ),
                  ),

                  // ── Large Title with Integrated Glass Search Bar ───────────
                  GlassLargeTitle(
                    text: 'Search Contacts',
                    controller: _titleController,
                    searchBar: GlassSearchBar(
                      placeholder: 'Search by name or number...',
                      useOwnLayer: true,
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onQueryChanged,
                      onCancel: _resetAll,
                    ),
                  ),

                  // ── Filter Chips Strip (Liquid Glass) ──────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: StreamBuilder<List<Tag>>(
                        stream: widget.db.watchAllTags(),
                        builder: (context, tagSnapshot) {
                          final allTags = tagSnapshot.data ?? [];

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                // 1. All Contacts Chip
                                GlassChip(
                                  label: 'All',
                                  icon: const Icon(
                                    Icons.people_outline_rounded,
                                    size: 15,
                                  ),
                                  selected: _selectedTagIds.isEmpty &&
                                      !_onlyFavorites,
                                  selectedColor:
                                      scheme.primary.withValues(alpha: 0.22),
                                  labelStyle: TextStyle(
                                    color: (_selectedTagIds.isEmpty &&
                                            !_onlyFavorites)
                                        ? scheme.primary
                                        : scheme.onSurface,
                                    fontWeight: (_selectedTagIds.isEmpty &&
                                            !_onlyFavorites)
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  quality: GlassQuality.standard,
                                  useOwnLayer: false,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedTagIds.clear();
                                      _onlyFavorites = false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),

                                // 2. Favorites Chip
                                GlassChip(
                                  label: 'Favorites',
                                  icon: const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  selected: _onlyFavorites,
                                  selectedColor:
                                      Colors.amber.withValues(alpha: 0.22),
                                  labelStyle: TextStyle(
                                    color: _onlyFavorites
                                        ? Colors.amber.shade700
                                        : scheme.onSurface,
                                    fontWeight: _onlyFavorites
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  quality: GlassQuality.standard,
                                  useOwnLayer: false,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _onlyFavorites = !_onlyFavorites;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),

                                // 3. Tags Dropdown (GlassPopover)
                                GlassPopover(
                                  popoverWidth: 260,
                                  popoverBorderRadius: 20,
                                  quality: GlassQuality.standard,
                                  triggerBuilder:
                                      (popoverContext, togglePopover) {
                                    final hasTags = _selectedTagIds.isNotEmpty;
                                    final String label;
                                    if (_selectedTagIds.isEmpty) {
                                      label = 'Tags';
                                    } else if (_selectedTagIds.length == 1) {
                                      final tag = allTags.firstWhere(
                                        (t) => t.id == _selectedTagIds.first,
                                        orElse: () => Tag(
                                          id: _selectedTagIds.first,
                                          name: 'Tag',
                                        ),
                                      );
                                      label = tag.name;
                                    } else {
                                      label =
                                          'Tags (${_selectedTagIds.length})';
                                    }

                                    return GlassChip(
                                      label: label,
                                      icon: Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 20,
                                        color: hasTags
                                            ? scheme.primary
                                            : scheme.onSurfaceVariant,
                                      ),
                                      selected: hasTags,
                                      selectedColor: scheme.primary
                                          .withValues(alpha: 0.22),
                                      labelStyle: TextStyle(
                                        color: hasTags
                                            ? scheme.primary
                                            : scheme.onSurface,
                                        fontWeight: hasTags
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
                                  contentBuilder:
                                      (popoverContext, closePopover) {
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
                                                    MainAxisAlignment
                                                        .spaceBetween,
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
                                                        'Filter by Tag',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              scheme.onSurface,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (_selectedTagIds
                                                      .isNotEmpty)
                                                    GestureDetector(
                                                      onTap: () {
                                                        HapticFeedback
                                                            .selectionClick();
                                                        setState(() {
                                                          _selectedTagIds
                                                              .clear();
                                                        });
                                                        setPopoverState(() {});
                                                      },
                                                      child: Text(
                                                        'Clear',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                              if (allTags.isEmpty)
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 20),
                                                  child: Center(
                                                    child: Text(
                                                      'No tags created yet',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: scheme
                                                            .onSurfaceVariant
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              else
                                                ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                    maxHeight: 220,
                                                  ),
                                                  child: SingleChildScrollView(
                                                    physics:
                                                        const BouncingScrollPhysics(),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children:
                                                          allTags.map((tag) {
                                                        final isSelected =
                                                            _selectedTagIds
                                                                .contains(
                                                          tag.id,
                                                        );
                                                        final tagHue = (tag
                                                                    .name
                                                                    .hashCode
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
                                                                BorderRadius
                                                                    .circular(
                                                              10,
                                                            ),
                                                            onTap: () {
                                                              HapticFeedback
                                                                  .selectionClick();
                                                              setState(() {
                                                                if (isSelected) {
                                                                  _selectedTagIds
                                                                      .remove(
                                                                    tag.id,
                                                                  );
                                                                } else {
                                                                  _selectedTagIds
                                                                      .add(
                                                                    tag.id,
                                                                  );
                                                                }
                                                              });
                                                              setPopoverState(
                                                                () {},
                                                              );
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
                                                                      color:
                                                                          tagColor,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      tag.name,
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            13.5,
                                                                        fontWeight:
                                                                            isSelected ? FontWeight.w700 : FontWeight.w500,
                                                                        color: isSelected
                                                                            ? tagColor
                                                                            : scheme.onSurface,
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
                                                                        ? scheme
                                                                            .primary
                                                                        : scheme
                                                                            .outlineVariant
                                                                            .withValues(
                                                                          alpha:
                                                                              0.5,
                                                                        ),
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
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ── Streamed Contact Search Results ────────────────────────
                  StreamBuilder<Set<String>>(
                    stream: widget.db.watchFavoriteNumbers(),
                    builder: (context, favSnapshot) {
                      final favNumbers = favSnapshot.data ?? const {};

                      return StreamBuilder<Map<String, int>>(
                        stream: widget.db.watchContactColors(),
                        builder: (context, colorSnapshot) {
                          final contactColors = colorSnapshot.data ?? const {};

                          return StreamBuilder<Set<String>?>(
                            stream: _selectedTagIds.isNotEmpty
                                ? widget.db
                                    .watchNumbersForTags(_selectedTagIds)
                                : Stream.value(null),
                            builder: (context, tagSnapshot) {
                              final tagNumbers = tagSnapshot.data;

                              return StreamBuilder<List<ContactSummary>>(
                                stream: _repository.watchContacts(
                                  _deviceContacts,
                                ),
                                builder: (context, snapshot) {
                                  final contacts = snapshot.data ?? [];

                                  final filtered = contacts.where((c) {
                                    final matchesQuery = _query.isEmpty ||
                                        c.displayName
                                            .toLowerCase()
                                            .contains(_query) ||
                                        c.displayNumber
                                            .toLowerCase()
                                            .contains(_query) ||
                                        c.normalizedNumber.contains(_query);
                                    final matchesTag = tagNumbers == null ||
                                        tagNumbers.contains(c.normalizedNumber);
                                    final matchesFav = !_onlyFavorites ||
                                        favNumbers.contains(c.normalizedNumber);
                                    return matchesQuery &&
                                        matchesTag &&
                                        matchesFav;
                                  }).toList();

                                  // Active filter count bar
                                  final showFilterBar = _hasActiveFilters;

                                  if (filtered.isEmpty) {
                                    return _buildNoResultsState(
                                      context,
                                      scheme,
                                    );
                                  }

                                  return SliverMainAxisGroup(
                                    slivers: [
                                      if (showFilterBar)
                                        SliverToBoxAdapter(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              18,
                                              4,
                                              18,
                                              8,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${filtered.length} contact${filtered.length == 1 ? '' : 's'} found',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    HapticFeedback.lightImpact();
                                                    _resetAll();
                                                  },
                                                  child: Text(
                                                    'Clear all',
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: scheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      SliverList(
                                        delegate: SliverChildBuilderDelegate((
                                          context,
                                          index,
                                        ) {
                                          final contact = filtered[index];
                                          return ContactCard(
                                            contact: contact,
                                            db: widget.db,
                                            colorValue: contactColors[
                                                contact.normalizedNumber],
                                            isFavorite: favNumbers.contains(
                                              contact.normalizedNumber,
                                            ),
                                            onTap: contact.displayNumber.isEmpty
                                                ? null
                                                : () => _openContact(contact),
                                          );
                                        }, childCount: filtered.length),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
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

  // ── No Results State (Liquid Glass) ────────────────────────────────────────
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
                    color:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.35),
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
                  'No Matching Contacts',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _query.isNotEmpty
                      ? 'No contacts match "$_query". Try searching by another name, phone number, or tag.'
                      : 'No contacts match the active filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(height: 18),
                  GlassButton(
                    label: 'Clear Filters',
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    quality: GlassQuality.standard,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _resetAll();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
