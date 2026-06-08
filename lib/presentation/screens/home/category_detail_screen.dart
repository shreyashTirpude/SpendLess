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
    final icon = CategoryEngine.getCategoryIcon(category);

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
            Text(icon, style: const TextStyle(fontSize: 20)),
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
    final icon = CategoryEngine.getCategoryIcon(category);
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
                                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
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
