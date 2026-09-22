import 'package:convolens/core/database/app_database.dart';
import 'package:convolens/features/history/widgets/call_details/call_detail_row.dart';
import 'package:convolens/features/history/widgets/call_details/call_info_section.dart';
import 'package:convolens/features/history/widgets/call_details/call_note_section.dart';
import 'package:convolens/features/history/widgets/call_details/call_tags_section.dart';
import 'package:convolens/features/history/widgets/call_details/tag_selection_glass_sheet.dart';
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

  testWidgets('CallTagsSection renders empty state and handles tap', (
    WidgetTester tester,
  ) async {
    bool addCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallTagsSection(
            tags: const [],
            onAdd: () => addCalled = true,
            onRemove: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('No tags added'), findsOneWidget);
    expect(find.text('Tap to categorize this call with tags'), findsOneWidget);

    await tester.tap(find.text('No tags added'));
    await tester.pump();
    expect(addCalled, isTrue);
  });

  testWidgets('CallTagsSection renders tags and handles callbacks without duplicate Add button', (
    WidgetTester tester,
  ) async {
    bool addCalled = false;
    Tag? removedTag;

    const testTag = Tag(id: 1, name: 'Important');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallTagsSection(
            tags: const [testTag],
            onAdd: () => addCalled = true,
            onRemove: (t) => removedTag = t,
          ),
        ),
      ),
    );

    expect(find.text('Important'), findsOneWidget);
    // Verified: No duplicate 'Add Tag' button in the chips wrap
    expect(find.text('Add Tag'), findsNothing);

    // Tap tag chip -> triggers onAdd to open sheet
    await tester.tap(find.text('Important'));
    await tester.pump();
    expect(addCalled, isTrue);

    // Tap delete icon on GlassChip -> triggers onRemove
    await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
    await tester.pump();
    expect(removedTag?.name, 'Important');
  });

  testWidgets('TagSelectionGlassSheet renders and manages call tags', (
    WidgetTester tester,
  ) async {
    final callId = await db.into(db.calls).insert(
      CallsCompanion.insert(
        type: 1,
        duration: 120,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TagSelectionGlassSheet(
            db: db,
            callId: callId,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Call Tags'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('SUGGESTED'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);

    // Tap a suggested tag 'Work' to add it to the call
    await tester.tap(find.text('Work'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify tag is now in the database for the call
    final assignedList = await (db.select(db.callTags)
          ..where((t) => t.callId.equals(callId)))
        .get();
    expect(assignedList.isNotEmpty, isTrue);

    // Verify 'ASSIGNED (1)' section and 'Clear All' appear
    expect(find.text('ASSIGNED (1)'), findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);

    // Tap 'Clear All' to remove all tags for the call
    await tester.tap(find.text('Clear All'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final callTagsAfter = await (db.select(db.callTags)
          ..where((t) => t.callId.equals(callId)))
        .get();
    expect(callTagsAfter.isEmpty, isTrue);

    // Unmount widget to dispose CupertinoSearchTextField cursor timers and flush timers
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('CallNoteSection triggers onClear callback when note exists', (
    WidgetTester tester,
  ) async {
    bool clearCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CallNoteSection(
            note: 'Existing call note',
            onSave: (_) {},
            onClear: () => clearCalled = true,
          ),
        ),
      ),
    );

    // Modify text to reveal the action row
    await tester.enterText(
      find.byType(CupertinoTextField),
      'Existing call note modified',
    );
    await tester.pump();

    expect(find.text('Delete Note'), findsOneWidget);
    await tester.tap(find.text('Delete Note'));
    await tester.pump();

    expect(clearCalled, isTrue);
  });
}
