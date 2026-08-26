import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/presentation/screens/home/home_screen.dart';
import 'package:spendlens/presentation/providers/transaction_provider.dart';
import 'package:spendlens/presentation/providers/health_provider.dart';
import 'package:spendlens/presentation/providers/budget_provider.dart';
import 'package:spendlens/presentation/providers/settings_provider.dart';
import 'package:spendlens/presentation/providers/recurring_provider.dart';
import 'package:spendlens/core/utils/recurring_detector.dart';
import 'package:spendlens/presentation/providers/insights_provider.dart';
import 'package:spendlens/presentation/providers/festival_provider.dart';
import 'package:spendlens/domain/models/transaction.dart';
import 'package:spendlens/core/theme/app_theme.dart';

// ── Stub data ──────────────────────────────────────────────────────────────

HomeStats _emptyStats = (
  totalSpent: 0.0,
  totalIncome: 0.0,
  categoryTotals: const <String, double>{},
  topPayees: const <({String name, double amount, int count})>[],
  recentTransactions: const <Transaction>[],
  safeToSpend: 0.0,
  daysRemainingInCycle: 15,
  cycleStart: DateTime(2024, 6, 1),
  cycleEnd: DateTime(2024, 6, 30),
);

HomeStats _nonEmptyStats = (
  totalSpent: 3200.0,
  totalIncome: 10000.0,
  categoryTotals: const {'Food & Dining': 1500.0, 'Transport': 700.0},
  topPayees: const [
    (name: 'Zomato', amount: 900.0, count: 5),
    (name: 'Ola', amount: 400.0, count: 3),
  ],
  recentTransactions: const <Transaction>[],
  safeToSpend: 450.0,
  daysRemainingInCycle: 15,
  cycleStart: DateTime(2024, 6, 1),
  cycleEnd: DateTime(2024, 6, 30),
);

const _healthData = (
  score: 72,
  grade: 'Good',
  tip: 'Solid! A 10% cut in your top category boosts your score.',
  savingsRate: 0.68,
  budgetAdherence: 1.0,
  spentVsIncomeRatio: 0.32,
);

const _emptyHealth = (
  score: 55,
  grade: 'Fair',
  tip: 'Review your biggest spending category this month.',
  savingsRate: 0.5,
  budgetAdherence: 1.0,
  spentVsIncomeRatio: 0.0,
);

/// In-memory savings goal so the widget test never touches Hive.
class _FixedGoalNotifier extends SavingsGoalNotifier {
  @override
  double build() => 5000.0;
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _buildHome({required bool empty}) {
  return ProviderScope(
    overrides: [
      homeStatsProvider.overrideWith(
        (ref) async => empty ? _emptyStats : _nonEmptyStats,
      ),
      healthScoreProvider.overrideWith(
        (ref) async => empty ? _emptyHealth : _healthData,
      ),
      allCategoriesSpendingProvider.overrideWith(
        (ref) async => <({String category, double spent, double? limit})>[],
      ),
      transactionsProvider.overrideWith((ref) async => <Transaction>[]),
      savingsGoalProvider.overrideWith(_FixedGoalNotifier.new),
      upcomingBillsProvider.overrideWith((ref) => <RecurringItem>[]),
      noSpendStreakProvider.overrideWith((ref) async => 0),
      upcomingFestivalProvider.overrideWith((ref) async => null),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomeScreen(),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('HomeScreen — renders without crash', () {
    testWidgets('empty state renders', (tester) async {
      await tester.pumpWidget(_buildHome(empty: true));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('non-empty state renders', (tester) async {
      await tester.pumpWidget(_buildHome(empty: false));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('HomeScreen — health score card', () {
    testWidgets('shows grade text after animation', (tester) async {
      await tester.pumpWidget(_buildHome(empty: false));
      await tester.pump(const Duration(seconds: 2));
      // Grade renders as "<emoji> Good" and may sit below the fold.
      final gradeFinder = find.textContaining('Good');
      await tester.scrollUntilVisible(
        gradeFinder.first,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(gradeFinder, findsWidgets);
    });
  });

  group('HomeScreen — scrollable', () {
    testWidgets('scroll does not throw', (tester) async {
      await tester.pumpWidget(_buildHome(empty: false));
      await tester.pump(const Duration(seconds: 1));
      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
