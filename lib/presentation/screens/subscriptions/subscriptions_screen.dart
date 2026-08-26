import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/recurring_detector.dart';
import '../../../data/local/hive_service.dart';
import '../../providers/recurring_provider.dart';

// ── Local state: cancelled subs ────────────────────────────────────────────────

final _cancelledSubsProvider = StateProvider<List<String>>((ref) {
  final raw = HiveService.settings.get('cancelled_subs', defaultValue: <String>[]);
  if (raw is List) return List<String>.from(raw);
  return [];
});

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allItemsRaw = ref.watch(recurringItemsProvider);
    final cancelledSubs = ref.watch(_cancelledSubsProvider);

    // Filter out cancelled subs
    final allItems = allItemsRaw
        .where((r) => !cancelledSubs.contains(r.canonicalMerchant))
        .toList();

    final upcoming = allItems
        .where((item) {
          final next = item.nextExpected;
          if (next == null) return false;
          final diff = next.difference(DateTime.now()).inDays;
          return diff >= 0 && diff <= 7;
        })
        .toList()
      ..sort((a, b) => a.nextExpected!.compareTo(b.nextExpected!));

    final monthlyTotal = allItems.fold(0.0, (sum, r) => sum + r.avgAmount);

    // Next charge among upcoming
    final nextCharge = upcoming.isNotEmpty ? upcoming.first : null;
    final nextDays = nextCharge?.nextExpected != null
        ? nextCharge!.nextExpected!.difference(DateTime.now()).inDays
        : null;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subscriptions',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Recurring bills & subscriptions',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: context.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            // ── NEW: Autopay summary card ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('💳', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          nextCharge != null && nextDays != null
                              ? '₹${_fmt(monthlyTotal)}/month in autopay  ·  Next: ${nextCharge.canonicalMerchant} in $nextDays day${nextDays != 1 ? 's' : ''}'
                              : '₹${_fmt(monthlyTotal)}/month in autopay',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Monthly total gradient card (existing)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monthly Recurring',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${_fmt(monthlyTotal)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${allItems.length} active recurring payments',
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Text('🔄', style: TextStyle(fontSize: 40)),
                    ],
                  ),
                ),
              ),
            ),

            // Upcoming bills section
            if (upcoming.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Due This Week',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _RecurringTile(
                      item: upcoming[i],
                      isUrgent: true,
                      allTransactionMerchants:
                          _recentMerchants(ref),
                      onCancel: (merchant) =>
                          _cancelSub(context, ref, merchant),
                    ),
                  ),
                  childCount: upcoming.length,
                ),
              ),
            ],

            // All items grouped by type
            if (allItems.isNotEmpty) ...[
              ..._buildGroupedSection(
                  context, ref, 'Subscriptions', allItems,
                  RecurringType.subscription),
              ..._buildGroupedSection(
                  context, ref, 'EMIs & Loans', allItems,
                  RecurringType.emi),
              ..._buildGroupedSection(
                  context, ref, 'Utilities', allItems,
                  RecurringType.utility),
              ..._buildGroupedSection(
                  context, ref, 'Other Recurring', allItems,
                  RecurringType.recurring),
            ],

            if (allItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          'No recurring payments found',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recurring payments appear after 2+ transactions to the same merchant in consecutive months.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.textMuted,
                                    height: 1.5,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the set of merchant names with a transaction in last 30 days.
  Set<String> _recentMerchants(WidgetRef ref) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));
    return HiveService.transactions.values
        .where((t) =>
            !t.isIgnored && t.transactionDate.isAfter(cutoff))
        .map((t) => t.merchant)
        .toSet();
  }

  void _cancelSub(BuildContext context, WidgetRef ref, String merchant) {
    final list = [...ref.read(_cancelledSubsProvider)];
    if (!list.contains(merchant)) list.add(merchant);
    ref.read(_cancelledSubsProvider.notifier).state = list;
    // Persist to Hive
    HiveService.settings.put('cancelled_subs', list);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$merchant marked as cancelled'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Widget> _buildGroupedSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<RecurringItem> all,
    RecurringType type,
  ) {
    final items = all.where((r) => r.type == type).toList();
    if (items.isEmpty) return [];
    final recentMerchants = _recentMerchants(ref);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.textMuted,
                  letterSpacing: 0.8,
                ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _RecurringTile(
              item: items[i],
              allTransactionMerchants: recentMerchants,
              onCancel: (merchant) =>
                  _cancelSub(context, ref, merchant),
            ),
          ),
          childCount: items.length,
        ),
      ),
    ];
  }
}

// ── Enhanced RecurringTile ────────────────────────────────────────────────────

class _RecurringTile extends StatelessWidget {
  final RecurringItem item;
  final bool isUrgent;
  final Set<String> allTransactionMerchants;
  final void Function(String merchant) onCancel;

  const _RecurringTile({
    required this.item,
    this.isUrgent = false,
    required this.allTransactionMerchants,
    required this.onCancel,
  });

  String get _typeIcon {
    switch (item.type) {
      case RecurringType.subscription:
        return '📺';
      case RecurringType.emi:
        return '🏦';
      case RecurringType.utility:
        return '⚡';
      case RecurringType.recurring:
        return '🔄';
    }
  }

  // ── Price drift: compare first vs most recent charge ──────────────────────
  bool get _hasPriceDrift {
    if (item.history.length < 2) return false;
    final first = item.history.first.amount;
    final latest = item.history.last.amount;
    return (latest - first).abs() > 1.0; // > ₹1 difference
  }

  double get _firstAmount =>
      item.history.isNotEmpty ? item.history.first.amount : item.avgAmount;
  double get _latestAmount =>
      item.history.isNotEmpty ? item.history.last.amount : item.avgAmount;
  double get _priceDriftPct => _firstAmount > 0
      ? ((_latestAmount - _firstAmount) / _firstAmount) * 100
      : 0.0;

  // ── Idle: no non-subscription tx from this merchant in last 30 days ───────
  bool _isIdle() {
    // Idle if merchant not in allTransactionMerchants OR only recurring txns
    // We simplify: idle = merchant not seen in any tx of last 30 days
    return !allTransactionMerchants.any(
        (m) => m.toLowerCase().contains(item.canonicalMerchant.toLowerCase()) ||
            item.canonicalMerchant
                .toLowerCase()
                .contains(m.toLowerCase()));
  }

  void _showCancelSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                item.canonicalMerchant,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '₹${_fmt(item.avgAmount)}/month',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: context.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
              title: const Text(
                'Mark as Cancelled',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                onCancel(item.canonicalMerchant);
              },
            ),
            ListTile(
              leading: Icon(Icons.close, color: context.textMuted),
              title: const Text('Dismiss'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = item.nextExpected;
    final daysUntil = next?.difference(DateTime.now()).inDays;
    final isDueWithin7 = daysUntil != null && daysUntil >= 0 && daysUntil <= 7;
    final idle = _isIdle();
    final priceDrift = _hasPriceDrift;

    return GestureDetector(
      onLongPress: () => _showCancelSheet(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUrgent
              ? Colors.orange.withValues(alpha: 0.08)
              : context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUrgent
                ? Colors.orange.withValues(alpha: 0.35)
                : context.cardBorderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? Colors.orange.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(_typeIcon,
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.canonicalMerchant,
                        style: Theme.of(context).textTheme.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        next != null
                            ? 'Due ${DateFormat('d MMM').format(next)} · ₹${_fmt(item.avgAmount)}'
                            : '₹${_fmt(item.avgAmount)}/month · day ${item.typicalDayOfMonth}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: isUrgent
                                    ? Colors.orange
                                    : context.textMuted),
                      ),
                    ],
                  ),
                ),

                // Right column: amount + due badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_fmt(item.avgAmount)}',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (isDueWithin7)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Due in $daysUntil day${daysUntil != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // ── Price drift warning ──────────────────────────────────────────
            if (priceDrift) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      'Price changed: ₹${_fmt(_firstAmount)} → ₹${_fmt(_latestAmount)} (${_priceDriftPct >= 0 ? '+' : ''}${_priceDriftPct.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Idle warning ─────────────────────────────────────────────────
            if (idle) ...[
              const SizedBox(height: 6),
              Text(
                '⚠️ Possibly unused — no recent activity',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade600,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _fmt(double amount) {
  if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}
