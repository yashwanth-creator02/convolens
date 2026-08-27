import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';

class InsightChecker {
  final AppDatabase db;

  InsightChecker(this.db);

  Future<void> checkStreakRecord() async {
    final now = DateTime.now();
    final yearAgo = now.subtract(const Duration(days: 364));
    final heatmapCounts = await db.getCallCountsByPeriod(
      yearAgo,
      now,
      '%Y-%m-%d',
    );

    final streaks = _computeStreaks(heatmapCounts, now);
    final currentStreak = streaks['current']!;

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

  Map<String, int> _computeStreaks(
    Map<String, int> heatmapCounts,
    DateTime now,
  ) {
    int currentStreak = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    bool stillCounting = true;

    for (int i = 0; i < 365; i++) {
      final key =
          '${cursor.year.toString().padLeft(4, '0')}-'
          '${cursor.month.toString().padLeft(2, '0')}-'
          '${cursor.day.toString().padLeft(2, '0')}';
      final hasCalls = (heatmapCounts[key] ?? 0) > 0;

      if (hasCalls) {
        if (stillCounting) currentStreak++;
      } else if (i != 0) {
        stillCounting = false;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return {'current': currentStreak};
  }
}
