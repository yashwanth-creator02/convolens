import 'package:flutter/material.dart';

import '../core/database/app_database.dart';
import '../core/notifications/notification_service.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/contacts/screens/contacts_screen.dart';
import '../features/contacts/widgets/add_contact_screen.dart';
import '../features/history/screens/history_screen.dart';
import '../features/history/screens/search_screen.dart';
import '../features/history/widgets/number_pad_sheet.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../shared/widgets/coming_soon_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final AppDatabase _db = AppDatabase();

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
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
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

  Future<void> _openNumberPad() async {
    final number = await showNumberPadSheet(context);

    if (!mounted || number == null || number.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SearchScreen(db: _db, initialContactQuery: number),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App Bar
  // ---------------------------------------------------------------------------

  List<Widget> _buildAppBarActions() {
    return [
      if (_selectedIndex == 0)
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: _openSearch,
        ),
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Settings',
        onPressed: _openSettings,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Floating Action Button
  // ---------------------------------------------------------------------------

  Widget? _buildFloatingActionButton() {
    if (_selectedIndex == 0) {
      return FloatingActionButton(
        tooltip: 'Dial number',
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
        child: const Icon(Icons.dialpad),
      );
    }

    if (_selectedIndex == 2) {
      return FloatingActionButton(
        tooltip: 'Add contact',
        onPressed: () async {
          final added = await showAddContactScreen(context);
          if (added) {
            await _contactsScreenKey.currentState?.refreshDeviceContacts();
          }
        },
        child: const Icon(Icons.person_add),
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Bottom Navigation
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: _onNavigationItemSelected,

      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,

      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Contacts'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: _buildAppBarActions(),
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
