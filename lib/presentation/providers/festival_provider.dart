import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/festival_calendar.dart';
import '../../data/local/hive_service.dart';
import 'transaction_provider.dart';

// ── Result model ───────────────────────────────────────────────────────────────

class FestivalPlanResult {
  final Festival festival;
  final int daysUntilFestival;
  final double lastYearSpend;
  final double estimatedBudget;
  final double dailySavingsNeeded;
  final List<String> recommendedCategories;

  const FestivalPlanResult({
    required this.festival,
    required this.daysUntilFestival,
    required this.lastYearSpend,
    required this.estimatedBudget,
    required this.dailySavingsNeeded,
    required this.recommendedCategories,
  });
}

// ── Upcoming festival provider ─────────────────────────────────────────────────

final upcomingFestivalProvider = FutureProvider<FestivalPlanResult?>((ref) async {
  final txns = await ref.watch(transactionsProvider.future);
  final festival = FestivalCalendar.upcomingFestival();
  if (festival == null) return null;

  final daysUntil = festival.daysUntilNext.clamp(1, 9999);

  // ── Last-year spend during the same festival window (±7 days) ──────────────
  final festDate2025 = festival.date2025;
  final windowStart = festDate2025.subtract(const Duration(days: 7));
  final windowEnd = festDate2025.add(const Duration(days: 7));

  // Look in all transactions (not just this month) for the past year window.
  // getByMonth is synchronous in TransactionRepositoryImpl.
  final repo = ref.watch(transactionRepositoryProvider);

  double lastYearSpend = 0.0;
  // Walk through each month in the window (may span 1–2 months).
  var cursor = DateTime(windowStart.year, windowStart.month, 1);
  final windowEndMonth = DateTime(windowEnd.year, windowEnd.month, 1);
  while (!cursor.isAfter(windowEndMonth)) {
    final monthTxns = repo.getByMonth(cursor.year, cursor.month);
    for (final t in monthTxns) {
      if (!t.isCredit &&
          !t.isIgnored &&
          festival.spendCategories.contains(t.category) &&
          !t.transactionDate.isBefore(windowStart) &&
          !t.transactionDate.isAfter(windowEnd)) {
        lastYearSpend += t.amount;
      }
    }
    // advance one month
    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }

  // ── Average monthly spend (from current month txns) ────────────────────────
  final totalSpent = txns
      .where((t) => !t.isCredit && !t.isIgnored)
      .fold<double>(0.0, (s, t) => s + t.amount);
  final avgMonthlySpend = totalSpent > 0 ? totalSpent : 15000.0; // sane fallback

  // ── Budget estimation ──────────────────────────────────────────────────────
  final estimatedBudget = lastYearSpend > 0
      ? lastYearSpend
      : festival.avgSpendMultiplier * avgMonthlySpend;

  // ── Custom user budget (overrides estimate if set) ─────────────────────────
  final customBudget = (HiveService.settings.get(
    'festivalBudget_${festival.name}',
    defaultValue: 0.0,
  ) as num).toDouble();

  final effectiveBudget = customBudget > 0 ? customBudget : estimatedBudget;
  final dailySavings = daysUntil > 0 ? effectiveBudget / daysUntil : 0.0;

  return FestivalPlanResult(
    festival: festival,
    daysUntilFestival: daysUntil,
    lastYearSpend: lastYearSpend,
    estimatedBudget: effectiveBudget,
    dailySavingsNeeded: dailySavings,
    recommendedCategories: festival.spendCategories,
  );
});

// ── Per-festival custom budget (StateProvider backed by Hive) ──────────────────

class FestivalBudgetNotifier extends StateNotifier<double?> {
  final String festivalName;

  FestivalBudgetNotifier(this.festivalName) : super(_load(festivalName));

  static double? _load(String name) {
    final raw = HiveService.settings.get(
      'festivalBudget_$name',
      defaultValue: 0.0,
    ) as num;
    final v = raw.toDouble();
    return v > 0 ? v : null;
  }

  Future<void> setBudget(double amount) async {
    await HiveService.settings.put('festivalBudget_$festivalName', amount);
    state = amount > 0 ? amount : null;
  }

  Future<void> clearBudget() async {
    await HiveService.settings.put('festivalBudget_$festivalName', 0.0);
    state = null;
  }
}

final festivalBudgetProvider =
    StateNotifierProvider.family<FestivalBudgetNotifier, double?, String>(
  (ref, festivalName) => FestivalBudgetNotifier(festivalName),
);

// ── Selected festival index (for the timeline chip selection) ─────────────────

final selectedFestivalIndexProvider = StateProvider<int>((ref) => 0);
