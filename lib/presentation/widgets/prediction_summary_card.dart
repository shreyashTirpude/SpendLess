import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../providers/prediction_provider.dart';

class PredictionSummaryCard extends ConsumerWidget {
  const PredictionSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salaryAsync = ref.watch(salaryRunOutProvider);

    return salaryAsync.when(
      loading: () => _LoadingCard(),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        final isOnTrack = result.isOnTrack;
        final bgColor = isOnTrack
            ? context.successBgColor
            : context.warningBgColor;
        final borderColor = isOnTrack
            ? AppColors.success.withValues(alpha: 0.3)
            : AppColors.warning.withValues(alpha: 0.3);
        final textColor =
            isOnTrack ? AppColors.success : AppColors.warning;

        return GestureDetector(
          onTap: () => _showForecastSheet(context, ref, result),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Text(
                  isOnTrack ? '✅' : '⚠️',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnTrack
                            ? 'Safe to spend: ₹${_fmt(result.safeToSpendPerDay)}/day'
                            : 'Salary runs out in ${result.daysUntilRunOut} day${result.daysUntilRunOut != 1 ? 's' : ''}${result.estimatedRunOutDate != null ? ' (${DateFormat('d MMM').format(result.estimatedRunOutDate!)})' : ''}',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Based on ₹${_fmt(result.avgDailySpend)}/day avg spend',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: textColor.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: textColor.withValues(alpha: 0.6), size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showForecastSheet(
    BuildContext context,
    WidgetRef ref,
    SalaryRunOutResult result,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ForecastSheet(result: result),
    );
  }
}

// ── Forecast bottom sheet ─────────────────────────────────────────────────────

class _ForecastSheet extends ConsumerWidget {
  final SalaryRunOutResult result;
  const _ForecastSheet({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlowAsync = ref.watch(dailyCashFlowProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag handle
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cash Flow Forecast',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Projected balance through month end',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: context.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: cashFlowAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                      child: Text('Could not load forecast')),
                  data: (days) {
                    if (days.isEmpty) {
                      return const Center(
                          child: Text('No forecast data'));
                    }
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          // Line chart
                          SizedBox(
                            height: 200,
                            child: _CashFlowChart(days: days),
                          ),
                          const SizedBox(height: 16),
                          // Day-by-day list
                          ...days.map((d) {
                            final isNegative = d.projectedBalance < 0;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      DateFormat('d MMM').format(d.date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: context.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      isNegative
                                          ? '-₹${_fmt(d.projectedBalance.abs())}'
                                          : '₹${_fmt(d.projectedBalance)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isNegative
                                                ? AppColors.error
                                                : AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Line chart widget ─────────────────────────────────────────────────────────

class _CashFlowChart extends StatelessWidget {
  final List<DailyCashFlow> days;
  const _CashFlowChart({required this.days});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final spots = days.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.projectedBalance);
    }).toList();

    final minY = days.map((d) => d.projectedBalance).reduce(
          (a, b) => a < b ? a : b,
        );
    final maxY = days.map((d) => d.projectedBalance).reduce(
          (a, b) => a > b ? a : b,
        );
    final yPad = ((maxY - minY) * 0.1).abs().clamp(100.0, double.infinity);

    return LineChart(
      LineChartData(
        minY: minY - yPad,
        maxY: maxY + yPad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval:
                  days.length > 10 ? (days.length / 5).floorToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  DateFormat('d').format(days[idx].date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textMuted,
                        fontSize: 9,
                      ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final idx = s.x.toInt();
                if (idx < 0 || idx >= days.length) return null;
                final bal = days[idx].projectedBalance;
                return LineTooltipItem(
                  '₹${_fmt(bal)}',
                  TextStyle(
                    color: bal >= 0 ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }
}

// ── Loading shimmer ───────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 160,
                height: 14,
                decoration: BoxDecoration(
                  color: context.cardBorderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 100,
                height: 11,
                decoration: BoxDecoration(
                  color: context.cardBorderColor,
                  borderRadius: BorderRadius.circular(4),
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
  if (amount >= 100000) {
    return '${(amount / 100000).toStringAsFixed(1)}L';
  }
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}
