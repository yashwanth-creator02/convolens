import '../../../core/database/app_database.dart';

class DateIndexEntry {
  final int day; // 1-31
  final int itemIndex;

  const DateIndexEntry(this.day, this.itemIndex);

  String get dayString => '$day';
}

Map<(int year, int month), List<DateIndexEntry>> buildDateIndexByMonth(
  List<Object> items,
) {
  final Map<(int, int), Map<int, int>> firstIndexByYearMonthAndDay = {};

  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    if (item is Call) {
      final dt = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
      final key = (dt.year, dt.month);
      firstIndexByYearMonthAndDay
          .putIfAbsent(key, () => {})
          .putIfAbsent(dt.day, () => i);
    }
  }

  final Map<(int, int), List<DateIndexEntry>> result = {};
  firstIndexByYearMonthAndDay.forEach((yearMonth, daysMap) {
    final entries =
        daysMap.entries.map((e) => DateIndexEntry(e.key, e.value)).toList()
          ..sort((a, b) => b.day.compareTo(a.day)); // Newest day first
    result[yearMonth] = entries;
  });

  return result;
}
