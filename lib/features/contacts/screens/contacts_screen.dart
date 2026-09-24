import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../models/contact_summary.dart';
import '../repository/contacts_repository.dart';
import '../utils/group_contacts_by_letter.dart';
import '../widgets/contact_card.dart';
import '../widgets/contacts_filter_chips.dart';
import '../widgets/favorites_carousel.dart';
import '../widgets/glass_alphabet_scrubber.dart';
import 'contact_detail_screen.dart';
import 'contact_search_screen.dart';
import '../../../shared/utils/stretch_reveal_route.dart';

class ContactsScreen extends StatefulWidget {
  final AppDatabase db;
  final GlassLargeTitleController titleController;

  const ContactsScreen({
    super.key,
    required this.db,
    required this.titleController,
  });

  @override
  State<ContactsScreen> createState() => ContactsScreenState();
}

class ContactsScreenState extends State<ContactsScreen>
    with WidgetsBindingObserver {
  late final ContactsRepository _repository;

  bool _isActive = false;
  bool _contactsLoaded = false;
  List<ContactSummary> _cachedContacts = [];
  Set<String> _cachedFavorites = {};
  int _cachedArchivedCount = 0;

  List<ContactSummary> _cachedFavoritesList = [];
  List<ContactSummary> _cachedArchivedContacts = [];

  ContactFilterMode _filterMode = ContactFilterMode.all;
  List<Object> _computedItems = [];
  List<String> _computedOrderedLetters = [];

  void _recomputeListItems() {
    if (_cachedContacts.isEmpty && _cachedArchivedContacts.isEmpty) {
      _computedItems = [];
      _computedOrderedLetters = [];
      _cachedFavoritesList = [];
      return;
    }

    final favorites = _cachedContacts
        .where(
          (contact) => _cachedFavorites.contains(contact.normalizedNumber),
        )
        .toList()
      ..sort(
        (a, b) => a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        ),
      );

    _cachedFavoritesList = favorites;

    switch (_filterMode) {
      case ContactFilterMode.all:
        final grouped = groupContactsByLetter(_cachedContacts);
        final orderedLetters = grouped.keys.toList()
          ..sort((a, b) {
            if (a == '#') return 1;
            if (b == '#') return -1;
            return a.compareTo(b);
          });

        final items = <Object>[];
        for (final letter in orderedLetters) {
          _letterKeys.putIfAbsent(letter, () => GlobalKey());
          items.add(letter);
          items.addAll(grouped[letter]!);
        }

        _computedItems = items;
        _computedOrderedLetters = orderedLetters;
        break;

      case ContactFilterMode.archived:
        final sortedArchived = [..._cachedArchivedContacts]
          ..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );
        _computedItems = sortedArchived;
        _computedOrderedLetters = [];
        break;
    }
  }

  StreamSubscription<List<ContactSummary>>? _contactsSub;
  StreamSubscription<Set<String>>? _favoritesSub;
  StreamSubscription<List<ContactSummary>>? _archivedSub;

  bool _permissionGranted = false;
  bool _loadingContacts = true;
  bool _pullSearchTriggered = false;

  List<Contact> _deviceContacts = [];
  final Map<String, GlobalKey> _letterKeys = {};
  final GlobalKey _dashboardKey = GlobalKey();
  double _measuredDashboardHeight = 0.0;

  double get _dashboardHeight {
    final box = _dashboardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.height > 0) {
      _measuredDashboardHeight = box.size.height;
      return box.size.height;
    }
    if (_measuredDashboardHeight > 0) {
      return _measuredDashboardHeight;
    }
    return _cachedFavoritesList.isNotEmpty ? 196.0 : 56.0;
  }

  final _searchFocusNode = FocusNode();

  void setActive(bool active) {
    if (_isActive == active) return;
    _isActive = active;
    _updateSubscriptions();
  }

  void _updateSubscriptions() {
    _contactsSub?.cancel();
    _favoritesSub?.cancel();
    _archivedSub?.cancel();
    _contactsSub = null;
    _favoritesSub = null;
    _archivedSub = null;

    if (!_isActive || _loadingContacts) return;

    _contactsSub = _repository.watchContacts(_deviceContacts).listen((data) {
      if (mounted) {
        setState(() {
          _cachedContacts = data;
          _contactsLoaded = true;
          _recomputeListItems();
        });
      }
    });

    _favoritesSub = widget.db.watchFavoriteNumbers().listen((data) {
      if (mounted) {
        setState(() {
          _cachedFavorites = data;
          _recomputeListItems();
        });
      }
    });

    _archivedSub = _repository.watchArchivedContacts(_deviceContacts).listen((
      data,
    ) {
      if (mounted) {
        setState(() {
          _cachedArchivedContacts = data;
          _cachedArchivedCount = data.length;
          _recomputeListItems();
        });
      }
    });
  }

  Future<void> refreshDeviceContacts() => _loadDeviceContacts();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _repository = ContactsRepository(widget.db);

    _loadDeviceContacts();

    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocusNode.dispose();
    _contactsSub?.cancel();
    _favoritesSub?.cancel();
    _archivedSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_permissionGranted) {
      _loadDeviceContacts();
    }
  }

  Future<void> _loadDeviceContacts() async {
    if (!mounted) return;

    setState(() {
      _loadingContacts = true;
    });

    final status = await Permission.contacts.status;

    if (!mounted) return;

    if (!status.isGranted) {
      setState(() {
        _permissionGranted = false;
        _loadingContacts = false;
      });
      return;
    }

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: true,
      );

      if (!mounted) return;

      setState(() {
        _permissionGranted = true;
        _deviceContacts = contacts;
        _loadingContacts = false;
      });
      _updateSubscriptions();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _permissionGranted = true;
        _loadingContacts = false;
      });
      _updateSubscriptions();
    }
  }

  Future<void> _requestContactsPermission() async {
    final status = await Permission.contacts.request();

    if (!mounted) return;

    if (status.isGranted) {
      await _loadDeviceContacts();
    }
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
      _openContactSearch();
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;

    // Overscrolling at the top shows as negative pixels.
    if (metrics.pixels < -80 && !_pullSearchTriggered) {
      _pullSearchTriggered = true;
      _openContactSearch();
    }

    if (notification is ScrollEndNotification) {
      _pullSearchTriggered = false;
    }

    return false; // let the notification keep bubbling
  }

  void _openContactSearch() {
    Navigator.of(context).push(
      StretchRevealRoute(
        builder: (context) => ContactSearchScreen(db: widget.db),
      ),
    );
  }

  void _openContact(ContactSummary contact) {
    if (contact.displayNumber.isEmpty) return;

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

  void _scrollToLetter(String letter) {
    final index = _computedItems.indexOf(letter);
    if (index == -1) return;

    final scrollController = widget.titleController.scrollController;
    if (!scrollController.hasClients) return;

    if (_computedOrderedLetters.isNotEmpty &&
        letter == _computedOrderedLetters.first) {
      scrollController.jumpTo(0.0);
      return;
    }

    double listOffsetBeforeTarget = 0.0;
    for (int i = 0; i < index; i++) {
      final item = _computedItems[i];
      if (item is String) {
        listOffsetBeforeTarget += 38.0;
      } else if (item is ContactSummary) {
        listOffsetBeforeTarget += 62.0;
      }
    }

    // 96.0px is the GlassLargeTitle collapse travel.
    // _dashboardHeight is the FavoritesCarousel + FilterChips header.
    final baseOffset = 96.0 + _dashboardHeight;
    final maxScroll = scrollController.position.maxScrollExtent;
    final target = (baseOffset + listOffsetBeforeTarget).clamp(0.0, maxScroll);
    scrollController.jumpTo(target);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _letterKeys[letter];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          alignment: 0.0,
          duration: const Duration(milliseconds: 60),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingContacts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_permissionGranted) {
      return _buildPermissionView();
    }

    return Material(
      type: MaterialType.transparency,
      child: _buildContactsList(),
    );
  }

  Widget _buildContactsList() {
    if (!_contactsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cachedContacts.isEmpty) {
      return const Center(child: Text('No contacts found.'));
    }

    final items = _computedItems;
    final orderedLetters = _computedOrderedLetters;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: CustomScrollView(
            controller: widget.titleController.scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + kToolbarHeight,
                ),
              ),

              GlassLargeTitle(
                text: 'Contacts',
                controller: widget.titleController,
                searchBar: GlassSearchBar(
                  placeholder: 'Search Contacts',
                  useOwnLayer: true,
                  focusNode: _searchFocusNode,
                ),
              ),

              // Header Dashboard: Filter Chips, Favorites Carousel
              SliverToBoxAdapter(
                child: Column(
                  key: _dashboardKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: ContactsFilterChips(
                        currentMode: _filterMode,
                        onModeChanged: (mode) {
                          setState(() {
                            _filterMode = mode;
                            _recomputeListItems();
                          });
                        },
                        allCount: _cachedContacts.length,
                        archivedCount: _cachedArchivedCount,
                      ),
                    ),
                    if (_filterMode == ContactFilterMode.all &&
                        _cachedFavoritesList.isNotEmpty)
                      FavoritesCarousel(
                        favorites: _cachedFavoritesList,
                        onContactTap: _openContact,
                      ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),

              // Contact Items or Filter Empty State
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filterEmptyIcon(),
                            size: 48,
                            color: scheme.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filterEmptyTitle(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _filterEmptySubtitle(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];

                    if (item is String) {
                      return _buildLetterHeader(context, item);
                    }

                    final contact = item as ContactSummary;

                    return ContactCard(
                      contact: contact,
                      db: widget.db,
                      isArchived: _filterMode == ContactFilterMode.archived,
                      isFavorite: _cachedFavorites.contains(contact.normalizedNumber),
                      onArchive: () => _loadDeviceContacts(),
                      onTap: contact.displayNumber.isEmpty
                          ? null
                          : () => _openContact(contact),
                    );
                  }, childCount: items.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),

        // Floating Glass Alphabet Scrubber
        if (_filterMode == ContactFilterMode.all && orderedLetters.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: SafeArea(
              left: false,
              right: false,
              child: Align(
                alignment: Alignment.centerRight,
                child: GlassAlphabetScrubber(
                  letters: orderedLetters,
                  onLetterSelected: _scrollToLetter,
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _filterEmptyIcon() {
    switch (_filterMode) {
      case ContactFilterMode.archived:
        return Icons.archive_outlined;
      case ContactFilterMode.all:
        return Icons.people_outline_rounded;
    }
  }

  String _filterEmptyTitle() {
    switch (_filterMode) {
      case ContactFilterMode.archived:
        return 'No Archived Contacts';
      case ContactFilterMode.all:
        return 'No Contacts Found';
    }
  }

  String _filterEmptySubtitle() {
    switch (_filterMode) {
      case ContactFilterMode.archived:
        return 'Contacts you archive will be moved here away from your main list.';
      case ContactFilterMode.all:
        return 'Grant permission or add contacts to get started.';
    }
  }

  Widget _buildLetterHeader(BuildContext context, String letter) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: _letterKeys[letter],
      width: double.infinity,
      height: 38.0,
      padding: const EdgeInsets.only(left: 20, right: 28, top: 8, bottom: 4),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            letter,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.contacts_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Contacts permission is needed to show your full contact list.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _requestContactsPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}
