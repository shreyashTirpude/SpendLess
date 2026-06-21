import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/data/festival_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/festival_provider.dart';
import '../../providers/subscription_provider.dart';

// ── Entry point ────────────────────────────────────────────────────────────────

class FestivalPlannerScreen extends ConsumerWidget {
  const FestivalPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isFeatureAvailableProvider('festivalPlanner'));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Festival Planner',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isPro ? const _PlannerBody() : const _LockedState(),
    );
  }
}

// ── Locked state (free / plus) ────────────────────────────────────────────────

class _LockedState extends StatelessWidget {
  const _LockedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('🪔', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Festival Planner',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Plan your festival budgets, track how much you spend every year, '
              'and get smart tips — so celebrations never hurt your wallet.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const _ProFeatureRow(
                icon: '🎯',
                text: 'Auto-estimated budgets based on last year\'s spend'),
            const _ProFeatureRow(
                icon: '📅',
                text: '12-month festival timeline with countdown'),
            const _ProFeatureRow(
                icon: '💡',
                text: 'Smart tips tailored to each festival type'),
            const _ProFeatureRow(
                icon: '⏰',
                text: '30-day reminder before every festival'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => context.push('/paywall'),
                child: const Text(
                  'Go Pro — Free for 7 days',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProFeatureRow extends StatelessWidget {
  final String icon;
  final String text;
  const _ProFeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main planner body (Pro only) ──────────────────────────────────────────────

class _PlannerBody extends ConsumerWidget {
  const _PlannerBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(upcomingFestivalProvider);
    final selectedIndex = ref.watch(selectedFestivalIndexProvider);
    final allFestivals = FestivalCalendar.allSorted;
    final now = DateTime.now();
    final next12Months = allFestivals
        .where((f) =>
            f.nextDate.isAfter(now) &&
            f.nextDate.isBefore(now.add(const Duration(days: 365))))
        .toList();

    return resultAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: TextStyle(color: context.textSecondary)),
      ),
      data: (result) => CustomScrollView(
        slivers: [
          // ── 1. Next Festival Banner ────────────────────────────────────────
          SliverToBoxAdapter(
            child: result != null
                ? _NextFestivalBanner(result: result, ref: ref)
                : _NoUpcomingFestival(),
          ),

          // ── 2. Festival Timeline ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FestivalTimeline(
              festivals: next12Months,
              selectedIndex: selectedIndex,
              onSelect: (i) =>
                  ref.read(selectedFestivalIndexProvider.notifier).state = i,
            ),
          ),

          // ── 3. Selected Festival Detail Panel ─────────────────────────────
          if (next12Months.isNotEmpty)
            SliverToBoxAdapter(
              child: _SelectedFestivalPanel(
                festival: next12Months[selectedIndex.clamp(0, next12Months.length - 1)],
                ref: ref,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Next Festival Banner ──────────────────────────────────────────────────────

class _NextFestivalBanner extends StatelessWidget {
  final FestivalPlanResult result;
  final WidgetRef ref;
  const _NextFestivalBanner({required this.result, required this.ref});

  List<Color> _gradientColors(FestivalType type) {
    switch (type) {
      case FestivalType.mixed: // Diwali etc.
        return [const Color(0xFFE65100), const Color(0xFFF57C00), const Color(0xFFFFB300)];
      case FestivalType.travel:
        return [const Color(0xFF1B5E20), const Color(0xFF2E7D32), const Color(0xFFC62828)];
      case FestivalType.shopping:
        return [const Color(0xFF4A148C), const Color(0xFF6A1B9A), const Color(0xFF8E24AA)];
      case FestivalType.gifting:
        return [const Color(0xFF004D40), const Color(0xFF00695C), const Color(0xFFF9A825)];
      case FestivalType.food:
        return [const Color(0xFF880E4F), const Color(0xFFC2185B), const Color(0xFFFF8F00)];
    }
  }

  void _showBudgetDialog(BuildContext context) {
    final ctrl = TextEditingController(
        text: result.estimatedBudget > 0
            ? result.estimatedBudget.toStringAsFixed(0)
            : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (innerCtx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(innerCtx).viewInsets.bottom),
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
              Text(
                '${result.festival.emoji} ${result.festival.name} Budget',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Set your total budget for this festival.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: context.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: 'e.g. ${result.estimatedBudget.toStringAsFixed(0)}',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final amt = double.tryParse(ctrl.text.trim()) ?? 0.0;
                    ref
                        .read(festivalBudgetProvider(result.festival.name).notifier)
                        .setBudget(amt);
                    Navigator.pop(context);
                  },
                  child: const Text('Save Budget'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradientColors(result.festival.type);
    final dailySavings = result.dailySavingsNeeded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(result.festival.emoji,
                    style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.festival.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'in ${result.daysUntilFestival} days · '
                        '${DateFormat('d MMM yyyy').format(result.festival.nextDate)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _BannerStat(
                    label: 'Your Budget',
                    value: '₹${_fmt(result.estimatedBudget)}',
                    trailing: GestureDetector(
                      onTap: () => _showBudgetDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BannerStat(
                    label: 'Save per day',
                    value: '₹${_fmt(dailySavings)}',
                  ),
                ),
              ],
            ),
            if (result.lastYearSpend > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('📊',
                        style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Last year you spent ₹${_fmt(result.lastYearSpend)} on ${result.festival.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  const _BannerStat({required this.label, required this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _NoUpcomingFestival extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Row(
          children: [
            const Text('🗓️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'No festival in the next 60 days. Enjoy the quiet!',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Festival Timeline ─────────────────────────────────────────────────────────

class _FestivalTimeline extends StatelessWidget {
  final List<Festival> festivals;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _FestivalTimeline({
    required this.festivals,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (festivals.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              'Next 12 Months',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: festivals.length,
              itemBuilder: (context, i) {
                final f = festivals[i];
                final selected = i == selectedIndex;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : context.cardBorderColor,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(f.emoji,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          f.name.split(' ').first,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : context.textSecondary,
                          ),
                        ),
                        Text(
                          DateFormat('d MMM').format(f.nextDate),
                          style: TextStyle(
                            fontSize: 9,
                            color: selected
                                ? Colors.white70
                                : context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Selected Festival Panel ───────────────────────────────────────────────────

class _SelectedFestivalPanel extends ConsumerWidget {
  final Festival festival;
  final WidgetRef ref;
  const _SelectedFestivalPanel(
      {required this.festival, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final customBudget = widgetRef.watch(festivalBudgetProvider(festival.name));
    final daysLeft = festival.daysUntilNext;
    final tips = FestivalCalendar.tipsForType(festival.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Spend History ──────────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(festival.emoji,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        festival.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'in $daysLeft days',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'This is your first ${festival.name} with SpendLens — we will track your spending this year and give you a personalized estimate next time.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                          color: context.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: festival.spendCategories
                      .map((cat) => _CategoryChip(category: cat))
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Budget Planner ─────────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget Planner',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  festival.spendTheme,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: context.textMuted),
                ),
                const SizedBox(height: 16),
                if (customBudget != null && customBudget > 0) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Budget',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: context.textMuted)),
                            Text(
                              '₹${_fmt(customBudget)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Daily savings needed',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: context.textMuted)),
                          Text(
                            '₹${_fmt(customBudget / daysLeft.clamp(1, 9999))}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showBudgetDialog(
                          context, ref, festival, customBudget),
                      icon: const Icon(Icons.edit_rounded, size: 15),
                      label: const Text('Edit Budget'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.cardBorderColor),
                        foregroundColor: context.textSecondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Text('💡',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Suggested budget: ₹${_fmt(festival.avgSpendMultiplier * 15000)} '
                            '(${festival.avgSpendMultiplier}× avg monthly)',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: context.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          _showBudgetDialog(context, ref, festival, 0),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Set My Budget'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Smart Tips ────────────────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Tips for ${festival.name.split(' ').first}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                ...tips.asMap().entries.map((e) => _TipRow(
                      index: e.key + 1,
                      text: e.value,
                    )),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Reminder Button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _scheduleReminder(context, festival),
              icon: const Icon(Icons.notifications_none_rounded, size: 16),
              label: Text(
                  'Remind me 30 days before ${festival.name.split('/').first.trim()}'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.cardBorderColor),
                foregroundColor: context.textSecondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(
      BuildContext context, WidgetRef ref, Festival f, double current) {
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (innerCtx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(innerCtx).viewInsets.bottom),
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
              Text(
                '${f.emoji} ${f.name} Budget',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: 'Enter budget amount',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final amt = double.tryParse(ctrl.text.trim()) ?? 0.0;
                    ref
                        .read(festivalBudgetProvider(f.name).notifier)
                        .setBudget(amt);
                    Navigator.pop(context);
                  },
                  child: const Text('Save Budget'),
                ),
              ),
              if (current > 0) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      ref
                          .read(festivalBudgetProvider(f.name).notifier)
                          .clearBudget();
                      Navigator.pop(context);
                    },
                    child: Text('Remove Budget',
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

  void _scheduleReminder(BuildContext context, Festival f) {
    final reminderDate =
        f.nextDate.subtract(const Duration(days: 30));
    final daysUntilReminder =
        reminderDate.difference(DateTime.now()).inDays;

    final msg = daysUntilReminder > 0
        ? 'Reminder set for ${DateFormat('d MMM').format(reminderDate)} — $daysUntilReminder days from now'
        : '${f.name} is less than 30 days away — start planning now!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏰ $msg'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: child,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final int index;
  final String text;
  const _TipRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Formatters ────────────────────────────────────────────────────────────────

String _fmt(double amount) {
  final v = amount.abs();
  if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}
