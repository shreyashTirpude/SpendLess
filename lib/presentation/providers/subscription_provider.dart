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

  Future<void> downgrade() async {
    await HiveService.settings.put('subscriptionTier', SubscriptionTier.free.name);
    await HiveService.settings.put('tierExpiry', '');
    if (AuthService.isLoggedIn) {
      await AuthService.setMembership(tier: 'free');
    }
    state = SubscriptionTier.free;
  }

  void refresh() => state = _loadTier();
}

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
