import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/transaction.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/local/hive_service.dart';
import '../../core/utils/merchant_normalizer.dart';
import 'cache_provider.dart';

final transactionRepositoryProvider = Provider((ref) {
  return TransactionRepositoryImpl();
});

// All providers watch transactionCacheProvider — one bump refreshes everything
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionCacheProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getThisMonth();
});

final transactionsByMonthProvider = FutureProvider.family<List<Transaction>, (int, int)>((ref, args) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getByMonth(args.$1, args.$2);
});

final categoryTotalsProvider = FutureProvider<Map<String, double>>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  final totals = <String, double>{};
  for (final t in txns.where((t) => !t.isCredit && !t.isIgnored)) {
    totals[t.category] = (totals[t.category] ?? 0) + t.amount;
  }
  return totals;
});

final totalSpentProvider = FutureProvider<double>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  return txns.where((t) => !t.isCredit && !t.isIgnored).fold<double>(0.0, (sum, t) => sum + t.amount);
});

final totalIncomeProvider = FutureProvider<double>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  return txns.where((t) => t.isCredit && !t.isIgnored).fold<double>(0.0, (sum, t) => sum + t.amount);
});

final dailySpendProvider = FutureProvider<List<(DateTime, double)>>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  final dailyMap = <DateTime, double>{};
  for (final t in txns.where((t) => !t.isCredit && !t.isIgnored)) {
    final date = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
    dailyMap[date] = (dailyMap[date] ?? 0) + t.amount;
  }
  return dailyMap.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => a.$1.compareTo(b.$1));
});

// Top 5 payees by total amount paid
final topPayeesByAmountProvider = FutureProvider<List<({String name, double amount, int count})>>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  final payeeData = <String, (double, int)>{};
  for (final t in txns.where((t) => !t.isCredit && !t.isIgnored)) {
    final existing = payeeData[t.merchant] ?? (0.0, 0);
    payeeData[t.merchant] = (existing.$1 + t.amount, existing.$2 + 1);
  }
  final sorted = payeeData.entries.toList()
    ..sort((a, b) => b.value.$1.compareTo(a.value.$1));
  return sorted
      .take(5)
      .map((e) => (name: e.key, amount: e.value.$1, count: e.value.$2))
      .toList();
});

final uniquePayeesProvider = FutureProvider<List<String>>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  final payees = txns.where((t) => !t.isCredit).map((t) => t.merchant).toSet().toList();
  payees.sort();
  return payees;
});

final transactionsByCategoryProvider = FutureProvider.family<List<Transaction>, String>((ref, category) async {
  final txns = await ref.watch(transactionsProvider.future);
  return txns.where((t) => t.category == category && !t.isIgnored).toList();
});

final categoryMonthComparisonProvider = FutureProvider.family<(double, double), String>((ref, category) async {
  final now = DateTime.now();
  final thisMonthTxns = await ref.watch(transactionsByCategoryProvider(category).future);

  final lastYear = now.month == 1 ? now.year - 1 : now.year;
  final lastMonth = now.month == 1 ? 12 : now.month - 1;

  final lastMonthTxns = HiveService.transactions.values
      .where((t) =>
          t.transactionDate.year == lastYear &&
          t.transactionDate.month == lastMonth &&
          t.category == category &&
          !t.isCredit &&
          !t.isIgnored)
      .toList();

  final thisSpent = thisMonthTxns.where((t) => !t.isCredit).fold(0.0, (sum, t) => sum + t.amount);
  final lastSpent = lastMonthTxns.fold(0.0, (sum, t) => sum + t.amount);

  return (thisSpent, lastSpent);
});

final allTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionCacheProvider);
  final all = HiveService.transactions.values
      .where((t) => !t.isIgnored)
      .toList()
    ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  return all;
});

// ── Merchant intelligence: per-merchant analytics ─────────────────────────────

typedef MerchantStats = ({
  String merchant,
  String canonical,
  double totalSpent,
  int txnCount,
  double avgOrder,
  double maxOrder,
  String topCategory,
});

final merchantIntelligenceProvider = FutureProvider<List<MerchantStats>>((ref) async {
  ref.watch(transactionCacheProvider);
  final all = HiveService.transactions.values
      .where((t) => !t.isCredit && !t.isIgnored)
      .toList();

  final grouped = <String, List<double>>{};
  final categoryMap = <String, Map<String, int>>{};

  for (final t in all) {
    final canonical = MerchantNormalizer.normalize(t.merchant);
    grouped.putIfAbsent(canonical, () => []).add(t.amount);
    final cats = categoryMap.putIfAbsent(canonical, () => {});
    cats[t.category] = (cats[t.category] ?? 0) + 1;
  }

  return grouped.entries.map((e) {
    final amounts = e.value;
    final cats = categoryMap[e.key]!;
    final topCat = cats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return (
      merchant: e.key,
      canonical: e.key,
      totalSpent: amounts.reduce((a, b) => a + b),
      txnCount: amounts.length,
      avgOrder: amounts.reduce((a, b) => a + b) / amounts.length,
      maxOrder: amounts.reduce((a, b) => a > b ? a : b),
      topCategory: topCat,
    );
  }).toList()
    ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
});

// ── Tax savings tracker ────────────────────────────────────────────────────────

typedef TaxInsights = ({
  double health80D,
  double investment80C,
  double rentHRA,
  double totalDeductions,
  double estimatedTaxSaving,
});

final taxInsightsProvider = FutureProvider<TaxInsights>((ref) async {
  ref.watch(transactionCacheProvider);
  final all = HiveService.transactions.values
      .where((t) => !t.isCredit && !t.isIgnored)
      .toList();

  const healthKeywords = ['pharmacy', 'hospital', 'clinic', 'health', 'medical', 'doctor', 'insurance'];
  const investmentKeywords = ['ppf', 'elss', 'nps', 'lic', 'mutual fund', 'fd', 'zerodha', 'groww', 'sip'];
  const rentKeywords = ['rent', 'rental', 'house rent', 'pg', 'hostel'];

  double health80D = 0, investment80C = 0, rentHRA = 0;

  for (final t in all) {
    final lower = '${t.merchant} ${t.category}'.toLowerCase();
    if (healthKeywords.any((k) => lower.contains(k))) health80D += t.amount;
    if (investmentKeywords.any((k) => lower.contains(k))) investment80C += t.amount;
    if (rentKeywords.any((k) => lower.contains(k))) rentHRA += t.amount;
  }

  // Cap at statutory limits
  health80D = health80D.clamp(0, 25000);
  investment80C = investment80C.clamp(0, 150000);
  rentHRA = rentHRA.clamp(0, 240000); // 20k/month max

  final totalDeductions = health80D + investment80C + rentHRA;
  // Rough tax saving at 30% slab
  final estimatedTaxSaving = totalDeductions * 0.30;

  return (
    health80D: health80D,
    investment80C: investment80C,
    rentHRA: rentHRA,
    totalDeductions: totalDeductions,
    estimatedTaxSaving: estimatedTaxSaving,
  );
});

// ── Cash flow forecast ────────────────────────────────────────────────────────

typedef CashFlowForecast = ({
  double projectedSpend,
  double projectedSavings,
  double dailyBudget,
  int daysUntilEmpty,
  bool isOnTrack,
});

final cashFlowForecastProvider = FutureProvider<CashFlowForecast>((ref) async {
  ref.watch(transactionCacheProvider);
  final stats = await ref.watch(homeStatsProvider.future);

  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysPassed = now.day;
  final daysLeft = daysInMonth - daysPassed;

  final dailyAvg = daysPassed > 0 ? stats.totalSpent / daysPassed : 0.0;
  final projectedSpend = dailyAvg * daysInMonth;
  final projectedSavings = stats.totalIncome - projectedSpend;

  final remaining = stats.totalIncome - stats.totalSpent;
  final dailyBudget = daysLeft > 0 ? remaining / daysLeft : 0.0;
  final daysUntilEmpty = (dailyAvg > 0 && remaining > 0)
      ? (remaining / dailyAvg).floor()
      : (remaining <= 0 ? 0 : 999);

  return (
    projectedSpend: projectedSpend,
    projectedSavings: projectedSavings,
    dailyBudget: dailyBudget.clamp(0.0, double.infinity),
    daysUntilEmpty: daysUntilEmpty.clamp(0, 999),
    isOnTrack: projectedSpend <= stats.totalIncome,
  );
});

// ── Account balance from parsed SMS ──────────────────────────────────────────

typedef AccountBalance = ({String accountLast4, double balance, DateTime updatedAt});

final accountBalancesProvider = Provider<List<AccountBalance>>((ref) {
  ref.watch(transactionCacheProvider);
  // Read stored per-account balances from settings box
  final raw = HiveService.settings.get('account_balances', defaultValue: <String, dynamic>{}) as Map;
  final result = <AccountBalance>[];
  for (final entry in raw.entries) {
    final data = entry.value as Map?;
    if (data == null) continue;
    result.add((
      accountLast4: entry.key as String,
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    ));
  }
  result.sort((a, b) => b.balance.compareTo(a.balance));
  return result;
});

final totalAccountBalanceProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountBalancesProvider);
  if (accounts.isEmpty) return 0.0;
  return accounts.fold(0.0, (s, a) => s + a.balance);
});

// (year, month) selected in transactions screen
final selectedMonthProvider = StateProvider<(int, int)>((ref) {
  final now = DateTime.now();
  return (now.year, now.month);
});

final selectedMonthTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  ref.watch(transactionCacheProvider); // refresh when SMS scan or edits occur
  final (year, month) = ref.watch(selectedMonthProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final txns = List<Transaction>.from(repo.getByMonth(year, month));
  return txns..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
});

// ── Cadence-aware salary cycle engine ────────────────────────────────────────

DateTime _computeCycleStart(DateTime now, int salaryDay) {
  final lastDayThisMonth = DateTime(now.year, now.month + 1, 0).day;
  final clamped = min(salaryDay, lastDayThisMonth);
  if (now.day >= clamped) {
    return DateTime(now.year, now.month, clamped);
  }
  final prevYear = now.month == 1 ? now.year - 1 : now.year;
  final prevMonth = now.month == 1 ? 12 : now.month - 1;
  final lastDayPrev = DateTime(prevYear, prevMonth + 1, 0).day;
  return DateTime(prevYear, prevMonth, min(salaryDay, lastDayPrev));
}

DateTime _computeCycleEnd(DateTime cycleStart) {
  final nextMonth = cycleStart.month == 12 ? 1 : cycleStart.month + 1;
  final nextYear = cycleStart.month == 12 ? cycleStart.year + 1 : cycleStart.year;
  return DateTime(nextYear, nextMonth, cycleStart.day).subtract(const Duration(days: 1));
}

// ── Aggregated home-screen stats ──────────────────────────────────────────────

typedef HomeStats = ({
  double totalSpent,
  double totalIncome,
  Map<String, double> categoryTotals,
  List<({String name, double amount, int count})> topPayees,
  List<Transaction> recentTransactions,
  double safeToSpend,
  int daysRemainingInCycle,
  DateTime cycleStart,
  DateTime cycleEnd,
});

final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  final now = DateTime.now();

  final salaryDay = HiveService.settings.get('salaryDay', defaultValue: 1) as int;
  final cycleStart = _computeCycleStart(now, salaryDay);
  final cycleEnd = _computeCycleEnd(cycleStart);
  final daysRemainingInCycle = max(0, cycleEnd.difference(now).inDays + 1);

  double totalSpent = 0;
  double totalIncome = 0;
  final categoryTotals = <String, double>{};
  final payeeData = <String, (double, int)>{};

  for (final t in txns.where((t) => !t.isIgnored)) {
    if (t.isCredit) {
      totalIncome += t.amount;
    } else {
      totalSpent += t.amount;
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
      final existing = payeeData[t.merchant] ?? (0.0, 0);
      payeeData[t.merchant] = (existing.$1 + t.amount, existing.$2 + 1);
    }
  }

  final topPayees = (payeeData.entries.toList()
        ..sort((a, b) => b.value.$1.compareTo(a.value.$1)))
      .take(5)
      .map((e) => (name: e.key, amount: e.value.$1, count: e.value.$2))
      .toList();

  final netBalance = totalIncome - totalSpent;
  final safeToSpend = daysRemainingInCycle > 0
      ? max(0.0, netBalance / daysRemainingInCycle)
      : max(0.0, netBalance);

  return (
    totalSpent: totalSpent,
    totalIncome: totalIncome,
    categoryTotals: categoryTotals,
    topPayees: topPayees,
    recentTransactions: (List<Transaction>.from(txns)
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate)))
        .take(5)
        .toList(),
    safeToSpend: safeToSpend,
    daysRemainingInCycle: daysRemainingInCycle,
    cycleStart: cycleStart,
    cycleEnd: cycleEnd,
  );
});
