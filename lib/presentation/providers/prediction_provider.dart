import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';
import '../../domain/models/transaction.dart';
import 'transaction_provider.dart';
import 'cache_provider.dart';

// ── Models ─────────────────────────────────────────────────────────────────────

class SalaryRunOutResult {
  final double salaryAmount;
  final DateTime? salaryDate;
  final double avgDailySpend;
  final DateTime? estimatedRunOutDate;
  final int daysUntilRunOut;
  final double safeToSpendPerDay;
  final bool isOnTrack;

  const SalaryRunOutResult({
    required this.salaryAmount,
    this.salaryDate,
    required this.avgDailySpend,
    this.estimatedRunOutDate,
    required this.daysUntilRunOut,
    required this.safeToSpendPerDay,
    required this.isOnTrack,
  });

  static SalaryRunOutResult empty() => const SalaryRunOutResult(
        salaryAmount: 0,
        avgDailySpend: 0,
        daysUntilRunOut: 999,
        safeToSpendPerDay: 0,
        isOnTrack: true,
      );
}

class CategoryProjection {
  final String category;
  final double spentSoFar;
  final double projectedMonthEnd;
  final double lastMonthActual;
  final bool isOverLast;
  final double overByPercent;
  final String trendIcon;

  const CategoryProjection({
    required this.category,
    required this.spentSoFar,
    required this.projectedMonthEnd,
    required this.lastMonthActual,
    required this.isOverLast,
    required this.overByPercent,
    required this.trendIcon,
  });
}

class DailyCashFlow {
  final DateTime date;
  final double projectedBalance;

  const DailyCashFlow({
    required this.date,
    required this.projectedBalance,
  });
}

// ── Internal helpers ──────────────────────────────────────────────────────────

const _salaryKeywords = [
  'salary', 'sal', 'payroll', 'ctc', 'stipend', 'wages',
];

bool _looksLikeSalary(Transaction t) {
  if (!t.isCredit) return false;
  final lower = t.merchant.toLowerCase();
  return _salaryKeywords.any((k) => lower.contains(k));
}

// ── salaryRunOutProvider ───────────────────────────────────────────────────────

final salaryRunOutProvider = FutureProvider<SalaryRunOutResult>((ref) async {
  ref.watch(transactionCacheProvider);
  final now = DateTime.now();
  final thisMonthTxns = await ref.watch(transactionsProvider.future);

  // Last 30-day debits for daily average
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  final last30Debits = HiveService.transactions.values
      .where((t) =>
          !t.isCredit &&
          !t.isIgnored &&
          t.transactionDate.isAfter(thirtyDaysAgo))
      .toList();

  final totalSpentLast30 =
      last30Debits.fold<double>(0.0, (s, t) => s + t.amount);
  final avgDailySpend = totalSpentLast30 / 30.0;

  // Detect salary: keyword match first, else largest credit this month
  final credits =
      thisMonthTxns.where((t) => t.isCredit && !t.isIgnored).toList();
  Transaction? salaryTxn;
  if (credits.isNotEmpty) {
    final keywordMatch = credits.where(_looksLikeSalary).toList();
    if (keywordMatch.isNotEmpty) {
      keywordMatch.sort((a, b) => b.amount.compareTo(a.amount));
      salaryTxn = keywordMatch.first;
    } else {
      credits.sort((a, b) => b.amount.compareTo(a.amount));
      salaryTxn = credits.first;
    }
  }

  final salaryAmount = salaryTxn?.amount ?? 0.0;
  final salaryDate = salaryTxn?.transactionDate;

  // Current balance proxy: totalIncome − totalSpent this month
  final totalIncome = credits.fold<double>(0.0, (s, t) => s + t.amount);
  final totalSpentThisMonth = thisMonthTxns
      .where((t) => !t.isCredit && !t.isIgnored)
      .fold<double>(0.0, (s, t) => s + t.amount);
  final currentBalance = totalIncome - totalSpentThisMonth;

  if (avgDailySpend <= 0 || currentBalance <= 0) {
    return SalaryRunOutResult(
      salaryAmount: salaryAmount,
      salaryDate: salaryDate,
      avgDailySpend: avgDailySpend,
      estimatedRunOutDate: null,
      daysUntilRunOut: 999,
      safeToSpendPerDay: 0,
      isOnTrack: true,
    );
  }

  final daysUntilRunOut = (currentBalance / avgDailySpend).floor();
  final estimatedRunOutDate = now.add(Duration(days: daysUntilRunOut));

  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysLeftInMonth = daysInMonth - now.day;
  final safeToSpendPerDay = daysLeftInMonth > 0
      ? max(0.0, currentBalance / daysLeftInMonth)
      : 0.0;

  final monthEnd = DateTime(now.year, now.month, daysInMonth);
  final isOnTrack = estimatedRunOutDate.isAfter(monthEnd);

  return SalaryRunOutResult(
    salaryAmount: salaryAmount,
    salaryDate: salaryDate,
    avgDailySpend: avgDailySpend,
    estimatedRunOutDate: estimatedRunOutDate,
    daysUntilRunOut: daysUntilRunOut,
    safeToSpendPerDay: safeToSpendPerDay,
    isOnTrack: isOnTrack,
  );
});

// ── categoryProjectionProvider ────────────────────────────────────────────────

final categoryProjectionProvider =
    FutureProvider<List<CategoryProjection>>((ref) async {
  ref.watch(transactionCacheProvider);
  final now = DateTime.now();
  final thisMonthTxns = await ref.watch(transactionsProvider.future);

  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final elapsedDays = max(1, now.day);

  // This month per category
  final thisMonthByCategory = <String, double>{};
  for (final t in thisMonthTxns.where((t) => !t.isCredit && !t.isIgnored)) {
    thisMonthByCategory[t.category] =
        (thisMonthByCategory[t.category] ?? 0) + t.amount;
  }

  // Last month per category (direct Hive access — same pattern as insights_provider)
  final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
  final lastMonthNum = now.month == 1 ? 12 : now.month - 1;
  final lastMonthByCategory = <String, double>{};
  for (final t in HiveService.transactions.values.where((t) =>
      !t.isCredit &&
      !t.isIgnored &&
      t.transactionDate.year == lastMonthYear &&
      t.transactionDate.month == lastMonthNum)) {
    lastMonthByCategory[t.category] =
        (lastMonthByCategory[t.category] ?? 0) + t.amount;
  }

  final allCategories = {
    ...thisMonthByCategory.keys,
    ...lastMonthByCategory.keys,
  };

  final projections = <CategoryProjection>[];
  for (final cat in allCategories) {
    final spentSoFar = thisMonthByCategory[cat] ?? 0.0;
    final dailyRate = spentSoFar / elapsedDays;
    final projectedMonthEnd = dailyRate * daysInMonth;
    final lastMonthActual = lastMonthByCategory[cat] ?? 0.0;

    double overByPercent = 0.0;
    if (lastMonthActual > 0) {
      overByPercent =
          ((projectedMonthEnd - lastMonthActual) / lastMonthActual) * 100;
    }

    final isOverLast =
        projectedMonthEnd > lastMonthActual && lastMonthActual > 0;
    final trendIcon = overByPercent > 5
        ? '📈'
        : overByPercent < -5
            ? '📉'
            : '➡️';

    projections.add(CategoryProjection(
      category: cat,
      spentSoFar: spentSoFar,
      projectedMonthEnd: projectedMonthEnd,
      lastMonthActual: lastMonthActual,
      isOverLast: isOverLast,
      overByPercent: overByPercent,
      trendIcon: trendIcon,
    ));
  }

  projections
      .sort((a, b) => b.projectedMonthEnd.compareTo(a.projectedMonthEnd));
  return projections;
});

// ── dailyCashFlowProvider ─────────────────────────────────────────────────────

final dailyCashFlowProvider =
    FutureProvider<List<DailyCashFlow>>((ref) async {
  ref.watch(transactionCacheProvider);
  final now = DateTime.now();
  final thisMonthTxns = await ref.watch(transactionsProvider.future);

  // Current balance
  final totalIncome = thisMonthTxns
      .where((t) => t.isCredit && !t.isIgnored)
      .fold<double>(0.0, (s, t) => s + t.amount);
  final totalSpent = thisMonthTxns
      .where((t) => !t.isCredit && !t.isIgnored)
      .fold<double>(0.0, (s, t) => s + t.amount);
  final currentBalance = totalIncome - totalSpent;

  // Average daily spend over last 30 days
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  final last30Debits = HiveService.transactions.values
      .where((t) =>
          !t.isCredit &&
          !t.isIgnored &&
          t.transactionDate.isAfter(thirtyDaysAgo))
      .toList();
  final avgDailySpend = last30Debits.isEmpty
      ? 0.0
      : last30Debits.fold<double>(0.0, (s, t) => s + t.amount) / 30.0;

  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

  final cashFlow = <DailyCashFlow>[];
  double balance = currentBalance;

  for (int day = now.day; day <= daysInMonth; day++) {
    final date = DateTime(now.year, now.month, day);
    // For days after today, deduct avg daily spend
    if (day > now.day) {
      balance -= avgDailySpend;
    }
    cashFlow.add(DailyCashFlow(
      date: date,
      projectedBalance: balance,
    ));
  }

  return cashFlow;
});
