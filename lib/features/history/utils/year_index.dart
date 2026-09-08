import '../../../core/database/app_database.dart';

class YearIndexEntry {
  final int year;
  final int itemIndex;

  const YearIndexEntry(this.year, this.itemIndex);
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
