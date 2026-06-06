import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';
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

final insightCardsProvider = FutureProvider<List<String>>((ref) async {
  final spent = await ref.watch(totalSpentProvider.future);
  final income = await ref.watch(totalIncomeProvider.future);
  final comparison = await ref.watch(monthComparisonProvider.future);

  final insights = <String>[];

  if (income > 0) {
    final avg = spent / 30;
    insights.add('📊 You spent ₹${avg.toStringAsFixed(0)}/day on average');
  }

  for (final entry in comparison.entries) {
    final (thisMonth, lastMonth) = entry.value;
    if (lastMonth > 0 && thisMonth > lastMonth) {
      final pct = ((thisMonth - lastMonth) / lastMonth * 100).toStringAsFixed(0);
      insights.add('🔴 ${entry.key} spending up $pct% vs last month');
    }
  }

  if (spent > income * 0.9 && income > 0) {
    insights.add('💡 You\'re spending 90%+ of income - consider saving more');
  }

  return insights;
});
