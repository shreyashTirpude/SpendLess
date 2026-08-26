import '../data/local/hive_service.dart';
import 'notification_service.dart';
import 'dart:math';

class StreakService {
  static Future<void> checkAndUpdateStreak() async {
    final settings = HiveService.settings;
    final lastChecked = settings.get('streak_last_checked') as DateTime?;
    final today = DateTime.now();

    // Only check once per day
    if (lastChecked != null &&
        lastChecked.day == today.day &&
        lastChecked.month == today.month &&
        lastChecked.year == today.year) {
      return;
    }

    // Get today's transactions
    final todayTxns = HiveService.transactions.values
        .where((t) {
          final txnDate = t.transactionDate;
          return txnDate.year == today.year &&
                 txnDate.month == today.month &&
                 txnDate.day == today.day &&
                 !t.isCredit &&
                 !t.isIgnored;
        })
        .fold(0.0, (sum, t) => sum + t.amount);

    // Get daily budget limit
    final budgets = HiveService.budgets.values
        .where((b) => b.monthYear == '${today.year}-${today.month.toString().padLeft(2, '0')}')
        .toList();

    final dailyBudgetLimit = budgets.isEmpty
        ? 0.0
        : budgets.fold(0.0, (sum, b) => sum + b.monthlyLimit) / 30;

    final underBudget = dailyBudgetLimit == 0 || todayTxns <= dailyBudgetLimit;

    int currentStreak = settings.get('budget_streak_days', defaultValue: 0) as int;
    if (underBudget) {
      currentStreak++;
    } else {
      currentStreak = 0;
    }

    final longest = settings.get('longest_streak', defaultValue: 0) as int;
    await settings.put('budget_streak_days', currentStreak);
    await settings.put('longest_streak', max(longest, currentStreak));
    await settings.put('streak_last_checked', today);

    // Send notification for milestones (respects the "Transaction alerts" toggle)
    final alertsOn = settings.get('transactionAlerts', defaultValue: true) as bool;
    if (alertsOn && currentStreak > 0 && currentStreak % 5 == 0) {
      await NotificationService().showTransactionNotif(
        title: '🔥 $currentStreak-day streak!',
        body: 'You\'ve stayed under budget for $currentStreak days in a row',
      );
    }
  }
}
