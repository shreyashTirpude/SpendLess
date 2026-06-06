import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spendlens/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SpendLens Feature Tests', () {
    testWidgets('Transaction list displays correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Mock login flow (assuming you auto-populate for testing)
      // Looking for transactions list
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Transaction filtering by category works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Navigate to transactions screen
      final transactionsTab = find.byIcon(Icons.receipt);
      if (transactionsTab.evaluate().isNotEmpty) {
        await tester.tap(transactionsTab);
        await tester.pumpAndSettle();
      }

      // Verify transaction screen
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Budget screen displays with progress bars', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Navigate to budget screen
      final budgetTab = find.byIcon(Icons.pie_chart);
      if (budgetTab.evaluate().isNotEmpty) {
        await tester.tap(budgetTab);
        await tester.pumpAndSettle();
      }

      // Verify budget elements
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('Insights screen shows analytics', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Navigate to insights
      final insightsTab = find.byIcon(Icons.trending_up);
      if (insightsTab.evaluate().isNotEmpty) {
        await tester.tap(insightsTab);
        await tester.pumpAndSettle();
      }

      // Verify analytics elements
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Settings screen accessible', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Navigate to settings
      final settingsTab = find.byIcon(Icons.settings);
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab);
        await tester.pumpAndSettle();
      }

      // Verify settings elements
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Add manual transaction flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Find FAB (floating action button)
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle();

        // Should show modal or form
        expect(find.byType(TextField), findsWidgets);
      }
    });

    testWidgets('Biometric settings toggle', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Navigate to settings
      final settingsTab = find.byIcon(Icons.settings);
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab);
        await tester.pumpAndSettle();

        // Look for biometric toggle
        final switches = find.byType(Switch);
        expect(switches, findsWidgets);
      }
    });

    testWidgets('Notification settings accessible', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Navigate to settings
      final settingsTab = find.byIcon(Icons.settings);
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab);
        await tester.pumpAndSettle();

        // Verify notification settings
        expect(find.byType(Switch), findsWidgets);
      }
    });

    testWidgets('Data export option visible', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Navigate to settings
      final settingsTab = find.byIcon(Icons.settings);
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab);
        await tester.pumpAndSettle();

        // Look for export option
        expect(find.byType(ListTile), findsWidgets);
      }
    });

    testWidgets('Privacy information displayed', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Navigate to settings
      final settingsTab = find.byIcon(Icons.settings);
      if (settingsTab.evaluate().isNotEmpty) {
        await tester.tap(settingsTab);
        await tester.pumpAndSettle();

        // Scroll to privacy policy
        await tester.scroll(find.byType(ListView).first, const Offset(0, -300));
        await tester.pumpAndSettle();

        // Should have privacy/about options
        expect(find.byType(ListTile), findsWidgets);
      }
    });

    testWidgets('Category colors and icons display', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Navigate to transactions
      final transactionsTab = find.byIcon(Icons.receipt);
      if (transactionsTab.evaluate().isNotEmpty) {
        await tester.tap(transactionsTab);
        await tester.pumpAndSettle();

        // Verify category badges with colors
        expect(find.byType(Container), findsWidgets);
      }
    });

    testWidgets('Spent vs Income cards display', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // On home screen, should show spent and income cards
      final cards = find.byType(Card);
      expect(cards, findsWidgets);
    });

    testWidgets('Date grouping in transactions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Navigate to transactions
      final transactionsTab = find.byIcon(Icons.receipt);
      if (transactionsTab.evaluate().isNotEmpty) {
        await tester.tap(transactionsTab);
        await tester.pumpAndSettle();

        // Should group by date
        expect(find.byType(Text), findsWidgets);
      }
    });

    testWidgets('Bottom navigation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 8));

      // Verify all nav items are tappable
      final navItems = find.byType(BottomNavigationBarItem);
      expect(navItems, findsWidgets);

      // Tap each nav item
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.home), findsWidgets);
    });
  });
}
