import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:spendlens/domain/models/budget.dart';
import 'package:spendlens/domain/models/transaction.dart';
import 'package:spendlens/presentation/providers/budget_provider.dart';
import 'package:spendlens/presentation/providers/cache_provider.dart';
import 'package:spendlens/presentation/providers/transaction_provider.dart';

// Value: protects=live category budgets and complete payday totals;
// fails_when=cache dependency or prior-month cycle range is lost;
// why_new=health tests override totals rather than reading real Hive; seam=none
void main() {
  late Directory fixture;
  late ProviderContainer container;
  setUpAll(() {
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(BudgetAdapter());
  });
  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('spendlens-finance-test-');
    Hive.init(fixture.path);
    await Hive.openBox<Transaction>('transactions');
    await Hive.openBox<Budget>('budgets');
    await Hive.openBox('settings');
    container = ProviderContainer();
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await fixture.delete(recursive: true);
  });
  Transaction txn(String id, double amount, DateTime date,
          {bool credit = false, bool ignored = false}) =>
      Transaction(id: id, amount: amount, merchant: 'Fixture',
          category: 'Food', isCredit: credit, transactionDate: date,
          source: 'manual', createdAt: date, isIgnored: ignored);

  test('a watched category budget refreshes on add, ignore and restore', () async {
    final now = DateTime.now();
    await Hive.box<Budget>('budgets').put('b', Budget(id: 'b', category: 'Food',
        monthlyLimit: 100, monthYear: '${now.year}-${now.month.toString().padLeft(2, '0')}',
        isSynced: false));
    final sub = container.listen(budgetProgressProvider('Food'), (_, __) {});
    addTearDown(sub.close);
    expect(await container.read(budgetProgressProvider('Food').future), (0.0, 100.0));
    final t = txn('food', 150, now);
    await Hive.box<Transaction>('transactions').put(t.id, t);
    container.read(transactionCacheProvider.notifier).bump();
    expect(await container.read(budgetProgressProvider('Food').future), (150.0, 100.0));
    expect(await container.read(overBudgetCategoriesProvider.future), ['Food']);
    t.isIgnored = true;
    await t.save();
    container.read(transactionCacheProvider.notifier).bump();
    expect(await container.read(budgetProgressProvider('Food').future), (0.0, 100.0));
    t.isIgnored = false;
    await t.save();
    container.read(transactionCacheProvider.notifier).bump();
    expect(await container.read(budgetProgressProvider('Food').future), (150.0, 100.0));
  });

  test('safe spending uses the salary cycle while home summaries remain monthly', () async {
    final now = DateTime.now();
    // Payday tomorrow means the current cycle starts in the previous month.
    final salaryDay = now.day < 31 ? now.day + 1 : 31;
    await Hive.box('settings').put('salaryDay', salaryDay);
    final prevLast = DateTime(now.year, now.month, 0);
    final prevPayday = DateTime(prevLast.year, prevLast.month,
        salaryDay > prevLast.day ? prevLast.day : salaryDay);
    final start = now.day < salaryDay ? prevPayday : DateTime(now.year, now.month, salaryDay);
    final nextLast = DateTime(start.year, start.month + 2, 0);
    final next = DateTime(nextLast.year, nextLast.month,
        salaryDay > nextLast.day ? nextLast.day : salaryDay);
    final rows = [txn('salary', 10000, start, credit: true),
      txn('cycle-expense', 500, start),
      txn('before', 700, start.subtract(const Duration(days: 1))),
      txn('after', 900, next), txn('ignored', 100, start, ignored: true)];
    await Hive.box<Transaction>('transactions').putAll({for (final t in rows) t.id: t});
    final stats = await container.read(homeStatsProvider.future);
    expect(stats.cycleStart, start);
    expect(stats.cycleEnd, next.subtract(const Duration(days: 1)));
    expect(stats.safeToSpend, closeTo(9500 / stats.daysRemainingInCycle, 0.001));
    final calendar = await container.read(transactionsProvider.future);
    final visible = calendar.where((t) => !t.isIgnored).toList();
    expect(stats.totalIncome, visible.where((t) => t.isCredit).fold<double>(0, (sum, t) => sum + t.amount));
    expect(stats.totalSpent, visible.where((t) => !t.isCredit).fold<double>(0, (sum, t) => sum + t.amount));
    expect(stats.recentTransactions.every((t) => visible.contains(t)), isTrue);
    expect(calendar.every((t) => t.transactionDate.month == now.month && t.transactionDate.year == now.year), isTrue);
  });
}
