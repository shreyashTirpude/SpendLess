import '../../../domain/models/partner_suggestion.dart';
import '../../../domain/models/transaction.dart';

class ContextualAdEngine {
  static const List<PartnerSuggestion> _partners = [
    PartnerSuggestion(
      id: 'swiggy_one',
      partnerName: 'Swiggy One',
      headline: 'Save up to ₹600/month on food',
      subtext: 'You spend heavily on food orders',
      ctaLabel: 'View Membership',
      affiliateUrl: 'https://www.swiggy.com/one',
      triggerCategory: 'Food & Dining',
      triggerAmount: 1500,
      iconEmoji: '🍔',
      colorHex: '#FF6B35',
    ),
    PartnerSuggestion(
      id: 'groww_sip',
      partnerName: 'Groww',
      headline: 'Start a SIP with ₹100/month',
      subtext: 'Salary received — make it grow',
      ctaLabel: 'Start Investing',
      affiliateUrl: 'https://groww.in',
      triggerCategory: 'Income',
      triggerAmount: 10000,
      iconEmoji: '📈',
      colorHex: '#00D09C',
    ),
    PartnerSuggestion(
      id: 'zerodha_kite',
      partnerName: 'Zerodha',
      headline: 'India\'s #1 stock broker, ₹0 account opening',
      subtext: 'Put your savings to work',
      ctaLabel: 'Open Free Account',
      affiliateUrl: 'https://zerodha.com/open-account',
      triggerCategory: 'Income',
      triggerAmount: 20000,
      iconEmoji: '📊',
      colorHex: '#387ED1',
    ),
  ];

  static PartnerSuggestion? getSuggestion({
    required List<Transaction> thisMonthTransactions,
    required Set<String> dismissedPartnerIds,
    required DateTime? lastSuggestionShown,
  }) {
    if (lastSuggestionShown != null) {
      final daysSince = DateTime.now().difference(lastSuggestionShown).inDays;
      if (daysSince < 7) return null;
    }

    final Map<String, double> categoryTotals = {};
    for (final t in thisMonthTransactions) {
      if (t.isIgnored || t.isCredit) continue;
      categoryTotals[t.category] =
          (categoryTotals[t.category] ?? 0) + t.amount;
    }

    PartnerSuggestion? bestMatch;
    double bestSpend = 0;

    for (final partner in _partners) {
      if (dismissedPartnerIds.contains(partner.id)) continue;
      final spend = categoryTotals[partner.triggerCategory] ?? 0;
      if (spend >= partner.triggerAmount && spend > bestSpend) {
        bestSpend = spend;
        bestMatch = partner;
      }
    }

    return bestMatch;
  }
}
