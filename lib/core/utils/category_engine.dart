class CategoryEngine {
  static const Map<String, List<String>> _rules = {
    'Food & Dining': [
      'zomato', 'swiggy', 'blinkit', 'zepto', 'bigbasket', 'grofers',
      'dunzo', 'dominos', 'mcdonalds', 'kfc', 'subway', 'pizza hut',
      'burger king', 'starbucks', 'cafe coffee day', 'ccd', 'haldirams',
      'barbeque', 'food', 'restaurant', 'cafe', 'dhaba', 'hotel',
    ],
    'Transport': [
      'uber', 'ola', 'rapido', 'meru', 'indrive',
      'metro', 'dmrc', 'bmtc', 'ksrtc', 'msrtc',
      'irctc', 'indian rail', 'railway',
      'indigo', 'air india', 'spicejet', 'goair', 'vistara',
      'petrol', 'fuel', 'hp petrol', 'iocl', 'bpcl', 'shell',
      'parking', 'fastag', 'toll', 'auto', 'cab', 'taxi', 'bus',
    ],
    'Shopping': [
      'amazon', 'flipkart', 'myntra', 'ajio', 'nykaa', 'meesho',
      'snapdeal', 'tatacliq', 'croma', 'reliance digital', 'vijay sales',
      'dmart', 'big bazaar', 'reliance fresh', 'more supermarket',
      'mall', 'shopping', 'store', 'mart', 'bazaar', 'retail',
    ],
    'Entertainment': [
      'netflix', 'spotify', 'amazon prime', 'hotstar', 'disney',
      'zee5', 'sonyliv', 'voot', 'mxplayer', 'jiocinema',
      'bookmyshow', 'pvr', 'inox', 'cinepolis',
      'gaming', 'steam', 'google play', 'apple', 'xbox', 'playstation',
    ],
    'Bills & Utilities': [
      'electricity', 'bescom', 'msedcl', 'tneb',
      'water', 'gas', 'indane', 'hp gas', 'bharat gas',
      'airtel', 'jio', 'vi', 'vodafone', 'idea', 'bsnl',
      'broadband', 'internet', 'recharge', 'topup',
    ],
    'Health': [
      'pharmacy', 'medplus', 'netmeds', '1mg', 'pharmeasy', 'apollo pharmacy',
      'hospital', 'clinic', 'lab', 'diagnostic', 'pathology',
      'doctor', 'dental', 'optical', 'medical', 'health',
      'gym', 'cult fit', 'cure fit', 'yoga', 'fitness',
    ],
    'Education': [
      'byju', 'unacademy', 'vedantu', 'whitehat', 'toppr',
      'coursera', 'udemy', 'udacity', 'skillshare',
      'school fees', 'college fees', 'tuition', 'coaching',
    ],
    'Investment': [
      'zerodha', 'groww', 'upstox', 'kuvera', 'coin by zerodha',
      'icicidirect', 'hdfcsec', 'motilal', 'angel broking',
      'sip', 'mutual fund', 'mf', 'nps', 'ppf',
      'lic', 'insurance', 'rd', 'fd', 'fixed deposit',
    ],
    'ATM & Cash': [
      'atm', 'cash withdrawal', 'cash advance', 'atm wd',
    ],
  };

  static String categorize(String merchant, bool isCredit) {
    if (isCredit) {
      final m = merchant.toLowerCase();
      if (m.contains('salary') || m.contains('payroll')) return 'Salary';
      if (m.contains('refund') || m.contains('cashback')) return 'Refund';
      return 'Income';
    }

    final m = merchant.toLowerCase();
    for (final entry in _rules.entries) {
      if (entry.value.any((keyword) => m.contains(keyword))) {
        return entry.key;
      }
    }
    return 'Other';
  }

  static String getCategoryColor(String category) {
    const colors = {
      'Food & Dining': '#FF6B6B',
      'Transport': '#4ECDC4',
      'Shopping': '#A78BFA',
      'Entertainment': '#F59E0B',
      'Bills & Utilities': '#60A5FA',
      'Health': '#FC8181',
      'Education': '#34D399',
      'Investment': '#10B981',
      'Income': '#10B981',
      'Salary': '#10B981',
      'Refund': '#34D399',
      'ATM & Cash': '#94A3B8',
    };
    return colors[category] ?? '#6B7280';
  }

  static String getCategoryIcon(String category) {
    const icons = {
      'Food & Dining': '🍔',
      'Transport': '🚗',
      'Shopping': '🛍️',
      'Entertainment': '🎬',
      'Bills & Utilities': '⚡',
      'Health': '🏥',
      'Education': '📚',
      'Investment': '📈',
      'Income': '💰',
      'Salary': '💰',
      'Refund': '↩️',
      'ATM & Cash': '🏧',
    };
    return icons[category] ?? '💳';
  }
}
