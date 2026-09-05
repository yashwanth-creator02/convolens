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
import '../widgets/side_bar_alphabet_index.dart';
import 'archived_contacts_screen.dart';
import 'contact_detail_screen.dart';
import 'contact_search_screen.dart';

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

  bool _permissionGranted = false;
  bool _loadingContacts = true;
  bool _pullSearchTriggered = false;

  List<Contact> _deviceContacts = [];
  final Map<String, GlobalKey> _letterKeys = {};

  final _searchFocusNode = FocusNode();

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
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _permissionGranted = true;
        _loadingContacts = false;
      });
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
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ContactSearchScreen(db: widget.db),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
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
    final key = _letterKeys[letter];

    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
    return StreamBuilder<List<ContactSummary>>(
      stream: _repository.watchArchivedContacts(_deviceContacts),
      builder: (context, archivedSnapshot) {
        final archivedCount = archivedSnapshot.data?.length ?? 0;

        return StreamBuilder<Set<String>>(
          stream: widget.db.watchFavoriteNumbers(),
          builder: (context, favoritesSnapshot) {
            final favoriteNumbers = favoritesSnapshot.data ?? <String>{};

            return StreamBuilder<List<ContactSummary>>(
              stream: _repository.watchContacts(_deviceContacts),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorView(snapshot.error);
                }

                final contacts = snapshot.data ?? [];

                if (contacts.isEmpty) {
                  return const Center(child: Text('No contacts found.'));
                }

                final favorites =
                    contacts
                        .where(
                          (contact) => favoriteNumbers.contains(
                            contact.normalizedNumber,
                          ),
                        )
                        .toList()
                      ..sort(
                        (a, b) => a.displayName.toLowerCase().compareTo(
                          b.displayName.toLowerCase(),
                        ),
                      );

                final remaining = contacts
                    .where(
                      (contact) =>
                          !favoriteNumbers.contains(contact.normalizedNumber),
                    )
                    .toList();

                final grouped = groupContactsByLetter(remaining);

                final orderedLetters = grouped.keys.toList()
                  ..sort((a, b) {
                    if (a == '#') return 1;
                    if (b == '#') return -1;

                    return a.compareTo(b);
                  });

                final items = <Object>[];

                if (favorites.isNotEmpty) {
                  items.add(const _FavoritesSectionMarker());
                  items.addAll(favorites);
                }

                for (final letter in orderedLetters) {
                  _letterKeys.putIfAbsent(letter, () => GlobalKey());

                  items.add(letter);
                  items.addAll(grouped[letter]!);
                }

                if (archivedCount > 0) {
                  items.add(_ArchivedSectionMarker(archivedCount));
                }

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
                              height:
                                  MediaQuery.of(context).padding.top +
                                  kToolbarHeight,
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

                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = items[index];

                              if (item is _ArchivedSectionMarker) {
                                return _buildArchivedTile(context, item.count);
                              }

                              if (item is _FavoritesSectionMarker) {
                                return _buildFavoritesHeader(context);
                              }

                              if (item is String) {
                                return _buildLetterHeader(context, item);
                              }

                              final contact = item as ContactSummary;

                              return ContactCard(
                                contact: contact,
                                onTap: contact.displayNumber.isEmpty
                                    ? null
                                    : () => _openContact(contact),
                              );
                            }, childCount: items.length),
                          ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 120),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: SideBarAlphabetIndex(
                        letters: orderedLetters,
                        onLetterSelected: _scrollToLetter,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildArchivedTile(BuildContext context, int count) {
    return ListTile(
      leading: const Icon(Icons.archive_outlined),
      title: const Text('Archived'),
      trailing: Text('$count', style: const TextStyle(color: Colors.grey)),
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ArchivedContactsScreen(
              db: widget.db,
              deviceContacts: _deviceContacts,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.star, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 6),
          Text(
            'Favorites',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Failed to load contacts.\n$error',
          textAlign: TextAlign.center,
        ),
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

  Widget _buildLetterHeader(BuildContext context, String letter) {
    return Container(
      key: _letterKeys[letter],
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _FavoritesSectionMarker {
  const _FavoritesSectionMarker();
}

class _ArchivedSectionMarker {
  final int count;

  const _ArchivedSectionMarker(this.count);
}
