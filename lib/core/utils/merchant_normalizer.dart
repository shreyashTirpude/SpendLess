class MerchantNormalizer {
  static const _map = <String, String>{
    // Food delivery
    'zomato': 'Zomato', 'zomatopay': 'Zomato', 'zomato online': 'Zomato',
    'swiggy': 'Swiggy', 'swiggy india': 'Swiggy', 'bundl technologies': 'Swiggy',
    'dunzo': 'Dunzo', 'magicpin': 'Magicpin',
    // Restaurants
    'mcdonald': "McDonald's", 'mcdonalds': "McDonald's", 'mcd': "McDonald's",
    "domino's": "Domino's", 'dominos': "Domino's", 'domino': "Domino's",
    'pizza hut': 'Pizza Hut', 'kfc': 'KFC', 'burger king': 'Burger King',
    'subway': 'Subway', 'starbucks': 'Starbucks', 'chaayos': 'Chaayos',
    'barbeque nation': 'Barbeque Nation', 'haldiram': "Haldiram's",
    // Shopping
    'amazon': 'Amazon', 'amazon.in': 'Amazon', 'amazonretail': 'Amazon',
    'amazon retail': 'Amazon', 'amazon seller': 'Amazon',
    'flipkart': 'Flipkart', 'flipkart internet': 'Flipkart',
    'myntra': 'Myntra', 'meesho': 'Meesho', 'nykaa': 'Nykaa',
    'ajio': 'AJIO', 'tatacliq': 'Tata CLiQ', 'tata cliq': 'Tata CLiQ',
    'snapdeal': 'Snapdeal', 'shopsy': 'Shopsy', 'limeroad': 'LimeRoad',
    // Transport
    'uber': 'Uber', 'uber india': 'Uber', 'uber bv': 'Uber',
    'ola': 'Ola', 'ola cabs': 'Ola', 'anirban technologies': 'Ola',
    'rapido': 'Rapido', 'roppen': 'Rapido',
    'irctc': 'IRCTC', 'indian railway': 'IRCTC', 'railways': 'IRCTC',
    'indigo': 'IndiGo', 'interglobe': 'IndiGo',
    'air india': 'Air India', 'spicejet': 'SpiceJet', 'vistara': 'Vistara',
    'akasa': 'Akasa Air', 'go first': 'Go First',
    'redbus': 'RedBus', 'abhibus': 'AbhiBus',
    'ola electric': 'Ola Electric',
    // Utilities / Telecom
    'jio': 'Jio', 'reliance jio': 'Jio', 'jio platforms': 'Jio',
    'airtel': 'Airtel', 'bharti airtel': 'Airtel',
    'bsnl': 'BSNL', 'vi': 'Vi', 'vodafone idea': 'Vi',
    'tata play': 'Tata Play', 'tata sky': 'Tata Play',
    'dish tv': 'Dish TV', 'sun direct': 'Sun Direct',
    'd2h': 'd2h',
    // Streaming subscriptions
    'netflix': 'Netflix', 'hotstar': 'Hotstar',
    'disney+ hotstar': 'Hotstar', 'novi digital': 'Hotstar',
    'spotify': 'Spotify', 'youtube': 'YouTube Premium',
    'youtube premium': 'YouTube Premium',
    'amazon prime': 'Amazon Prime', 'prime video': 'Amazon Prime',
    'zee5': 'ZEE5', 'sonyliv': 'SonyLIV', 'sony liv': 'SonyLIV',
    'mxplayer': 'MX Player', 'mx player': 'MX Player',
    'jiocinema': 'JioCinema', 'jio cinema': 'JioCinema',
    'apple': 'Apple', 'apple india': 'Apple',
    // Finance / Investment
    'zerodha': 'Zerodha', 'zerodha broking': 'Zerodha',
    'groww': 'Groww', 'nextbillion': 'Groww',
    'upstox': 'Upstox', 'rksv': 'Upstox',
    'angel': 'Angel One', 'angel broking': 'Angel One', 'angel one': 'Angel One',
    'smallcase': 'Smallcase', 'cred': 'CRED',
    'paytm': 'Paytm', 'one97': 'Paytm',
    'phonepe': 'PhonePe', 'phone pe': 'PhonePe',
    'gpay': 'Google Pay', 'google pay': 'Google Pay',
    'bhim': 'BHIM UPI', 'navi': 'Navi',
    'bajaj finserv': 'Bajaj Finserv', 'bajaj': 'Bajaj Finserv',
    'hdfc': 'HDFC', 'icici': 'ICICI', 'sbi': 'SBI',
    'axis': 'Axis Bank', 'kotak': 'Kotak Bank',
    // Health
    'apollo pharmacy': 'Apollo Pharmacy', 'apollo': 'Apollo Pharmacy',
    'medplus': 'MedPlus', 'practo': 'Practo',
    '1mg': '1mg', 'tata 1mg': '1mg', 'netmeds': 'Netmeds',
    'pharmeasy': 'PharmEasy',
    // Grocery
    'blinkit': 'Blinkit', 'grofers': 'Blinkit',
    'zepto': 'Zepto', 'bigbasket': 'BigBasket',
    'bb now': 'BigBasket Now', 'jiomart': 'JioMart',
    'dmart': 'DMart', 'd-mart': 'DMart',
    'instamart': 'Swiggy Instamart',
    // Education
    'byju': "BYJU'S", 'byjus': "BYJU'S", 'think and learn': "BYJU'S",
    'unacademy': 'Unacademy', 'vedantu': 'Vedantu',
    'coursera': 'Coursera', 'udemy': 'Udemy', 'physicswallah': 'PW',
    'pw': 'PW', 'toppr': 'Toppr',
    // Hotel / Travel
    'oyo': 'OYO', 'oyo rooms': 'OYO',
    'makemytrip': 'MakeMyTrip', 'goibibo': 'Goibibo',
    'yatra': 'Yatra', 'airbnb': 'Airbnb', 'booking.com': 'Booking.com',
    // Insurance
    'lic': 'LIC', 'hdfc life': 'HDFC Life',
    'max life': 'Max Life', 'star health': 'Star Health',
    'policybazaar': 'PolicyBazaar', 'acko': 'Acko',
    // Fuel
    'iocl': 'Indian Oil', 'indian oil': 'Indian Oil',
    'bpcl': 'BPCL', 'hpcl': 'HPCL', 'hp petro': 'HPCL',
    // Misc
    'urban company': 'Urban Company', 'urbanclap': 'Urban Company',
    'lenskart': 'Lenskart', 'pepperfry': 'Pepperfry',
    'cult.fit': 'Cult.fit', 'cult fit': 'Cult.fit',
    'fueladream': 'FuelADream', 'ketto': 'Ketto',
  };

  static String normalize(String raw) {
    if (raw.trim().isEmpty) return raw;
    final lower = raw.toLowerCase().trim();

    // 1. Direct exact match
    if (_map.containsKey(lower)) return _map[lower]!;

    // 2. UPI VPA: strip bank suffix "zomato@okicici" → check "zomato"
    if (lower.contains('@')) {
      final vpa = lower.split('@').first
          .replaceAll(RegExp(r'[._\-]'), ' ')
          .trim();
      if (_map.containsKey(vpa)) return _map[vpa]!;
      for (final e in _map.entries) {
        if (vpa.startsWith(e.key)) return e.value;
      }
    }

    // 3. Starts-with match
    for (final e in _map.entries) {
      if (lower.startsWith(e.key)) return e.value;
    }

    // 4. Substring match (only for keywords ≥6 chars to avoid false positives)
    for (final e in _map.entries.where((e) => e.key.length >= 6)) {
      if (lower.contains(e.key)) return e.value;
    }

    // 5. Title-case the original
    return _toTitleCase(raw.trim());
  }

  static String _toTitleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}
