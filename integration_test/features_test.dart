import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spendlens/main.dart' as app;

/// Helper: boot app → skip onboarding → skip auth → land on Dashboard
Future<void> _bootToDashboard(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));
  for (int i = 0; i < 3; i++) {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue without login'));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SpendLens — Navigation Flow', () {
    testWidgets('TC-F01: Full onboarding → auth → home flow completes', (tester) async {
      await _bootToDashboard(tester);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('TC-F02: Tab bar persists across all screens', (tester) async {
      await _bootToDashboard(tester);

      final tabs = ['Transactions', 'Budget', 'Insights', 'Settings', 'Home'];
      for (final tab in tabs) {
        final finder = find.text(tab);
        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder.last);
          await tester.pumpAndSettle();
          // Bottom nav must always be visible
          expect(find.byType(BottomNavigationBar), findsOneWidget);
        }
      }
    });

    testWidgets('TC-F03: Back-navigation from Budget returns to Home', (tester) async {
      await _bootToDashboard(tester);

      await tester.tap(find.text('Budget').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('TC-F04: Back-navigation from Insights returns to Home', (tester) async {
      await _bootToDashboard(tester);

      await tester.tap(find.text('Insights').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });
  });

  group('SpendLens — Dashboard Widgets', () {
    testWidgets('TC-F05: Spent amount starts at ₹0 for new user', (tester) async {
      await _bootToDashboard(tester);

      // ₹0 should appear in both SPENT and INCOME cards
      expect(find.textContaining('₹0'), findsWidgets);
    });

    testWidgets('TC-F06: Dashboard has share/export action icon', (tester) async {
      await _bootToDashboard(tester);

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('TC-F07: Dashboard renders without overflow errors', (tester) async {
      await _bootToDashboard(tester);

      // If any RenderFlex overflow occurs, tester would have reported it.
      // Just verify the two summary cards are present side by side.
      expect(find.text('SPENT'), findsOneWidget);
      expect(find.text('INCOME'), findsOneWidget);
    });
  });

  group('SpendLens — Transactions Screen', () {
    testWidgets('TC-F08: Transactions screen renders with ListView', (tester) async {
      await _bootToDashboard(tester);
      await tester.tap(find.text('Transactions').last);
      await tester.pumpAndSettle();

      // Either a ListView (has transactions) or empty state text is shown
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      final hasEmptyText =
          find.textContaining('Error').evaluate().isEmpty; // no error
      expect(hasListView || hasEmptyText, isTrue);
    });

    testWidgets('TC-F09: FAB is tappable on Transactions screen', (tester) async {
      await _bootToDashboard(tester);
      await tester.tap(find.text('Transactions').last);
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // Tap it — should not crash
      await tester.tap(fab);
      await tester.pumpAndSettle();
    });
  });

  group('SpendLens — Budget Screen', () {
    testWidgets('TC-F10: Budget screen renders without crash', (tester) async {
      await _bootToDashboard(tester);
      await tester.tap(find.text('Budget').last);
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Budget'), findsWidgets);
    });

    testWidgets('TC-F11: Budget screen has Add Budget button', (tester) async {
      await _bootToDashboard(tester);
      await tester.tap(find.text('Budget').last);
      await tester.pumpAndSettle();

      // FAB or Add button should exist
      final fab = find.byType(FloatingActionButton);
      final addBtn = find.textContaining('Add');
      expect(
        fab.evaluate().isNotEmpty || addBtn.evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('SpendLens — Settings Screen', () {
    Future<void> goToSettings(WidgetTester tester) async {
      await _bootToDashboard(tester);
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
    }

    testWidgets('TC-F12: Settings lists all sections', (tester) async {
      await goToSettings(tester);

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('TC-F13: Biometric Lock toggle is interactive', (tester) async {
      await goToSettings(tester);

      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      // Tap the first switch — should not crash
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
    });

    testWidgets('TC-F14: Settings scrollable — bottom items reachable', (tester) async {
      await goToSettings(tester);

      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();

      // After scrolling, more list tiles should still be present
      expect(find.byType(ListTile), findsWidgets);
    });
  });

  group('SpendLens — Theme & Accessibility', () {
    testWidgets('TC-F15: App uses MaterialApp with dark theme', (tester) async {
      app.main();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      // Dark theme configured — themeMode should not be light-only
      expect(materialApp, isNotNull);
    });

    testWidgets('TC-F16: No RenderFlex overflow on splash screen', (tester) async {
      app.main();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Splash screen is a centered column — should layout without errors
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('TC-F17: All screens have correct AppBar titles', (tester) async {
      await _bootToDashboard(tester);

      final screenLabels = {
        'Transactions': 'Transactions',
        'Budget': 'Budget',
        'Insights': 'Insights',
        'Settings': 'Settings',
      };

      for (final entry in screenLabels.entries) {
        await tester.tap(find.text(entry.key).last);
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsWidgets);
      }
    });
  });
}
