import '../../domain/models/transaction.dart';
import 'merchant_normalizer.dart';

class RecurringItem {
  final String merchant;
  final String canonicalMerchant;
  final double avgAmount;
  final int typicalDayOfMonth;
  final RecurringType type;
  final List<Transaction> history;
  final DateTime? nextExpected;

  const RecurringItem({
    required this.merchant,
    required this.canonicalMerchant,
    required this.avgAmount,
    required this.typicalDayOfMonth,
    required this.type,
    required this.history,
    this.nextExpected,
  });
}

enum RecurringType { subscription, emi, utility, recurring }

class RecurringDetector {
  static const _subscriptionMerchants = {
    'Netflix', 'Spotify', 'Hotstar', 'YouTube Premium', 'Amazon Prime',
    'ZEE5', 'SonyLIV', 'MX Player', 'JioCinema', 'Apple', 'CRED',
    'Coursera', 'Udemy', 'Unacademy',
  };

  static const _emiKeywords = ['emi', 'loan', 'equated', 'installment', 'home loan', 'car loan'];
  static const _utilityMerchants = {'Jio', 'Airtel', 'BSNL', 'Vi', 'BESCOM', 'Tata Play', 'Dish TV'};

  static List<RecurringItem> detect(List<Transaction> allTxns) {
    final debits = allTxns.where((t) => !t.isCredit && !t.isIgnored).toList();

    // Group by canonical merchant name
    final byMerchant = <String, List<Transaction>>{};
    for (final t in debits) {
      final canonical = MerchantNormalizer.normalize(t.merchant);
      byMerchant.putIfAbsent(canonical, () => []).add(t);
    }

    final results = <RecurringItem>[];

    for (final entry in byMerchant.entries) {
      final merchant = entry.key;
      final txns = entry.value..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

      if (txns.length < 2) continue;

      // Check if amounts are consistent (within ±10%)
      final amounts = txns.map((t) => t.amount).toList();
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      final allConsistent = amounts.every((a) => (a - avgAmount).abs() / avgAmount <= 0.10);
      if (!allConsistent && txns.length < 3) continue;

      // Check if intervals are monthly (25–35 days)
      var monthlyCount = 0;
      for (var i = 1; i < txns.length; i++) {
        final diff = txns[i].transactionDate.difference(txns[i - 1].transactionDate).inDays;
        if (diff >= 25 && diff <= 35) monthlyCount++;
      }

      final isMonthly = monthlyCount >= (txns.length - 1) * 0.6; // 60%+ intervals are monthly
      if (!isMonthly && txns.length < 3) continue;

      // Determine type
      final type = _classifyType(merchant, txns.last.merchant);
      final avgDay = (txns.map((t) => t.transactionDate.day).reduce((a, b) => a + b) / txns.length).round();

      // Project next date
      final lastTxn = txns.last.transactionDate;
      final nextDate = DateTime(lastTxn.year, lastTxn.month + 1, avgDay.clamp(1, 28));

      results.add(RecurringItem(
        merchant: txns.last.merchant,
        canonicalMerchant: merchant,
        avgAmount: avgAmount,
        typicalDayOfMonth: avgDay,
        type: type,
        history: txns,
        nextExpected: nextDate,
      ));
    }

    results.sort((a, b) => b.avgAmount.compareTo(a.avgAmount));
    return results;
  }

  static RecurringType _classifyType(String canonical, String raw) {
    if (_subscriptionMerchants.contains(canonical)) return RecurringType.subscription;
    final lower = raw.toLowerCase();
    if (_emiKeywords.any((k) => lower.contains(k))) return RecurringType.emi;
    if (_utilityMerchants.contains(canonical)) return RecurringType.utility;
    return RecurringType.recurring;
  }

  // Bills due within the next N days
  static List<RecurringItem> upcomingIn(List<RecurringItem> items, int days) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    return items.where((item) {
      final next = item.nextExpected;
      return next != null && next.isAfter(now) && next.isBefore(cutoff);
    }).toList()
      ..sort((a, b) => a.nextExpected!.compareTo(b.nextExpected!));
  }
}
