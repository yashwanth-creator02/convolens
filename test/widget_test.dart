import 'package:convolens/core/widgets/multi_hit_stack.dart';
import 'package:convolens/features/history/utils/year_index.dart';
import 'package:convolens/features/history/widgets/timeline_wave_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TimelineWaveNavigator smoke test renders without crash', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimelineWaveNavigator(
            items: const [],
            yearIndex: const [],
            onCommit: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(TimelineWaveNavigator), findsOneWidget);
  });

  testWidgets(
    'button in overlapping trigger zone receives tap and drag activates wave',
    (WidgetTester tester) async {
      bool buttonTapped = false;
      final isManifestedNotifier = ValueNotifier<bool>(false);
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiHitStack(
              children: [
                // Scrollable content with button in the right-edge overlapping zone
                Positioned.fill(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Container(height: 50, color: Colors.blue),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: IconButton(
                            icon: const Icon(Icons.call),
                            onPressed: () {
                              buttonTapped = true;
                            },
                          ),
                        ),
                      ),
                      Container(height: 1200, color: Colors.green),
                    ],
                  ),
                ),
                // TimelineWaveNavigator on top covering the right 88px
                Positioned.fill(
                  child: TimelineWaveNavigator(
                    items: const ['2026', 'Call 1'],
                    yearIndex: const [
                      YearIndexEntry(2026, 0),
                    ],
                    onCommit: (_) {},
                    isManifestedNotifier: isManifestedNotifier,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // 1. Tapping the call button in the overlapping zone triggers onPressed
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(buttonTapped, isTrue);

      // 2. Dragging horizontally inward from the right activates the wave
      final dragGesture = await tester.startGesture(const Offset(780, 150));
      await dragGesture.moveBy(const Offset(-60, 0));
      await tester.pump();

      // Manifestation should be triggered by horizontal drag
      expect(isManifestedNotifier.value, isTrue);

      // Releasing retracts the wave
      await dragGesture.up();
      await tester.pumpAndSettle();
      expect(isManifestedNotifier.value, isFalse);

      // 3. Vertical dragging in the overlapping zone scrolls the list
      expect(scrollController.offset, 0.0);
      await tester.dragFrom(const Offset(780, 200), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(scrollController.offset, greaterThan(0.0));
    },
  );
}
