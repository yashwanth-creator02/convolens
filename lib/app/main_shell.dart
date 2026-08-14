import 'package:flutter/material.dart';

import '../core/database/app_database.dart';
import '../core/notifications/notification_service.dart';
import '../features/history/screens/history_screen.dart';
import '../features/history/screens/search_screen.dart';
import '../features/history/widgets/number_pad_sheet.dart';
import '../features/settings/screens/settings_screen.dart';
import '../shared/widgets/coming_soon_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final AppDatabase db = AppDatabase();

  int _selectedIndex = 0;

  static const _titles = ['History', 'Analytics', 'Profile'];

  late final List<Widget> _screens = [
    HistoryScreen(db: db),
    const ComingSoonView(title: 'Analytics'),
    const ComingSoonView(title: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    NotificationService.init();
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }

  Widget? _buildFloatingActionButton() {
    if (_selectedIndex != 0) {
      return null;
    }

    return FloatingActionButton(
      tooltip: 'Dial number',
      onPressed: () async {
        final number = await showNumberPadSheet(context);

        if (!mounted || number == null || number.isEmpty) {
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchScreen(db: db, initialContactQuery: number),
          ),
        );
      },
      child: const Icon(Icons.dialpad),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen(db: db)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen(db: db)),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
