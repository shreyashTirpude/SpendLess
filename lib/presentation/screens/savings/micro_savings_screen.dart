import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/micro_savings_provider.dart';

// ─── Paywall (reused pattern — same as chat_screen.dart) ─────────────────────

class _ProPaywallScreen extends StatelessWidget {
  final String featureName;
  const _ProPaywallScreen({required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: context.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Pro Feature',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '$featureName is available on the Pro plan.\nUpgrade to unlock personalised savings opportunities.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientMid,
                          AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Upgrade flow coming soon!')),
                      );
                    },
                    child: const Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text('Maybe later',
                    style: TextStyle(color: context.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tier check ───────────────────────────────────────────────────────────────

bool _isProUser() => true; // TODO: wire to real tier provider when available

// ─── Color helpers ────────────────────────────────────────────────────────────

Color _categoryColor(SavingCategory cat) {
  switch (cat) {
    case SavingCategory.food:
      return AppColors.catFood;
    case SavingCategory.subscription:
      return AppColors.catEntertainment;
    case SavingCategory.habit:
      return AppColors.catShopping;
    case SavingCategory.general:
      return AppColors.primary;
  }
}

Color _categoryBg(SavingCategory cat, bool isDark) {
  switch (cat) {
    case SavingCategory.food:
      return isDark ? AppColors.errorBg : AppColors.errorBgLight;
    case SavingCategory.subscription:
      return isDark ? AppColors.warningBg : AppColors.warningBgLight;
    case SavingCategory.habit:
      return isDark
          ? const Color(0xFF1A1030)
          : const Color(0xFFF5F0FF);
    case SavingCategory.general:
      return isDark ? AppColors.surface : AppColors.surfaceLight;
  }
}

// ─── Main screen ──────────────────────────────────────────────────────────────

class MicroSavingsScreen extends ConsumerWidget {
  const MicroSavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isProUser()) {
      return const _ProPaywallScreen(featureName: 'Micro Savings');
    }

    final savingsAsync = ref.watch(microSavingsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: savingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Could not load savings data',
                style: TextStyle(color: context.textSecondary)),
          ),
          data: (opportunities) =>
              _MicroSavingsBody(opportunities: opportunities),
        ),
      ),
    );
  }
}

class _MicroSavingsBody extends StatelessWidget {
  final List<SavingOpportunity> opportunities;
  const _MicroSavingsBody({required this.opportunities});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###', 'en_IN');
    final totalMonthly =
        opportunities.fold<double>(0, (s, o) => s + o.monthlySaving);

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BackButton(
                      color: context.textPrimary,
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(EdgeInsets.zero),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Micro Savings',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Text(
                    'Personalised for you',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Total savings potential card ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: _TotalSavingsCard(totalMonthly: totalMonthly, fmt: fmt),
          ),
        ),

        // ── Empty state ──────────────────────────────────────────────────────
        if (opportunities.isEmpty)
          SliverFillRemaining(
            child: _EmptyState(),
          )
        else ...[
          // ── Section label ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '${opportunities.length} opportunit${opportunities.length == 1 ? 'y' : 'ies'} found',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
          ),

          // ── Opportunity cards ────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final opp = opportunities[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _OpportunityCard(opportunity: opp, fmt: fmt),
                );
              },
              childCount: opportunities.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ],
    );
  }
}

// ─── Total savings card ───────────────────────────────────────────────────────

class _TotalSavingsCard extends StatelessWidget {
  final double totalMonthly;
  final NumberFormat fmt;
  const _TotalSavingsCard({required this.totalMonthly, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final annual = totalMonthly * 12;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientMid,
              AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💰', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Total Savings Potential',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            totalMonthly > 0
                ? 'You could save ₹${fmt.format(totalMonthly.round())}/month'
                : 'Keep tracking to unlock savings!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          if (annual > 0) ...[
            const SizedBox(height: 6),
            Text(
              'That\'s ₹${fmt.format(annual.round())} saved in a year',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Opportunity card ─────────────────────────────────────────────────────────

class _OpportunityCard extends StatelessWidget {
  final SavingOpportunity opportunity;
  final NumberFormat fmt;
  const _OpportunityCard({required this.opportunity, required this.fmt});

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OpportunityDetailSheet(
          opportunity: opportunity, fmt: fmt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(opportunity.category);
    final bg = _categoryBg(opportunity.category, context.isDark);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.cardBorderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(opportunity.icon,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opportunity.description,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Save ₹${fmt.format(opportunity.monthlySaving.round())}/mo'
                          ' → ₹${fmt.format(opportunity.annualSaving.round())}/yr',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.chevron_right_rounded,
                  color: context.textMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail bottom sheet ──────────────────────────────────────────────────────

class _OpportunityDetailSheet extends StatelessWidget {
  final SavingOpportunity opportunity;
  final NumberFormat fmt;
  const _OpportunityDetailSheet(
      {required this.opportunity, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(opportunity.category);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 20),

          // Icon + title
          Row(
            children: [
              Text(opportunity.icon,
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  opportunity.title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            opportunity.description,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Monthly',
                  value: '₹${fmt.format(opportunity.monthlySaving.round())}',
                  color: color,
                  context: context,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  label: 'Annually',
                  value: '₹${fmt.format(opportunity.annualSaving.round())}',
                  color: AppColors.success,
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('${opportunity.actionLabel} — coming soon!')),
                );
              },
              child: Text(
                opportunity.actionLabel,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final BuildContext context;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: context.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              'Not enough data yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep tracking! We need 30+ days of data to find personalised savings opportunities.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
