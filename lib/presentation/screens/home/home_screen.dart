import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/insights_provider.dart';
import '../../providers/festival_provider.dart';
import '../../../core/utils/recurring_detector.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_engine.dart';
import '../../../domain/models/transaction.dart';
import '../../widgets/prediction_summary_card.dart';
import 'category_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  void _showIncomeDetail(BuildContext context, List<Transaction> allTxns) {
    final credits = allTxns.where((t) => t.isCredit && !t.isIgnored).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetailSheet(
        title: 'Income This Month',
        subtitle: '${credits.length} credits',
        transactions: credits,
        accentColor: AppColors.success,
      ),
    );
  }

  void _showSpentDetail(BuildContext context, List<Transaction> allTxns) {
    final debits = allTxns.where((t) => !t.isCredit && !t.isIgnored).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetailSheet(
        title: 'Expenses This Month',
        subtitle: '${debits.length} transactions',
        transactions: debits,
        accentColor: AppColors.error,
      ),
    );
  }

  void _showSetGoalDialog(BuildContext context, WidgetRef ref, double current) {
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (innerCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(innerCtx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: context.cardBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Set Savings Goal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('How much do you want to save this month?',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: 'e.g. 5000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final amt = double.tryParse(ctrl.text.trim()) ?? 0.0;
                    ref.read(savingsGoalProvider.notifier).setGoal(amt);
                    Navigator.pop(context);
                  },
                  child: const Text('Save Goal'),
                ),
              ),
              if (current > 0) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      ref.read(savingsGoalProvider.notifier).setGoal(0.0);
                      Navigator.pop(context);
                    },
                    child: Text('Remove Goal',
                        style: TextStyle(color: context.textMuted)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(homeStatsProvider);
    final healthAsync = ref.watch(healthScoreProvider);
    final txnsAsync = ref.watch(transactionsProvider);
    final savingsGoal = ref.watch(savingsGoalProvider);
    final upcomingBills = ref.watch(upcomingBillsProvider);
    final streakAsync = ref.watch(noSpendStreakProvider);
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          // Ambient glow — top-left purple, bottom-right blue
          if (context.isDark) ...[
            Positioned(
              top: -120,
              left: -80,
              child: IgnorePointer(
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gradientStart.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: -100,
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gradientEnd.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading data')),
        data: (stats) => CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: context.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          monthLabel,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showNotifications(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.cardBorderColor),
                        ),
                        child: Icon(Icons.notifications_none_rounded,
                            color: context.textSecondary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Privacy trust strip
            SliverToBoxAdapter(
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  children: const [
                    _TrustChip(icon: '🔒', label: 'AES-256 Encrypted'),
                    SizedBox(width: 8),
                    _TrustChip(icon: '📵', label: 'No Cloud Upload'),
                    SizedBox(width: 8),
                    _TrustChip(icon: '🚫', label: 'No Raw SMS Stored'),
                    SizedBox(width: 8),
                    _TrustChip(icon: '📍', label: 'Local Device Only'),
                  ],
                ),
              ),
            ),

            // Balance Hero Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _BalanceCard(
                  totalSpent: stats.totalSpent,
                  totalIncome: stats.totalIncome,
                  safeToSpend: stats.safeToSpend,
                  daysRemaining: stats.daysRemainingInCycle,
                  cycleEnd: stats.cycleEnd,
                  onIncomeTap: () =>
                      _showIncomeDetail(context, txnsAsync.valueOrNull ?? []),
                  onSpentTap: () =>
                      _showSpentDetail(context, txnsAsync.valueOrNull ?? []),
                ),
              ),
            ),

            // Achievement / Streak Banner
            SliverToBoxAdapter(
              child: streakAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (streak) => statsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (stats) => _AchievementBanner(
                    streak: streak,
                    totalSpent: stats.totalSpent,
                    totalIncome: stats.totalIncome,
                  ),
                ),
              ),
            ),

            // Financial Health Score
            SliverToBoxAdapter(
              child: healthAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (health) => _HealthScoreCard(data: health),
              ),
            ),

            // Savings Goal
            SliverToBoxAdapter(
              child: statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => _SavingsGoalCard(
                  goal: savingsGoal,
                  currentSavings: (stats.totalIncome - stats.totalSpent).clamp(0.0, double.infinity),
                  onSetGoal: () => _showSetGoalDialog(context, ref, savingsGoal),
                ),
              ),
            ),

            // Salary run-out / daily safe-to-spend prediction
            const SliverToBoxAdapter(child: PredictionSummaryCard()),

            // AI Money Coach — offline assistant, Pro-gated on its own screen
            const SliverToBoxAdapter(child: _AiCoachCard()),

            // Festival planner banner (shows when festival is within 60 days)
            const SliverToBoxAdapter(child: _FestivalBanner()),

            // Upcoming Bills
            if (upcomingBills.isNotEmpty)
              SliverToBoxAdapter(
                child: _UpcomingBillsCard(bills: upcomingBills),
              ),

            // Spending Breakdown
            if (stats.categoryTotals.isNotEmpty)
              SliverToBoxAdapter(
                child: _SpendingBreakdownCard(totals: stats.categoryTotals),
              ),

            // Category Grid
            if (stats.categoryTotals.isNotEmpty)
              SliverToBoxAdapter(
                child: _CategoryGrid(totals: stats.categoryTotals),
              ),

            // Top Payees
            if (stats.topPayees.isNotEmpty)
              SliverToBoxAdapter(
                child: _TopPayeesCard(payees: stats.topPayees),
              ),

            // Recent Transactions
            if (stats.recentTransactions.isNotEmpty)
              SliverToBoxAdapter(
                child: _RecentTransactionsCard(
                    transactions: stats.recentTransactions),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    ],
  ),
);
  }
}

// ── Festival Banner ───────────────────────────────────────────────────────────

class _FestivalBanner extends ConsumerWidget {
  const _FestivalBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final festivalAsync = ref.watch(upcomingFestivalProvider);
    return festivalAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (result == null) return const SizedBox.shrink();
        final festival = result.festival;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: GestureDetector(
            onTap: () => context.push('/festival'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withValues(alpha: 0.85),
                    const Color(0xFFFF9500).withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(festival.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          festival.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'In ${result.daysUntilFestival} days · Plan ₹${result.estimatedBudget.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Privacy Trust Chip ────────────────────────────────────────────────────────

/// Gradient entry card for the AI Money Coach (route /chat). The chat screen
/// runs fully offline (rule-based templates; optional local Ollama) and gates
/// itself behind the Pro tier, so this card only navigates.
class _AiCoachCard extends StatelessWidget {
  const _AiCoachCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () => context.push('/chat'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.gradientStart,
                AppColors.gradientMid,
                AppColors.gradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientMid.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Center(child: Text('✨', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask your AI Money Coach',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Why did I overspend? How much can I save?',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final String icon;
  final String label;
  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notifications Bottom Sheet ────────────────────────────────────────────────

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetData = ref.watch(allCategoriesSpendingProvider).valueOrNull ?? [];
    final recentTxns = ref.watch(transactionsProvider).valueOrNull ?? [];

    final overBudget = budgetData
        .where((b) => b.limit != null && b.spent > b.limit!)
        .toList();
    final nearBudget = budgetData
        .where((b) => b.limit != null && b.spent >= b.limit! * 0.8 && b.spent <= b.limit!)
        .toList();
    final todayTxns = recentTxns.where((t) {
      final now = DateTime.now();
      return t.transactionDate.year == now.year &&
          t.transactionDate.month == now.month &&
          t.transactionDate.day == now.day;
    }).toList();

    final hasAlerts = overBudget.isNotEmpty || nearBudget.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cardBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Notifications', style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  if (hasAlerts)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${overBudget.length + nearBudget.length} alerts',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (!hasAlerts && todayTxns.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Text('✅', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              "You're all caught up!",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Over-budget alerts
                  ...overBudget.map((b) => _NotifCard(
                        icon: '🔴',
                        title: '${b.category} budget exceeded',
                        body:
                            'Spent ₹${_fmt(b.spent)} of ₹${_fmt(b.limit!)} limit (${((b.spent / b.limit!) * 100).round()}%)',
                        isAlert: true,
                      )),

                  // Near-budget alerts
                  ...nearBudget.map((b) => _NotifCard(
                        icon: '⚠️',
                        title: '${b.category} nearing limit',
                        body:
                            'Spent ₹${_fmt(b.spent)} of ₹${_fmt(b.limit!)} (${((b.spent / b.limit!) * 100).round()}%)',
                        isAlert: true,
                      )),

                  // Today's activity
                  if (todayTxns.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 10),
                      child: Text(
                        "Today's Activity",
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: context.textMuted),
                      ),
                    ),
                    ...todayTxns.take(5).map((t) => _NotifCard(
                          icon: CategoryEngine.getCategoryIcon(t.category),
                          title: t.merchant,
                          body:
                              '${t.isCredit ? 'Received' : 'Spent'} ₹${_fmt(t.amount)} · ${t.category}',
                          isAlert: false,
                        )),
                  ],

                  // Tips
                  const _NotifCard(
                    icon: '💡',
                    title: 'Tip: Long-press any transaction to recategorize',
                    body: 'Accurate categories improve your insights.',
                    isAlert: false,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final String icon, title, body;
  final bool isAlert;
  const _NotifCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.isAlert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAlert
            ? AppColors.error.withValues(alpha: 0.07)
            : context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlert
              ? AppColors.error.withValues(alpha: 0.3)
              : context.cardBorderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: isAlert ? AppColors.error : null)),
                const SizedBox(height: 2),
                Text(body,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction Detail Bottom Sheet ──────────────────────────────────────────

class _TransactionDetailSheet extends StatelessWidget {
  final String title, subtitle;
  final List<Transaction> transactions;
  final Color accentColor;
  const _TransactionDetailSheet({
    required this.title,
    required this.subtitle,
    required this.transactions,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = transactions.fold(0.0, (s, t) => s + t.amount);

    // Group by merchant for contact-like summary
    final byMerchant = <String, ({double total, int count, String category})>{};
    for (final t in transactions) {
      final existing = byMerchant[t.merchant];
      byMerchant[t.merchant] = (
        total: (existing?.total ?? 0) + t.amount,
        count: (existing?.count ?? 0) + 1,
        category: t.category,
      );
    }
    final sortedMerchants = byMerchant.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cardBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: context.textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '₹${_fmt(total)}',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Contact-style breakdown
                  if (sortedMerchants.isNotEmpty) ...[
                    Text(
                      'By Contact / Merchant',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: context.textMuted),
                    ),
                    const SizedBox(height: 10),
                    ...sortedMerchants.take(8).map((e) {
                      final color = CategoryEngine.getCategoryFlutterColor(e.value.category);
                      final icon = CategoryEngine.getCategoryIconData(e.value.category);
                      final share = total > 0 ? e.value.total / total : 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.cardBorderColor),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                      child: Icon(icon, size: 17, color: color)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.key,
                                          style: Theme.of(context).textTheme.labelMedium,
                                          overflow: TextOverflow.ellipsis),
                                      Text(
                                        '${e.value.count} transaction${e.value.count != 1 ? 's' : ''} · ${e.value.category}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: context.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${_fmt(e.value.total)}',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: share.clamp(0.0, 1.0),
                                minHeight: 3,
                                backgroundColor: context.cardBorderColor,
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Full transaction list
                  Text(
                    'All Transactions',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: context.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.cardBorderColor),
                    ),
                    child: Column(
                      children: transactions.asMap().entries.map((entry) {
                        final i = entry.key;
                        final t = entry.value;
                        final color = CategoryEngine.getCategoryFlutterColor(t.category);
                        final icon = CategoryEngine.getCategoryIconData(t.category);
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                        child: Icon(icon, size: 16, color: color)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.merchant,
                                            style:
                                                Theme.of(context).textTheme.labelMedium,
                                            overflow: TextOverflow.ellipsis),
                                        Text(
                                          DateFormat('d MMM, h:mm a')
                                              .format(t.transactionDate),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: context.textMuted,
                                                  fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        t.isCredit
                                            ? Icons.arrow_downward_rounded
                                            : Icons.arrow_upward_rounded,
                                        size: 10,
                                        color: t.isCredit ? AppColors.success : AppColors.error,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '₹${_fmt(t.amount)}',
                                        style: TextStyle(
                                          color: t.isCredit ? AppColors.success : AppColors.error,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (i < transactions.length - 1)
                              Divider(
                                  height: 1,
                                  color: context.cardBorderColor,
                                  indent: 60),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Balance Hero Card ──────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final double totalSpent;
  final double totalIncome;
  final double safeToSpend;
  final int daysRemaining;
  final DateTime cycleEnd;
  final VoidCallback onIncomeTap;
  final VoidCallback onSpentTap;
  const _BalanceCard({
    required this.totalSpent,
    required this.totalIncome,
    required this.safeToSpend,
    required this.daysRemaining,
    required this.cycleEnd,
    required this.onIncomeTap,
    required this.onSpentTap,
  });

  @override
  Widget build(BuildContext context) {
    final net = totalIncome - totalSpent;
    final incomeTracked = totalIncome > 0;
    final hasSavings = incomeTracked && net > 0;
    final isOverIncome = incomeTracked && net < 0;
    final spentRatio =
        incomeTracked ? (totalSpent / totalIncome).clamp(0.0, 1.0) : 0.0;
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // Require at least 5 days of data to avoid wild early-month projections
    final projectedMonthly = dayOfMonth >= 5 && totalSpent > 0
        ? (totalSpent / dayOfMonth) * daysInMonth
        : 0.0;
    final arcColor = spentRatio > 0.9
        ? Colors.redAccent.shade100
        : spentRatio > 0.7
            ? Colors.orange.shade300
            : Colors.greenAccent.shade200;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color(0xFF6366F1),
            Color(0xFF3B82F6),
          ],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.45),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.gradientEnd.withValues(alpha: 0.15),
            blurRadius: 60,
            spreadRadius: 0,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spent This Month',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: totalSpent),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        '₹${_fmt(v)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (hasSavings) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.greenAccent.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          '💚 Saved ₹${_fmt(net)} this month',
                          style: TextStyle(
                              color: Colors.greenAccent.shade200,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ] else if (isOverIncome) ...[
                      const SizedBox(height: 4),
                      Text(
                        '⚠️ Spent ₹${_fmt(net.abs())} more than income this month',
                        style: TextStyle(color: Colors.orange.shade200, fontSize: 11),
                      ),
                    ] else if (projectedMonthly > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'On pace for ₹${_fmt(projectedMonthly)} this month',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              // Spending arc ring — shown whenever any income is tracked
              if (incomeTracked)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: spentRatio),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: v,
                            strokeWidth: 5,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(arcColor),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(v * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            const Text(
                              'spent',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (incomeTracked && safeToSpend > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Safe to Spend Today',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: safeToSpend),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Text(
                          '₹${_fmt(v)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$daysRemaining days left',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cycle ends ${DateFormat('d MMM').format(cycleEnd)}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (incomeTracked)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onIncomeTap,
                    child: _BalancePill(
                      label: 'Income',
                      icon: Icons.arrow_downward_rounded,
                      color: Colors.greenAccent.shade200,
                      value: totalIncome,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onSpentTap,
                    child: _BalancePill(
                      label: 'Spent',
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.redAccent.shade100,
                      value: totalSpent,
                    ),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: onSpentTap,
              child: _BalancePill(
                label: 'Expenses This Month',
                icon: Icons.arrow_upward_rounded,
                color: Colors.redAccent.shade100,
                value: totalSpent,
              ),
            ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double value;
  const _BalancePill(
      {required this.label,
      required this.icon,
      required this.color,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: value),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    '₹${_fmt(v)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 14),
        ],
      ),
    );
  }
}

// ── Financial Health Score Card ────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  final HealthData data;
  const _HealthScoreCard({required this.data});

  Color get _scoreColor {
    if (data.grade == 'No Data') return Colors.grey;
    if (data.score >= 85) return AppColors.success;
    if (data.score >= 70) return const Color(0xFF3ABEFF);
    if (data.score >= 55) return AppColors.warning;
    if (data.score >= 40) return Colors.orange;
    return AppColors.error;
  }

  String get _gradeEmoji {
    if (data.grade == 'No Data') return '📊';
    if (data.score >= 85) return '🏆';
    if (data.score >= 70) return '👍';
    if (data.score >= 55) return '🙂';
    if (data.score >= 40) return '⚠️';
    return '🚨';
  }

  void _showExplainer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: context.cardBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('What is Financial Health?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'It\'s your money report card for this month — a score out of 100 that shows '
              'how well you are managing your finances. Like a school report card, higher is better.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            const _ScoreRow(emoji: '🏆', range: '85–100', label: 'Excellent', sub: 'You are saving well and staying within limits', color: AppColors.success),
            const _ScoreRow(emoji: '👍', range: '70–84', label: 'Good', sub: 'You are on the right track', color: Color(0xFF3ABEFF)),
            const _ScoreRow(emoji: '🙂', range: '55–69', label: 'Fair', sub: 'Some areas need attention', color: AppColors.warning),
            const _ScoreRow(emoji: '⚠️', range: '40–54', label: 'Needs Work', sub: 'Set budgets to gain control', color: Colors.orange),
            const _ScoreRow(emoji: '🚨', range: '0–39', label: 'Critical', sub: 'Spending is more than income', color: AppColors.error),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to improve your score:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('• Set category budgets and stay within them (+30 pts)\n• Make sure salary/income SMS is detected (+20 pts)\n• Reduce spending in your biggest category (+50 pts)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savingsPct = (data.savingsRate * 100).round();
    final budgetPct = (data.budgetAdherence * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: GestureDetector(
        onTap: () => _showExplainer(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: data.score / 100),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: v,
                          strokeWidth: 7,
                          backgroundColor: context.cardBorderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(v * 100).round()}',
                            style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: _scoreColor, height: 1,
                            ),
                          ),
                          Text('/100',
                            style: TextStyle(fontSize: 9, color: context.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Financial Health',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.info_outline_rounded, size: 13, color: context.textMuted),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_gradeEmoji ${data.grade}',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: _scoreColor, height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.tip,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.textSecondary, height: 1.4,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    _MiniBar(label: 'Savings $savingsPct%', value: data.savingsRate, color: AppColors.success),
                    const SizedBox(height: 4),
                    _MiniBar(label: 'Budget $budgetPct%', value: data.budgetAdherence, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String emoji;
  final String range;
  final String label;
  final String sub;
  final Color color;
  const _ScoreRow({required this.emoji, required this.range, required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(range, style: TextStyle(fontSize: 11, color: context.textMuted)),
                  ],
                ),
                Text(sub, style: TextStyle(fontSize: 11, color: context.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MiniBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.textMuted,
                  fontSize: 9,
                ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: context.cardBorderColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(value * 100).round()}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.textMuted,
                fontSize: 9,
              ),
        ),
      ],
    );
  }
}

// ── Spending Breakdown ─────────────────────────────────────────────────────────

class _SpendingBreakdownCard extends StatelessWidget {
  final Map<String, double> totals;
  const _SpendingBreakdownCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final expenseTotals = Map.fromEntries(
      totals.entries
          .where((e) =>
              !['Income', 'Salary', 'Refund'].contains(e.key) && e.value > 0),
    );
    if (expenseTotals.isEmpty) return const SizedBox.shrink();

    final totalSpent = expenseTotals.values.fold(0.0, (a, b) => a + b);
    final sorted = expenseTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();

    final sections = sorted.map((e) {
      return PieChartSectionData(
        value: e.value,
        color: CategoryEngine.getCategoryFlutterColor(e.key),
        title: '',
        radius: 34,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Spending Breakdown',
                    style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '₹${_fmt(totalSpent)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 36,
                      sectionsSpace: 2,
                      borderData: FlBorderData(show: false),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 400),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: top3.map((e) {
                      final pct =
                          (e.value / totalSpent * 100).toStringAsFixed(0);
                      final color =
                          CategoryEngine.getCategoryFlutterColor(e.key);
                      final catIcon = CategoryEngine.getCategoryIconData(e.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(catIcon, size: 13, color: color),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    e.key.split(' ').first,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$pct%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                    Text(
                                      '₹${_fmt(e.value)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: context.textMuted,
                                            fontSize: 9,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                    begin: 0.0,
                                    end: (e.value / totalSpent)
                                        .clamp(0.0, 1.0)),
                                duration:
                                    const Duration(milliseconds: 800),
                                builder: (_, v, __) =>
                                    LinearProgressIndicator(
                                  value: v,
                                  minHeight: 4,
                                  backgroundColor: color.withValues(alpha: 0.12),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Grid ──────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final Map<String, double> totals;
  const _CategoryGrid({required this.totals});

  @override
  Widget build(BuildContext context) {
    final expenseTotals = Map.fromEntries(
      totals.entries
          .where((e) =>
              !['Income', 'Salary', 'Refund'].contains(e.key) && e.value > 0),
    );
    if (expenseTotals.isEmpty) return const SizedBox.shrink();

    final sorted = expenseTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final display = sorted.take(6).toList();
    final total = expenseTotals.values.fold(0.0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Categories',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Tap to drill down',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: context.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemCount: display.length,
            itemBuilder: (context, i) {
              final cat = display[i].key;
              final amount = display[i].value;
              final share = total > 0 ? (amount / total) : 0.0;
              final color = CategoryEngine.getCategoryFlutterColor(cat);
              final icon = CategoryEngine.getCategoryIcon(cat);

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryDetailScreen(category: cat),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      top: BorderSide(color: color, width: 3),
                      left: BorderSide(color: context.cardBorderColor),
                      right: BorderSide(color: context.cardBorderColor),
                      bottom: BorderSide(color: context.cardBorderColor),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 20)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${(share * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.split(' ').first,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: context.textSecondary, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '₹${_fmt(amount)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: context.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Top Payees ─────────────────────────────────────────────────────────────────

class _TopPayeesCard extends StatelessWidget {
  final List<({String name, double amount, int count})> payees;
  const _TopPayeesCard({required this.payees});

  @override
  Widget build(BuildContext context) {
    if (payees.isEmpty) return const SizedBox.shrink();
    final maxAmount =
        payees.map((p) => p.amount).fold(0.0, (m, a) => a > m ? a : m);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Recipients',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              "Who you've paid the most",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.textMuted),
            ),
            const SizedBox(height: 16),
            ...payees.asMap().entries.map((entry) {
              final i = entry.key;
              final payee = entry.value;
              final bar =
                  maxAmount > 0 ? (payee.amount / maxAmount) : 0.0;
              final color = i == 0
                  ? AppColors.primary
                  : i == 1
                      ? AppColors.catSendMoney
                      : AppColors.catFood;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: i == 0 ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: i == 0
                                    ? AppColors.primary
                                    : context.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(payee.name,
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                '${payee.count} txn${payee.count != 1 ? 's' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: context.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${_fmt(payee.amount)}',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: bar),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 4,
                          backgroundColor: context.cardBorderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Recent Transactions ────────────────────────────────────────────────────────

class _RecentTransactionsCard extends StatelessWidget {
  final List<Transaction> transactions;
  const _RecentTransactionsCard({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () => context.go('/transactions'),
                child: const Text('See all',
                    style: TextStyle(color: AppColors.primary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.cardBorderColor),
            ),
            child: Column(
              children: transactions.asMap().entries.map((entry) {
                final i = entry.key;
                final t = entry.value;
                final color = CategoryEngine.getCategoryFlutterColor(t.category);
                final icon = CategoryEngine.getCategoryIcon(t.category);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child:
                                  Text(icon, style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.merchant,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                    overflow: TextOverflow.ellipsis),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        t.category,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    t.isCredit
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: 10,
                                    color: t.isCredit
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '₹${_fmt(t.amount)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: t.isCredit
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                  ),
                                ],
                              ),
                              Text(
                                DateFormat('d MMM').format(t.transactionDate),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: context.textMuted,
                                        fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (i < transactions.length - 1)
                      Divider(
                          height: 1,
                          color: context.cardBorderColor,
                          indent: 70),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Achievement Banner ────────────────────────────────────────────────────────

class _AchievementBanner extends StatelessWidget {
  final int streak;
  final double totalSpent;
  final double totalIncome;

  const _AchievementBanner({
    required this.streak,
    required this.totalSpent,
    required this.totalIncome,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <({String icon, String label, Color color})>[];

    if (streak >= 7) {
      badges.add((icon: '🔥', label: '$streak-day streak', color: Colors.orange));
    } else if (streak >= 3) {
      badges.add((icon: '✨', label: '$streak-day streak', color: Colors.amber));
    } else if (streak >= 1) {
      badges.add((icon: '⚡', label: '$streak days clean', color: Colors.yellow));
    }

    if (totalSpent == 0) {
      badges.add((icon: '🎯', label: 'No spend yet', color: AppColors.primary));
    } else if (totalIncome > 0 && totalSpent < totalIncome * 0.7) {
      badges.add((icon: '💚', label: 'Under budget!', color: AppColors.success));
      if (totalSpent < totalIncome * 0.5) {
        badges.add((icon: '🏆', label: 'Saving 50%+', color: AppColors.success));
      }
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: badges.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final b = badges[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: b.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: b.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(b.icon, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    b.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: b.color,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

String _fmt(double amount) {
  final v = amount.abs();
  if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}

// ── Savings Goal Card ──────────────────────────────────────────────────────────

class _SavingsGoalCard extends StatelessWidget {
  final double goal;
  final double currentSavings;
  final VoidCallback onSetGoal;

  const _SavingsGoalCard({
    required this.goal,
    required this.currentSavings,
    required this.onSetGoal,
  });

  @override
  Widget build(BuildContext context) {
    final hasGoal = goal > 0;
    final progress = hasGoal ? (currentSavings / goal).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    final goalColor = progress >= 1.0
        ? AppColors.success
        : progress >= 0.6
            ? const Color(0xFF3ABEFF)
            : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: GestureDetector(
        onTap: onSetGoal,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Savings Goal',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    hasGoal ? 'Edit' : 'Set Goal',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (!hasGoal) ...[
                const SizedBox(height: 8),
                Text(
                  'Set a monthly savings target to track your progress here.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: context.textMuted, height: 1.4),
                ),
              ] else ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saved so far',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: context.textMuted)),
                        Text(
                          '₹${_fmt(currentSavings)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: goalColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Goal',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: context.textMuted)),
                        Text(
                          '₹${_fmt(goal)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: context.cardBorderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  progress >= 1.0
                      ? '🎉 Goal achieved! Great work!'
                      : '$pct% of your goal — ₹${_fmt(goal - currentSavings)} more to go',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: context.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Upcoming Bills Card ────────────────────────────────────────────────────────

class _UpcomingBillsCard extends StatelessWidget {
  final List<RecurringItem> bills;
  const _UpcomingBillsCard({required this.bills});

  String _typeLabel(RecurringType type) {
    switch (type) {
      case RecurringType.subscription: return 'Subscription';
      case RecurringType.emi: return 'EMI';
      case RecurringType.utility: return 'Utility';
      default: return 'Recurring';
    }
  }

  String _typeEmoji(RecurringType type) {
    switch (type) {
      case RecurringType.subscription: return '📱';
      case RecurringType.emi: return '🏦';
      case RecurringType.utility: return '💡';
      default: return '🔄';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⏰', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Bills Due Soon',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Next 7 days',
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...bills.take(4).map((bill) {
              // nextExpected is always in the future here (upcomingIn() filters past dates)
              final daysLeft = bill.nextExpected != null
                  ? bill.nextExpected!.difference(DateTime.now()).inDays.clamp(0, 999)
                  : 0;
              final urgency = daysLeft <= 1
                  ? Colors.red
                  : daysLeft <= 3
                      ? Colors.orange
                      : Colors.blue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(_typeEmoji(bill.type),
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bill.canonicalMerchant,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text(_typeLabel(bill.type),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: context.textMuted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${_fmt(bill.avgAmount)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          daysLeft <= 0
                              ? 'Due today!'
                              : 'in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                          style: TextStyle(
                              fontSize: 11,
                              color: urgency,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
