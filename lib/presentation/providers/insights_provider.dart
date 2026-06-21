import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';
import '../../domain/models/transaction.dart';
import 'transaction_provider.dart';
import 'cache_provider.dart';

final topMerchantsProvider = FutureProvider<List<(String, int)>>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  final merchantCount = <String, int>{};
  for (final t in txns.where((t) => !t.isCredit && !t.isIgnored)) {
    merchantCount[t.merchant] = (merchantCount[t.merchant] ?? 0) + 1;
  }
  final sorted = merchantCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(5).map((e) => (e.key, e.value)).toList();
});

final monthComparisonProvider = FutureProvider<Map<String, (double, double)>>((ref) async {
  ref.watch(transactionCacheProvider);
  final now = DateTime.now();
  final thisMonth = await ref.watch(transactionsProvider.future);

  final lastMonthDate = now.month == 1
      ? DateTime(now.year - 1, 12)
      : DateTime(now.year, now.month - 1);
  final lastMonth = HiveService.transactions.values
      .where((t) => t.transactionDate.year == lastMonthDate.year &&
                    t.transactionDate.month == lastMonthDate.month &&
                    !t.isCredit && !t.isIgnored)
      .toList();

  final result = <String, (double, double)>{};
  final thisDebits = thisMonth.where((t) => !t.isCredit && !t.isIgnored).toList();
  final categories = {...thisDebits.map((t) => t.category), ...lastMonth.map((t) => t.category)};

  for (final cat in categories) {
    final thisSpent = thisDebits.where((t) => t.category == cat).fold(0.0, (sum, t) => sum + t.amount);
    final lastSpent = lastMonth.where((t) => t.category == cat).fold(0.0, (sum, t) => sum + t.amount);
    result[cat] = (thisSpent, lastSpent);
  }

  return result;
});

// Day-of-week spending ranked highest to lowest
typedef DaySpendRank = ({
  String dayName,
  String dayShort,
  double total,
  int count,
  int rank,
});

final dayOfWeekRankingProvider = FutureProvider<List<DaySpendRank>>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const dayShorts = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final totals = List<double>.filled(7, 0.0);
  final counts = List<int>.filled(7, 0);

  for (final t in txns.where((t) => !t.isCredit && !t.isIgnored)) {
    final dow = t.transactionDate.weekday - 1; // 0=Mon, 6=Sun
    totals[dow] += t.amount;
    counts[dow]++;
  }

  final items = List.generate(7, (i) => (
    dayName: dayNames[i],
    dayShort: dayShorts[i],
    total: totals[i],
    count: counts[i],
  ))..sort((a, b) => b.total.compareTo(a.total));

  final result = <DaySpendRank>[];
  for (int i = 0; i < items.length; i++) {
    result.add((
      dayName: items[i].dayName,
      dayShort: items[i].dayShort,
      total: items[i].total,
      count: items[i].count,
      rank: i + 1,
    ));
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
  ref.watch(transactionCacheProvider);
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

  // Count backwards from today — if today has no spend, it counts too
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
  final biggest = await ref.watch(biggestSpendProvider.future);
  final savings = await ref.watch(savingsRateProvider.future);
  final health = await ref.watch(financialHealthProvider.future);
  final anomalies = await ref.watch(spendingAnomaliesProvider.future);

  final insights = <String>[];

  // Financial health score (headline)
  if (income > 0) {
    final emoji = health.score >= 80
        ? '🟢'
        : health.score >= 60
            ? '🟡'
            : health.score >= 40
                ? '🟠'
                : '🔴';
    insights.add('$emoji Financial health: ${health.score}/100 (${health.label}) — ${health.tip}');
  }

  // Savings rate
  if (savings.income > 0) {
    final pct = (savings.rate * 100).round();
    if (savings.rate >= 0.2) {
      insights.add('💚 Saving $pct% of income (₹${_fmt(savings.saved)}) — above the 20% target!');
    } else if (savings.rate >= 0) {
      insights.add('💰 Saving $pct% of income — aim for 20% (₹${_fmt(savings.income * 0.2)})');
    } else {
      insights.add('🔴 Spending more than you earn this month by ₹${_fmt(-savings.saved)}');
    }
  }

  // Anomaly alerts (category spikes vs 3-month average)
  for (final a in anomalies.take(2)) {
    final pct = (a.pctOver * 100).round();
    insights.add('📈 ${a.category} is $pct% above your 3-month average (₹${_fmt(a.current)} vs ₹${_fmt(a.avg)})');
  }

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

  // streak is shown in _StreakCard widget already — skip here to avoid duplication

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

// ── Advanced analytics ──────────────────────────────────────────────────────

/// Current-month savings rate = (income − spend) / income.
final savingsRateProvider =
    FutureProvider<({double rate, double saved, double income, double spent})>(
        (ref) async {
  final spent = await ref.watch(totalSpentProvider.future);
  final income = await ref.watch(totalIncomeProvider.future);
  final saved = income - spent;
  final rate = income > 0 ? (saved / income) : 0.0;
  return (rate: rate, saved: saved, income: income, spent: spent);
});

/// Category spend anomalies — this month's spend vs the trailing 3-month
/// average for that category. Surfaces categories spiking >50% above normal.
typedef Anomaly = ({String category, double current, double avg, double pctOver});

final spendingAnomaliesProvider = FutureProvider<List<Anomaly>>((ref) async {
  ref.watch(transactionCacheProvider);
  final now = DateTime.now();
  final all = HiveService.transactions.values
      .where((t) => !t.isCredit && !t.isIgnored)
      .toList();

  // Per-category: this month total + prior 3 months totals.
  final thisMonth = <String, double>{};
  final priorMonths = <String, List<double>>{};

  for (var m = 1; m <= 3; m++) {
    final d = DateTime(now.year, now.month - m);
    for (final t in all.where((t) =>
        t.transactionDate.year == d.year &&
        t.transactionDate.month == d.month)) {
      priorMonths.putIfAbsent(t.category, () => [0, 0, 0]);
      priorMonths[t.category]![m - 1] += t.amount;
    }
  }
  for (final t in all.where((t) =>
      t.transactionDate.year == now.year &&
      t.transactionDate.month == now.month)) {
    thisMonth[t.category] = (thisMonth[t.category] ?? 0) + t.amount;
  }

  const skip = {'Income', 'Salary', 'Refund', 'Interest', 'Income Transfer'};
  final out = <Anomaly>[];
  for (final entry in thisMonth.entries) {
    if (skip.contains(entry.key)) continue;
    final prior = priorMonths[entry.key];
    if (prior == null) continue;
    final months = prior.where((v) => v > 0).toList();
    if (months.isEmpty) continue;
    final avg = months.reduce((a, b) => a + b) / months.length;
    if (avg <= 0) continue;
    final pctOver = (entry.value - avg) / avg;
    if (pctOver >= 0.5 && entry.value > avg + 200) {
      out.add((category: entry.key, current: entry.value, avg: avg, pctOver: pctOver));
    }
  }
  out.sort((a, b) => b.pctOver.compareTo(a.pctOver));
  return out;
});

/// Composite financial-health score (0–100): savings rate (50%), spend-to-income
/// ratio (30%), and spend consistency / no-overspend (20%).
final financialHealthProvider =
    FutureProvider<({int score, String label, String tip})>((ref) async {
  final sr = await ref.watch(savingsRateProvider.future);
  final projected = await ref.watch(projectedSpendProvider.future);

  double score = 0;
  // Savings rate component (target ≥20% → full marks)
  score += (sr.rate / 0.20).clamp(0.0, 1.0) * 50;
  // Spend-to-income (lower is better; ≤0.7 → full marks)
  if (sr.income > 0) {
    final ratio = sr.spent / sr.income;
    score += (1 - ((ratio - 0.7) / 0.3)).clamp(0.0, 1.0) * 30;
  }
  // Projection headroom (projected ≤ income → full marks)
  if (sr.income > 0 && projected.projected > 0) {
    final p = projected.projected / sr.income;
    score += (1 - ((p - 0.85) / 0.15)).clamp(0.0, 1.0) * 20;
  }

  final s = score.round().clamp(0, 100);
  final (label, tip) = switch (s) {
    >= 80 => ('Excellent', 'You\'re saving well and spending in control. Keep it up!'),
    >= 60 => ('Good', 'Solid habits — trim one recurring expense to reach Excellent.'),
    >= 40 => ('Fair', 'Set a savings goal and watch your top category.'),
    _ => ('Needs work', 'Spending is high vs income — review subscriptions & dining.'),
  };
  return (score: s, label: label, tip: tip);
});

String _fmt(double amount) {
  if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}
