import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/subscription_tier.dart';
import '../../providers/subscription_provider.dart';

/// Single "Go Pro" offer — one plan (₹99/mo), 7-day free trial, UPI auto-pay.
/// Replaces the old multi-tier (Plus/Pro/Family) paywall.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const _features = [
    ('🤖', 'AI Money Chatbot', 'Ask anything about your spending, get instant answers'),
    ('💰', 'Smart Micro-Savings', 'Auto-spot small daily saving opportunities'),
    ('🎉', 'Festival Budget Planner', 'Plan Diwali, Rakhi & more without overspending'),
    ('📈', 'Spend Predictions', 'See month-end forecasts before you overshoot'),
    ('📊', 'Advanced Insights', 'Trends, anomalies & savings-rate analytics'),
    ('🚫', 'Ad-free, forever', 'A clean, distraction-free experience'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(subscriptionTierProvider);
    final billing = ref.watch(proBillingProvider);
    final isPro = tier != SubscriptionTier.free;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(onClose: () => context.pop())),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (isPro)
                  _ActivePill(billing: billing)
                else
                  const _PriceLine(),
                const SizedBox(height: 20),
                ..._features.map((f) => _FeatureRow(f.$1, f.$2, f.$3)),
                const SizedBox(height: 24),
                if (!isPro)
                  _CtaButton(
                    label: 'Start 7-Day Free Trial',
                    onPressed: () => _startTrialFlow(context, ref),
                  )
                else
                  _ManageButton(onCancel: () => _confirmCancel(context, ref)),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    isPro
                        ? 'You have full access to all Pro features'
                        : 'Free for 7 days · then ₹99/month · cancel anytime',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
                if (!isPro)
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text('Maybe later',
                          style: TextStyle(color: context.textSecondary)),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Trial flow: UPI entry → simulated redirect → activate ──────────────────

  Future<void> _startTrialFlow(BuildContext context, WidgetRef ref) async {
    final upi = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _UpiSheet(),
    );
    if (upi == null || upi.isEmpty || !context.mounted) return;

    // Step 1: send the user to their UPI app to AUTHORIZE an autopay mandate.
    // (No money moves now — a mandate just pre-authorizes the future charge.)
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set up AutoPay',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'You\'ll be taken to your UPI app (e.g. Google Pay) to approve an '
          'AutoPay mandate for $upi.\n\nNothing is charged now — ₹99/month '
          'starts only after your 7-day free trial, and you can cancel anytime.',
          style: TextStyle(color: context.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open UPI app'),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;

    // Step 2: attempt to open a UPI app for mandate authorization. We do NOT
    // collect money — this is a setup-mandate intent. If no UPI app handles it
    // we continue with the in-app authorization step.
    await _openUpiMandate(upi);

    // Step 3: confirm the mandate was enabled.
    if (!context.mounted) return;
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm AutoPay',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Did you approve the AutoPay mandate in your UPI app? '
          'Confirm to start your free trial.',
          style: TextStyle(color: context.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Not yet', style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('AutoPay enabled ✓'),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return;

    await ref.read(subscriptionTierProvider.notifier).startProTrial(upi);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉  You\'re on Pro!',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Your 7-day free trial is active and AutoPay is set up for $upi. '
          'No money has been deducted. ₹99 will be auto-debited only after the '
          'trial ends — cancel anytime before then and pay nothing.',
          style: TextStyle(color: context.textSecondary, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Explore Pro'),
          ),
        ],
      ),
    );
    if (context.mounted) context.pop();
  }

  /// Opens a UPI app to authorize an autopay mandate. Best-effort: if no app
  /// handles the intent (or on desktop/web), we silently fall through to the
  /// in-app confirmation. No funds are transferred.
  Future<void> _openUpiMandate(String upi) async {
    try {
      final uri = Uri.parse(
          'upi://mandate?pa=$upi&pn=SpendLens&am=99&cu=INR&tn=SpendLens%20Pro');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // No UPI app / unsupported — continue with in-app confirmation.
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Pro?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'You\'ll keep Pro until the current period ends, then return to Free. '
          'No further charges.',
          style: TextStyle(color: context.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Keep Pro', style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Pro'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(subscriptionTierProvider.notifier).downgrade();
    }
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientMid, AppColors.gradientEnd],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -0.6),
                  radius: 1.2,
                  colors: [Colors.white.withValues(alpha: 0.14), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
            ),
          ),
          Positioned(
            bottom: 34,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                      child: Text('👑', style: TextStyle(fontSize: 32))),
                ),
                const SizedBox(height: 12),
                const Text('SpendLens Pro',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: '₹99',
                  style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w900)),
              TextSpan(
                  text: ' /month',
                  style: TextStyle(color: context.textSecondary, fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 4),
          const Text('First 7 days free',
              style: TextStyle(
                  color: AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  final ProBilling billing;
  const _ActivePill({required this.billing});

  @override
  Widget build(BuildContext context) {
    final trialLeft = billing.trialDaysLeft;
    final msg = (trialLeft != null && trialLeft >= 0)
        ? 'Free trial · $trialLeft days left'
        : 'Pro active';
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg,
                    style: const TextStyle(
                        color: AppColors.success, fontWeight: FontWeight.w700)),
                if (billing.upiId != null)
                  Text('Auto-pay ₹${billing.price} · ${billing.upiId}',
                      style: TextStyle(color: context.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji, title, subtitle;
  const _FeatureRow(this.emoji, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cardBorderColor),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: context.textSecondary, fontSize: 12.5, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _CtaButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientMid]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.gradientStart.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _ManageButton extends StatelessWidget {
  final VoidCallback onCancel;
  const _ManageButton({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('Cancel subscription'),
      ),
    );
  }
}

// ── UPI entry sheet ─────────────────────────────────────────────────────────────

class _UpiSheet extends StatefulWidget {
  const _UpiSheet();
  @override
  State<_UpiSheet> createState() => _UpiSheetState();
}

class _UpiSheetState extends State<_UpiSheet> {
  final _controller = TextEditingController();
  String? _error;

  bool _validUpi(String v) =>
      RegExp(r'^[\w.\-]{2,256}@[a-zA-Z0-9]{2,}$').hasMatch(v.trim());

  void _submit() {
    final v = _controller.text.trim();
    if (!_validUpi(v)) {
      setState(() => _error = 'Enter a valid UPI ID (e.g. name@oksbi)');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.cardBorderColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Set up UPI auto-pay',
              style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'No charge for 7 days. We\'ll set up a UPI mandate so ₹99/month is '
            'auto-debited after your free trial. Cancel anytime.',
            style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(color: context.textPrimary),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ],
            decoration: InputDecoration(
              hintText: 'yourname@oksbi',
              hintStyle: TextStyle(color: context.textMuted),
              errorText: _error,
              filled: true,
              fillColor: context.cardColor,
              prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                  size: 20, color: context.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.cardBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _submit,
              child: const Text('Continue to UPI',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 13, color: context.textMuted),
                const SizedBox(width: 6),
                Text('Secured by your UPI app · we never see your PIN',
                    style: TextStyle(color: context.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
