class PartnerSuggestion {
  final String id;
  final String partnerName;
  final String headline;
  final String subtext;
  final String ctaLabel;
  final String affiliateUrl;
  final String triggerCategory;
  final double triggerAmount;
  final String iconEmoji;
  final String colorHex;

  const PartnerSuggestion({
    required this.id,
    required this.partnerName,
    required this.headline,
    required this.subtext,
    required this.ctaLabel,
    required this.affiliateUrl,
    required this.triggerCategory,
    required this.triggerAmount,
    required this.iconEmoji,
    required this.colorHex,
  });
}
