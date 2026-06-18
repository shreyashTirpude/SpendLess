// Sub-merchant mapping: normalized merchant name → parent category + brand info.
// Enables rich "Food & Dining → Swiggy (delivery)" style display.

enum SubMerchantType {
  delivery,
  dineIn,
  grocery,
  quickCommerce,
  cafe,
  cab,
  flight,
  train,
  bus,
  metro,
  pharmacy,
  doctor,
  fitness,
  fashion,
  ecommerce,
  beauty,
  streaming,
  music,
  cinema,
  events,
  stocks,
  mutualFund,
  upi,
  wallet,
}

class SubMerchantInfo {
  final String category;
  final String subBrand;
  final String emoji;
  final String color; // hex string
  final SubMerchantType type;

  const SubMerchantInfo({
    required this.category,
    required this.subBrand,
    required this.emoji,
    required this.color,
    required this.type,
  });
}

class SubMerchantMapper {
  // ── Lookup table: all keys are lowercase ────────────────────────────────────
  static const Map<String, SubMerchantInfo> _entries = {
    // ── Food & Delivery ──────────────────────────────────────────────────────
    'swiggy': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: 'Swiggy',
      emoji: '🍔',
      color: '#FC8019',
      type: SubMerchantType.delivery,
    ),
    'zomato': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: 'Zomato',
      emoji: '🍕',
      color: '#CB202D',
      type: SubMerchantType.delivery,
    ),
    'bigbasket': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: 'BigBasket',
      emoji: '🛒',
      color: '#84C225',
      type: SubMerchantType.grocery,
    ),
    'big basket': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: 'BigBasket',
      emoji: '🛒',
      color: '#84C225',
      type: SubMerchantType.grocery,
    ),
    'blinkit': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: 'Blinkit',
      emoji: '⚡',
      color: '#FFE01B',
      type: SubMerchantType.quickCommerce,
    ),
    'grofers': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: 'Blinkit',
      emoji: '⚡',
      color: '#FFE01B',
      type: SubMerchantType.quickCommerce,
    ),
    'dunzo': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: 'Dunzo',
      emoji: '🏃',
      color: '#00C48C',
      type: SubMerchantType.quickCommerce,
    ),
    'zepto': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: 'Zepto',
      emoji: '🚀',
      color: '#7B2FBE',
      type: SubMerchantType.quickCommerce,
    ),
    'dominos': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: "Domino's",
      emoji: '🍕',
      color: '#006491',
      type: SubMerchantType.dineIn,
    ),
    "domino's": SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: "Domino's",
      emoji: '🍕',
      color: '#006491',
      type: SubMerchantType.dineIn,
    ),
    'mcdonalds': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: "McDonald's",
      emoji: '🍟',
      color: '#FFC72C',
      type: SubMerchantType.dineIn,
    ),
    'mcd': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: "McDonald's",
      emoji: '🍟',
      color: '#FFC72C',
      type: SubMerchantType.dineIn,
    ),
    'starbucks': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: 'Starbucks',
      emoji: '☕',
      color: '#00704A',
      type: SubMerchantType.cafe,
    ),
    'chaayos': SubMerchantInfo(
      category: 'Food & Dining',
      subBrand: 'Chaayos',
      emoji: '🍵',
      color: '#8B4513',
      type: SubMerchantType.cafe,
    ),

    // ── Travel ───────────────────────────────────────────────────────────────
    'uber': SubMerchantInfo(
      category: 'Transport',
      subBrand: 'Uber',
      emoji: '🚗',
      color: '#000000',
      type: SubMerchantType.cab,
    ),
    'ola': SubMerchantInfo(
      category: 'Transport',
      subBrand: 'Ola',
      emoji: '🟡',
      color: '#F5A623',
      type: SubMerchantType.cab,
    ),
    'rapido': SubMerchantInfo(
      category: 'Transport',
      subBrand: 'Rapido',
      emoji: '🏍️',
      color: '#FFD700',
      type: SubMerchantType.cab,
    ),
    'mmt': SubMerchantInfo(
      category: 'Travel & Hotels',
      subBrand: 'MakeMyTrip',
      emoji: '✈️',
      color: '#E8175D',
      type: SubMerchantType.flight,
    ),
    'makemytrip': SubMerchantInfo(
      category: 'Travel & Hotels',
      subBrand: 'MakeMyTrip',
      emoji: '✈️',
      color: '#E8175D',
      type: SubMerchantType.flight,
    ),
    'irctc': SubMerchantInfo(
      category: 'Travel & Hotels',
      subBrand: 'IRCTC',
      emoji: '🚂',
      color: '#003580',
      type: SubMerchantType.train,
    ),
    'yatra': SubMerchantInfo(
      category: 'Travel & Hotels',
      subBrand: 'Yatra',
      emoji: '✈️',
      color: '#FF6600',
      type: SubMerchantType.flight,
    ),
    'cleartrip': SubMerchantInfo(
      category: 'Travel & Hotels',
      subBrand: 'Cleartrip',
      emoji: '✈️',
      color: '#FF6633',
      type: SubMerchantType.flight,
    ),
    'redbus': SubMerchantInfo(
      category: 'Transport',
      subBrand: 'RedBus',
      emoji: '🚌',
      color: '#D84315',
      type: SubMerchantType.bus,
    ),
    'namma metro': SubMerchantInfo(
      category: 'Transport',
      subBrand: 'Namma Metro',
      emoji: '🚇',
      color: '#0047AB',
      type: SubMerchantType.metro,
    ),
    'dmrc': SubMerchantInfo(
      category: 'Transport',
      subBrand: 'DMRC',
      emoji: '🚇',
      color: '#0047AB',
      type: SubMerchantType.metro,
    ),
    'metro': SubMerchantInfo(
      category: 'Transport',
      subBrand: 'Metro',
      emoji: '🚇',
      color: '#0047AB',
      type: SubMerchantType.metro,
    ),

    // ── Health ───────────────────────────────────────────────────────────────
    'apollo pharmacy': SubMerchantInfo(
      category: 'Health',
      subBrand: 'Apollo Pharmacy',
      emoji: '💊',
      color: '#0078B3',
      type: SubMerchantType.pharmacy,
    ),
    'apollo': SubMerchantInfo(
      category: 'Health',
      subBrand: 'Apollo Pharmacy',
      emoji: '💊',
      color: '#0078B3',
      type: SubMerchantType.pharmacy,
    ),
    'practo': SubMerchantInfo(
      category: 'Health',
      subBrand: 'Practo',
      emoji: '🩺',
      color: '#5DB75D',
      type: SubMerchantType.doctor,
    ),
    'pharmeasy': SubMerchantInfo(
      category: 'Health',
      subBrand: 'PharmEasy',
      emoji: '💊',
      color: '#47B5AD',
      type: SubMerchantType.pharmacy,
    ),
    'netmeds': SubMerchantInfo(
      category: 'Health',
      subBrand: 'Netmeds',
      emoji: '💊',
      color: '#E51D2A',
      type: SubMerchantType.pharmacy,
    ),
    '1mg': SubMerchantInfo(
      category: 'Health',
      subBrand: '1mg',
      emoji: '💊',
      color: '#E83B3B',
      type: SubMerchantType.pharmacy,
    ),
    'healthkart': SubMerchantInfo(
      category: 'Health',
      subBrand: 'HealthKart',
      emoji: '💪',
      color: '#FF6B00',
      type: SubMerchantType.fitness,
    ),
    'cult.fit': SubMerchantInfo(
      category: 'Health',
      subBrand: 'Cult.fit',
      emoji: '🏋️',
      color: '#2B3990',
      type: SubMerchantType.fitness,
    ),
    'cultfit': SubMerchantInfo(
      category: 'Health',
      subBrand: 'Cult.fit',
      emoji: '🏋️',
      color: '#2B3990',
      type: SubMerchantType.fitness,
    ),

    // ── Shopping ─────────────────────────────────────────────────────────────
    'myntra': SubMerchantInfo(
      category: 'Shopping',
      subBrand: 'Myntra',
      emoji: '👗',
      color: '#FF3F6C',
      type: SubMerchantType.fashion,
    ),
    'amazon': SubMerchantInfo(
      category: 'Shopping',
      subBrand: 'Amazon',
      emoji: '📦',
      color: '#FF9900',
      type: SubMerchantType.ecommerce,
    ),
    'flipkart': SubMerchantInfo(
      category: 'Shopping',
      subBrand: 'Flipkart',
      emoji: '🛍️',
      color: '#2874F0',
      type: SubMerchantType.ecommerce,
    ),
    'nykaa': SubMerchantInfo(
      category: 'Shopping',
      subBrand: 'Nykaa',
      emoji: '💄',
      color: '#FC2779',
      type: SubMerchantType.beauty,
    ),
    'meesho': SubMerchantInfo(
      category: 'Shopping',
      subBrand: 'Meesho',
      emoji: '👜',
      color: '#8B2FC9',
      type: SubMerchantType.fashion,
    ),
    'ajio': SubMerchantInfo(
      category: 'Shopping',
      subBrand: 'AJIO',
      emoji: '👔',
      color: '#333333',
      type: SubMerchantType.fashion,
    ),

    // ── Entertainment ─────────────────────────────────────────────────────────
    'netflix': SubMerchantInfo(
      category: 'Entertainment',
      subBrand: 'Netflix',
      emoji: '🎬',
      color: '#E50914',
      type: SubMerchantType.streaming,
    ),
    'hotstar': SubMerchantInfo(
      category: 'Entertainment',
      subBrand: 'Hotstar',
      emoji: '⭐',
      color: '#0D0D0D',
      type: SubMerchantType.streaming,
    ),
    'disney+': SubMerchantInfo(
      category: 'Entertainment',
      subBrand: 'Hotstar',
      emoji: '⭐',
      color: '#0D0D0D',
      type: SubMerchantType.streaming,
    ),
    'spotify': SubMerchantInfo(
      category: 'Entertainment',
      subBrand: 'Spotify',
      emoji: '🎵',
      color: '#1DB954',
      type: SubMerchantType.music,
    ),
    'youtube premium': SubMerchantInfo(
      category: 'Entertainment',
      subBrand: 'YouTube Premium',
      emoji: '📺',
      color: '#FF0000',
      type: SubMerchantType.streaming,
    ),
    'bookmyshow': SubMerchantInfo(
      category: 'Entertainment',
      subBrand: 'BookMyShow',
      emoji: '🎭',
      color: '#E3000F',
      type: SubMerchantType.events,
    ),
    'pvr': SubMerchantInfo(
      category: 'Entertainment',
      subBrand: 'PVR',
      emoji: '🎬',
      color: '#7B1FA2',
      type: SubMerchantType.cinema,
    ),
    'inox': SubMerchantInfo(
      category: 'Entertainment',
      subBrand: 'INOX',
      emoji: '🎬',
      color: '#7B1FA2',
      type: SubMerchantType.cinema,
    ),

    // ── Finance & Investment ──────────────────────────────────────────────────
    'zerodha': SubMerchantInfo(
      category: 'Investment',
      subBrand: 'Zerodha',
      emoji: '📈',
      color: '#387ED1',
      type: SubMerchantType.stocks,
    ),
    'groww': SubMerchantInfo(
      category: 'Investment',
      subBrand: 'Groww',
      emoji: '📊',
      color: '#00D09C',
      type: SubMerchantType.stocks,
    ),
    'coin': SubMerchantInfo(
      category: 'Investment',
      subBrand: 'Coin by Zerodha',
      emoji: '🪙',
      color: '#387ED1',
      type: SubMerchantType.mutualFund,
    ),
    'phonepe': SubMerchantInfo(
      category: 'Bills & Utilities',
      subBrand: 'PhonePe',
      emoji: '💜',
      color: '#5F259F',
      type: SubMerchantType.upi,
    ),
    'paytm': SubMerchantInfo(
      category: 'Bills & Utilities',
      subBrand: 'Paytm',
      emoji: '💙',
      color: '#00BAF2',
      type: SubMerchantType.wallet,
    ),
    'gpay': SubMerchantInfo(
      category: 'Bills & Utilities',
      subBrand: 'Google Pay',
      emoji: '🔵',
      color: '#4285F4',
      type: SubMerchantType.upi,
    ),
    'google pay': SubMerchantInfo(
      category: 'Bills & Utilities',
      subBrand: 'Google Pay',
      emoji: '🔵',
      color: '#4285F4',
      type: SubMerchantType.upi,
    ),
  };

  /// Returns [SubMerchantInfo] for a given (already-normalized or raw) merchant name.
  /// Matching is case-insensitive; tries exact match then starts-with.
  static SubMerchantInfo? map(String merchantName) {
    if (merchantName.trim().isEmpty) return null;
    final lower = merchantName.toLowerCase().trim();

    // 1. Exact match
    if (_entries.containsKey(lower)) return _entries[lower];

    // 2. Starts-with (longest key wins to avoid 'mmt' matching 'mmtc')
    String? bestKey;
    for (final key in _entries.keys) {
      if (lower.startsWith(key)) {
        if (bestKey == null || key.length > bestKey.length) {
          bestKey = key;
        }
      }
    }
    if (bestKey != null) return _entries[bestKey];

    // 3. Contains (only keys >= 5 chars to avoid noise)
    for (final entry in _entries.entries) {
      if (entry.key.length >= 5 && lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Returns all known normalized merchant keys that belong to a given category.
  static List<String> merchantsForCategory(String category) {
    return _entries.entries
        .where((e) => e.value.category == category)
        .map((e) => e.value.subBrand)
        .toSet()
        .toList()
      ..sort();
  }

  /// Human-readable label for the type.
  static String typeLabel(SubMerchantType type) {
    switch (type) {
      case SubMerchantType.delivery:
        return 'Delivery';
      case SubMerchantType.dineIn:
        return 'Dine-in';
      case SubMerchantType.grocery:
        return 'Grocery';
      case SubMerchantType.quickCommerce:
        return 'Quick Commerce';
      case SubMerchantType.cafe:
        return 'Cafe';
      case SubMerchantType.cab:
        return 'Cab';
      case SubMerchantType.flight:
        return 'Flight';
      case SubMerchantType.train:
        return 'Train';
      case SubMerchantType.bus:
        return 'Bus';
      case SubMerchantType.metro:
        return 'Metro';
      case SubMerchantType.pharmacy:
        return 'Pharmacy';
      case SubMerchantType.doctor:
        return 'Doctor';
      case SubMerchantType.fitness:
        return 'Fitness';
      case SubMerchantType.fashion:
        return 'Fashion';
      case SubMerchantType.ecommerce:
        return 'E-Commerce';
      case SubMerchantType.beauty:
        return 'Beauty';
      case SubMerchantType.streaming:
        return 'Streaming';
      case SubMerchantType.music:
        return 'Music';
      case SubMerchantType.cinema:
        return 'Cinema';
      case SubMerchantType.events:
        return 'Events';
      case SubMerchantType.stocks:
        return 'Stocks';
      case SubMerchantType.mutualFund:
        return 'Mutual Fund';
      case SubMerchantType.upi:
        return 'UPI';
      case SubMerchantType.wallet:
        return 'Wallet';
    }
  }
}
