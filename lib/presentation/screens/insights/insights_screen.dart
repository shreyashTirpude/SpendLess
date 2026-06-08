import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/insights_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_engine.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  DateTime? _selectedDay;

  void _onChartDayTapped(DateTime date, List<(DateTime, double)> days) {
    setState(() => _selectedDay = date);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailSheet(date: date),
    ).then((_) => setState(() => _selectedDay = null));
  }

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(insightCardsProvider);
    final merchants = ref.watch(topMerchantsProvider);
    final comparison = ref.watch(monthComparisonProvider);
    final dailySpend = ref.watch(dailySpendProvider);
    final topPayees = ref.watch(topPayeesByAmountProvider);
    final weeklyPattern = ref.watch(weeklyPatternProvider);
    final projected = ref.watch(projectedSpendProvider);
    final streak = ref.watch(noSpendStreakProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Text('Insights', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Your spending intelligence',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
            ),
            const SizedBox(height: 20),

            // Summary stats row
            projected.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (p) => _SummaryStatsRow(projected: p),
            ),

            const SizedBox(height: 16),

            // Spending trend chart (clickable)
            dailySpend.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (days) => _SpendingTrendCard(
                days: days,
                selectedDay: _selectedDay,
                onDayTapped: (date) => _onChartDayTapped(date, days),
              ),
            ),

            const SizedBox(height: 16),

            // Smart insight cards
            insights.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (insightList) {
                if (insightList.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart Insights', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ...insightList.map((insight) => _InsightCard(text: insight)),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Weekly spending pattern
            weeklyPattern.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (pattern) {
                if (pattern.every((v) => v == 0)) return const SizedBox.shrink();
                return _WeeklyPatternCard(pattern: pattern);
              },
            ),

            const SizedBox(height: 16),

            // No-spend streak
            streak.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (days) => days > 0
                  ? _StreakCard(days: days)
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Month-over-month comparison
            comparison.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (comp) => _MonthComparisonCard(comparison: comp),
            ),

            const SizedBox(height: 16),

            // Top recipients by amount
            topPayees.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (payees) {
                if (payees.isEmpty) return const SizedBox.shrink();
                return _TopRecipientsCard(payees: payees);
              },
            ),

            const SizedBox(height: 16),

            // Top merchants by frequency
            merchants.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (merchantList) {
                if (merchantList.isEmpty) return const SizedBox.shrink();
                return _TopMerchantsCard(merchants: merchantList);
              },
            ),

            const SizedBox(height: 16),

            // Subscriptions teaser card
            _SubscriptionsTeaserCard(ref: ref),
          ],
        ),
      ),
    );
  }
}

// ── Summary Stats Row ─────────────────────────────────────────────────────────

class _SummaryStatsRow extends StatelessWidget {
  final ({double projected, double dailyAvg, int daysLeft}) projected;
  const _SummaryStatsRow({required this.projected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          label: 'Daily Avg',
          value: '₹${projected.dailyAvg.toStringAsFixed(0)}',
          icon: '📅',
          context: context,
        ),
        const SizedBox(width: 10),
        _StatChip(
          label: 'Projected',
          value: '₹${_fmt(projected.projected)}',
          icon: '📈',
          context: context,
        ),
        const SizedBox(width: 10),
        _StatChip(
          label: 'Days Left',
          value: '${projected.daysLeft}',
          icon: '⏳',
          context: context,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value, icon;
  final BuildContext context;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: context.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Spending Trend Chart ───────────────────────────────────────────────────────

class _SpendingTrendCard extends StatefulWidget {
  final List<(DateTime, double)> days;
  final DateTime? selectedDay;
  final void Function(DateTime) onDayTapped;
  const _SpendingTrendCard(
      {required this.days,
      required this.selectedDay,
      required this.onDayTapped});

  @override
  State<_SpendingTrendCard> createState() => _SpendingTrendCardState();
}

class _SpendingTrendCardState extends State<_SpendingTrendCard> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.days.isEmpty) return const SizedBox.shrink();

    final maxY = widget.days.fold(0.0, (m, d) => d.$2 > m ? d.$2 : m) * 1.3;
    final spots = widget.days.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.$2);
    }).toList();

    final totalThisMonth = widget.days.fold(0.0, (s, d) => s + d.$2);

    return Container(
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
              Text('Daily Spending', style: Theme.of(context).textTheme.titleLarge),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM yyyy').format(DateTime.now()),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.textMuted),
                  ),
                  Text(
                    '₹${_fmt(totalThisMonth)} total',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap any point to see that day\'s transactions',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: context.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) {
                        final isSelected = _touchedIndex == idx;
                        return FlDotCirclePainter(
                          radius: isSelected ? 6 : 3,
                          color: isSelected ? Colors.white : AppColors.primary,
                          strokeColor: AppColors.primary,
                          strokeWidth: isSelected ? 3 : 1,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.22),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxY > 0 ? maxY / 3 : 1,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: context.cardBorderColor,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval:
                          (widget.days.length / 5).ceilToDouble().clamp(1, 10),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= widget.days.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat('d').format(widget.days[idx].$1),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.textMuted,
                                fontSize: 10,
                              ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                maxY: maxY > 0 ? maxY : 100,
                minY: 0,
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchCallback: (event, response) {
                    if (response?.lineBarSpots != null &&
                        event is FlTapUpEvent) {
                      final idx = response!.lineBarSpots!.first.spotIndex;
                      if (idx < widget.days.length) {
                        setState(() => _touchedIndex = idx);
                        widget.onDayTapped(widget.days[idx].$1);
                      }
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => context.cardColor,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final idx = s.spotIndex;
                        if (idx >= widget.days.length) return null;
                        return LineTooltipItem(
                          '₹${_fmt(widget.days[idx].$2)}\n${DateFormat('d MMM').format(widget.days[idx].$1)}',
                          TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day Detail Bottom Sheet ───────────────────────────────────────────────────

class _DayDetailSheet extends ConsumerWidget {
  final DateTime date;
  const _DayDetailSheet({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(transactionsByDateProvider(date));
    final dateLabel = DateFormat('EEEE, d MMMM').format(date);

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateLabel, style: Theme.of(context).textTheme.headlineSmall),
                      txnsAsync.when(
                        data: (txns) {
                          final spent = txns
                              .where((t) => !t.isCredit)
                              .fold(0.0, (s, t) => s + t.amount);
                          return Text(
                            '₹${_fmt(spent)} spent · ${txns.length} transactions',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: context.textMuted),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: txnsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error loading')),
                data: (txns) {
                  if (txns.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✅', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('No transactions on this day',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: context.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    itemCount: txns.length,
                    itemBuilder: (ctx, i) {
                      final t = txns[i];
                      final color = CategoryEngine.getCategoryFlutterColor(t.category);
                      final icon = CategoryEngine.getCategoryIcon(t.category);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.cardBorderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                  child: Text(icon,
                                      style: const TextStyle(fontSize: 18))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.merchant,
                                      style: Theme.of(context).textTheme.labelLarge,
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
                                        child: Text(t.category,
                                            style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: color)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${t.isCredit ? '+' : '-'}₹${_fmt(t.amount)}',
                              style: TextStyle(
                                color: t.isCredit ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly Pattern Card ───────────────────────────────────────────────────────

class _WeeklyPatternCard extends StatelessWidget {
  final List<double> pattern;
  const _WeeklyPatternCard({required this.pattern});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = pattern.reduce((a, b) => a > b ? a : b);
    final todayDow = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending by Day of Week',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Average spend per weekday this month',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: context.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final val = pattern[i];
              final barH = maxVal > 0 ? (val / maxVal) * 80 : 4.0;
              final isToday = i == todayDow;
              final isHighest = val == maxVal && maxVal > 0;

              return Column(
                children: [
                  if (isHighest)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '₹${_fmt(val)}',
                        style: TextStyle(
                            fontSize: 8, color: AppColors.error, fontWeight: FontWeight.w700),
                      ),
                    )
                  else
                    const SizedBox(height: 18),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    width: 28,
                    height: barH.clamp(4.0, 80.0),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary
                          : isHighest
                              ? AppColors.error.withValues(alpha: 0.7)
                              : AppColors.primary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      color: isToday ? AppColors.primary : context.textMuted,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── No-Spend Streak Card ──────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int days;
  const _StreakCard({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$days-Day No-Spend Streak',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                days >= 7
                    ? 'Amazing discipline! You\'re saving big.'
                    : 'Keep it up — every day counts!',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: context.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Smart Insight Card ────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final String text;
  const _InsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final isAlert = text.startsWith('🔴') || text.startsWith('⚠️');
    final isPositive = text.startsWith('✅') || text.startsWith('🏆');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAlert
            ? context.errorBgColor
            : isPositive
                ? AppColors.success.withValues(alpha: 0.07)
                : context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlert
              ? AppColors.error.withValues(alpha: 0.3)
              : isPositive
                  ? AppColors.success.withValues(alpha: 0.3)
                  : context.cardBorderColor,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isAlert ? AppColors.error : null,
            ),
      ),
    );
  }
}

// ── Month Comparison ──────────────────────────────────────────────────────────

class _MonthComparisonCard extends StatelessWidget {
  final Map<String, (double, double)> comparison;
  const _MonthComparisonCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final entries = comparison.entries
        .where((e) => !['Income', 'Salary', 'Refund'].contains(e.key))
        .where((e) => e.value.$1 > 0 || e.value.$2 > 0)
        .toList()
      ..sort((a, b) => b.value.$1.compareTo(a.value.$1));

    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
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
          Row(
            children: [
              _LegendDot(color: context.textMuted, label: 'Last month', ctx: context),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.primary, label: 'This month', ctx: context),
            ],
          ),
          const SizedBox(height: 16),
          ...entries.take(5).map((e) {
            final (thisMonth, lastMonth) = e.value;
            final maxVal = [thisMonth, lastMonth, 1.0].reduce((a, b) => a > b ? a : b);
            final color = CategoryEngine.getCategoryFlutterColor(e.key);
            final icon = CategoryEngine.getCategoryIcon(e.key);
            final isUp = thisMonth > lastMonth && lastMonth > 0;
            final isDown = thisMonth < lastMonth && lastMonth > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(e.key, style: Theme.of(context).textTheme.labelMedium),
                      const Spacer(),
                      if (isUp)
                        Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.error)
                      else if (isDown)
                        Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 2),
                      Text(
                        '₹${_fmt(thisMonth)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: isUp ? AppColors.error : isDown ? AppColors.success : null,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: maxVal > 0 ? (lastMonth / maxVal).clamp(0.0, 1.0) : 0.0,
                      backgroundColor: context.cardBorderColor,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(context.textMuted.withValues(alpha: 0.4)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: maxVal > 0 ? (thisMonth / maxVal).clamp(0.0, 1.0) : 0.0,
                      backgroundColor: context.cardBorderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Top Recipients ────────────────────────────────────────────────────────────

class _TopRecipientsCard extends StatelessWidget {
  final List<({String name, double amount, int count})> payees;
  const _TopRecipientsCard({required this.payees});

  @override
  Widget build(BuildContext context) {
    final maxAmount = payees.map((p) => p.amount).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Recipients', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'By total amount paid this month',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
          ),
          const SizedBox(height: 16),
          ...payees.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final bar = maxAmount > 0 ? p.amount / maxAmount : 0.0;
            final colors = [
              AppColors.primary,
              AppColors.catSendMoney,
              AppColors.catFood,
              AppColors.catTransport,
              AppColors.catShopping,
            ];
            final barColor = colors[i % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: barColor)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(p.name,
                            style: Theme.of(context).textTheme.labelMedium,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('₹${_fmt(p.amount)}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: barColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: bar,
                      backgroundColor: context.cardBorderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Top Merchants ─────────────────────────────────────────────────────────────

class _TopMerchantsCard extends StatelessWidget {
  final List<(String, int)> merchants;
  const _TopMerchantsCard({required this.merchants});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Most Visited', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'By number of transactions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
          ),
          const SizedBox(height: 16),
          ...merchants.asMap().entries.map((entry) {
            final i = entry.key;
            final (merchant, count) = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: i == 0 ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: i == 0 ? AppColors.primary : context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      merchant,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.cardBorderColor),
                    ),
                    child: Text(
                      '$count txn${count != 1 ? 's' : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: context.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Subscriptions Teaser Card ─────────────────────────────────────────────────

class _SubscriptionsTeaserCard extends ConsumerWidget {
  final WidgetRef ref;
  const _SubscriptionsTeaserCard({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recurringItemsProvider);
    final total = ref.watch(monthlyRecurringTotalProvider);
    if (items.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/subscriptions'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Text('🔄', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subscriptions & Recurring', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    '${items.length} active · ₹${_fmt(total)}/month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textMuted),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final BuildContext ctx;
  const _LegendDot({required this.color, required this.label, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: ctx.textMuted)),
      ],
    );
  }
}

String _fmt(double amount) {
  if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
  return amount.toStringAsFixed(0);
}
