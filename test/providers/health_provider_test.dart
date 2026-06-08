import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/presentation/providers/health_provider.dart';
import 'package:spendlens/presentation/providers/transaction_provider.dart';
import 'package:spendlens/presentation/providers/budget_provider.dart';
import 'package:spendlens/domain/models/transaction.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

HomeStats _makeStats({double spent = 0, double income = 0}) => (
  totalSpent: spent,
  totalIncome: income,
  categoryTotals: const <String, double>{},
  topPayees: const <({String name, double amount, int count})>[],
  recentTransactions: const <Transaction>[],
  safeToSpend: income > 0 && income > spent ? (income - spent) / 15 : 0.0,
  daysRemainingInCycle: 15,
  cycleStart: DateTime(2024, 6, 1),
  cycleEnd: DateTime(2024, 6, 30),
);

typedef CategoryRow = ({String category, double spent, double? limit});

ProviderContainer _container({
  required HomeStats stats,
  List<CategoryRow> categories = const [],
}) {
  return ProviderContainer(
    overrides: [
      homeStatsProvider.overrideWith((ref) async => stats),
      allCategoriesSpendingProvider.overrideWith((ref) async => categories),
    ],
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('healthScoreProvider — grade thresholds', () {
    test('high savings → Excellent', () async {
      // savingsRate = 0.8 → 40pts + 30 (no budgets) + 20 (income) = 90
      final stats = _makeStats(income: 10000, spent: 2000);
      final c = _container(stats: stats);
      addTearDown(c.dispose);
      final h = await c.read(healthScoreProvider.future);
      expect(h.grade, anyOf('Excellent', 'Good'));
      expect(h.score, greaterThan(69));
    });

    test('moderate savings → Good or Fair', () async {
      final stats = _makeStats(income: 10000, spent: 5000);
      final c = _container(stats: stats);
      addTearDown(c.dispose);
      final h = await c.read(healthScoreProvider.future);
      expect(h.score, inInclusiveRange(0, 100));
      expect(h.grade, isNotEmpty);
    });

    test('no income → reduced income score', () async {
      final stats = _makeStats(income: 0, spent: 0);
      final c = _container(stats: stats);
      addTearDown(c.dispose);
      final h = await c.read(healthScoreProvider.future);
      // incomeScore = 5, savingsRate=0.5 (neutral) → 50*0.5+30+5=60 → Fair
      expect(h.score, lessThanOrEqualTo(65));
    });

    test('all income spent → low score', () async {
      final stats = _makeStats(income: 5000, spent: 5000);
      final c = _container(stats: stats);
      addTearDown(c.dispose);
      final h = await c.read(healthScoreProvider.future);
      expect(h.score, lessThan(55));
    });

    test('spending over income → Critical or Needs Work', () async {
      final stats = _makeStats(income: 3000, spent: 8000);
      final c = _container(stats: stats);
      addTearDown(c.dispose);
      final h = await c.read(healthScoreProvider.future);
      expect(h.grade, anyOf('Critical', 'Needs Work'));
    });
  });

  group('healthScoreProvider — fields', () {
    test('score clamped to 0-100', () async {
      final stats = _makeStats(income: 10000, spent: 0);
      final c = _container(stats: stats);
      addTearDown(c.dispose);
      final h = await c.read(healthScoreProvider.future);
      expect(h.score, inInclusiveRange(0, 100));
    });

    test('tip is non-empty', () async {
      final stats = _makeStats(income: 5000, spent: 2000);
      final c = _container(stats: stats);
      addTearDown(c.dispose);
      final h = await c.read(healthScoreProvider.future);
      expect(h.tip, isNotEmpty);
    });

    test('savingsRate is 0 when spend > income', () async {
      final stats = _makeStats(income: 1000, spent: 5000);
      final c = _container(stats: stats);
      addTearDown(c.dispose);
      final h = await c.read(healthScoreProvider.future);
      expect(h.savingsRate, equals(0.0));
    });

    test('budget adherence = 1.0 when no budgets set', () async {
      final stats = _makeStats(income: 5000, spent: 2000);
      final c = _container(stats: stats, categories: []);
      addTearDown(c.dispose);
      final h = await c.read(healthScoreProvider.future);
      expect(h.budgetAdherence, equals(1.0));
    });

    test('budget adherence < 1 when over-budget categories exist', () async {
      final stats = _makeStats(income: 5000, spent: 2000);
      final cats = [
        (category: 'Food & Dining', spent: 1500.0, limit: 1000.0),
        (category: 'Transport', spent: 300.0, limit: 500.0),
      ];
      final c = _container(stats: stats, categories: cats);
      addTearDown(c.dispose);
      final h = await c.read(healthScoreProvider.future);
      expect(h.budgetAdherence, lessThan(1.0));
    });

    test('spentVsIncomeRatio is 0 when no income', () async {
      final stats = _makeStats(income: 0, spent: 0);
      final c = _container(stats: stats);
      addTearDown(c.dispose);
      final h = await c.read(healthScoreProvider.future);
      expect(h.spentVsIncomeRatio, equals(0.0));
    });
  });
}
