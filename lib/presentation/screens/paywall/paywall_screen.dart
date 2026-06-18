import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/subscription_tier.dart';
import '../../providers/subscription_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _upgrading = false;

  Future<void> _selectTier(SubscriptionTier tier) async {
    setState(() => _upgrading = true);
    await ref.read(subscriptionTierProvider.notifier).upgradeTo(tier);
    if (mounted) {
      setState(() => _upgrading = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(subscriptionTierProvider);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // ── Gradient header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _GradientHeader(onClose: () => context.pop()),
            ),

            // ── Tier cards ───────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _TierCard(
                    tier: SubscriptionTier.plus,
                    isCurrent: current == SubscriptionTier.plus,
                    isPopular: false,
                    features: const [
                      '🚫  Ad-free experience',
                      '📈  Spend Prediction',
                      '🔄  Autopay Analysis',
                      '🗂️  Category Drilldown',
                      '🏷️  Smart Categorization',
                    ],
                    onSelect: _upgrading ? null : () => _selectTier(SubscriptionTier.plus),
                  ),
                  const SizedBox(height: 12),
                  _TierCard(
                    tier: SubscriptionTier.pro,
                    isCurrent: current == SubscriptionTier.pro,
                    isPopular: true,
                    features: const [
                      '🚫  Ad-free experience',
                      '📈  Spend Prediction',
                      '🔄  Autopay Analysis',
                      '🗂️  Category Drilldown',
                      '🏷️  Smart Categorization',
                      '🤖  AI Chatbot',
                      '💰  Micro Savings',
                      '🎉  Festival Planner',
                    ],
                    onSelect: _upgrading ? null : () => _selectTier(SubscriptionTier.pro),
                  ),
                  const SizedBox(height: 12),
                  _TierCard(
                    tier: SubscriptionTier.family,
                    isCurrent: current == SubscriptionTier.family,
                    isPopular: false,
                    features: const [
                      '🚫  Ad-free experience',
                      '📈  Spend Prediction',
                      '🔄  Autopay Analysis',
                      '🗂️  Category Drilldown',
                      '🏷️  Smart Categorization',
                      '🤖  AI Chatbot',
                      '💰  Micro Savings',
                      '🎉  Festival Planner',
                      '👨‍👩‍👧‍👦  Up to 5 members',
                      '👛  Shared Wallet',
                      '🎯  Partner Goals',
                    ],
                    onSelect: _upgrading ? null : () => _selectTier(SubscriptionTier.family),
                  ),
                  const SizedBox(height: 24),

                  // ── Maybe later ──────────────────────────────────────────
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Maybe later',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient header ────────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _GradientHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
      ),
      child: Stack(
        children: [
          // Subtle radial shimmer for depth
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -0.6),
                  radius: 1.2,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
            ),
          ),

          // Title / subtitle
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  '✨ Go Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '7-day free trial — cancel anytime',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tier card ─────────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  final SubscriptionTier tier;
  final bool isCurrent;
  final bool isPopular;
  final List<String> features;
  final VoidCallback? onSelect;

  const _TierCard({
    required this.tier,
    required this.isCurrent,
    required this.isPopular,
    required this.features,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isPopular
        ? const Color(0xFFD4AF37) // golden
        : isCurrent
            ? AppColors.primary
            : AppColors.cardBorder;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isPopular ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tier.displayName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFD4AF37), width: 1),
                              ),
                              child: const Text(
                                'Most Popular',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '₹${tier.monthlyPrice}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(
                              text: '/mo',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Annual saving badge
                if (tier.annualSaving > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Save ₹${tier.annualSaving}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'annually',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 14),

            // ── Feature list ───────────────────────────────────────────
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  f,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── CTA button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Current Plan',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular
                            ? const Color(0xFFD4AF37)
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Start Free Trial · ${tier.displayName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
