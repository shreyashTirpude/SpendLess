import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';
import '../../domain/models/transaction.dart';
import 'transaction_provider.dart';

final topMerchantsProvider = FutureProvider<List<(String, int)>>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  final merchantCount = <String, int>{};
  for (final t in txns.where((t) => !t.isCredit)) {
    merchantCount[t.merchant] = (merchantCount[t.merchant] ?? 0) + 1;
  }
  final sorted = merchantCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(5).map((e) => (e.key, e.value)).toList();
});

final monthComparisonProvider = FutureProvider<Map<String, (double, double)>>((ref) async {
  final now = DateTime.now();
  final thisMonth = await ref.watch(transactionsProvider.future);

  final lastMonthDate = DateTime(now.year, now.month - 1);
  final lastMonth = HiveService.transactions.values
      .where((t) => t.transactionDate.year == lastMonthDate.year &&
                    t.transactionDate.month == lastMonthDate.month &&
                    !t.isCredit && !t.isIgnored)
      .toList();

  final result = <String, (double, double)>{};
  final categories = {...thisMonth.map((t) => t.category), ...lastMonth.map((t) => t.category)};

  for (final cat in categories) {
    final thisSpent = thisMonth.where((t) => t.category == cat && !t.isCredit).fold(0.0, (sum, t) => sum + t.amount);
    final lastSpent = lastMonth.where((t) => t.category == cat).fold(0.0, (sum, t) => sum + t.amount);
    result[cat] = (thisSpent, lastSpent);
  }

  return result;
});

// Weekly spending pattern (0=Mon … 6=Sun) — avg spend per weekday
final weeklyPatternProvider = FutureProvider<List<double>>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  final weekdayTotals = List<double>.filled(7, 0.0);
  final weekdayCounts = List<int>.filled(7, 0);

  for (final t in txns.where((t) => !t.isCredit && !t.isIgnored)) {
    final dow = t.transactionDate.weekday - 1; // 0=Mon
    weekdayTotals[dow] += t.amount;
    weekdayCounts[dow]++;
  }

  return List.generate(7,
      (i) => weekdayCounts[i] > 0 ? weekdayTotals[i] / weekdayCounts[i] : 0.0);
});

// Projected monthly spend based on daily average
final projectedSpendProvider =
    FutureProvider<({double projected, double dailyAvg, int daysLeft})>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysPassed = now.day;
  final daysLeft = daysInMonth - daysPassed;

  final spent = txns.where((t) => !t.isCredit && !t.isIgnored).fold(0.0, (s, t) => s + t.amount);
  final dailyAvg = daysPassed > 0 ? spent / daysPassed : 0.0;
  final projected = dailyAvg * daysInMonth;

  return (projected: projected, dailyAvg: dailyAvg, daysLeft: daysLeft);
});

// No-spend streak: consecutive days with zero debit transactions (ending today or yesterday)
final noSpendStreakProvider = FutureProvider<int>((ref) async {
  final all = HiveService.transactions.values
      .where((t) => !t.isIgnored && !t.isCredit)
      .toList();

  if (all.isEmpty) return 0;

  final spendDays = <DateTime>{};
  for (final t in all) {
    final d = t.transactionDate;
    spendDays.add(DateTime(d.year, d.month, d.day));
  }

  var check = DateTime.now();
  int streak = 0;

  // If today has no spend, start counting from today
  final today = DateTime(check.year, check.month, check.day);
  if (!spendDays.contains(today)) {
    // Count backwards from yesterday
    check = check.subtract(const Duration(days: 1));
  }

  while (streak < 365) {
    final day = DateTime(check.year, check.month, check.day);
    if (spendDays.contains(day)) break;
    streak++;
    check = check.subtract(const Duration(days: 1));
  }
  return streak;
});

// Largest single debit transaction this month
final biggestSpendProvider = FutureProvider<Transaction?>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  final debits = txns.where((t) => !t.isCredit && !t.isIgnored).toList();
  if (debits.isEmpty) return null;
  return debits.reduce((a, b) => a.amount > b.amount ? a : b);
});

final insightCardsProvider = FutureProvider<List<String>>((ref) async {
  final spent = await ref.watch(totalSpentProvider.future);
  final income = await ref.watch(totalIncomeProvider.future);
  final comparison = await ref.watch(monthComparisonProvider.future);
  final projected = await ref.watch(projectedSpendProvider.future);
  final streak = await ref.watch(noSpendStreakProvider.future);
  final biggest = await ref.watch(biggestSpendProvider.future);

  final insights = <String>[];

  if (projected.dailyAvg > 0) {
    insights.add('📊 ₹${projected.dailyAvg.toStringAsFixed(0)}/day avg spend this month');
  }

  if (projected.projected > 0 && income > 0) {
    final pct = (projected.projected / income * 100).round();
    if (pct > 100) {
      insights.add('🔴 On track to overspend — projected ₹${_fmt(projected.projected)} vs ₹${_fmt(income)} income');
    } else if (pct > 85) {
      insights.add('⚠️ Projected ₹${_fmt(projected.projected)} spend (${pct}% of income) — leave some margin');
    } else {
      insights.add('✅ Projected ₹${_fmt(projected.projected)} spend — ${100 - pct}% headroom remaining');
    }
  }

  if (streak >= 2) {
    insights.add('🏆 ${streak}-day no-spend streak — incredible discipline!');
  }

  if (biggest != null) {
    insights.add('💸 Biggest transaction: ₹${_fmt(biggest.amount)} at ${biggest.merchant}');
  }

  for (final entry in comparison.entries
      .where((e) => !['Income', 'Salary', 'Refund'].contains(e.key))) {
    final (thisM, lastM) = entry.value;
    if (lastM > 0 && thisM > lastM * 1.3) {
      final pct = ((thisM - lastM) / lastM * 100).toStringAsFixed(0);
      insights.add('🔴 ${entry.key} up $pct% vs last month (₹${_fmt(thisM)} vs ₹${_fmt(lastM)})');
    } else if (lastM > 0 && thisM < lastM * 0.7) {
      final pct = ((lastM - thisM) / lastM * 100).toStringAsFixed(0);
      insights.add('✅ ${entry.key} down $pct% — great savings vs last month!');
    }
  }

  if (spent > income * 0.9 && income > 0) {
    insights.add('💡 Spending 90%+ of income — consider a savings goal');
  }

  return insights;
});

// Transactions for a specific day — used when graph point is tapped
final transactionsByDateProvider =
    FutureProvider.family<List<Transaction>, DateTime>((ref, date) async {
  return HiveService.transactions.values
      .where((t) =>
          t.transactionDate.year == date.year &&
          t.transactionDate.month == date.month &&
          t.transactionDate.day == date.day &&
          !t.isIgnored)
      .toList()
    ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
});

String _fmt(double amount) {
  if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}
