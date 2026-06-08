import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/budget_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_engine.dart';
import '../../../domain/models/transaction.dart';
import 'category_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _showNotifications(BuildContext context, WidgetRef ref) {
    final budgetData = ref.read(allCategoriesSpendingProvider).valueOrNull ?? [];
    final recentTxns = ref.read(transactionsProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsSheet(budgetData: budgetData, recentTxns: recentTxns),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(homeStatsProvider);
    final healthAsync = ref.watch(healthScoreProvider);
    final txnsAsync = ref.watch(transactionsProvider);
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: context.bgColor,
      body: statsAsync.when(
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
                      onTap: () => _showNotifications(context, ref),
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

            // Financial Health Score
            SliverToBoxAdapter(
              child: healthAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (health) => _HealthScoreCard(data: health),
              ),
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
    );
  }
}

// ── Privacy Trust Chip ────────────────────────────────────────────────────────

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

class _NotificationsSheet extends StatelessWidget {
  final List<({String category, double spent, double? limit})> budgetData;
  final List<Transaction> recentTxns;
  const _NotificationsSheet({required this.budgetData, required this.recentTxns});

  @override
  Widget build(BuildContext context) {
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
                        style: TextStyle(
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
                        context: context,
                      )),

                  // Near-budget alerts
                  ...nearBudget.map((b) => _NotifCard(
                        icon: '⚠️',
                        title: '${b.category} nearing limit',
                        body:
                            'Spent ₹${_fmt(b.spent)} of ₹${_fmt(b.limit!)} (${((b.spent / b.limit!) * 100).round()}%)',
                        isAlert: true,
                        context: context,
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
                              '${t.isCredit ? '+' : '-'}₹${_fmt(t.amount)} · ${t.category}',
                          isAlert: false,
                          context: context,
                        )),
                  ],

                  // Tips
                  _NotifCard(
                    icon: '💡',
                    title: 'Tip: Long-press any transaction to recategorize',
                    body: 'Accurate categories improve your insights.',
                    isAlert: false,
                    context: context,
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
  final BuildContext context;
  const _NotifCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.isAlert,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
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
                      final icon = CategoryEngine.getCategoryIcon(e.value.category);
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
                                      child: Text(icon,
                                          style: const TextStyle(fontSize: 17))),
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
                        final icon = CategoryEngine.getCategoryIcon(t.category);
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
                                        child: Text(icon,
                                            style: const TextStyle(fontSize: 16))),
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
                                  Text(
                                    '${t.isCredit ? '+' : '-'}₹${_fmt(t.amount)}',
                                    style: TextStyle(
                                      color: t.isCredit ? AppColors.success : AppColors.error,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
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
    final spentRatio =
        totalIncome > 0 ? (totalSpent / totalIncome).clamp(0.0, 1.0) : 0.0;
    final dayOfMonth = DateTime.now().day;
    final projectedMonthly =
        dayOfMonth > 3 ? (totalSpent / dayOfMonth) * 30 : 0.0;
    final arcColor = spentRatio > 0.9
        ? Colors.redAccent.shade100
        : spentRatio > 0.7
            ? Colors.orange.shade300
            : Colors.greenAccent.shade200;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
                      'Net Balance',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: net.abs()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        '${net < 0 ? '-' : ''}₹${_fmt(v)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (projectedMonthly > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'On pace for ₹${_fmt(projectedMonthly)} this month',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              // Spending arc ring
              if (totalIncome > 0)
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
          if (safeToSpend > 0 || daysRemaining > 0) ...[
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
    if (data.score >= 80) return AppColors.success;
    if (data.score >= 65) return const Color(0xFF3ABEFF);
    if (data.score >= 45) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_scoreColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(v * 100).round()}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _scoreColor,
                            height: 1,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 9,
                            color: context.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
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
                  Text(
                    'Financial Health',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.grade,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _scoreColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.tip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.textSecondary,
                          height: 1.4,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  _MiniBar(
                    label: 'Savings',
                    value: data.savingsRate,
                    color: AppColors.success,
                    context: context,
                  ),
                  const SizedBox(height: 4),
                  _MiniBar(
                    label: 'Budget',
                    value: data.budgetAdherence,
                    color: AppColors.primary,
                    context: context,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final BuildContext context;
  const _MiniBar(
      {required this.label,
      required this.value,
      required this.color,
      required this.context});

  @override
  Widget build(BuildContext ctx) {
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
                      final catIcon = CategoryEngine.getCategoryIcon(e.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(catIcon, style: const TextStyle(fontSize: 12)),
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
    final maxAmount =
        payees.map((p) => p.amount).reduce((a, b) => a > b ? a : b);

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
                onPressed: () {},
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
                              Text(
                                '${t.isCredit ? '+' : '-'}₹${_fmt(t.amount)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: t.isCredit
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
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

String _fmt(double amount) {
  if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}
