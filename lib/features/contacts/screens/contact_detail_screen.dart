import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
      ),
      body: StreamBuilder<ContactDetail?>(
        stream: widget.db.watchContactDetails(
          widget.normalizedNumber,
        ),
        builder: (context, snapshot) {
          final detail = snapshot.data;

          return Column(
            children: [
              ContactHeader(
                displayName: widget.displayName,
                displayNumber: widget.displayNumber,
                deviceContact: widget.deviceContact,
                isFavorite: detail?.isFavorite ?? false,
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
                  setState(() {
                    _selectedTab = index;
                  });
                },
              ),

              const Divider(height: 1),

              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    ContactOverviewTab(
                      normalizedNumber: widget.normalizedNumber,
                      displayNumber: widget.displayNumber,
                      deviceContact: widget.deviceContact,
                      detail: detail,
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
                      detail: detail,
                      db: widget.db,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
