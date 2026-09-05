import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../shared/glass_action_ids.dart';
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
  final GlobalKey<AnalyticsScreenState> _analyticsScreenKey =
      GlobalKey<AnalyticsScreenState>();

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
  // Bottom-bar minimize controller
  // ---------------------------------------------------------------------------

  final _tabBarMinimizeController = GlassTabBarMinimizeController(
    behavior: GlassBarMinimizeBehavior.onScrollDown,
  );

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

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
    AnalyticsScreen(
      key: _analyticsScreenKey,
      db: _db,
      titleController: _analyticsTitleController,
    ),
    ContactsScreen(
      key: _contactsScreenKey,
      db: _db,
      titleController: _contactsTitleController,
    ),
    ProfileScreen(db: _db, titleController: _profileTitleController),
  ];

  // ---------------------------------------------------------------------------
  // Active large-title controller
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

  // ---------------------------------------------------------------------------
  // Active scroll controller
  // ---------------------------------------------------------------------------

  ScrollController get _activeScrollController {
    return _activeTitleController.scrollController;
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
  // Main-tab navigation
  // ---------------------------------------------------------------------------

  void _onNavigationItemSelected(int index) {
    if (_selectedIndex == index) {
      _tabBarMinimizeController.expand();
      return;
    }

    _tabBarMinimizeController.expand();

    setState(() {
      _selectedIndex = index;
    });
  }

  // ---------------------------------------------------------------------------
  // Header actions
  // ---------------------------------------------------------------------------

  void _openSearch() {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (context) => SearchScreen(db: _db)));
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (context) => SettingsScreen(db: _db)));
  }

  // ---------------------------------------------------------------------------
  // Bottom-bar actions
  // ---------------------------------------------------------------------------

  Future<void> _openNumberPad() async {
    final number = await showNumberPadSheet(context);

    if (!mounted || number == null || number.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) =>
            SearchScreen(db: _db, initialContactQuery: number),
      ),
    );
  }

  Future<void> _addContact() async {
    final added = await showAddContactScreen(context);

    if (!mounted || !added) {
      return;
    }

    await _contactsScreenKey.currentState?.refreshDeviceContacts();
  }

  void _editProfile() {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => EditProfileScreen(db: _db)),
    );
  }

  void _openAnalyticsFilters() {
    _analyticsScreenKey.currentState?.openFilters();
  }

  // ---------------------------------------------------------------------------
  // App-bar actions
  //
  // Changing this list allows the glass action capsule to morph.
  // ---------------------------------------------------------------------------

  List<GlassBarItem> _buildAppBarActions() {
    switch (_selectedIndex) {
      case 0:
        return [
          GlassBarItem.icon(
            icon: const Icon(Icons.search),
            id: GlassActionIds.search,
            label: 'Search',
            onTap: _openSearch,
          ),
          GlassBarItem.icon(
            icon: const Icon(Icons.settings),
            id: GlassActionIds.settings,
            label: 'Settings',
            onTap: _openSettings,
          ),
        ];

      case 1:
      case 2:
      case 3:
        return [
          GlassBarItem.icon(
            icon: const Icon(Icons.settings),
            id: GlassActionIds.settings,
            label: 'Settings',
            onTap: _openSettings,
          ),
        ];

      default:
        return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Contextual bottom-bar trailing button
  // ---------------------------------------------------------------------------

  GlassTabBarTrailingButton? get _trailingButton {
    switch (_selectedIndex) {
      case 0:
        return GlassTabBarTrailingButton(
          icon: const Icon(Icons.dialpad),
          onTap: _openNumberPad,
        );

      case 1:
        return GlassTabBarTrailingButton(
          icon: const Icon(Icons.tune),
          onTap: _openAnalyticsFilters,
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
  // Bottom navigation
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

      // -----------------------------------------------------------------------
      // Minimization
      // -----------------------------------------------------------------------
      minimizeController: _tabBarMinimizeController,

      // The active large-title controller and tab-bar controller are both
      // listening to the same scroll position.
      scrollController: _activeScrollController,

      onMinimizedTabTap: _tabBarMinimizeController.expand,

      // -----------------------------------------------------------------------
      // Contextual action
      // -----------------------------------------------------------------------
      trailingButton: _trailingButton,
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------

  Widget _buildAppBar() {
    return GlassAppBar.pinned(
      title: Text(_titles[_selectedIndex]),

      // This connects the pinned title to the active screen's large title.
      largeTitleController: _activeTitleController,

      // Changing this list allows the glass action capsule to morph.
      actions: _buildAppBarActions(),
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
