enum SubscriptionTier { free, plus, pro, family }

extension SubscriptionTierX on SubscriptionTier {
  String get displayName => switch (this) {
        SubscriptionTier.free => 'Free',
        SubscriptionTier.plus => 'Plus',
        SubscriptionTier.pro => 'Pro',
        SubscriptionTier.family => 'Family',
      };

  int get monthlyPrice => switch (this) {
        SubscriptionTier.free => 0,
        SubscriptionTier.plus => 99,
        SubscriptionTier.pro => 299,
        SubscriptionTier.family => 449,
      };

  int get annualPrice => switch (this) {
        SubscriptionTier.free => 0,
        SubscriptionTier.plus => 799,
        SubscriptionTier.pro => 1999,
        SubscriptionTier.family => 2999,
      };

  // Annual saving vs paying monthly for 12 months
  int get annualSaving => monthlyPrice > 0 ? (monthlyPrice * 12) - annualPrice : 0;

  bool get isAdFree => this != SubscriptionTier.free;
  bool get hasChatbot =>
      this == SubscriptionTier.pro || this == SubscriptionTier.family;
  bool get hasMicroSavings =>
      this == SubscriptionTier.pro || this == SubscriptionTier.family;
  bool get hasSpendPrediction => this != SubscriptionTier.free;
  bool get hasAutopayAnalysis => this != SubscriptionTier.free;
  bool get hasCategoryDrilldown => this != SubscriptionTier.free;
  bool get hasFestivalPlanner =>
      this == SubscriptionTier.pro || this == SubscriptionTier.family;
  bool get hasSharedWallet => this == SubscriptionTier.family;

  /// Check access by feature name string (used by isFeatureAvailableProvider).
  bool hasFeature(String feature) => switch (feature) {
        'adFree' => isAdFree,
        'chatbot' => hasChatbot,
        'microSavings' => hasMicroSavings,
        'spendPrediction' => hasSpendPrediction,
        'autopayAnalysis' => hasAutopayAnalysis,
        'categoryDrilldown' => hasCategoryDrilldown,
        'festivalPlanner' => hasFestivalPlanner,
        'sharedWallet' => hasSharedWallet,
        _ => false,
      };
}
