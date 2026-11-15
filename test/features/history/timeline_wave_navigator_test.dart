import 'package:convolens/core/database/app_database.dart';
import 'package:convolens/features/history/utils/year_index.dart';
import 'package:convolens/features/history/widgets/timeline_wave_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Call call(int id, String number, DateTime timestamp) => Call(
    id: id,
    number: number,
    name: number,
    type: 1,
    duration: 10,
    timestamp: timestamp.millisecondsSinceEpoch,
    removedFromDevice: false,
  );

  Future<void> pumpFrames(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets(
    'wave retracts after a trigger while the finger keeps dragging',
    (tester) async {
      final items = <Object>[
        call(1, '111', DateTime(2026, 9, 18, 14)),
        call(2, '222', DateTime(2025, 3, 2, 9)),
      ];
      final manifested = ValueNotifier<bool>(false);
      final commits = <int>[];
      addTearDown(manifested.dispose);

      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineWaveNavigator(
              items: items,
              yearIndex: buildYearIndex(items),
              onCommit: commits.add,
              isManifestedNotifier: manifested,
            ),
          ),
        ),
      );

      // Pull inward from the right edge, past the 195px trigger depth.
      final gesture = await tester.startGesture(const Offset(396, 300));
      await gesture.moveBy(const Offset(-40, 0));
      await gesture.moveBy(const Offset(-160, 0));
      await tester.pump();

      expect(commits, hasLength(1));
      expect(manifested.value, isTrue);

      // Retraction must complete with the finger still down.
      await pumpFrames(tester, 30);
      expect(manifested.value, isFalse);

      // Further movement must not re-manifest the wave.
      await gesture.moveBy(const Offset(-30, 0));
      await pumpFrames(tester, 5);
      expect(manifested.value, isFalse);

      await gesture.up();
      await pumpFrames(tester, 30);
      expect(manifested.value, isFalse);
      expect(commits, hasLength(1));
    },
  );
}
