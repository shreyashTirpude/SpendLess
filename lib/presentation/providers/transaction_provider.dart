import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/transaction.dart';
import '../../data/repositories/transaction_repository_impl.dart';

final transactionRepositoryProvider = Provider((ref) {
  return TransactionRepositoryImpl();
});

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
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
  for (final t in txns.where((t) => !t.isCredit)) {
    final date = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
    dailyMap[date] = (dailyMap[date] ?? 0) + t.amount;
  }
  return dailyMap.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => a.$1.compareTo(b.$1));
});
