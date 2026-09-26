import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  final AppDatabase db;
  final VoidCallback onFinish;
  final bool isRevisit;

  const OnboardingScreen({
    super.key,
    required this.db,
    required this.onFinish,
    this.isRevisit = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _phoneGranted = false;
  bool _contactsGranted = false;
  bool _notificationsGranted = false;
  bool _microphoneGranted = false;
  bool _alarmGranted = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!widget.isRevisit) {
      widget.db.setOnboardingCompleted(true);
    }
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final phoneStatus = await Permission.phone.status;
      final contactsStatus = await Permission.contacts.status;
      final notifGranted = await NotificationService.areNotificationsGranted();
      final micStatus = await Permission.microphone.status;
      final alarmGranted = await NotificationService.canScheduleExactAlarms();

      if (mounted) {
        setState(() {
          _phoneGranted = phoneStatus.isGranted;
          _contactsGranted = contactsStatus.isGranted;
          _notificationsGranted = notifGranted;
          _microphoneGranted = micStatus.isGranted;
          _alarmGranted = alarmGranted;
        });
      }
    } catch (_) {}
  }

  Future<void> _requestPhonePermission() async {
    HapticFeedback.lightImpact();
    final status = await Permission.phone.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    await _checkPermissions();
  }

  Future<void> _requestContactsPermission() async {
    HapticFeedback.lightImpact();
    final status = await Permission.contacts.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    await _checkPermissions();
  }

  Future<void> _requestNotificationPermission() async {
    HapticFeedback.lightImpact();
    await NotificationService.requestNotificationPermission();
    await _checkPermissions();
  }

  Future<void> _requestMicrophonePermission() async {
    HapticFeedback.lightImpact();
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    await _checkPermissions();
  }

  Future<void> _requestAlarmPermission() async {
    HapticFeedback.lightImpact();
    await NotificationService.requestExactAlarmPermission();
    await _checkPermissions();
  }

  Future<void> _grantAllEssential() async {
    setState(() => _isRequesting = true);
    HapticFeedback.mediumImpact();

    try {
      if (!_phoneGranted) {
        await Permission.phone.request();
      }
      if (!_contactsGranted) {
        await Permission.contacts.request();
      }
      if (!_notificationsGranted) {
        await NotificationService.requestNotificationPermission();
      }
    } finally {
      if (mounted) {
        await _checkPermissions();
        setState(() => _isRequesting = false);
      }
    }
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    HapticFeedback.selectionClick();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    await widget.db.setOnboardingCompleted(true);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Step Indicator & Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: _previousPage,
                      tooltip: 'Back',
                    )
                  else if (widget.isRevisit)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back to Settings',
                    )
                  else
                    const SizedBox(width: 40),
                  const Spacer(),
                  // Page Dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  if (!widget.isRevisit && _currentPage < 2)
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (widget.isRevisit)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(scheme, isDark),
                  _buildEssentialPermissionsPage(scheme, isDark),
                  _buildAdvancedPermissionsPage(scheme, isDark),
                ],
              ),
            ),

            // Bottom Navigation Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == 2
                            ? (widget.isRevisit ? 'Done' : 'Get Started')
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PAGE 1: WELCOME & OVERVIEW
  // ===========================================================================

  Widget _buildWelcomePage(ColorScheme scheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          // App Logo / Visual Icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icons/logo.png',
                width: 88,
                height: 88,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.all_inclusive_rounded,
                    size: 44,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Point',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your intelligent call history, personal relationship analytics, and private CRM.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),

          // Feature Highlights
          _buildFeatureCard(
            scheme: scheme,
            isDark: isDark,
            icon: Icons.waves_rounded,
            color: const Color(0xFF00D2C4),
            title: 'Precision Timeline Wave',
            subtitle: 'Scrub through years and months of call records with fluid physics.',
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            scheme: scheme,
            isDark: isDark,
            icon: Icons.query_stats_rounded,
            color: const Color(0xFF6366F1),
            title: 'Callback & Latency Analytics',
            subtitle: 'Understand communication balance, return rates, and optimal calling hours.',
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            scheme: scheme,
            isDark: isDark,
            icon: Icons.shield_outlined,
            color: const Color(0xFF10B981),
            title: '100% Private & Local',
            subtitle: 'Your logs and notes never leave this device. Encrypted and offline.',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAGE 2: ESSENTIAL PERMISSIONS
  // ===========================================================================

  Widget _buildEssentialPermissionsPage(ColorScheme scheme, bool isDark) {
    final allEssentialGranted =
        _phoneGranted && _contactsGranted && _notificationsGranted;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Required Permissions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Point runs entirely locally on your phone. Granting access allows the app to populate your timeline and organize contacts.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Quick Action: Grant All
          if (!allEssentialGranted)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isRequesting ? null : _grantAllEssential,
                  icon: _isRequesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bolt_rounded, size: 20),
                  label: Text(
                    _isRequesting
                        ? 'Requesting Permissions...'
                        : 'Grant All Required',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

          // Permission Item 1: Phone / Call Logs
          _buildPermissionTile(
            scheme: scheme,
            isDark: isDark,
            icon: Icons.phone_in_talk_rounded,
            color: const Color(0xFF00D2C4),
            title: 'Call Logs & Phone State',
            description:
                'Access past and incoming call records to compute timelines, missed calls, and callback metrics.',
            isGranted: _phoneGranted,
            onRequest: _requestPhonePermission,
          ),
          const SizedBox(height: 12),

          // Permission Item 2: Contacts
          _buildPermissionTile(
            scheme: scheme,
            isDark: isDark,
            icon: Icons.contacts_rounded,
            color: const Color(0xFF6366F1),
            title: 'Device Contacts',
            description:
                'Match phone numbers with caller names, photos, and provide real-time duplicate detection.',
            isGranted: _contactsGranted,
            onRequest: _requestContactsPermission,
          ),
          const SizedBox(height: 12),

          // Permission Item 3: Notifications
          _buildPermissionTile(
            scheme: scheme,
            isDark: isDark,
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Notifications & Alerts',
            description:
                'Receive missed call callback reminders, streak milestones, and weekly summary digests.',
            isGranted: _notificationsGranted,
            onRequest: _requestNotificationPermission,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAGE 3: ADVANCED & OPTIONAL TOOLS
  // ===========================================================================

  Widget _buildAdvancedPermissionsPage(ColorScheme scheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Tools (Optional)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enhance your experience with voice notes, exact alarm follow-ups, and recording scanner capabilities.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Permission Item 4: Microphone
          _buildPermissionTile(
            scheme: scheme,
            isDark: isDark,
            icon: Icons.mic_rounded,
            color: const Color(0xFFEC4899),
            title: 'Microphone & Voice Notes',
            description:
                'Record quick audio notes attached to specific calls and meetings.',
            isGranted: _microphoneGranted,
            onRequest: _requestMicrophonePermission,
            isOptional: true,
          ),
          const SizedBox(height: 12),

          // Permission Item 5: Exact Alarms
          _buildPermissionTile(
            scheme: scheme,
            isDark: isDark,
            icon: Icons.alarm_on_rounded,
            color: const Color(0xFF10B981),
            title: 'Exact Timed Reminders',
            description:
                'Guarantees your follow-up reminders trigger at the precise scheduled minute.',
            isGranted: _alarmGranted,
            onRequest: _requestAlarmPermission,
            isOptional: true,
          ),
          const SizedBox(height: 24),

          // Ready Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: scheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are all set!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap Get Started to enter Point. You can adjust permissions anytime in Settings.',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE WIDGETS
  // ===========================================================================

  Widget _buildFeatureCard({
    required ColorScheme scheme,
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required ColorScheme scheme,
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
    bool isOptional = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF10B981).withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isOptional) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.onSurface.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Optional',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isGranted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Allowed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                )
              else
                TextButton(
                  onPressed: onRequest,
                  style: TextButton.styleFrom(
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    foregroundColor: scheme.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
