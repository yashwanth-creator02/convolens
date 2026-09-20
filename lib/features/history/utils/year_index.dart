import '../../../core/database/app_database.dart';

class YearIndexEntry {
  final int year;
  final int itemIndex;

  const YearIndexEntry(this.year, this.itemIndex);
}

class MonthIndexEntry {
  final int month; // 1-12
  final int itemIndex;

  const MonthIndexEntry(this.month, this.itemIndex);
}

class DateIndexEntry {
  final int day; // 1-31
  final int itemIndex;

  const DateIndexEntry(this.day, this.itemIndex);
}

List<YearIndexEntry> buildYearIndex(List<Object> items) {
  final Map<int, int> firstIndexForYear = {};

  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    if (item is Call) {
      final year = DateTime.fromMillisecondsSinceEpoch(item.timestamp).year;
      firstIndexForYear.putIfAbsent(year, () => i);
    }
  }

  final entries =
      firstIndexForYear.entries
          .map((e) => YearIndexEntry(e.key, e.value))
          .toList()
        ..sort((a, b) => b.year.compareTo(a.year));

  return entries;
}

List<MonthIndexEntry> buildMonthIndex(List<Object> items, int year) {
  final Map<int, int> firstIndexForMonth = {};

  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    if (item is Call) {
      final dt = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
      if (dt.year == year) {
        firstIndexForMonth.putIfAbsent(dt.month, () => i);
      }
    }
  }

  final entries =
      firstIndexForMonth.entries
          .map((e) => MonthIndexEntry(e.key, e.value))
          .toList()
        ..sort((a, b) => b.month.compareTo(a.month));

  return entries;
}

List<DateIndexEntry> buildDateIndex(List<Object> items, int year, int month) {
  final Map<int, int> firstIndexForDate = {};

  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    if (item is Call) {
      final dt = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
      if (dt.year == year && dt.month == month) {
        firstIndexForDate.putIfAbsent(dt.day, () => i);
      }
    }
  }

  final entries =
      firstIndexForDate.entries
          .map((e) => DateIndexEntry(e.key, e.value))
          .toList()
        ..sort((a, b) => b.day.compareTo(a.day));

  return entries;
}
