import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/hive_service.dart';
import '../../domain/models/subscription_tier.dart';

// ── Subscription Tier Notifier ─────────────────────────────────────────────────

class SubscriptionTierNotifier extends StateNotifier<SubscriptionTier> {
  SubscriptionTierNotifier() : super(_loadTier());

  static SubscriptionTier _loadTier() {
    final raw = HiveService.settings.get(
      'subscriptionTier',
      defaultValue: 'free',
    ) as String;
    return SubscriptionTier.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => SubscriptionTier.free,
    );
  }

  Future<void> upgradeTo(SubscriptionTier tier) async {
    await HiveService.settings.put('subscriptionTier', tier.name);
    state = tier;
  }

  Future<void> downgrade() async {
    await HiveService.settings.put('subscriptionTier', SubscriptionTier.free.name);
    state = SubscriptionTier.free;
  }
}

final subscriptionTierProvider =
    StateNotifierProvider<SubscriptionTierNotifier, SubscriptionTier>(
  (ref) => SubscriptionTierNotifier(),
);

// ── Per-feature gate provider ──────────────────────────────────────────────────
//
// Usage:  ref.watch(isFeatureAvailableProvider('chatbot'))
//
final isFeatureAvailableProvider =
    Provider.family<bool, String>((ref, feature) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.hasFeature(feature);
});
