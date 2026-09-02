import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

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
    AppTabItem(
      label: 'Overview',
      icon: Icons.person_outline,
    ),
    AppTabItem(
      label: 'Activity',
      icon: Icons.history,
    ),
    AppTabItem(
      label: 'Analytics',
      icon: Icons.analytics_outlined,
    ),
    AppTabItem(
      label: 'More',
      icon: Icons.more_horiz,
    ),
  ];

  Future<void> _toggleFavorite(bool isFavorite) async {
    await widget.db.toggleContactFavorite(
      widget.normalizedNumber,
      !isFavorite,
    );
  }

  void _showContactMenu(ContactDetail? detail) {
    final isArchived = detail?.isArchived ?? false;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit contact'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Open edit contact screen.
                },
              ),
              ListTile(
                leading: Icon(
                  isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                ),
                title: Text(isArchived ? 'Unarchive contact' : 'Archive contact'),
                onTap: () async {
                  Navigator.pop(context);

                  await widget.db.setContactFields(
                    widget.normalizedNumber,
                    ContactDetailsCompanion(
                      isArchived: drift.Value(!isArchived),
                    ),
                  );

                  if (mounted) {
                    ToastService.success(
                      context,
                      isArchived ? 'Contact unarchived' : 'Contact archived',
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ContactDetail?>(
      stream: widget.db.watchContactDetails(
        widget.normalizedNumber,
      ),
      builder: (context, snapshot) {
        final detail = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Contact'),
            actions: [
              IconButton(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showContactMenu(detail),
              ),
            ],
          ),
          body: Column(
            children: [
              ContactHeader(
                displayName: widget.displayName,
                displayNumber: widget.displayNumber,
                deviceContact: widget.deviceContact,
                isFavorite: detail?.isFavorite ?? false,
                isArchived: detail?.isArchived ?? false,
                onFavoritePressed: () => _toggleFavorite(
                  detail?.isFavorite ?? false,
                ),
                colorValue: detail?.colorValue,
              ),

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

              const Divider(height: 1),

              Expanded(
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
            ],
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
        Offstage(
          offstage: widget.selectedIndex != 0,
          child: TickerMode(
            enabled: widget.selectedIndex == 0,
            child: _pages[0],
          ),
        ),
        Offstage(
          offstage: widget.selectedIndex != 1,
          child: TickerMode(
            enabled: widget.selectedIndex == 1,
            child: _pages[1],
          ),
        ),
        Offstage(
          offstage: widget.selectedIndex != 2,
          child: TickerMode(
            enabled: widget.selectedIndex == 2,
            child: _pages[2],
          ),
        ),
        Offstage(
          offstage: widget.selectedIndex != 3,
          child: TickerMode(
            enabled: widget.selectedIndex == 3,
            child: _pages[3],
          ),
        ),
      ],
    );
  }
}

