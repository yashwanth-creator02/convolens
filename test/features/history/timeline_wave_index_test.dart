import 'package:convolens/core/database/app_database.dart';
import 'package:convolens/features/history/utils/date_index.dart';
import 'package:convolens/features/history/utils/month_index.dart';
import 'package:convolens/features/history/utils/year_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hierarchical Wave Timeline Index Tests', () {
    late List<Object> testItems;

    setUp(() {
      // Create fixture timestamps:
      // 1. Call 1: 2024-03-15
      // 2. Call 2: 2024-03-10
      // 3. Call 3: 2024-01-05
      // 4. Call 4: 2023-11-20
      final dt1 = DateTime(2024, 3, 15, 10, 0);
      final dt2 = DateTime(2024, 3, 10, 14, 0);
      final dt3 = DateTime(2024, 1, 5, 9, 0);
      final dt4 = DateTime(2023, 11, 20, 18, 0);

      final call1 = Call(
        id: 1,
        number: '1234567890',
        timestamp: dt1.millisecondsSinceEpoch,
        duration: 60,
        type: 1,
        removedFromDevice: false,
      );
      final call2 = Call(
        id: 2,
        number: '1234567890',
        timestamp: dt2.millisecondsSinceEpoch,
        duration: 120,
        type: 2,
        removedFromDevice: false,
      );
      final call3 = Call(
        id: 3,
        number: '0987654321',
        timestamp: dt3.millisecondsSinceEpoch,
        duration: 30,
        type: 3,
        removedFromDevice: false,
      );
      final call4 = Call(
        id: 4,
        number: '5555555555',
        timestamp: dt4.millisecondsSinceEpoch,
        duration: 300,
        type: 1,
        removedFromDevice: false,
      );

      testItems = [
        'March 15, 2024',
        call1, // index 1
        'March 10, 2024',
        call2, // index 3
        'January 5, 2024',
        call3, // index 5
        'November 20, 2023',
        call4, // index 7
      ];
    });

    test('buildYearIndex groups by year correctly', () {
      final yearIndex = buildYearIndex(testItems);

      expect(yearIndex.length, equals(2));
      expect(yearIndex[0].year, equals(2024));
      expect(yearIndex[0].itemIndex, equals(1)); // first occurrence in 2024

      expect(yearIndex[1].year, equals(2023));
      expect(yearIndex[1].itemIndex, equals(7)); // first occurrence in 2023
    });

    test('buildMonthIndexByYear groups by year and month correctly', () {
      final monthIndexMap = buildMonthIndexByYear(testItems);

      expect(monthIndexMap.containsKey(2024), isTrue);
      expect(monthIndexMap.containsKey(2023), isTrue);

      final months2024 = monthIndexMap[2024]!;
      expect(months2024.length, equals(2));
      expect(months2024[0].month, equals(3)); // March (newest first)
      expect(months2024[0].monthName, equals('Mar'));
      expect(months2024[0].itemIndex, equals(1));

      expect(months2024[1].month, equals(1)); // January
      expect(months2024[1].monthName, equals('Jan'));
      expect(months2024[1].itemIndex, equals(5));

      final months2023 = monthIndexMap[2023]!;
      expect(months2023.length, equals(1));
      expect(months2023[0].month, equals(11)); // November
      expect(months2023[0].monthName, equals('Nov'));
      expect(months2023[0].itemIndex, equals(7));
    });

    test('buildDateIndexByMonth includes only data-aware days with calls', () {
      final dateIndexMap = buildDateIndexByMonth(testItems);

      final mar2024 = dateIndexMap[(2024, 3)]!;
      expect(mar2024.length, equals(2));
      expect(mar2024[0].day, equals(15)); // 15th
      expect(mar2024[0].itemIndex, equals(1));

      expect(mar2024[1].day, equals(10)); // 10th
      expect(mar2024[1].itemIndex, equals(3));

      final jan2024 = dateIndexMap[(2024, 1)]!;
      expect(jan2024.length, equals(1));
      expect(jan2024[0].day, equals(5));
      expect(jan2024[0].itemIndex, equals(5));
    });
  });
}
