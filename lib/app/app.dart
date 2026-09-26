import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/database/app_database.dart';
import '../core/notifications/notification_service.dart';
import '../core/services/contact_cache.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_theme_type.dart';
import '../core/utils/normalize_number.dart';
import '../features/contacts/screens/contact_detail_screen.dart';
import '../features/history/screens/call_details_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import 'main_shell.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppDatabase _db;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool? _hasCompletedOnboarding;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase();
    NotificationService.onNotificationPayload.addListener(_handleNotificationPayload);
    // Process any initial payload from cold start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationPayload();
    });
  }

  @override
  void dispose() {
    NotificationService.onNotificationPayload.removeListener(_handleNotificationPayload);
    _db.close();
    super.dispose();
  }

  Future<void> _handleNotificationPayload() async {
    final payload = NotificationService.onNotificationPayload.value;
    if (payload == null) return;
    NotificationService.onNotificationPayload.value = null;

    if (payload.startsWith('call:')) {
      final callPart = payload.substring(5);
      final callIdStr = callPart.contains(':') ? callPart.split(':')[0] : callPart;
      final callId = int.tryParse(callIdStr);
      if (callId == null) return;

      final call = await _db.getCallById(callId);
      if (call != null && mounted) {
        _navigatorKey.currentState?.push(
          CupertinoPageRoute(
            builder: (context) => CallDetailScreen(call: call, db: _db),
          ),
        );
      }
    } else if (payload.startsWith('contact:')) {
      final number = payload.substring(8);
      if (number.isEmpty) return;

      final contact = ContactCache.findContact(number: number);
      if (mounted) {
        _navigatorKey.currentState?.push(
          CupertinoPageRoute(
            builder: (context) => ContactDetailScreen(
              normalizedNumber: normalizePhoneNumber(number),
              displayName: contact?.displayName ?? number,
              displayNumber: number,
              deviceContact: contact,
              db: _db,
            ),
          ),
        );
      }
    }
  }

  AppThemeType _themeFromString(String value) {
    switch (value) {
      case 'light':
        return AppThemeType.light;

      case 'dark':
        return AppThemeType.dark;

      case 'purple':
      case 'violet':
        return AppThemeType.purple;

      case 'cosmo':
        return AppThemeType.cosmo;

      case 'system':
      default:
        return AppThemeType.dark;
    }
  }

  Widget _buildAppWithTheme({
    required AppThemeType themeType,
    ThemeMode themeMode = ThemeMode.dark,
    required AppDatabase db,
    required bool hasCompletedOnboarding,
  }) {
    final activeTheme = AppTheme.getTheme(
      themeType == AppThemeType.system ? AppThemeType.dark : themeType,
    );

    return MaterialApp(
      key: ValueKey('PointAppMaterialApp_$hasCompletedOnboarding'),
      navigatorKey: _navigatorKey,
      title: 'Point',
      theme: themeType == AppThemeType.light
          ? activeTheme
          : AppTheme.getTheme(AppThemeType.light),
      darkTheme: activeTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return GlassNavigationShell(
          child: Scaffold(
            backgroundColor: activeTheme.scaffoldBackgroundColor,
            resizeToAvoidBottomInset: false,
            body: child!,
          ),
        );
      },
      home: hasCompletedOnboarding
          ? MainShell(db: db)
          : OnboardingScreen(
              db: db,
              onFinish: () {
                setState(() {
                  _hasCompletedOnboarding = true;
                });
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Setting>(
      stream: _db.watchSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          final darkTheme = AppTheme.getTheme(AppThemeType.dark);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: darkTheme,
            home: Scaffold(
              backgroundColor: darkTheme.scaffoldBackgroundColor,
              body: const SizedBox.shrink(),
            ),
          );
        }

        final settings = snapshot.data!;
        final themeType = _themeFromString(settings.theme);
        _hasCompletedOnboarding ??= settings.hasCompletedOnboarding;

        return _buildAppWithTheme(
          themeType: themeType,
          themeMode: themeType == AppThemeType.system
              ? ThemeMode.system
              : (themeType == AppThemeType.light
                  ? ThemeMode.light
                  : ThemeMode.dark),
          db: _db,
          hasCompletedOnboarding: _hasCompletedOnboarding!,
        );
      },
    );
  }
}
