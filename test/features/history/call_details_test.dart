import 'package:convolens/core/database/app_database.dart';
import 'package:convolens/features/history/widgets/call_details/call_detail_row.dart';
import 'package:convolens/features/history/widgets/call_details/call_info_section.dart';
import 'package:convolens/features/history/widgets/call_details/call_note_section.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('CallDetailRow renders label, value, and optional icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CallDetailRow(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: '2m 15s (135s)',
          ),
        ),
      ),
    );

    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('2m 15s (135s)'), findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
  });

  testWidgets('CallInfoSection renders call details breakdown', (
    WidgetTester tester,
  ) async {
    final call = Call(
      id: 1,
      number: '+1234567890',
      name: 'John Doe',
      type: 1, // Incoming
      duration: 120,
      timestamp: DateTime(2026, 9, 20, 14, 30).millisecondsSinceEpoch,
      removedFromDevice: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallInfoSection(call: call, db: db),
        ),
      ),
    );

    expect(find.text('Direction'), findsOneWidget);
    expect(find.text('Incoming'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('2m (120s)'), findsOneWidget);
    expect(find.text('+1234567890'), findsOneWidget);
  });

  testWidgets('CallNoteSection renders GlassTextArea and triggers onSave', (
    WidgetTester tester,
  ) async {
    String? savedNote;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallNoteSection(
            note: 'Initial note',
            onSave: (val) {
              savedNote = val;
            },
          ),
        ),
      ),
    );

    expect(find.text('Initial note'), findsOneWidget);

    // Enter text into the text area
    await tester.enterText(find.byType(CupertinoTextField), 'Updated call note');
    await tester.pump();

    // Verify Save Note button appears
    expect(find.text('Save Note'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Save Note
    await tester.tap(find.text('Save Note'));
    await tester.pump();

    expect(savedNote, 'Updated call note');
  });
}
