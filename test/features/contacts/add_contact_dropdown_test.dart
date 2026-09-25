import 'package:convolens/features/contacts/widgets/add_contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContactSuggestionsDropdown Tests', () {
    testWidgets('renders matching contacts with name, subtitle, and handles tap',
        (tester) async {
      Contact? selectedContact;
      bool dismissed = false;

      final testContact = Contact()
        ..id = '123'
        ..displayName = 'Alice Walker'
        ..name = (Name()..first = 'Alice'..last = 'Walker')
        ..phones = [Phone('+1 555 123 4567')]
        ..emails = [Email('alice@example.com')];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactSuggestionsDropdown(
              contacts: [testContact],
              fieldLabel: 'First Name',
              subtitleBuilder: (c) => c.phones.first.number,
              onSelect: (c) => selectedContact = c,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('1 existing contact found'), findsOneWidget);
      expect(find.text('Tap to edit'), findsOneWidget);

      // Verify contact details
      expect(find.text('Alice Walker'), findsOneWidget);
      expect(find.text('+1 555 123 4567'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      // Tap on the contact row
      await tester.tap(find.text('Alice Walker'));
      await tester.pumpAndSettle();

      expect(selectedContact, isNotNull);
      expect(selectedContact?.displayName, equals('Alice Walker'));

      // Tap on dismiss icon
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('renders multiple contacts in scrollable list', (tester) async {
      final contacts = [
        Contact()
          ..id = '1'
          ..displayName = 'John Doe'
          ..phones = [Phone('1234567890')],
        Contact()
          ..id = '2'
          ..displayName = 'John Smith'
          ..phones = [Phone('0987654321')],
        Contact()
          ..id = '3'
          ..displayName = 'Johnny Appleseed'
          ..phones = [Phone('1122334455')],
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactSuggestionsDropdown(
              contacts: contacts,
              fieldLabel: 'Name',
              onSelect: (_) {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('3 existing contacts found'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('John Smith'), findsOneWidget);
    });
  });
}
