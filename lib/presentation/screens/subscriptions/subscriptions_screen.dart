import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/recurring_detector.dart';
import '../../providers/recurring_provider.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allItems = ref.watch(recurringItemsProvider);
    final upcoming = ref.watch(upcomingBillsProvider);
    final monthlyTotal = ref.watch(monthlyRecurringTotalProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subscriptions', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Recurring bills & subscriptions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            // Monthly total summary card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                              style: TextStyle(color: Colors.white70, fontSize: 12),
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
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
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
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Due This Week',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _RecurringTile(item: upcoming[i], isUrgent: true),
                  ),
                  childCount: upcoming.length,
                ),
              ),
            ],

            // All items grouped by type
            if (allItems.isNotEmpty) ...[
              ..._buildGroupedSection(context, 'Subscriptions', allItems, RecurringType.subscription),
              ..._buildGroupedSection(context, 'EMIs & Loans', allItems, RecurringType.emi),
              ..._buildGroupedSection(context, 'Utilities', allItems, RecurringType.utility),
              ..._buildGroupedSection(context, 'Other Recurring', allItems, RecurringType.recurring),
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
                        const Text('🔍', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          'No recurring payments found',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recurring payments appear after 2+ transactions to the same merchant in consecutive months.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  List<Widget> _buildGroupedSection(
    BuildContext context,
    String title,
    List<RecurringItem> all,
    RecurringType type,
  ) {
    final items = all.where((r) => r.type == type).toList();
    if (items.isEmpty) return [];
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
            child: _RecurringTile(item: items[i]),
          ),
          childCount: items.length,
        ),
      ),
    ];
  }
}

class _RecurringTile extends StatelessWidget {
  final RecurringItem item;
  final bool isUrgent;
  const _RecurringTile({required this.item, this.isUrgent = false});

  String get _typeIcon {
    switch (item.type) {
      case RecurringType.subscription: return '📺';
      case RecurringType.emi: return '🏦';
      case RecurringType.utility: return '⚡';
      case RecurringType.recurring: return '🔄';
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = item.nextExpected;
    final daysUntil = next != null ? next.difference(DateTime.now()).inDays : null;

    return Container(
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
      child: Row(
        children: [
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
              child: Text(_typeIcon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isUrgent ? Colors.orange : context.textMuted,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_fmt(item.avgAmount)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (daysUntil != null && daysUntil <= 7)
                Text(
                  'in $daysUntil day${daysUntil != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
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
