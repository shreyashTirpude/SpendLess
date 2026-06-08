import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CategoryEngine {
  // Named business/brand keywords checked BEFORE send-money signals
  static const Map<String, List<String>> _rules = {
    'Food & Dining': [
      'zomato', 'swiggy', 'blinkit', 'zepto', 'bigbasket', 'grofers',
      'dunzo', 'dominos', 'pizza hut', 'mcdonalds', 'kfc', 'subway',
      'burger king', 'starbucks', 'cafe coffee day', 'ccd', 'haldirams',
      'barbeque nation', 'barbeque', 'food', 'restaurant', 'cafe',
      'dhaba', 'eatery', 'kitchen', 'swiggy instamart', 'milkbasket',
      'fresh menu', 'faasos', 'box8', 'rebel foods', 'instacart',
      'eat', 'dine', 'biryani', 'hotel restaurant',
    ],
    'Transport': [
      'uber', 'ola', 'rapido', 'meru', 'indrive', 'yulu',
      'metro', 'dmrc', 'bmtc', 'ksrtc', 'msrtc', 'best bus',
      'irctc', 'indian rail', 'railway', 'train ticket',
      'indigo', 'air india', 'spicejet', 'goair', 'vistara', 'akasa air',
      'petrol', 'fuel', 'hp petrol', 'iocl', 'bpcl', 'shell',
      'parking', 'fastag', 'toll', 'cab', 'taxi', 'bus pass',
      'flight', 'airways', 'airlines', 'makemytrip', 'goibibo',
      'redbus', 'abhibus', 'easy my trip',
    ],
    'Shopping': [
      'amazon', 'flipkart', 'myntra', 'ajio', 'nykaa', 'meesho',
      'snapdeal', 'tatacliq', 'croma', 'reliance digital', 'vijay sales',
      'dmart', 'big bazaar', 'reliance fresh', 'more supermarket',
      'mall', 'retail', 'hypermarket', 'supermarket', 'mart', 'bazaar',
      'shoppers stop', 'lifestyle', 'westside', 'pantaloons',
      'h&m', 'zara', 'max fashion', 'decathlon', 'ikea',
      'lenskart', 'purplle', 'mamaearth', 'boat ', 'oneplus',
    ],
    'Entertainment': [
      'netflix', 'spotify', 'amazon prime', 'hotstar', 'disney+',
      'zee5', 'sonyliv', 'voot', 'mxplayer', 'jiocinema',
      'bookmyshow', 'pvr', 'inox', 'cinepolis', 'carnival cinemas',
      'gaming', 'steam', 'google play', 'apple itunes', 'app store',
      'xbox', 'playstation', 'epic games', 'ea games',
      'youtube premium', 'audible', 'kindle',
    ],
    'Bills & Utilities': [
      'electricity', 'bescom', 'msedcl', 'tneb', 'tata power',
      'water bill', 'gas cylinder', 'indane', 'hp gas', 'bharat gas',
      'airtel', 'jio', 'vi ', 'vodafone', 'idea', 'bsnl',
      'broadband', 'internet', 'recharge', 'mobile bill',
      'dish tv', 'tata sky', 'd2h', 'sun direct', 'cable tv',
      'maintenance', 'society', 'rent', 'emi', 'loan emi',
    ],
    'Health': [
      'pharmacy', 'medplus', 'netmeds', '1mg', 'pharmeasy',
      'apollo pharmacy', 'hospital', 'clinic', 'lab ', 'diagnostic',
      'pathology', 'doctor', 'dental', 'optical', 'medical',
      'health', 'gym', 'cult fit', 'cure fit', 'yoga', 'fitness',
      'wellness', 'healthkart', 'tata health', 'practo',
    ],
    'Education': [
      "byju", 'unacademy', 'vedantu', 'whitehat', 'toppr',
      'coursera', 'udemy', 'udacity', 'skillshare', 'linkedin learning',
      'school fees', 'college fees', 'tuition', 'coaching',
      'exam fee', 'admission fee', 'university', 'institute',
      'merit nation', 'simplilearn',
    ],
    'Investment': [
      'zerodha', 'groww', 'upstox', 'kuvera', 'coin by zerodha',
      'icicidirect', 'hdfcsec', 'motilal oswal', 'angel broking',
      'sip', 'mutual fund', 'mf ', 'nps', 'ppf',
      'lic', 'insurance', 'rd ', 'fd ', 'fixed deposit',
      'sovereign gold', 'stock', 'shares', 'smallcase',
      'paytm money', 'etmoney',
    ],
    'ATM & Cash': [
      'atm', 'cash withdrawal', 'cash advance', 'atm wd',
      'cash deposit',
    ],
    'Groceries': [
      'kirana', 'grocery', 'vegetables', 'fruits', 'milk', 'dairy',
      'nature\'s basket', 'heritage fresh', 'lulu hypermarket',
      'jiomart', 'instamart', 'quick commerce', 'fresh produce',
      'daily basket', 'spencers', 'reliance smart',
    ],
    'Travel & Hotels': [
      'hotel', 'oyo', 'treebo', 'fabhotel', 'lemon tree', 'marriott',
      'hilton', 'taj hotel', 'itc hotel', 'airbnb', 'booking.com',
      'expedia', 'mmt hotel', 'goibibo hotel', 'stayfit',
      'resort', 'hostel', 'lodging', 'accommodation',
      'cleartrip', 'yatra', 'holiday', 'travel package',
    ],
    'Personal Care': [
      'salon', 'spa', 'haircut', 'parlour', 'lakme', 'vlcc',
      'jawed habib', 'naturals', 'ustraa', 'bombay shaving', 'beardo',
      'dermatologist', 'skincare', 'grooming', 'manicure', 'pedicure',
      'loreal', 'garnier', 'dove', 'nivea', 'himalaya',
    ],
    'Fuel': [
      'petrol pump', 'nayara', 'reliance bp', 'fuel fill',
      'cng', 'lpg', 'diesel fill',
    ],
    'Subscriptions': [
      'membership', 'annual plan', 'monthly plan', 'subscription',
      'prime membership', 'hotstar subscription', 'netflix bill',
      'spotify premium', 'adobe', 'microsoft 365', 'google one',
      'icloud', 'dropbox', 'notion', 'slack',
    ],
    'Rent & EMI': [
      'house rent', 'flat rent', 'pg rent', 'home loan emi',
      'home loan', 'car loan', 'vehicle loan', 'personal loan',
      'society maintenance', 'property tax',
    ],
    'Charity & Gifts': [
      'donation', 'charity', 'ngo', 'give india', 'ketto',
      'milaap', 'crowdfunding', 'temple', 'church donation', 'masjid',
      'gift', 'birthday gift', 'wedding gift', 'flowers',
    ],
  };

  // Send Money signals — checked AFTER named categories
  static const _sendMoneySignals = [
    'upi', 'neft', 'imps', 'rtgs', 'p2p', 'peer to peer',
    'money transfer', 'fund transfer', 'bank transfer',
    'gpay', 'phonepe', 'paytm', 'bhim', 'mobikwik',
    'transfer to', 'sent to', 'paid to',
    '@okicici', '@okhdfcbank', '@oksbi', '@okaxis',
    '@ybl', '@ibl', '@axl', '@paytm', '@waicici',
  ];

  /// Primary categorization using raw SMS body + merchant name.
  /// Named categories are checked first; UPI/transfer signals last.
  static String categorizeFromSms(String rawSms, String merchant, bool isCredit) {
    if (isCredit) {
      final body = '${rawSms.toLowerCase()} ${merchant.toLowerCase()}';
      if (body.contains('salary') || body.contains('payroll')) return 'Salary';
      if (body.contains('refund') || body.contains('cashback') || body.contains('reversal')) return 'Refund';
      return 'Income';
    }

    final body = '${rawSms.toLowerCase()} ${merchant.toLowerCase()}';

    // Named categories first
    for (final entry in _rules.entries) {
      if (entry.value.any((kw) => body.contains(kw))) return entry.key;
    }

    // Send Money (UPI P2P, NEFT, etc.)
    if (_sendMoneySignals.any((kw) => body.contains(kw))) return 'Send Money';

    return 'Other';
  }

  /// Legacy fallback used in manual-entry flows where no raw SMS is available.
  static String categorize(String merchant, bool isCredit) =>
      categorizeFromSms('', merchant, isCredit);

  // ─── Display helpers ────────────────────────────────────────────────────────

  static const List<String> expenseCategories = [
    'Send Money',
    'Food & Dining',
    'Groceries',
    'Transport',
    'Fuel',
    'Shopping',
    'Entertainment',
    'Subscriptions',
    'Bills & Utilities',
    'Rent & EMI',
    'Health',
    'Personal Care',
    'Education',
    'Investment',
    'Travel & Hotels',
    'Charity & Gifts',
    'ATM & Cash',
    'Other',
  ];

  static Color getCategoryFlutterColor(String category) {
    const map = {
      'Send Money': AppColors.catSendMoney,
      'Food & Dining': AppColors.catFood,
      'Groceries': Color(0xFF84CC16),
      'Transport': AppColors.catTransport,
      'Fuel': Color(0xFFF97316),
      'Shopping': AppColors.catShopping,
      'Entertainment': AppColors.catEntertainment,
      'Subscriptions': Color(0xFF8B5CF6),
      'Bills & Utilities': AppColors.catBills,
      'Rent & EMI': Color(0xFFEF4444),
      'Health': AppColors.catHealth,
      'Personal Care': Color(0xFFF472B6),
      'Education': AppColors.catEducation,
      'Investment': AppColors.catInvestment,
      'Travel & Hotels': Color(0xFF06B6D4),
      'Charity & Gifts': Color(0xFFEC4899),
      'Income': AppColors.catIncome,
      'Salary': AppColors.catIncome,
      'Refund': AppColors.catEducation,
      'ATM & Cash': AppColors.catAtm,
    };
    return map[category] ?? AppColors.catOther;
  }

  static String getCategoryColor(String category) {
    const colors = {
      'Send Money': '#EC4899',
      'Food & Dining': '#FF6B6B',
      'Groceries': '#84CC16',
      'Transport': '#4ECDC4',
      'Fuel': '#F97316',
      'Shopping': '#A78BFA',
      'Entertainment': '#F59E0B',
      'Subscriptions': '#8B5CF6',
      'Bills & Utilities': '#60A5FA',
      'Rent & EMI': '#EF4444',
      'Health': '#FC8181',
      'Personal Care': '#F472B6',
      'Education': '#34D399',
      'Investment': '#10B981',
      'Travel & Hotels': '#06B6D4',
      'Charity & Gifts': '#EC4899',
      'Income': '#10B981',
      'Salary': '#10B981',
      'Refund': '#34D399',
      'ATM & Cash': '#94A3B8',
    };
    return colors[category] ?? '#6B7280';
  }

  static String getCategoryIcon(String category) {
    const icons = {
      'Send Money': '💸',
      'Food & Dining': '🍔',
      'Groceries': '🛒',
      'Transport': '🚗',
      'Fuel': '⛽',
      'Shopping': '🛍️',
      'Entertainment': '🎬',
      'Subscriptions': '📺',
      'Bills & Utilities': '⚡',
      'Rent & EMI': '🏠',
      'Health': '🏥',
      'Personal Care': '💆',
      'Education': '📚',
      'Investment': '📈',
      'Travel & Hotels': '✈️',
      'Charity & Gifts': '🎁',
      'Income': '💰',
      'Salary': '💰',
      'Refund': '↩️',
      'ATM & Cash': '🏧',
      'Other': '💳',
    };
    return icons[category] ?? '💳';
  }
}
