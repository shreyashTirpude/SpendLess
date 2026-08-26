import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spendlens/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SpendLens — Splash & Onboarding', () {
    testWidgets('TC-01: Splash screen shows logo and app name', (tester) async {
      app.main();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('SpendLens'), findsWidgets);
      expect(find.text('💸'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('TC-02: Splash auto-routes to onboarding after 2s', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Your money, tracked automatically'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('TC-03: Onboarding page 1 content is correct', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Your money, tracked automatically'), findsOneWidget);
      expect(
        find.text(
          'SpendLens reads your bank SMS and logs every transaction the moment it happens.',
        ),
        findsOneWidget,
      );
      expect(find.text('📱'), findsOneWidget);
    });

    testWidgets('TC-04: Next advances to onboarding page 2', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Zero manual entry'), findsOneWidget);
      expect(find.text('✨'), findsOneWidget);
    });

    testWidgets('TC-05: Next advances to onboarding page 3', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Your data stays private'), findsOneWidget);
      expect(find.text('🔒'), findsOneWidget);
    });

    testWidgets('TC-06: Next advances to onboarding page 4 (Get Started)', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('We built privacy in'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('🛡️'), findsOneWidget);
    });

    testWidgets('TC-07: Get Started navigates to auth screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('SpendLens'), findsWidgets);
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  group('SpendLens — Auth Screen', () {
    Future<void> goToAuth(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
    }

    testWidgets('TC-08: Auth screen has email and password fields', (tester) async {
      await goToAuth(tester);

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('TC-09: Auth screen shows login button and skip option', (tester) async {
      await goToAuth(tester);

      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Continue without login'), findsOneWidget);
    });

    testWidgets('TC-10: Empty submit shows validation snackbar', (tester) async {
      await goToAuth(tester);

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Enter email and password'), findsOneWidget);
    });

    testWidgets('TC-11: Tap sign-up toggle switches to sign-up mode', (tester) async {
      await goToAuth(tester);

      await tester.tap(find.text("Don't have an account? Sign up"));
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full name'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('TC-12: Sign-up toggle back to login mode', (tester) async {
      await goToAuth(tester);

      await tester.tap(find.text("Don't have an account? Sign up"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Already have an account? Login'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('TC-13: Password visibility toggle works', (tester) async {
      await goToAuth(tester);

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('TC-14: Privacy info card is visible', (tester) async {
      await goToAuth(tester);

      expect(
        find.text('Free forever · No credit card · Your data stays on your device'),
        findsOneWidget,
      );
    });

    testWidgets('TC-15: Continue without login routes to home', (tester) async {
      await goToAuth(tester);

      await tester.tap(find.text('Continue without login'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });
  });

  group('SpendLens — Home Dashboard', () {
    Future<void> goToHome(WidgetTester tester) async {
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

    testWidgets('TC-16: Dashboard shows SPENT and INCOME cards', (tester) async {
      await goToHome(tester);

      expect(find.text('SPENT'), findsOneWidget);
      expect(find.text('INCOME'), findsOneWidget);
      expect(find.text('this month'), findsNWidgets(2));
    });

    testWidgets('TC-17: Dashboard shows Recent Transactions section', (tester) async {
      await goToHome(tester);

      expect(find.text('Recent Transactions'), findsOneWidget);
    });

    testWidgets('TC-18: Bottom nav has all 5 tabs', (tester) async {
      await goToHome(tester);

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('TC-19: Tapping Transactions tab navigates to Transactions screen', (tester) async {
      await goToHome(tester);

      await tester.tap(find.text('Transactions').last);
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('TC-20: Tapping Budget tab navigates to Budget screen', (tester) async {
      await goToHome(tester);

      await tester.tap(find.text('Budget').last);
      await tester.pumpAndSettle();

      expect(find.text('Budget'), findsWidgets);
    });

    testWidgets('TC-21: Tapping Insights tab navigates to Insights screen', (tester) async {
      await goToHome(tester);

      await tester.tap(find.text('Insights').last);
      await tester.pumpAndSettle();

      expect(find.text('Insights'), findsWidgets);
    });

    testWidgets('TC-22: Tapping Settings tab navigates to Settings screen', (tester) async {
      await goToHome(tester);

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('TC-23: Home tab returns to Dashboard from Settings', (tester) async {
      await goToHome(tester);

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });
  });

  group('SpendLens — Transactions Screen', () {
    Future<void> goToTransactions(WidgetTester tester) async {
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
      await tester.tap(find.text('Transactions').last);
      await tester.pumpAndSettle();
    }

    testWidgets('TC-24: Transactions screen has AppBar with title', (tester) async {
      await goToTransactions(tester);

      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
    });

    testWidgets('TC-25: FAB (+) button is present on Transactions screen', (tester) async {
      await goToTransactions(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('SpendLens — Settings Screen', () {
    Future<void> goToSettings(WidgetTester tester) async {
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
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
    }

    testWidgets('TC-26: Settings has Profile section', (tester) async {
      await goToSettings(tester);

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('TC-27: Settings has Security section with Biometric Lock toggle', (tester) async {
      await goToSettings(tester);

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Biometric Lock'), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('TC-28: Settings has Notifications section', (tester) async {
      await goToSettings(tester);

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Transaction Alerts'), findsOneWidget);
      expect(find.text('Budget Alerts'), findsOneWidget);
    });
  });
}
