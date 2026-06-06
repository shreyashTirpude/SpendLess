import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/budget.dart';
import '../../data/local/hive_service.dart';

final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final now = DateTime.now();
  final monthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  return HiveService.budgets.values
      .where((b) => b.monthYear == monthYear)
      .toList();
});

final budgetProgressProvider = FutureProvider.family<(double, double), String>((ref, category) async {
  final budgets = await ref.watch(budgetsProvider.future);
  final budget = budgets.firstWhere((b) => b.category == category, orElse: () => Budget(
    id: '', userId: null, category: category, monthlyLimit: 0, monthYear: '', isSynced: false,
  ));

  final transactions = HiveService.transactions.values
      .where((t) => t.category == category && !t.isCredit && !t.isIgnored)
      .fold(0.0, (sum, t) => sum + t.amount);

  return (transactions, budget.monthlyLimit);
});

final overBudgetCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final budgets = await ref.watch(budgetsProvider.future);
  final overBudget = <String>[];

  for (final b in budgets) {
    final (spent, limit) = await ref.watch(budgetProgressProvider(b.category).future);
    if (spent > limit) {
      overBudget.add(b.category);
    }
  }
  return overBudget;
});
