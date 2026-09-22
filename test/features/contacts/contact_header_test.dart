import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:convolens/features/contacts/widgets/contact_glass_card.dart';
import 'package:convolens/features/contacts/widgets/contact_header.dart';

void main() {
  group('ContactGlassCard Tests', () {
    testWidgets('renders title, icon, and child correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContactGlassCard(
              title: 'Test Section',
              icon: Icons.star,
              child: Text('Content Inside Card'),
            ),
          ),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Content Inside Card'), findsOneWidget);
    });
  });

  group('ContactHeader Tests', () {
    testWidgets('renders avatar initials, name, and rotating call launcher',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ContactHeader(
                displayName: 'Bruce Wayne',
                displayNumber: '+1234567890',
                isFavorite: false,
                isArchived: false,
              ),
            ),
          ),
        ),
      );

      // Verify initials "BW" are rendered in the avatar
      expect(find.text('BW'), findsOneWidget);

      // Verify contact display name
      expect(find.text('Bruce Wayne'), findsOneWidget);

      // Verify rotating call options launcher
      expect(find.byType(CircularPhoneNumber), findsOneWidget);

      // Verify call button
      expect(find.byIcon(Icons.call_rounded), findsWidgets);

      // Verify message and SMS side action buttons
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sms_outlined), findsOneWidget);
    });

    testWidgets('renders archived badge when contact is archived',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ContactHeader(
                displayName: 'Clark Kent',
                displayNumber: '+1987654321',
                isFavorite: true,
                isArchived: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('ARCHIVED'), findsOneWidget);
      expect(find.text('Clark Kent'), findsOneWidget);
    });
  });
}
