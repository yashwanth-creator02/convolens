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
    testWidgets('renders avatar initials, single message button, and rotating call launcher',
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

      // Verify initials "BW" are rendered in the fallback banner
      expect(find.text('BW'), findsOneWidget);

      // Verify contact display name is NOT in header (it belongs in the app bar)
      expect(find.text('Bruce Wayne'), findsNothing);

      // Verify rotating call options launcher
      expect(find.byType(CircularPhoneNumber), findsOneWidget);

      // Verify call button
      expect(find.byIcon(Icons.call_rounded), findsWidgets);

      // Verify single message action button and no duplicate SMS button
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sms_outlined), findsNothing);

      // Verify no favorite star chip when isFavorite is false
      expect(find.text('Favorite'), findsNothing);
    });

    testWidgets('renders favorite star chip when contact is favorited',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ContactHeader(
                displayName: 'Clark Kent',
                displayNumber: '+1987654321',
                isFavorite: true,
                isArchived: false,
              ),
            ),
          ),
        ),
      );

      // Verify favorite star chip and star icon appear
      expect(find.text('Favorite'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });
  });
}
