import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/database/app_database.dart';
import '../tabs/contact_activity_tab.dart';
import '../tabs/contact_analytics_tab.dart';
import '../tabs/contact_more_tab.dart';
import '../tabs/contact_overview_tab.dart';
import '../widgets/contact_header.dart';

class ContactDetailScreen extends StatelessWidget {
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

  Future<void> _toggleFavorite(bool isFavorite) async {
    await db.toggleContactFavorite(
      normalizedNumber,
      !isFavorite,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contact'),
        ),
        body: StreamBuilder<ContactDetail?>(
          stream: db.watchContactDetails(normalizedNumber),
          builder: (context, snapshot) {
            final detail = snapshot.data;

            return Column(
              children: [
                // ----------------------------------------------------------
                // Contact header
                // ----------------------------------------------------------

                ContactHeader(
                  displayName: displayName,
                  displayNumber: displayNumber,
                  deviceContact: deviceContact,
                  isFavorite: detail?.isFavorite ?? false,
                  onFavoritePressed: () => _toggleFavorite(
                    detail?.isFavorite ?? false,
                  ),
                  colorValue: detail?.colorValue,
                ),

                // ----------------------------------------------------------
                // Tabs
                // ----------------------------------------------------------

                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.person_outline),
                      text: 'Overview',
                    ),
                    Tab(
                      icon: Icon(Icons.history),
                      text: 'Activity',
                    ),
                    Tab(
                      icon: Icon(Icons.analytics_outlined),
                      text: 'Analytics',
                    ),
                    Tab(
                      icon: Icon(Icons.more_horiz),
                      text: 'More',
                    ),
                  ],
                ),

                // ----------------------------------------------------------
                // Tab content
                // ----------------------------------------------------------

                Expanded(
                  child: TabBarView(
                    children: [
                      ContactOverviewTab(
                        normalizedNumber: normalizedNumber,
                        displayNumber: displayNumber,
                        deviceContact: deviceContact,
                        detail: detail,
                        db: db,
                      ),

                      ContactActivityTab(
                        normalizedNumber: normalizedNumber,
                        db: db,
                      ),

                      ContactAnalyticsTab(
                        normalizedNumber: normalizedNumber,
                        db: db,
                      ),

                      ContactMoreTab(
                        normalizedNumber: normalizedNumber,
                        displayName: displayName,
                        displayNumber: displayNumber,
                        detail: detail,
                        db: db,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
