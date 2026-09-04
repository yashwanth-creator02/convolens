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
import '../features/profile/screens/edit_profile_screen.dart';
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

  // ---------------------------------------------------------------------------
  // Keys
  // ---------------------------------------------------------------------------

  final _contactsScreenKey = GlobalKey<ContactsScreenState>();

  // ---------------------------------------------------------------------------
  // Large-title controllers
  //
  // Each screen owns its own scroll position.
  // The same scrollController is also used by the minimizable tab bar.
  // ---------------------------------------------------------------------------

  final _historyTitleController = GlassLargeTitleController();
  final _analyticsTitleController = GlassLargeTitleController();
  final _contactsTitleController = GlassLargeTitleController();
  final _profileTitleController = GlassLargeTitleController();

  // ---------------------------------------------------------------------------
  // Bottom tab bar minimize controller
  // ---------------------------------------------------------------------------

  final _tabBarMinimizeController = GlassTabBarMinimizeController(
    behavior: GlassBarMinimizeBehavior.onScrollDown,
  );

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
    HistoryScreen(db: _db, titleController: _historyTitleController),
    AnalyticsScreen(db: _db, titleController: _analyticsTitleController),
    ContactsScreen(
      key: _contactsScreenKey,
      db: _db,
      titleController: _contactsTitleController,
    ),
    ProfileScreen(db: _db, titleController: _profileTitleController),
  ];

  // ---------------------------------------------------------------------------
  // Active controllers
  // ---------------------------------------------------------------------------

  GlassLargeTitleController get _activeTitleController {
    switch (_selectedIndex) {
      case 0:
        return _historyTitleController;
      case 1:
        return _analyticsTitleController;
      case 2:
        return _contactsTitleController;
      case 3:
        return _profileTitleController;
      default:
        return _historyTitleController;
    }
  }

  ScrollController get _activeScrollController {
    return _activeTitleController.scrollController;
  }

  GlassTabBarTrailingButton? get _trailingButton {
    switch (_selectedIndex) {
      case 0:
        return GlassTabBarTrailingButton(
          icon: const Icon(Icons.dialpad),
          onTap: _openNumberPad,
        );

      case 2:
        return GlassTabBarTrailingButton(
          icon: const Icon(Icons.person_add),
          onTap: _addContact,
        );

      case 3:
        return GlassTabBarTrailingButton(
          icon: const Icon(Icons.edit),
          onTap: _editProfile,
        );

      default:
        return null;
    }
  }

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

  @override
  void dispose() {
    _tabBarMinimizeController.dispose();

    _historyTitleController.dispose();
    _analyticsTitleController.dispose();
    _contactsTitleController.dispose();
    _profileTitleController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _onNavigationItemSelected(int index) {
    if (_selectedIndex == index) {
      // Tapping the currently selected tab while minimized should
      // bring the tab bar back.
      _tabBarMinimizeController.expand();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // Newly selected tab starts with the tab bar visible.
    _tabBarMinimizeController.expand();
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchScreen(db: _db)),
    );
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen(db: _db)),
    );
  }

  // ---------------------------------------------------------------------------
  // Numpad
  // ---------------------------------------------------------------------------

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
  // Add contact
  // ---------------------------------------------------------------------------

  Future<void> _addContact() async {
    final added = await showAddContactScreen(context);

    if (!mounted || !added) {
      return;
    }

    await _contactsScreenKey.currentState?.refreshDeviceContacts();
  }

  // ---------------------------------------------------------------------------
  // Edit profile
  // ---------------------------------------------------------------------------

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(db: _db)),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom tab bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomNavigationBar() {
    return GlassTabBar.minimizable(
      tabs: const [
        GlassTab(
          label: 'History',
          icon: Icon(Icons.history),
          activeIcon: Icon(Icons.history),
        ),
        GlassTab(
          label: 'Analytics',
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
        ),
        GlassTab(
          label: 'Contacts',
          icon: Icon(Icons.contacts_outlined),
          activeIcon: Icon(Icons.contacts),
        ),
        GlassTab(
          label: 'Profile',
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
        ),
      ],

      selectedIndex: _selectedIndex,

      onTabSelected: _onNavigationItemSelected,

      // ---------------------------------------------------------
      // Bottom bar minimization
      // ---------------------------------------------------------
      minimizeController: _tabBarMinimizeController,

      // IMPORTANT:
      // This must point to the same scroll controller used by
      // the currently visible screen.
      scrollController: _activeScrollController,

      // When the compact/minimized tab is tapped, restore the bar.
      onMinimizedTabTap: _tabBarMinimizeController.expand,

      // ---------------------------------------------------------
      // Numpad / Actions
      // ---------------------------------------------------------
      trailingButton: _trailingButton,
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------

  Widget _buildAppBar() {
    return GlassAppBar.pinned(
      title: Text(_titles[_selectedIndex]),

      largeTitleController: _activeTitleController,

      actions: [
        if (_selectedIndex == 0)
          GlassBarItem.icon(
            icon: const Icon(Icons.search),
            label: 'Search',
            onTap: _openSearch,
          ),

        GlassBarItem.icon(
          icon: const Icon(Icons.settings),
          label: 'Settings',
          onTap: _openSettings,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      statusBarStyle: GlassStatusBarStyle.auto,

      appBar: _buildAppBar(),

      body: IndexedStack(index: _selectedIndex, children: _screens),

      bottomBar: _buildBottomNavigationBar(),
    );
  }
}
