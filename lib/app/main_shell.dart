import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/database/app_database.dart';
import '../core/notifications/notification_service.dart';
import '../features/analytics/repository/insight_checker.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/contacts/screens/contacts_screen.dart';
import '../features/contacts/widgets/add_contact_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/history/screens/search_screen.dart';
import '../features/history/widgets/number_pad_sheet.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  final AppDatabase db;

  const MainShell({super.key, required this.db});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppDatabase get _db => widget.db;

  final _contactsScreenKey = GlobalKey<ContactsScreenState>();

  int _selectedIndex = 0;

  static const List<String> _titles = [
    'History',
    'Analytics',
    'Contacts',
    'Profile',
  ];

  // ---------------------------------------------------------------------------
  // Screens
  // ---------------------------------------------------------------------------

  late final List<Widget> _screens = [
    HistoryScreen(db: _db),
    AnalyticsScreen(db: _db),
    ContactsScreen(key: _contactsScreenKey, db: _db),
    ProfileScreen(db: _db),
  ];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    InsightChecker(_db).checkStreakRecord();
    InsightChecker(_db).checkWeeklySummary();
  }

  // ---------------------------------------------------------------------------
  // Navigation Actions
  // ---------------------------------------------------------------------------

  void _onNavigationItemSelected(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchScreen(db: _db)),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen(db: _db)),
    );
  }

  // ---------------------------------------------------------------------------
  // App Bar Actions
  // ---------------------------------------------------------------------------

  List<Widget> _buildAppBarActions() {
    return [
      if (_selectedIndex == 0)
        GlassIconButton(icon: const Icon(Icons.search), onPressed: _openSearch),
      GlassIconButton(
        icon: const Icon(Icons.settings),
        onPressed: _openSettings,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Floating Action Button
  // ---------------------------------------------------------------------------

  Widget? _buildFloatingActionButton() {
    if (_selectedIndex == 0) {
      return GlassIconButton(
        icon: const Icon(Icons.dialpad),
        onPressed: () async {
          final number = await showNumberPadSheet(context);
          if (!mounted || number == null || number.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SearchScreen(db: _db, initialContactQuery: number),
            ),
          );
        },
      );
    }

    if (_selectedIndex == 2) {
      return GlassIconButton(
        icon: const Icon(Icons.person_add),
        onPressed: () async {
          final added = await showAddContactScreen(context);
          if (added) {
            await _contactsScreenKey.currentState?.refreshDeviceContacts();
          }
        },
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Bottom Navigation
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavigationBar() {
    return GlassTabBar.bottom(
      selectedIndex: _selectedIndex,
      onTabSelected: _onNavigationItemSelected,
      tabs: const [
        GlassTab(icon: Icon(Icons.history), label: 'History'),
        GlassTab(icon: Icon(Icons.bar_chart), label: 'Analytics'),
        GlassTab(icon: Icon(Icons.contacts), label: 'Contacts'),
        GlassTab(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final fab = _buildFloatingActionButton();

    return GlassScaffold(
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        title: Text(_titles[_selectedIndex]),
        actions: _buildAppBarActions(),
      ),
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _screens),
          if (fab != null) Positioned(bottom: 96, right: 16, child: fab),
        ],
      ),
      bottomBar: _buildBottomNavigationBar(),
    );
  }
}
