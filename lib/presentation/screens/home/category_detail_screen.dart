import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_engine.dart';
import '../../../domain/models/transaction.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final String category;
  const CategoryDetailScreen({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(transactionsByCategoryProvider(category));
    final comparisonAsync = ref.watch(categoryMonthComparisonProvider(category));
    final color = CategoryEngine.getCategoryFlutterColor(category);
    final icon = CategoryEngine.getCategoryIconData(category);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(category, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
        actions: [
          comparisonAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (comparison) {
              final (thisMonth, _) = comparison;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '₹${_fmt(thisMonth)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: txnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading transactions')),
        data: (txns) {
          return CustomScrollView(
            slivers: [
              // Month comparison card
              SliverToBoxAdapter(
                child: comparisonAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (comparison) => _ComparisonCard(
                    comparison: comparison,
                    color: color,
                    category: category,
                  ),
                ),
              ),

              // Transactions list
              if (txns.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Text('🧾', style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions this month',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ..._buildGroupedList(context, txns),

              // ── Section A: When do you spend? ─────────────────────────────
              if (txns.isNotEmpty)
                SliverToBoxAdapter(
                  child: _DayOfWeekSection(txns: txns, color: color),
                ),

              // ── Section B: Where do you spend? ────────────────────────────
              if (txns.isNotEmpty)
                SliverToBoxAdapter(
                  child: _MerchantBreakdownSection(txns: txns, color: color),
                ),

              // ── Section C: How much per visit? ────────────────────────────
              if (txns.isNotEmpty)
                SliverToBoxAdapter(
                  child: _PerVisitSection(txns: txns, color: color),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedList(BuildContext context, List<Transaction> txns) {
    final sorted = txns.toList()..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final grouped = <DateTime, List<Transaction>>{};
    for (final t in sorted) {
      final date = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
      grouped.putIfAbsent(date, () => []).add(t);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final color = CategoryEngine.getCategoryFlutterColor(category);
    final icon = CategoryEngine.getCategoryIconData(category);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'All Transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final date = dates[index];
            final dayTxns = grouped[date]!;
            String label;
            if (date.year == today.year && date.month == today.month && date.day == today.day) {
              label = 'Today';
            } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
              label = 'Yesterday';
            } else {
              label = DateFormat('MMM d, yyyy').format(date);
            }
            final dayTotal = dayTxns.where((t) => !t.isCredit).fold(0.0, (s, t) => s + t.amount);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                      Text(
                        '-₹${_fmt(dayTotal)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.cardBorderColor),
                    ),
                    child: Column(
                      children: dayTxns.asMap().entries.map((entry) {
                        final i = entry.key;
                        final t = entry.value;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(child: Icon(icon, size: 18, color: color)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.merchant,
                                            style: Theme.of(context).textTheme.labelLarge,
                                            overflow: TextOverflow.ellipsis),
                                        Text(
                                          DateFormat('h:mm a').format(t.transactionDate),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: context.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${t.isCredit ? '+' : '-'}₹${_fmt(t.amount)}',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: t.isCredit ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i < dayTxns.length - 1)
                              Divider(height: 1, color: context.cardBorderColor, indent: 68),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: dates.length,
        ),
      ),
    ];
  }
}

// ── Section A: When do you spend? ─────────────────────────────────────────────

class _DayOfWeekSection extends StatelessWidget {
  final List<Transaction> txns;
  final Color color;
  const _DayOfWeekSection({required this.txns, required this.color});

  @override
  Widget build(BuildContext context) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final totals = List<double>.filled(7, 0.0);

    for (final t in txns.where((t) => !t.isCredit && !t.isIgnored)) {
      final dow = t.transactionDate.weekday - 1; // 0=Mon, 6=Sun
      totals[dow] += t.amount;
    }

    final maxTotal = totals.isEmpty ? 0.0 : totals.reduce(max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
            Text('When do you spend?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Spend by day of week this month',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.textMuted),
            ),
            const SizedBox(height: 16),
            ...List.generate(7, (i) {
              final frac = maxTotal > 0
                  ? (totals[i] / maxTotal).clamp(0.0, 1.0)
                  : 0.0;
              final barColor = Color.lerp(
                color.withValues(alpha: 0.2),
                color,
                frac,
              )!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        dayNames[i],
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: context.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: context.cardBorderColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              Container(
                                height: 20,
                                width: constraints.maxWidth * frac,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      child: Text(
                        totals[i] > 0 ? '₹${_fmt(totals[i])}' : '—',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: totals[i] > 0
                                  ? context.textSecondary
                                  : context.textMuted,
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

// ── Section B: Where do you spend? ────────────────────────────────────────────

class _MerchantBreakdownSection extends StatelessWidget {
  final List<Transaction> txns;
  final Color color;
  const _MerchantBreakdownSection({required this.txns, required this.color});

  @override
  Widget build(BuildContext context) {
    final debits = txns.where((t) => !t.isCredit && !t.isIgnored).toList();
    final categoryTotal = debits.fold<double>(0.0, (s, t) => s + t.amount);

    final byMerchant = <String, double>{};
    for (final t in debits) {
      byMerchant[t.merchant] = (byMerchant[t.merchant] ?? 0) + t.amount;
    }
    final sorted = byMerchant.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    if (top5.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
            Text('Where do you spend?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Top merchants this month',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.textMuted),
            ),
            const SizedBox(height: 16),

            // Donut chart (fl_chart is available)
            if (top5.length >= 2)
              SizedBox(
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: top5.asMap().entries.map((e) {
                      final pct = categoryTotal > 0
                          ? (e.value.value / categoryTotal * 100)
                          : 0.0;
                      final opacity =
                          (1.0 - e.key * 0.12).clamp(0.25, 1.0);
                      return PieChartSectionData(
                        value: e.value.value,
                        color: color.withValues(alpha: opacity),
                        radius: 28,
                        title: pct >= 10
                            ? '${pct.toStringAsFixed(0)}%'
                            : '',
                        titleStyle: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 300),
                ),
              ),

            const SizedBox(height: 12),

            ...top5.map((e) {
              final pct =
                  categoryTotal > 0 ? e.value / categoryTotal : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(e.key,
                              style: Theme.of(context).textTheme.labelLarge,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          '₹${_fmt(e.value)} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: context.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: context.cardBorderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(4),
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

// ── Section C: How much per visit? ────────────────────────────────────────────

class _PerVisitSection extends StatelessWidget {
  final List<Transaction> txns;
  final Color color;
  const _PerVisitSection({required this.txns, required this.color});

  @override
  Widget build(BuildContext context) {
    final amounts = txns
        .where((t) => !t.isCredit && !t.isIgnored)
        .map((t) => t.amount)
        .toList()
      ..sort();

    if (amounts.isEmpty) return const SizedBox.shrink();

    final avg = amounts.reduce((a, b) => a + b) / amounts.length;
    final minVal = amounts.first;
    final maxVal = amounts.last;
    final median = amounts.length.isOdd
        ? amounts[amounts.length ~/ 2]
        : (amounts[amounts.length ~/ 2 - 1] +
                amounts[amounts.length ~/ 2]) /
            2;

    // Top merchant by frequency
    final byMerchant = <String, ({double total, int count})>{};
    for (final t in txns.where((t) => !t.isCredit && !t.isIgnored)) {
      final ex = byMerchant[t.merchant];
      byMerchant[t.merchant] = (
        total: (ex?.total ?? 0) + t.amount,
        count: (ex?.count ?? 0) + 1,
      );
    }
    final topEntry = byMerchant.entries.isEmpty
        ? null
        : byMerchant.entries
            .reduce((a, b) => a.value.count > b.value.count ? a : b);
    final topAvg = topEntry != null && topEntry.value.count > 0
        ? topEntry.value.total / topEntry.value.count
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
            Text('How much per visit?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${amounts.length} transaction${amounts.length != 1 ? 's' : ''} this month',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Average',
                    value: '₹${_fmt(avg)}',
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Median',
                    value: '₹${_fmt(median)}',
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Smallest',
                    value: '₹${_fmt(minVal)}',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Largest',
                    value: '₹${_fmt(maxVal)}',
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            if (topEntry != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'You visit ${topEntry.key} ${topEntry.value.count}x this month, avg ₹${_fmt(topAvg)} per visit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textMuted,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Existing cards ─────────────────────────────────────────────────────────────

class _ComparisonCard extends StatelessWidget {
  final (double, double) comparison;
  final Color color;
  final String category;
  const _ComparisonCard({required this.comparison, required this.color, required this.category});

  @override
  Widget build(BuildContext context) {
    final (thisMonth, lastMonth) = comparison;
    final hasLastMonth = lastMonth > 0;
    final change = hasLastMonth ? ((thisMonth - lastMonth) / lastMonth * 100) : 0.0;
    final isUp = change > 0;
    final maxVal = max(thisMonth, lastMonth) * 1.3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
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
            Text('vs Last Month', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            if (hasLastMonth)
              Row(
                children: [
                  Icon(
                    isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    color: isUp ? AppColors.error : AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isUp ? '+' : ''}${change.toStringAsFixed(1)}% ${isUp ? 'more' : 'less'} than last month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isUp ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              )
            else
              Text(
                'No data for last month',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
              ),
            const SizedBox(height: 16),
            if (maxVal > 0)
              SizedBox(
                height: 100,
                child: BarChart(
                  BarChartData(
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: lastMonth,
                            color: context.textMuted,
                            width: 36,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: thisMonth,
                            color: color,
                            width: 36,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (value, meta) {
                            final labels = ['Last Mo.', 'This Mo.'];
                            final idx = value.toInt();
                            return Text(
                              labels[idx],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.textMuted,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    maxY: maxVal,
                    barTouchData: BarTouchData(enabled: false),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 300),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendDot(color: context.textMuted, label: 'Last: ₹${_fmt(lastMonth)}', context: context),
                const SizedBox(width: 16),
                _LegendDot(color: color, label: 'This: ₹${_fmt(thisMonth)}', context: context),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final BuildContext context;
  const _LegendDot({required this.color, required this.label, required this.context});

  @override
  Widget build(BuildContext _) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondary)),
      ],
    );
  }
}

String _fmt(double amount) {
  if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}
