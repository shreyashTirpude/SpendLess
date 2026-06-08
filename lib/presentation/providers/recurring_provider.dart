import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/recurring_detector.dart';
import '../../data/local/hive_service.dart';
import 'cache_provider.dart';

final recurringItemsProvider = Provider<List<RecurringItem>>((ref) {
  ref.watch(transactionCacheProvider); // re-run when transactions change

  final all = HiveService.transactions.values
      .where((t) => !t.isIgnored)
      .toList();

  return RecurringDetector.detect(all);
});

final subscriptionsProvider = Provider<List<RecurringItem>>((ref) {
  return ref.watch(recurringItemsProvider)
      .where((r) => r.type == RecurringType.subscription)
      .toList();
});

final emisProvider = Provider<List<RecurringItem>>((ref) {
  return ref.watch(recurringItemsProvider)
      .where((r) => r.type == RecurringType.emi)
      .toList();
});

final upcomingBillsProvider = Provider<List<RecurringItem>>((ref) {
  final items = ref.watch(recurringItemsProvider);
  return RecurringDetector.upcomingIn(items, 7);
});

final monthlyRecurringTotalProvider = Provider<double>((ref) {
  return ref.watch(recurringItemsProvider)
      .fold(0.0, (sum, r) => sum + r.avgAmount);
});
