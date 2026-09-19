import 'package:convolens/core/database/app_database.dart';
import 'package:convolens/features/history/utils/year_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Timeline Wave Indexing Tests', () {
    final sampleCalls = [
      Call(
        id: 1,
        number: '111',
        name: 'Call 1',
        type: 1,
        duration: 30,
        timestamp: DateTime(2026, 9, 18, 14, 0).millisecondsSinceEpoch,
        removedFromDevice: false,
      ),
      Call(
        id: 2,
        number: '222',
        name: 'Call 2',
        type: 2,
        duration: 45,
        timestamp: DateTime(2026, 9, 15, 10, 0).millisecondsSinceEpoch,
        removedFromDevice: false,
      ),
      Call(
        id: 3,
        number: '333',
        name: 'Call 3',
        type: 1,
        duration: 120,
        timestamp: DateTime(2026, 8, 20, 9, 0).millisecondsSinceEpoch,
        removedFromDevice: false,
      ),
      Call(
        id: 4,
        number: '444',
        name: 'Call 4',
        type: 3,
        duration: 0,
        timestamp: DateTime(2025, 12, 25, 18, 0).millisecondsSinceEpoch,
        removedFromDevice: false,
      ),
      Call(
        id: 5,
        number: '555',
        name: 'Call 5',
        type: 1,
        duration: 50,
        timestamp: DateTime(2024, 1, 1, 0, 0).millisecondsSinceEpoch,
        removedFromDevice: false,
      ),
    ];

    test('buildYearIndex correctly extracts unique years in descending order', () {
      final yearIndex = buildYearIndex(sampleCalls);

      expect(yearIndex.length, 3);
      expect(yearIndex[0].year, 2026);
      expect(yearIndex[0].itemIndex, 0);

      expect(yearIndex[1].year, 2025);
      expect(yearIndex[1].itemIndex, 3);

      expect(yearIndex[2].year, 2024);
      expect(yearIndex[2].itemIndex, 4);
    });

    test('buildMonthIndex correctly extracts months for a year in descending order', () {
      final months2026 = buildMonthIndex(sampleCalls, 2026);

      expect(months2026.length, 2);
      expect(months2026[0].month, 9);
      expect(months2026[0].itemIndex, 0);

      expect(months2026[1].month, 8);
      expect(months2026[1].itemIndex, 2);

      final months2025 = buildMonthIndex(sampleCalls, 2025);
      expect(months2025.length, 1);
      expect(months2025[0].month, 12);
      expect(months2025[0].itemIndex, 3);
    });

    test('buildDateIndex correctly extracts days for a year and month in descending order', () {
      final datesSept2026 = buildDateIndex(sampleCalls, 2026, 9);

      expect(datesSept2026.length, 2);
      expect(datesSept2026[0].day, 18);
      expect(datesSept2026[0].itemIndex, 0);

      expect(datesSept2026[1].day, 15);
      expect(datesSept2026[1].itemIndex, 1);
    });

    test('indexing gracefully handles interleaved non-Call objects', () {
      final mixedItems = <Object>[
        'Header 2026',
        sampleCalls[0],
        sampleCalls[1],
        'Divider',
        sampleCalls[2],
        123, // random metadata
        sampleCalls[3],
      ];

      final yearIndex = buildYearIndex(mixedItems);
      expect(yearIndex.length, 2);
      expect(yearIndex[0].year, 2026);
      expect(yearIndex[0].itemIndex, 1); // index in mixedItems
      expect(yearIndex[1].year, 2025);
      expect(yearIndex[1].itemIndex, 6);

      final months = buildMonthIndex(mixedItems, 2026);
      expect(months.length, 2);
      expect(months[0].month, 9);
      expect(months[0].itemIndex, 1);
      expect(months[1].month, 8);
      expect(months[1].itemIndex, 4);

      final dates = buildDateIndex(mixedItems, 2026, 9);
      expect(dates.length, 2);
      expect(dates[0].day, 18);
      expect(dates[0].itemIndex, 1);
      expect(dates[1].day, 15);
      expect(dates[1].itemIndex, 2);
    });

    test('empty list returns empty indices', () {
      expect(buildYearIndex([]), isEmpty);
      expect(buildMonthIndex([], 2026), isEmpty);
      expect(buildDateIndex([], 2026, 9), isEmpty);
    });
  });
}
