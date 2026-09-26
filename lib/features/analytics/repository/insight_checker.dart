import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../utils/streak_calculator.dart';

class InsightChecker {
  final AppDatabase db;

  InsightChecker(this.db);

  Future<void> checkStreakRecord() async {
    final granted = await NotificationService.areNotificationsGranted();
    if (!granted) return;

    final settings =
        await (db.select(db.settings)..where((s) => s.id.equals(0))).getSingle();
    if (!settings.streakNotifications) return;

    final now = DateTime.now();
    final yearAgo = now.subtract(const Duration(days: 364));
    final heatmapCounts = await db.getCallCountsByPeriod(
      yearAgo,
      now,
      '%Y-%m-%d',
    );

    final streaks = computeStreaks(heatmapCounts, now);
    final currentStreak = streaks.current;

    final lastNotifiedStreak = await db.getLastNotifiedStreak();

    if (currentStreak > 2 && currentStreak > lastNotifiedStreak) {
      await NotificationService.showInsight(
        title: '🔥 New streak!',
        body: 'You\'ve called someone $currentStreak days in a row.',
      );
      await db.setLastNotifiedStreak(currentStreak);
    }
  }

  Future<void> checkWeeklySummary() async {
    final granted = await NotificationService.areNotificationsGranted();
    if (!granted) return;

    final settings =
        await (db.select(db.settings)..where((s) => s.id.equals(0))).getSingle();
    if (!settings.weeklySummaryNotifications) return;

    final lastSent = await db.getLastWeeklySummaryDate();
    final now = DateTime.now();

    if (lastSent != null && now.difference(lastSent).inDays < 7) return;

    final weekAgo = now.subtract(const Duration(days: 7));
    final counts = await db.getCallCountsByPeriod(weekAgo, now, '%Y-%m-%d');
    final totalCalls = counts.values.fold<int>(0, (a, b) => a + b);

    if (totalCalls == 0) return;

    await NotificationService.showInsight(
      title: '📊 Your week in calls',
      body: 'You made $totalCalls calls this week. Open Analytics to see more.',
    );
    await db.setLastWeeklySummaryDate(now);
  }

  Future<void> checkFavoriteInactivity() async {
    final granted = await NotificationService.areNotificationsGranted();
    if (!granted) return;

    final settings =
        await (db.select(db.settings)..where((s) => s.id.equals(0))).getSingle();
    if (!settings.favoriteInactivityNotifications) return;

    final lastSent = await db.getLastFavoriteInactivityDate();
    final now = DateTime.now();

    if (lastSent != null && now.difference(lastSent).inDays < 7) return;

    final inactive = await db.getInactiveFavorites(14);
    if (inactive.isEmpty) return;

    final target = inactive.first;
    final daysSince = target.lastCall != null
        ? now.difference(target.lastCall!).inDays
        : 14;

    await NotificationService.showFavoriteInactivityAlert(
      contactName: target.name,
      number: target.number,
      daysSince: daysSince,
    );
    await db.setLastFavoriteInactivityDate(now);
  }
}
