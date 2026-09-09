import '../../../core/database/app_database.dart';

class MonthIndexEntry {
  final int month; // 1-12
  final int itemIndex;

  const MonthIndexEntry(this.month, this.itemIndex);

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get monthName =>
      (month >= 1 && month <= 12) ? _monthNames[month - 1] : '$month';
}

Map<int, List<MonthIndexEntry>> buildMonthIndexByYear(List<Object> items) {
  final Map<int, Map<int, int>> firstIndexByYearAndMonth = {};

  for (int i = 0; i < items.length; i++) {
    final item = items[i];
    if (item is Call) {
      final dt = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
      final year = dt.year;
      final month = dt.month;
      firstIndexByYearAndMonth
          .putIfAbsent(year, () => {})
          .putIfAbsent(month, () => i);
    }
  }

  final Map<int, List<MonthIndexEntry>> result = {};
  firstIndexByYearAndMonth.forEach((year, monthsMap) {
    final entries =
        monthsMap.entries.map((e) => MonthIndexEntry(e.key, e.value)).toList()
          ..sort((a, b) => b.month.compareTo(a.month)); // Newest month first
    result[year] = entries;
  });

  return result;
}
