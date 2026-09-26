({int current, int longest}) computeStreaks(
  Map<String, int> heatmapCounts,
  DateTime now,
) {
  int currentStreak = 0;
  int longestStreak = 0;
  int runningStreak = 0;
  var cursor = DateTime(now.year, now.month, now.day);
  bool stillCountingCurrent = true;

  for (int i = 0; i < 365; i++) {
    final key = '${cursor.year.toString().padLeft(4, '0')}-'
        '${cursor.month.toString().padLeft(2, '0')}-'
        '${cursor.day.toString().padLeft(2, '0')}';
    final hasCalls = (heatmapCounts[key] ?? 0) > 0;

    if (hasCalls) {
      runningStreak++;
      if (stillCountingCurrent) currentStreak++;
      if (runningStreak > longestStreak) longestStreak = runningStreak;
    } else {
      runningStreak = 0;
      if (i != 0) stillCountingCurrent = false;
    }
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return (current: currentStreak, longest: longestStreak);
}
