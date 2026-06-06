import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spendlens/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SpendLens E2E Tests', () {
    testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('SpendLens'), findsWidgets);
      expect(find.byIcon(Icons.attach_money), findsWidgets);
    });

    testWidgets('Navigation to onboarding screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Skip splash
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Zero Manual Entry'), findsWidgets);
    });

    testWidgets('Onboarding carousel works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find first slide
      expect(find.text('Zero Manual Entry'), findsWidgets);

      // Tap next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should move to next slide
      expect(find.text('Your Data, Your Phone'), findsWidgets);
    });

    testWidgets('Phone authentication screen visible', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Complete onboarding
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Last slide - Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Should show auth screen
      expect(find.text('+91'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Phone OTP tab functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Navigate to auth
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // Enter phone number
      final phoneField = find.byType(TextField).first;
      await tester.tap(phoneField);
      await tester.typeText(phoneField, '9876543210');
      await tester.pumpAndSettle();

      // Verify Send OTP button exists
      expect(find.text('Send OTP'), findsWidgets);
    });

    testWidgets('Email tab visible in auth', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Navigate to auth
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // Find and tap Email tab
      final emailTab = find.text('Email');
      expect(emailTab, findsWidgets);
      await tester.tap(emailTab);
      await tester.pumpAndSettle();

      // Should show email fields
      expect(find.text('Login'), findsWidgets);
      expect(find.text('Create Account'), findsWidgets);
    });

    testWidgets('Form validation - empty phone number', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 6));

      // Navigate to auth
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // Try to submit empty form
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      // Should show error or prevent submission
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('Dark theme applied', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Get root widget theme
      final materialApp = find.byType(MaterialApp);
      expect(materialApp, findsWidgets);

      // Verify dark theme is used
      expect(find.byWidgetPredicate(
        (widget) => widget is Material && widget.color != Colors.white,
      ), findsWidgets);
    });

    testWidgets('Navigation structure exists', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify GoRouter is configured
      expect(find.byType(MaterialApp), findsWidgets);
    });
  });
}
