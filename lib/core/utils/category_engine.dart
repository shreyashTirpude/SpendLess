import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Categorises a transaction from SMS context, merchant name, VPA, and channel.
///
/// Category hierarchy (aligned with user's cashflow view):
///   Income:       Salary | Freelance | Refund | Interest
///   Send Money:   Friends | Family | Transfer
///   Food:         Food & Dining | Groceries
///   Transport:    Transport | Fuel
///   Shopping:     Shopping
///   Bills:        Bills & Utilities | Subscriptions
///   Finance:      Investment | Loan EMI | Insurance
///   Health:       Health
///   Travel:       Travel & Hotels
///   Education:    Education
///   Personal Care
///   Entertainment
///   Government
///   ATM & Cash
///   Other
class CategoryEngine {
  // ── VPA personal suffixes → triggers P2P detection ───────────────────────
  static const _personalSuffixes = {
    'ybl', 'ibl', 'axl',
    'oksbi', 'okaxis', 'okicici', 'okhdfcbank',
    'paytm', 'upi', 'apl',
    'sbi', 'icici', 'hdfcbank', 'axisbank', 'kotak',
    'yesbank', 'federal', 'indus', 'rbl',
  };

  // ── Named category keyword rules (checked in order) ─────────────────────

  static const Map<String, List<String>> _rules = {
    // ── Government / EPF / Tax ──────────────────────────────────────────────
    'Government': [
      'epfo', 'pf contribution', 'employees pf',
      'mnrega', 'mgnregs', 'nrega', 'pm kisan', 'pmkisan',
      'cbic', 'gstn', 'income tax', 'itd', 'direct tax',
      'nps', 'national pension', 'pfrda',
      'uidai', 'aadhaar', 'parivahan', 'passport seva',
      'bbps', 'bharatbill', 'municipal', 'mcd', 'nmmc', 'bmc', 'bbmp', 'ghmc',
    ],

    // ── Salary / Income ─────────────────────────────────────────────────────
    'Salary': [
      'salary', 'sal/', '/sal', 'sal-', 'sal credit',
      'payroll', 'stipend', 'wages', 'emolument',
      'monthly pay', 'pay credit', 'ctc',
    ],

    // ── Loan EMI (NACH/ECS auto-debit) ──────────────────────────────────────
    'Loan EMI': [
      'emi', 'equated monthly', 'loan emi', 'home loan', 'car loan',
      'vehicle loan', 'personal loan', 'education loan',
      'hdfc loan', 'sbi loan', 'icici loan', 'bajaj loan',
      'nach', 'ecs debit', 'auto debit', 'standing instruction',
      'si debit', 'lender', 'emi debit',
    ],

    // ── Rent ────────────────────────────────────────────────────────────────
    'Rent': [
      'house rent', 'flat rent', 'pg rent', 'hostel rent',
      'rent payment', 'room rent', 'property rent', 'society maintenance',
      'landlord',
    ],

    // ── Investment ──────────────────────────────────────────────────────────
    'Investment': [
      'zerodha', 'groww', 'upstox', 'kuvera', 'coin by zerodha',
      'icicidirect', 'hdfcsec', 'motilal oswal', 'angel broking',
      'angel one', 'smallcase', 'indmoney', 'fisdom',
      'sip', 'mutual fund', 'mf ', 'nps contribution', 'ppf',
      'sovereign gold', 'stock purchase', 'share purchase', 'etmoney',
      'paytm money', 'kite ',
    ],

    // ── Insurance ────────────────────────────────────────────────────────────
    'Insurance': [
      'lic ', 'lic premium', 'life insurance', 'health insurance',
      'policy premium', 'insurance premium', 'policybazaar', 'acko',
      'digit insurance', 'star health', 'hdfc life', 'max life',
      'icici pru', 'sbi life', 'tata aia',
    ],

    // ── Food Delivery ────────────────────────────────────────────────────────
    'Food & Dining': [
      'zomato', 'swiggy', 'dunzo', 'blinkit', 'box8', 'faasos',
      'rebel foods', 'eatfit', 'eat fit', 'freshmenu',
      'dominos', "domino's", 'pizza hut', 'mcdonalds', 'mcd',
      'kfc', 'burger king', 'subway', 'starbucks',
      'cafe coffee day', 'ccd', 'chaayos', 'haldirams',
      'barbeque nation', 'biryani', 'restaurant', 'cafe ',
      'dhaba', 'eatery', 'kitchen ', 'hotel restaurant', 'food ',
    ],

    // ── Groceries / Q-commerce ───────────────────────────────────────────────
    'Groceries': [
      'instamart', 'swiggy instamart', 'zepto',
      'bigbasket', 'big basket', 'jiomart', 'dmart', 'd-mart',
      'grofers', 'milkbasket', 'milk basket', 'country delight',
      'licious', 'grocery', 'kirana', 'vegetables', 'fruits',
      'supermarket', 'hypermarket', 'fresh produce',
      "nature's basket", 'spencers', 'big bazaar', 'reliance fresh',
      'more supermarket', 'more retail',
    ],

    // ── Transport ────────────────────────────────────────────────────────────
    'Transport': [
      'uber', 'ola ', 'rapido', 'namma yatri', 'meru', 'indrive',
      'yulu', 'bounce', 'blusmart',
      'metro', 'dmrc', 'bmtc', 'ksrtc', 'msrtc',
      'irctc', 'indian rail', 'railway', 'train ticket',
      'indigo', 'air india', 'spicejet', 'goair', 'vistara', 'akasa',
      'makemytrip', 'goibibo', 'redbus', 'abhibus', 'easemytrip',
      'cleartrip', 'yatra ', 'cab ', 'taxi ', 'bus ',
      'zoomcar', 'drivezy', 'ola electric',
    ],

    // ── Fuel ─────────────────────────────────────────────────────────────────
    'Fuel': [
      'petrol', 'fuel fill', 'hp petrol', 'iocl', 'bpcl petrol',
      'hpcl', 'nayara', 'indian oil petrol', 'shell ',
      'cng ', 'diesel fill', 'petrol pump', 'reliance bp',
      'fastag', 'nhai ', 'toll ',
    ],

    // ── Shopping — General ───────────────────────────────────────────────────
    'Shopping': [
      'amazon', 'flipkart', 'myntra', 'ajio', 'nykaa', 'meesho',
      'snapdeal', 'tatacliq', 'tata cliq', 'croma', 'reliance digital',
      'vijay sales', 'dmart', 'big bazaar',
      'shoppers stop', 'lifestyle ', 'westside', 'pantaloons',
      'h&m', 'zara ', 'max fashion', 'decathlon', 'ikea',
      'lenskart', 'puma', 'adidas', 'nike ', 'bata ',
      'firstcry', 'shopsy', 'hopscotch', 'fabindia',
      'urban ladder', 'pepperfry', 'samsung ', 'apple store',
      'mall ', 'retail ', 'online shop', 'ecommerce',
    ],

    // ── Entertainment ────────────────────────────────────────────────────────
    'Entertainment': [
      'bookmyshow', 'pvr ', 'inox ', 'cinepolis',
      'dream11', 'dream 11', 'mpl ', 'winzo', 'rummy circle',
      'steam ', 'google play', 'app store', 'epic games',
      'gaming ', 'xbox ', 'playstation', 'ea games',
    ],

    // ── Subscriptions ────────────────────────────────────────────────────────
    'Subscriptions': [
      'netflix', 'hotstar', 'disney+', 'disney plus', 'prime video',
      'amazon prime', 'zee5', 'sonyliv', 'voot ', 'jiocinema',
      'spotify', 'gaana ', 'jiosaavn', 'apple music', 'youtube premium',
      'membership', 'annual plan', 'monthly plan', 'subscription',
      'netflix bill', 'spotify premium', 'adobe ', 'microsoft 365',
      'google one', 'icloud', 'dropbox ', 'notion ', 'slack ', 'zoom ',
      'canva ',
    ],

    // ── Bills & Utilities ────────────────────────────────────────────────────
    'Bills & Utilities': [
      'electricity', 'bescom', 'msedcl', 'tata power', 'adani elec',
      'torrent power', 'tneb', 'tpddl', 'bses',
      'water bill', 'bwssb', 'nmmc water',
      'gas cylinder', 'indane', 'hp gas', 'bharat gas', 'piped gas',
      'mgl ', 'igl ', 'mahanagar gas',
      'airtel ', 'jio ', 'vi ', 'vodafone ', 'idea ', 'bsnl',
      'broadband', 'internet bill', 'mobile bill', 'recharge',
      'dish tv', 'tata play', 'd2h ', 'sun direct ', 'cable tv',
      'maintenance ', 'society fee',
    ],

    // ── Health ────────────────────────────────────────────────────────────────
    'Health': [
      'pharmacy', 'medplus', 'netmeds', '1mg', 'pharmeasy',
      'apollo pharmacy', 'hospital', 'clinic', 'lab ', 'diagnostic',
      'pathology', 'doctor', 'dental ', 'optical ', 'medical ',
      'health ', 'gym ', 'cult fit', 'cure fit', 'yoga ', 'fitness ',
      'healthkart', 'tata health', 'practo', 'mfine', 'aster ',
      'licious',
    ],

    // ── Education ─────────────────────────────────────────────────────────────
    'Education': [
      "byju", 'byjus', 'unacademy', 'vedantu', 'whitehat',
      'upgrad', 'toppr', 'coursera', 'udemy', 'physicswallah',
      'school fees', 'college fees', 'tuition', 'coaching ',
      'exam fee', 'admission fee', 'university ', 'institute ',
      'simplilearn', 'geeksforgeeks',
    ],

    // ── Travel & Hotels ───────────────────────────────────────────────────────
    'Travel & Hotels': [
      'hotel ', 'oyo ', 'treebo', 'fabhotel', 'lemon tree',
      'marriott', 'hilton', 'taj hotel', 'itc hotel', 'airbnb',
      'booking.com', 'expedia', 'cleartrip hotel', 'resort ',
      'hostel ', 'lodging ', 'accommodation', 'holiday ',
      'travel package',
    ],

    // ── Personal Care ─────────────────────────────────────────────────────────
    'Personal Care': [
      'salon ', 'spa ', 'haircut ', 'parlour ', 'lakme ',
      'vlcc ', 'jawed habib', 'naturals ', 'ustraa ',
      'bombay shaving', 'beardo ', 'dermatologist',
      'skincare ', 'grooming ', 'manicure ', 'pedicure ',
      'loreal', 'garnier ', 'dove ', 'nivea ', 'himalaya ',
      'nykaa beauty', 'mamaearth',
    ],

    // ── ATM & Cash ────────────────────────────────────────────────────────────
    'ATM & Cash': [
      'atm', 'cash withdrawal', 'cash advance', 'atm wd',
      'cash deposit', 'cdm ', 'atm cash',
    ],
  };

  // ── Merchant-only VPA prefixes → always P2B ──────────────────────────────
  static const _merchantVpaPrefixes = {
    'zomato', 'swiggy', 'uber', 'ola', 'rapido', 'amazon', 'flipkart',
    'myntra', 'ajio', 'netflix', 'spotify', 'hotstar', 'jio', 'airtel',
    'blinkit', 'zepto', 'bigbasket', 'irctc', 'dominos', 'kfc', 'mcdonalds',
    'paytm', 'phonepe', 'bookmyshow', 'pvr', 'inox', 'dream11', 'groww',
    'zerodha', 'upstox', 'cred', 'practo', 'nykaa', 'dmart', 'makemytrip',
    'oyo', 'pizza', 'subway', 'starbucks', 'dunzo', 'byjus', 'unacademy',
    'meesho', 'tatacliq', 'cleartrip', 'redbus', 'yatra', 'hdfc', 'sbi',
    'icici', 'axis', 'kotak', 'lic', 'epfo', 'indigo', 'vistara',
    'akasa', 'spicejet', 'hpcl', 'bpcl', 'iocl', 'fastag', 'google',
    'microsoft', 'adobe', 'canva', 'notion', 'slack', 'zoom',
  };

  // ── Primary categorisation ────────────────────────────────────────────────

  static String categorizeFromSms(
    String rawSms,
    String merchant, {
    required bool isCredit,
    String? vpa,
    String channel = 'UNKNOWN',
    bool isP2P = false,
  }) {
    final body = '${rawSms.toLowerCase()} ${merchant.toLowerCase()}';

    // ── Credits ──────────────────────────────────────────────────────────────
    if (isCredit) {
      if (_anyMatch(body, _rules['Salary']!)) return 'Salary';
      if (_anyMatch(body, ['refund', 'cashback', 'reversal'])) return 'Refund';
      if (_anyMatch(body, ['interest', 'int credit', 'fd interest'])) return 'Interest';
      // P2P credit from a known personal VPA → "Income Transfer"
      if (isP2P || (vpa != null && _isPersonalVpaLocal(vpa))) return 'Income Transfer';
      return 'Income';
    }

    // ── NACH/ECS debits → always Loan EMI or recurring bill ──────────────────
    if (channel == 'NACH') {
      if (_anyMatch(body, ['emi', 'loan', 'home loan', 'car loan', 'personal loan',
          'housing loan', 'vehicle loan', 'education loan'])) {
        return 'Loan EMI';
      }
      if (_anyMatch(body, ['insurance', 'premium', 'lic', 'policy'])) return 'Insurance';
      if (_anyMatch(body, ['sip', 'mutual fund', 'mf '])) return 'Investment';
      if (_anyMatch(body, ['rent', 'maintenance'])) return 'Rent';
      return 'Loan EMI'; // default for NACH is structured obligation
    }

    // ── P2P transfers ─────────────────────────────────────────────────────────
    if (isP2P || (vpa != null && _isPersonalVpaLocal(vpa) && !_isMerchantVpa(vpa))) {
      // Note: cashflow_provider will further split into Friends / Family
      return 'Send Money';
    }

    // ── Named keyword categories (in priority order) ──────────────────────────
    for (final entry in _rules.entries) {
      if (_anyMatch(body, entry.value)) return entry.key;
    }

    // ── UPI / transfer signals (fallback) ─────────────────────────────────────
    const transferSignals = [
      'upi', 'neft', 'imps', 'rtgs', 'p2p',
      'money transfer', 'fund transfer', 'bank transfer',
      'gpay', 'phonepe', 'bhim',
      '@okicici', '@okhdfcbank', '@oksbi', '@okaxis',
      '@ybl', '@ibl', '@axl', '@paytm',
    ];
    if (_anyMatch(body, transferSignals)) return 'Send Money';

    return 'Other';
  }

  /// Convenience for manual-entry flows (no raw SMS).
  static String categorize(String merchant, bool isCredit) =>
      categorizeFromSms('', merchant, isCredit: isCredit);

  // ── VPA helpers ───────────────────────────────────────────────────────────

  static bool _isPersonalVpaLocal(String vpa) {
    final parts = vpa.split('@');
    if (parts.length < 2) return false;
    final suffix = parts[1].toLowerCase();
    final prefix = parts[0].toLowerCase().replaceAll(RegExp(r'[\d.\-_]'), '');
    // Pure mobile number prefix → personal
    if (RegExp(r'^\d{10}$').hasMatch(parts[0])) return true;
    return _personalSuffixes.contains(suffix) && !_merchantVpaPrefixes.contains(prefix);
  }

  static bool _isMerchantVpa(String vpa) {
    const merchantSuffixes = {
      'razorpay', 'upirzp', 'paytmqr', 'yapl', 'rapl',
      'freecharge', 'pinelab', 'zoicici', 'tapicici', 'fkaxis',
      'axisgo', 'sliceaxis', 'jupiteraxis', 'niyoicici',
    };
    final parts = vpa.split('@');
    if (parts.length < 2) return false;
    final suffix = parts[1].toLowerCase();
    final prefix = parts[0].toLowerCase().replaceAll(RegExp(r'[\d.\-_]'), '');
    if (merchantSuffixes.contains(suffix)) return true;
    if (_merchantVpaPrefixes.contains(prefix)) return true;
    return false;
  }

  static bool _anyMatch(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  // ── Display helpers ────────────────────────────────────────────────────────

  static const List<String> expenseCategories = [
    'Send Money',
    'Friends',
    'Family',
    'Food & Dining',
    'Groceries',
    'Transport',
    'Fuel',
    'Shopping',
    'Entertainment',
    'Subscriptions',
    'Bills & Utilities',
    'Rent',
    'Loan EMI',
    'Health',
    'Personal Care',
    'Education',
    'Investment',
    'Insurance',
    'Travel & Hotels',
    'Government',
    'ATM & Cash',
    'Other',
  ];

  static Color getCategoryFlutterColor(String category) {
    const map = {
      'Send Money':      AppColors.catSendMoney,
      'Friends':         AppColors.catSendMoney,
      'Family':          Color(0xFFEC4899),
      'Food & Dining':   AppColors.catFood,
      'Groceries':       Color(0xFF84CC16),
      'Transport':       AppColors.catTransport,
      'Fuel':            Color(0xFFF97316),
      'Shopping':        AppColors.catShopping,
      'Entertainment':   AppColors.catEntertainment,
      'Subscriptions':   Color(0xFF8B5CF6),
      'Bills & Utilities': AppColors.catBills,
      'Rent':            Color(0xFFEF4444),
      'Loan EMI':        Color(0xFFDC2626),
      'Health':          AppColors.catHealth,
      'Personal Care':   Color(0xFFF472B6),
      'Education':       AppColors.catEducation,
      'Investment':      AppColors.catInvestment,
      'Insurance':       Color(0xFF0EA5E9),
      'Travel & Hotels': Color(0xFF06B6D4),
      'Government':      Color(0xFF6B7280),
      'Income':          AppColors.catIncome,
      'Income Transfer': AppColors.catIncome,
      'Salary':          AppColors.catIncome,
      'Refund':          AppColors.catEducation,
      'Interest':        Color(0xFF34D399),
      'ATM & Cash':      AppColors.catAtm,
    };
    return map[category] ?? AppColors.catOther;
  }

  static String getCategoryColor(String category) {
    const colors = {
      'Send Money':      '#EC4899',
      'Friends':         '#F472B6',
      'Family':          '#EC4899',
      'Food & Dining':   '#FF6B6B',
      'Groceries':       '#84CC16',
      'Transport':       '#4ECDC4',
      'Fuel':            '#F97316',
      'Shopping':        '#A78BFA',
      'Entertainment':   '#F59E0B',
      'Subscriptions':   '#8B5CF6',
      'Bills & Utilities': '#60A5FA',
      'Rent':            '#EF4444',
      'Loan EMI':        '#DC2626',
      'Health':          '#FC8181',
      'Personal Care':   '#F472B6',
      'Education':       '#34D399',
      'Investment':      '#10B981',
      'Insurance':       '#0EA5E9',
      'Travel & Hotels': '#06B6D4',
      'Government':      '#6B7280',
      'Income':          '#10B981',
      'Income Transfer': '#10B981',
      'Salary':          '#10B981',
      'Refund':          '#34D399',
      'Interest':        '#34D399',
      'ATM & Cash':      '#94A3B8',
    };
    return colors[category] ?? '#6B7280';
  }

  static String getCategoryIcon(String category) {
    const icons = {
      'Send Money':      '💸',
      'Friends':         '👥',
      'Family':          '👨‍👩‍👧',
      'Food & Dining':   '🍔',
      'Groceries':       '🛒',
      'Transport':       '🚗',
      'Fuel':            '⛽',
      'Shopping':        '🛍️',
      'Entertainment':   '🎬',
      'Subscriptions':   '📺',
      'Bills & Utilities': '⚡',
      'Rent':            '🏠',
      'Loan EMI':        '🏦',
      'Health':          '🏥',
      'Personal Care':   '💆',
      'Education':       '📚',
      'Investment':      '📈',
      'Insurance':       '🛡️',
      'Travel & Hotels': '✈️',
      'Government':      '🏛️',
      'Income':          '💰',
      'Income Transfer': '💰',
      'Salary':          '💰',
      'Refund':          '↩️',
      'Interest':        '📊',
      'ATM & Cash':      '🏧',
      'Other':           '💳',
    };
    return icons[category] ?? '💳';
  }
}
