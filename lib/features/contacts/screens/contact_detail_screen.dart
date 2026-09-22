import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/contact_cache.dart';
import '../../../core/toast/toast_service.dart';
import '../tabs/contact_activity_tab.dart';
import '../tabs/contact_analytics_tab.dart';
import '../tabs/contact_more_tab.dart';
import '../tabs/contact_overview_tab.dart';
import '../widgets/contact_header.dart';
import '../widgets/edit_contact_screen.dart';
import '../widgets/add_contact_screen.dart';

class ContactDetailScreen extends StatefulWidget {
  final String normalizedNumber;
  final String displayName;
  final String displayNumber;
  final Contact? deviceContact;
  final AppDatabase db;

  const ContactDetailScreen({
    super.key,
    required this.normalizedNumber,
    required this.displayName,
    required this.displayNumber,
    required this.deviceContact,
    required this.db,
  });

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  int _selectedTab = 0;
  late Contact? _deviceContact;

  @override
  void initState() {
    super.initState();
    _deviceContact = widget.deviceContact ??
        ContactCache.findContact(
          number: widget.normalizedNumber,
          name: widget.displayName,
        );
    if (_deviceContact != null && _deviceContact!.photo == null) {
      _loadFullResPhoto();
    }
  }

  Future<void> _loadFullResPhoto() async {
    if (_deviceContact == null) return;
    try {
      final full = await FlutterContacts.getContact(
        _deviceContact!.id,
        withPhoto: true,
        withThumbnail: true,
      );
      if (full != null && full.photo != null && mounted) {
        setState(() {
          _deviceContact = full;
        });
        ContactCache.updateContact(full);
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(bool isFavorite) async {
    await widget.db.toggleContactFavorite(widget.normalizedNumber, !isFavorite);
  }

  String _getTitleText() {
    final name = widget.displayName.trim();
    if (name.isNotEmpty &&
        name != widget.normalizedNumber &&
        name != widget.displayNumber) {
      return name;
    }
    if (widget.displayNumber.trim().isNotEmpty) {
      return widget.displayNumber.trim();
    }
    return 'Contact';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ContactDetail?>(
      stream: widget.db.watchContactDetails(widget.normalizedNumber),
      builder: (context, snapshot) {
        final detail = snapshot.data;

        // ── Dynamic background tint from selected contact color ──────────
        final colorValue = detail?.colorValue;
        final scheme = Theme.of(context).colorScheme;
        final bgColor = colorValue != null
            ? Color.lerp(
                scheme.surface,
                Color(colorValue),
                0.06,
              )!
            : null;

        return Material(
          child: GlassScaffold(
            backgroundColor: bgColor,
            appBar: GlassAppBar.pinned(
              title: Text(
                _getTitleText(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                GlassBarItem.menu(
                  icon: const Icon(Icons.more_horiz),
                  id: 'contact_more',
                  label: 'More',
                  menuAlignment: GlassMenuAlignment.topRight,
                  menuWidth: 200,
                  menuItems: [
                    GlassMenuItem(
                      title: detail?.isFavorite == true
                          ? 'Remove Favorite'
                          : 'Add to Favorite',
                      icon: Icon(
                        detail?.isFavorite == true
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: detail?.isFavorite == true
                            ? Colors.amber
                            : Colors.white,
                      ),
                      titleStyle: const TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      onTap: () =>
                          _toggleFavorite(detail?.isFavorite ?? false),
                    ),
                    GlassMenuItem(
                      title: 'Copy Number',
                      icon: const Icon(Icons.copy_rounded),
                      titleStyle: const TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      onTap: () {
                        final numberToCopy =
                            widget.displayNumber.isNotEmpty
                                ? widget.displayNumber
                                : widget.normalizedNumber;
                        Clipboard.setData(
                            ClipboardData(text: numberToCopy));
                        ToastService.info(
                            context, 'Phone number copied.');
                      },
                    ),
                    GlassMenuItem(
                      title: 'Share Contact',
                      icon: const Icon(Icons.share_outlined),
                      titleStyle: const TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      onTap: () {
                        final info = widget.displayName !=
                                widget.displayNumber
                            ? '${widget.displayName}\n${widget.displayNumber}'
                            : widget.displayNumber;
                        Clipboard.setData(ClipboardData(text: info));
                        ToastService.info(
                            context, 'Contact details copied to share.');
                      },
                    ),
                    if (_deviceContact != null)
                      GlassMenuItem(
                        title: 'Edit Contact',
                        icon: const Icon(Icons.edit_outlined),
                        titleStyle: const TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        onTap: () async {
                          final updated = await Navigator.of(context)
                              .push<bool>(
                                CupertinoPageRoute(
                                  builder: (context) => EditContactScreen(
                                    contact: _deviceContact!,
                                  ),
                                ),
                              );

                          if (updated == true && mounted) {
                            setState(() {});
                            if (context.mounted) {
                              ToastService.success(
                                  context, 'Contact updated.');
                            }
                          }
                        },
                      )
                    else
                      GlassMenuItem(
                        title: 'Create Contact',
                        icon: const Icon(Icons.person_add_outlined),
                        titleStyle: const TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        onTap: () async {
                          final created = await showAddContactScreen(
                            context,
                            initialName: widget.displayName,
                            initialPhone: widget.displayNumber,
                          );

                          if (created != null && mounted) {
                            setState(() => _deviceContact = created);
                            if (context.mounted) {
                              ToastService.success(
                                  context, 'Contact created.');
                            }
                          }
                        },
                      ),
                    GlassMenuItem(
                      title: detail?.isArchived == true
                          ? 'Unarchive'
                          : 'Archive',
                      icon: Icon(
                        detail?.isArchived == true
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                      ),
                      titleStyle: const TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      onTap: () async {
                        final isArchived = detail?.isArchived ?? false;

                        await widget.db.setContactFields(
                          widget.normalizedNumber,
                          ContactDetailsCompanion(
                            isArchived: drift.Value(!isArchived),
                          ),
                        );

                        if (!context.mounted) return;

                        ToastService.success(
                          context,
                          isArchived
                              ? 'Contact unarchived'
                              : 'Contact archived',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: kToolbarHeight),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                    child: ContactHeader(
                      displayName: widget.displayName,
                      displayNumber: widget.displayNumber,
                      deviceContact: _deviceContact,
                      isFavorite: detail?.isFavorite ?? false,
                      isArchived: detail?.isArchived ?? false,
                      onFavoritePressed: () =>
                          _toggleFavorite(detail?.isFavorite ?? false),
                      colorValue: detail?.colorValue,
                      db: widget.db,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassSegmentedControl.scrollable(
                      quality: GlassQuality.standard,
                      selectedIndex: _selectedTab,
                      onSegmentSelected: (index) {
                        if (_selectedTab == index) {
                          return;
                        }

                        setState(() {
                          _selectedTab = index;
                        });
                      },
                      segments: const [
                        GlassSegment(label: 'Overview'),
                        GlassSegment(label: 'Activity'),
                        GlassSegment(label: 'Analytics'),
                        GlassSegment(label: 'More'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey<int>(_selectedTab),
                        child: _ContactTabView(
                          selectedIndex: _selectedTab,
                          detail: detail,
                          normalizedNumber: widget.normalizedNumber,
                          displayName: widget.displayName,
                          displayNumber: widget.displayNumber,
                          deviceContact: _deviceContact,
                          db: widget.db,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContactTabView extends StatefulWidget {
  final int selectedIndex;
  final ContactDetail? detail;
  final String normalizedNumber;
  final String displayName;
  final String displayNumber;
  final Contact? deviceContact;
  final AppDatabase db;

  const _ContactTabView({
    required this.selectedIndex,
    required this.detail,
    required this.normalizedNumber,
    required this.displayName,
    required this.displayNumber,
    required this.deviceContact,
    required this.db,
  });

  @override
  State<_ContactTabView> createState() => _ContactTabViewState();
}

class _ContactTabViewState extends State<_ContactTabView> {
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      ContactOverviewTab(
        normalizedNumber: widget.normalizedNumber,
        displayNumber: widget.displayNumber,
        deviceContact: widget.deviceContact,
        detail: widget.detail,
        db: widget.db,
      ),
      ContactActivityTab(
        normalizedNumber: widget.normalizedNumber,
        db: widget.db,
        deviceContact: widget.deviceContact,
      ),
      ContactAnalyticsTab(
        normalizedNumber: widget.normalizedNumber,
        db: widget.db,
      ),
      ContactMoreTab(
        normalizedNumber: widget.normalizedNumber,
        displayName: widget.displayName,
        displayNumber: widget.displayNumber,
        detail: widget.detail,
        db: widget.db,
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant _ContactTabView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.detail != widget.detail ||
        oldWidget.deviceContact != widget.deviceContact) {
      _pages[0] = ContactOverviewTab(
        normalizedNumber: widget.normalizedNumber,
        displayNumber: widget.displayNumber,
        deviceContact: widget.deviceContact,
        detail: widget.detail,
        db: widget.db,
      );

      _pages[1] = ContactActivityTab(
        normalizedNumber: widget.normalizedNumber,
        db: widget.db,
        deviceContact: widget.deviceContact,
      );

      _pages[3] = ContactMoreTab(
        normalizedNumber: widget.normalizedNumber,
        displayName: widget.displayName,
        displayNumber: widget.displayNumber,
        detail: widget.detail,
        db: widget.db,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (int index = 0; index < _pages.length; index++) _buildPage(index),
      ],
    );
  }

  Widget _buildPage(int index) {
    final isSelected = index == widget.selectedIndex;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isSelected,
        child: TickerMode(
          enabled: isSelected,
          child: AnimatedOpacity(
            opacity: isSelected ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: AnimatedSlide(
              offset: isSelected ? Offset.zero : const Offset(0, 0.015),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Offstage(offstage: !isSelected, child: _pages[index]),
            ),
          ),
        ),
      ),
    );
  }
}
