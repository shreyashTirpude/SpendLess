import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/budget.dart';
import '../../data/local/hive_service.dart';
import 'cache_provider.dart';
import 'transaction_provider.dart';

final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final now = DateTime.now();
  final monthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  return HiveService.budgets.values
      .where((b) => b.monthYear == monthYear)
      .toList();
});

final budgetProgressProvider = FutureProvider.family<(double, double), String>((ref, category) async {
  // MainShell bumps transactionCacheProvider on every Hive transaction write;
  // watching it here keeps "spent" (and overBudgetCategoriesProvider) fresh.
  ref.watch(transactionCacheProvider);
  final budgets = await ref.watch(budgetsProvider.future);
  final budget = budgets.firstWhere(
    (b) => b.category == category,
    orElse: () => Budget(
      id: '', userId: null, category: category, monthlyLimit: 0, monthYear: '', isSynced: false,
    ),
  );

  // Spent THIS MONTH only (budgets are monthly). Previously summed all-time,
  // which inflated "spent" and triggered false over-budget warnings.
  final now = DateTime.now();
  final transactions = HiveService.transactions.values
      .where((t) =>
          t.category == category &&
          !t.isCredit &&
          !t.isIgnored &&
          t.transactionDate.year == now.year &&
          t.transactionDate.month == now.month)
      .fold(0.0, (sum, t) => sum + t.amount);

  return (transactions, budget.monthlyLimit);
});

// ── Global ("for all") monthly budget ──────────────────────────────────────────
//
// An optional single overall limit. Spent = total expenses scanned this month.
// Stored in settings so it persists independent of per-category budgets.

class GlobalBudgetNotifier extends StateNotifier<double> {
  GlobalBudgetNotifier()
      : super((HiveService.settings.get('globalMonthlyBudget',
                defaultValue: 0.0) as num)
            .toDouble());

  Future<void> setLimit(double amount) async {
    await HiveService.settings.put('globalMonthlyBudget', amount);
    state = amount;
  }

  Future<void> clear() async {
    await HiveService.settings.put('globalMonthlyBudget', 0.0);
    state = 0.0;
  }
}

final globalBudgetProvider =
    StateNotifierProvider<GlobalBudgetNotifier, double>(
        (ref) => GlobalBudgetNotifier());

/// (spent this month, global limit). Spent auto-syncs from scanned transactions.
final globalBudgetProgressProvider =
    FutureProvider<(double, double)>((ref) async {
  final limit = ref.watch(globalBudgetProvider);
  final totalSpent = await ref.watch(totalSpentProvider.future);
  return (totalSpent, limit);
});

final overBudgetCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final budgets = await ref.watch(budgetsProvider.future);
  final overBudget = <String>[];

  for (final b in budgets) {
    final (spent, limit) = await ref.watch(budgetProgressProvider(b.category).future);
    if (limit > 0 && spent > limit) {
      overBudget.add(b.category);
    }
  }
  return overBudget;
});

// Merged view: all categories that have spending this month + any set budgets
// Returns sorted by spent amount descending. Used by the budget screen to fix the empty state.
final allCategoriesSpendingProvider = FutureProvider<List<({String category, double spent, double? limit})>>((ref) async {
  final totals = await ref.watch(categoryTotalsProvider.future);
  final budgets = await ref.watch(budgetsProvider.future);

  final budgetMap = {for (final b in budgets) b.category: b.monthlyLimit};

  // Start with all expense categories that have spending
  final result = totals.entries
      .where((e) => e.value > 0)
      .map((e) => (category: e.key, spent: e.value, limit: budgetMap[e.key]))
      .toList();

  // Also add budget-set categories with zero spending (so they're always visible)
  for (final b in budgets) {
    if (!totals.containsKey(b.category)) {
      result.add((category: b.category, spent: 0.0, limit: b.monthlyLimit));
    }
  }

  result.sort((a, b) => b.spent.compareTo(a.spent));
  return result;
});
