import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cache_provider.dart';
import 'transaction_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum SavingCategory { food, subscription, habit, general }

class SavingOpportunity {
  final String title;
  final String description;
  final double monthlySaving;
  final double annualSaving;
  final String icon;
  final SavingCategory category;
  final String actionLabel;

  const SavingOpportunity({
    required this.title,
    required this.description,
    required this.monthlySaving,
    required this.icon,
    required this.category,
    required this.actionLabel,
  }) : annualSaving = monthlySaving * 12;
}

// ─── Helper: keyword match ────────────────────────────────────────────────────

bool _kw(String text, List<String> keywords) =>
    keywords.any((k) => text.toLowerCase().contains(k));

// ─── Provider ─────────────────────────────────────────────────────────────────

final microSavingsProvider =
    FutureProvider<List<SavingOpportunity>>((ref) async {
  ref.watch(transactionCacheProvider);
  final txns = await ref.watch(transactionsProvider.future);

  final now = DateTime.now();
  final expenses = txns.where((t) => !t.isCredit && !t.isIgnored).toList();

  if (expenses.isEmpty) return [];

  final totalSpent =
      expenses.fold<double>(0, (s, t) => s + t.amount);

  final opportunities = <SavingOpportunity>[];

  // ── 1. Food delivery reduction ──────────────────────────────────────────────
  final foodKeywords = ['swiggy', 'zomato', 'food', 'dining', 'restaurant',
      'blinkit', 'zepto', 'dunzo', 'pizza', 'burger', 'cafe', 'eat'];
  final foodTxns =
      expenses.where((t) => _kw(t.merchant, foodKeywords) || _kw(t.category, foodKeywords)).toList();
  final foodTotal = foodTxns.fold<double>(0, (s, t) => s + t.amount);

  if (totalSpent > 0 && foodTotal / totalSpent > 0.15) {
    final currentOrders = foodTxns.length;
    final targetOrders = (currentOrders * 0.7).round(); // 30% cut
    final saving = foodTotal * 0.30;
    opportunities.add(SavingOpportunity(
      title: 'Reduce Food Delivery Orders',
      description:
          'You\'re ordering food $currentOrders times/month. Cutting to $targetOrders orders '
          'saves ₹${saving.toStringAsFixed(0)}/month — cook at home on weekdays.',
      monthlySaving: saving,
      icon: '🛵',
      category: SavingCategory.food,
      actionLabel: 'Set Reminder',
    ));
  }

  // ── 2. Subscription audit ───────────────────────────────────────────────────
  final subKeywords = ['netflix', 'spotify', 'prime', 'hotstar', 'zee5', 'sony',
      'youtube', 'apple', 'adobe', 'notion', 'gym', 'fitpass', 'cult'];
  final subTxns = expenses.where((t) => _kw(t.merchant, subKeywords)).toList();

  for (final sub in subTxns) {
    // Check if this merchant had any transaction in the last 30 days
    final recentUse = expenses.where((t) =>
        t.merchant == sub.merchant &&
        now.difference(t.transactionDate).inDays <= 30).toList();

    if (recentUse.length == 1 && sub.amount >= 200) {
      // Only charged, not really used (just the billing itself)
      opportunities.add(SavingOpportunity(
        title: 'Unused Subscription: ${sub.merchant}',
        description:
            'You\'re being charged ₹${sub.amount.toStringAsFixed(0)}/month for ${sub.merchant} '
            'but show low engagement. Cancelling saves ₹${sub.amount.toStringAsFixed(0)}/month.',
        monthlySaving: sub.amount,
        icon: '📺',
        category: SavingCategory.subscription,
        actionLabel: 'Cancel Sub',
      ));
    }
  }

  // ── 3. Weekend spend spike ──────────────────────────────────────────────────
  final weekdaySpend = expenses
      .where((t) =>
          t.transactionDate.weekday >= 1 && t.transactionDate.weekday <= 5)
      .fold<double>(0, (s, t) => s + t.amount);
  final weekendSpend = expenses
      .where((t) =>
          t.transactionDate.weekday == 6 || t.transactionDate.weekday == 7)
      .fold<double>(0, (s, t) => s + t.amount);

  final weekdayDays = expenses
      .map((t) => t.transactionDate.weekday)
      .where((d) => d >= 1 && d <= 5)
      .toSet()
      .length;
  final weekendDays = expenses
      .map((t) => t.transactionDate.weekday)
      .where((d) => d == 6 || d == 7)
      .toSet()
      .length;

  final avgWeekday = weekdayDays > 0 ? weekdaySpend / weekdayDays : 0.0;
  final avgWeekend = weekendDays > 0 ? weekendSpend / weekendDays : 0.0;

  if (avgWeekday > 0 && avgWeekend > avgWeekday * 1.8) {
    final multiplier = (avgWeekend / avgWeekday);
    final weekendSaving = weekendSpend * 0.20;
    opportunities.add(SavingOpportunity(
      title: 'Weekend Spending Spike',
      description:
          'You spend ${multiplier.toStringAsFixed(1)}× more on weekends than weekdays. '
          'Reducing weekend spend by 20% saves ₹${weekendSaving.toStringAsFixed(0)}/month.',
      monthlySaving: weekendSaving,
      icon: '🎉',
      category: SavingCategory.habit,
      actionLabel: 'Try Challenge',
    ));
  }

  // ── 4. Late-night orders ────────────────────────────────────────────────────
  final lateNightTxns = expenses.where((t) {
    final hour = t.transactionDate.hour;
    return (hour >= 23 || hour <= 2) &&
        (_kw(t.merchant, foodKeywords) || _kw(t.category, foodKeywords));
  }).toList();

  if (lateNightTxns.isNotEmpty) {
    final lateTotal =
        lateNightTxns.fold<double>(0, (s, t) => s + t.amount);
    opportunities.add(SavingOpportunity(
      title: 'Late-Night Order Premium',
      description:
          'You spent ₹${lateTotal.toStringAsFixed(0)} on late-night food orders (11 PM–2 AM). '
          'These cost ~30% more in surge pricing. Switching saves ₹${(lateTotal * 0.30).toStringAsFixed(0)}/month.',
      monthlySaving: lateTotal * 0.30,
      icon: '🌙',
      category: SavingCategory.food,
      actionLabel: 'Set Reminder',
    ));
  }

  // ── 5. Round-number daily saving challenge ─────────────────────────────────
  if (expenses.isNotEmpty) {
    final daysWithData = expenses.map((t) => DateTime(
          t.transactionDate.year,
          t.transactionDate.month,
          t.transactionDate.day,
        )).toSet().length;

    if (daysWithData >= 5) {
      final dailyAvg = totalSpent / daysWithData;
      // Suggest saving 10% of daily avg rounded to nearest 10
      final savePerDay = ((dailyAvg * 0.10) / 10).round() * 10.0;
      if (savePerDay >= 10) {
        final monthly = savePerDay * 30;
        opportunities.add(SavingOpportunity(
          title: '₹${savePerDay.toStringAsFixed(0)}/Day Saving Challenge',
          description:
              'Based on your daily average of ₹${dailyAvg.toStringAsFixed(0)}, '
              'setting aside ₹${savePerDay.toStringAsFixed(0)}/day adds up to '
              '₹${monthly.toStringAsFixed(0)} extra by end of month.',
          monthlySaving: monthly,
          icon: '🎯',
          category: SavingCategory.general,
          actionLabel: 'Start Challenge',
        ));
      }
    }
  }

  // Sort by monthly saving — biggest impact first
  opportunities.sort((a, b) => b.monthlySaving.compareTo(a.monthlySaving));
  return opportunities;
});
