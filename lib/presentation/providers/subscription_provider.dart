import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';
import '../../domain/models/subscription_tier.dart';
import '../../services/auth/auth_service.dart';

// ── Subscription Tier Notifier ─────────────────────────────────────────────────

class SubscriptionTierNotifier extends StateNotifier<SubscriptionTier> {
  SubscriptionTierNotifier() : super(_loadTier());

  static SubscriptionTier _loadTier() {
    // Prefer the authenticated account's tier (it carries expiry + auto-downgrade).
    final account = AuthService.currentUser;
    if (account != null) {
      // currentUser already enforces expiry, downgrading to free if lapsed.
      return _parse(account.tier);
    }
    final raw = HiveService.settings.get('subscriptionTier',
        defaultValue: 'free') as String;
    return _parse(raw);
  }

  static SubscriptionTier _parse(String raw) => SubscriptionTier.values
      .firstWhere((t) => t.name == raw, orElse: () => SubscriptionTier.free);

  /// Upgrade to [tier] for [durationDays]. Persists to both the account
  /// (for expiry tracking) and settings (for logged-out demo).
  Future<void> upgradeTo(SubscriptionTier tier, {int durationDays = 30}) async {
    await HiveService.settings.put('subscriptionTier', tier.name);
    if (AuthService.isLoggedIn) {
      await AuthService.setMembership(
          tier: tier.name, durationDays: durationDays);
    } else {
      await HiveService.settings.put(
        'tierExpiry',
        tier == SubscriptionTier.free
            ? ''
            : DateTime.now().add(Duration(days: durationDays)).toIso8601String(),
      );
    }
    state = tier;
  }

  /// Start the single Pro plan with a 7-day free trial. After the trial the
  /// plan renews at ₹99/month via the provided UPI ID (auto-deduct). Features
  /// unlock immediately for the whole period.
  Future<void> startProTrial(String upiId) async {
    const trialDays = 7;
    final now = DateTime.now();
    final firstCharge = now.add(const Duration(days: trialDays));
    await HiveService.settings.put('pro_upi_id', upiId);
    await HiveService.settings.put('pro_trial_start', now.toIso8601String());
    await HiveService.settings.put('pro_first_charge', firstCharge.toIso8601String());
    await HiveService.settings.put('pro_auto_renew', true);
    await HiveService.settings.put('pro_price', 99);
    // Unlock Pro for trial + first paid month (37 days) so it doesn't lapse
    // mid-trial; renewal logic extends this on each simulated charge.
    await upgradeTo(SubscriptionTier.pro, durationDays: trialDays + 30);
  }

  Future<void> downgrade() async {
    await HiveService.settings.put('subscriptionTier', SubscriptionTier.free.name);
    await HiveService.settings.put('tierExpiry', '');
    await HiveService.settings.put('pro_auto_renew', false);
    if (AuthService.isLoggedIn) {
      await AuthService.setMembership(tier: 'free');
    }
    state = SubscriptionTier.free;
  }

  void refresh() => state = _loadTier();
}

/// Pro trial / billing details for display.
class ProBilling {
  final bool autoRenew;
  final String? upiId;
  final DateTime? firstCharge;
  final int price;
  const ProBilling({
    required this.autoRenew,
    this.upiId,
    this.firstCharge,
    this.price = 99,
  });

  int? get trialDaysLeft =>
      firstCharge == null ? null : firstCharge!.difference(DateTime.now()).inDays;
  bool get inTrial => (trialDaysLeft ?? -1) >= 0;
}

final proBillingProvider = Provider<ProBilling>((ref) {
  ref.watch(subscriptionTierProvider);
  final s = HiveService.settings;
  final fc = s.get('pro_first_charge', defaultValue: '') as String;
  return ProBilling(
    autoRenew: s.get('pro_auto_renew', defaultValue: false) as bool,
    upiId: (s.get('pro_upi_id', defaultValue: '') as String).isEmpty
        ? null
        : s.get('pro_upi_id') as String,
    firstCharge: fc.isEmpty ? null : DateTime.tryParse(fc),
    price: (s.get('pro_price', defaultValue: 99) as num).toInt(),
  );
});

final subscriptionTierProvider =
    StateNotifierProvider<SubscriptionTierNotifier, SubscriptionTier>(
  (ref) => SubscriptionTierNotifier(),
);

// ── Membership expiry ───────────────────────────────────────────────────────────

class MembershipInfo {
  final SubscriptionTier tier;
  final DateTime? expiry;
  const MembershipInfo(this.tier, this.expiry);

  int? get daysLeft =>
      expiry == null ? null : expiry!.difference(DateTime.now()).inDays;
  bool get isExpiringSoon => daysLeft != null && daysLeft! <= 7 && daysLeft! >= 0;
  bool get isActive => tier != SubscriptionTier.free;
}

/// Membership tier + expiry date for the countdown UI on the paywall/settings.
final membershipInfoProvider = Provider<MembershipInfo>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  DateTime? expiry;

  final account = AuthService.currentUser;
  if (account?.tierExpiry != null) {
    expiry = account!.tierExpiry;
  } else {
    final raw = HiveService.settings.get('tierExpiry', defaultValue: '') as String;
    if (raw.isNotEmpty) expiry = DateTime.tryParse(raw);
  }
  return MembershipInfo(tier, expiry);
});

// ── Per-feature gate provider ──────────────────────────────────────────────────
//
// Usage:  ref.watch(isFeatureAvailableProvider('chatbot'))
//
final isFeatureAvailableProvider =
    Provider.family<bool, String>((ref, feature) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.hasFeature(feature);
});
