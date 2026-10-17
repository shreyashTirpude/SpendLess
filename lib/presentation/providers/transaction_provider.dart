import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/transaction.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/local/hive_service.dart';
import '../../core/utils/merchant_normalizer.dart';
import '../../core/utils/salary_cycle.dart';
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

// ── People summary: per-person money sent vs received (all-time) ────────────────
//
// Groups person-to-person transactions (Send Money / Friends / Family /
// Income Transfer) by the person's name so the user can see, per contact, how
// much they've sent and received.

typedef PersonSummary = ({
  String name,
  double sent,
  double received,
  int count,
});

final peopleSummaryProvider = FutureProvider<List<PersonSummary>>((ref) async {
  ref.watch(transactionCacheProvider);
  const p2pCategories = {
    'Send Money', 'Friends', 'Family', 'Income Transfer'
  };
  final sent = <String, double>{};
  final received = <String, double>{};
  final count = <String, int>{};

  for (final t in HiveService.transactions.values) {
    if (t.isIgnored) continue;
    if (!p2pCategories.contains(t.category)) continue;
    final name = t.merchant.trim();
    if (name.isEmpty) continue;
    if (t.isCredit) {
      received[name] = (received[name] ?? 0) + t.amount;
    } else {
      sent[name] = (sent[name] ?? 0) + t.amount;
    }
    count[name] = (count[name] ?? 0) + 1;
  }

  final names = {...sent.keys, ...received.keys};
  final list = names
      .map((n) => (
            name: n,
            sent: sent[n] ?? 0,
            received: received[n] ?? 0,
            count: count[n] ?? 0,
          ))
      .toList()
    ..sort((a, b) =>
        (b.sent + b.received).compareTo(a.sent + a.received));
  return list;
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
//
// Boundaries come from SalaryCycle (lib/core/utils/salary_cycle.dart), which
// keeps the original salary day when clamping across short months.

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
  // Keep the direct cache watch so this provider still refreshes on any
  // cache bump independent of the derived future providers.
  ref.watch(transactionCacheProvider);

  // Calendar-month summary fields (totalSpent, totalIncome, categoryTotals,
  // topPayees, recentTransactions) follow the existing calendar-month
  // contract: derive them from transactionsProvider (this calendar month,
  // ignored excluded) so month labels, drilldowns, monthly savings, calendar
  // cashflow, health score and chat consumers stay consistent.
  final monthTxns = await ref.watch(transactionsProvider.future);

  final now = DateTime.now();

  final salaryDay = HiveService.settings.get('salaryDay', defaultValue: 1) as int;
  final cycle = SalaryCycle.forDate(now, salaryDay);
  final cycleStart = cycle.start;
  final cycleEnd = cycle.end;

  // Calendar days left in the cycle, ignoring time of day.
  final today = DateTime(now.year, now.month, now.day);
  final daysRemainingInCycle = max(0, cycleEnd.difference(today).inDays + 1);

  // Calendar-month totals from the month-scoped provider (already excludes
  // ignored transactions).
  double totalSpent = 0;
  double totalIncome = 0;
  final categoryTotals = <String, double>{};
  final payeeData = <String, (double, int)>{};

  for (final t in monthTxns) {
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

  // safeToSpend uses the salary-cycle balance ONLY: all non-ignored Hive
  // transactions within the half-open window [cycle.start, next payday),
  // i.e. the day after cycle.end. This includes prior-month income at the
  // start of a cycle without leaking it into the calendar-month fields.
  final windowEnd = DateTime(cycleEnd.year, cycleEnd.month, cycleEnd.day + 1);
  double cycleIncome = 0;
  double cycleSpent = 0;
  for (final t in HiveService.transactions.values) {
    if (t.isIgnored) continue;
    if (t.transactionDate.isBefore(cycleStart)) continue;
    if (!t.transactionDate.isBefore(windowEnd)) continue;
    if (t.isCredit) {
      cycleIncome += t.amount;
    } else {
      cycleSpent += t.amount;
    }
  }

  final cycleBalance = cycleIncome - cycleSpent;
  final safeToSpend = daysRemainingInCycle > 0
      ? max(0.0, cycleBalance / daysRemainingInCycle)
      : max(0.0, cycleBalance);

  return (
    totalSpent: totalSpent,
    totalIncome: totalIncome,
    categoryTotals: categoryTotals,
    topPayees: topPayees,
    recentTransactions: (List<Transaction>.from(monthTxns)
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate)))
        .take(5)
        .toList(),
    safeToSpend: safeToSpend,
    daysRemainingInCycle: daysRemainingInCycle,
    cycleStart: cycleStart,
    cycleEnd: cycleEnd,
  );
});
