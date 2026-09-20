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
}
