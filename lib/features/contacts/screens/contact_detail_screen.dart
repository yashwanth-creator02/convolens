import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/database/app_database.dart';
import '../../../core/toast/toast_service.dart';
import '../../../shared/widgets/app_tab_row.dart';
import '../tabs/contact_activity_tab.dart';
import '../tabs/contact_analytics_tab.dart';
import '../tabs/contact_more_tab.dart';
import '../tabs/contact_overview_tab.dart';
import '../widgets/contact_header.dart';

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
    this.deviceContact,
    required this.db,
  });

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  int _selectedTab = 0;

  static const _tabs = [
    AppTabItem(label: 'Overview', icon: Icons.person_outline),
    AppTabItem(label: 'Activity', icon: Icons.history),
    AppTabItem(label: 'Analytics', icon: Icons.analytics_outlined),
    AppTabItem(label: 'More', icon: Icons.more_horiz),
  ];

  Future<void> _toggleFavorite(bool isFavorite) async {
    await widget.db.toggleContactFavorite(widget.normalizedNumber, !isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ContactDetail?>(
      stream: widget.db.watchContactDetails(widget.normalizedNumber),
      builder: (context, snapshot) {
        final detail = snapshot.data;

        return Material(
          child: GlassScaffold(
            appBar: GlassAppBar.pinned(
              title: const Text('Contact'),
              actions: [
                GlassBarItem.menu(
                  icon: const Icon(Icons.more_horiz),
                  id: 'contact_more',
                  label: 'More',
                  menuAlignment: GlassMenuAlignment.topRight,
                  menuWidth: 170,
                  menuItems: [
                    GlassMenuItem(
                      title: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      titleStyle: const TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      onTap: () {
                        // TODO: Open edit contact screen.
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
                      deviceContact: widget.deviceContact,
                      isFavorite: detail?.isFavorite ?? false,
                      isArchived: detail?.isArchived ?? false,
                      onFavoritePressed: () =>
                          _toggleFavorite(detail?.isFavorite ?? false),
                      colorValue: detail?.colorValue,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  AppTabRow(
                    tabs: _tabs,
                    scrollable: true,
                    selectedIndex: _selectedTab,
                    onTabSelected: (index) {
                      if (_selectedTab == index) {
                        return;
                      }

                      setState(() {
                        _selectedTab = index;
                      });
                    },
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(context).dividerColor.withAlpha(20),
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
                          deviceContact: widget.deviceContact,
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

    if (oldWidget.detail != widget.detail) {
      _pages[0] = ContactOverviewTab(
        normalizedNumber: widget.normalizedNumber,
        displayNumber: widget.displayNumber,
        deviceContact: widget.deviceContact,
        detail: widget.detail,
        db: widget.db,
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
