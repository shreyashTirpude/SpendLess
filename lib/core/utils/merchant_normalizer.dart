// ignore_for_file: constant_identifier_names

/// Normalises raw merchant strings extracted from bank SMS.
///
/// Pipeline:
///   1. Strip bank-wrapper prefixes  (SBI*MERCHANT*, HDFC*POS*, …)
///   2. Strip asterisk noise segments (SWIGGY*ORDER#123 → SWIGGY)
///   3. Strip trailing city/trip codes
///   4. Strip trailing order-ID digits
///   5. Extract VPA local-part prefix  (zomato.food@hdfcbank → zomato)
///   6. Exact dictionary lookup
///   7. Legal-entity alias lookup
///   8. Starts-with lookup (handles truncation: AMAZON SELLER SERVIC)
///   9. Substring lookup (≥6-char keys only)
///  10. Title-case fallback
class MerchantNormalizer {
  // ── Dictionary: lowercase key → display name ─────────────────────────────────
  static const Map<String, String> _map = {
    // ── Food Delivery ────────────────────────────────────────────────────────────
    'zomato': 'Zomato',
    'zomatopay': 'Zomato',
    'zomato online': 'Zomato',
    'bundl technologies': 'Swiggy',
    'bundl tech': 'Swiggy',
    'swiggy': 'Swiggy',
    'swiggy india': 'Swiggy',
    'swiggy instamart': 'Swiggy Instamart',
    'instamart': 'Swiggy Instamart',
    'dunzo': 'Dunzo',
    'box8': 'Box8',
    'faasos': 'Faasos',
    'rebel foods': 'Rebel Foods',
    'eatfit': 'EatFit',
    'eat fit': 'EatFit',
    'freshmenu': 'FreshMenu',
    'fresh menu': 'FreshMenu',
    'magicpin': 'Magicpin',
    'thrive': 'Thrive',

    // ── Restaurants / Cafes ──────────────────────────────────────────────────────
    'mcdonald': "McDonald's",
    'mcdonalds': "McDonald's",
    'mcd': "McDonald's",
    'golden arches': "McDonald's",
    "domino's": "Domino's",
    'dominos': "Domino's",
    'domino': "Domino's",
    'jubilant food': "Domino's",
    'jubilant foodworks': "Domino's",
    'pizza hut': 'Pizza Hut',
    'pizzahut': 'Pizza Hut',
    'yum restaurants': 'Pizza Hut',
    'kfc': 'KFC',
    'burger king': 'Burger King',
    'burgerking': 'Burger King',
    'subway': 'Subway',
    'starbucks': 'Starbucks',
    'chaayos': 'Chaayos',
    'cafe coffee day': 'CCD',
    'coffee day': 'CCD',
    'ccd': 'CCD',
    'haldiram': "Haldiram's",
    'haldirams': "Haldiram's",
    'barbeque nation': 'Barbeque Nation',
    'bbq nation': 'Barbeque Nation',
    'biryani by kilo': 'Biryani By Kilo',
    'paradise biryani': 'Paradise Biryani',
    'wow momo': 'Wow! Momo',

    // ── Grocery / Q-commerce ─────────────────────────────────────────────────────
    'blinkit': 'Blinkit',
    'grofers': 'Blinkit',
    'grofers india': 'Blinkit',
    'eternal limited': 'Blinkit',
    'zepto': 'Zepto',
    'bigbasket': 'BigBasket',
    'big basket': 'BigBasket',
    'supermart': 'BigBasket',
    'bb now': 'BigBasket Now',
    'bb daily': 'BigBasket Daily',
    'jiomart': 'JioMart',
    'jio mart': 'JioMart',
    'dmart': 'DMart',
    'd-mart': 'DMart',
    'avenue supermarts': 'DMart',
    'more supermarket': 'More',
    'more retail': 'More',
    "nature's basket": "Nature's Basket",
    'natures basket': "Nature's Basket",
    'godrej natures basket': "Nature's Basket",
    'licious': 'Licious',
    'milkbasket': 'Milkbasket',
    'milk basket': 'Milkbasket',
    'country delight': 'Country Delight',
    "spencers": "Spencer's",
    "spencer's": "Spencer's",
    'big bazaar': 'Big Bazaar',
    'bigbazaar': 'Big Bazaar',
    'future retail': 'Big Bazaar',
    'reliance smart': 'Reliance Smart',
    'reliance fresh': 'Reliance Fresh',
    'jiomart grocery': 'JioMart',

    // ── Shopping — E-commerce ────────────────────────────────────────────────────
    'amazon': 'Amazon',
    'amazon.in': 'Amazon',
    'amazonretail': 'Amazon',
    'amazon retail': 'Amazon',
    'amazon seller': 'Amazon',
    'amazon seller servic': 'Amazon',
    'amazon seller service': 'Amazon',
    'amzn': 'Amazon',
    'amazon mktplace': 'Amazon',
    'amazon marketplace': 'Amazon',
    'flipkart': 'Flipkart',
    'flipkart internet': 'Flipkart',
    'walmart': 'Flipkart',
    'shopsy': 'Shopsy',
    'myntra': 'Myntra',
    'meesho': 'Meesho',
    'nykaa': 'Nykaa',
    'nykaa fashion': 'Nykaa Fashion',
    'ajio': 'AJIO',
    'tatacliq': 'Tata CLiQ',
    'tata cliq': 'Tata CLiQ',
    'snapdeal': 'Snapdeal',
    'limeroad': 'LimeRoad',
    'hopscotch': 'Hopscotch',
    'fabindia': 'FabIndia',
    'fab india': 'FabIndia',

    // ── Shopping — Fashion / Apparel ─────────────────────────────────────────────
    'bata': 'Bata',
    'bata india': 'Bata',
    'puma': 'Puma',
    'adidas': 'Adidas',
    'nike': 'Nike',
    'h&m': 'H&M',
    'zara': 'Zara',
    "levi's": "Levi's",
    'levis': "Levi's",
    'westside': 'Westside',
    'trent westside': 'Westside',
    'trent': 'Westside',
    'pantaloons': 'Pantaloons',
    'brand factory': 'Brand Factory',
    'max fashion': 'Max Fashion',
    'max retail': 'Max Fashion',
    'reliance trends': 'Reliance Trends',
    'trends': 'Reliance Trends',
    'decathlon': 'Decathlon',
    'firstcry': 'FirstCry',
    'first cry': 'FirstCry',

    // ── Shopping — Electronics ────────────────────────────────────────────────────
    'croma': 'Croma',
    'croma retail': 'Croma',
    'infiniti retail': 'Croma',
    'vijay sales': 'Vijay Sales',
    'vijaysales': 'Vijay Sales',
    'reliance digital': 'Reliance Digital',
    'samsung': 'Samsung',
    'apple': 'Apple',
    'apple india': 'Apple',
    'ikea': 'IKEA',
    'ikea india': 'IKEA',
    'pepperfry': 'Pepperfry',
    'urban ladder': 'Urban Ladder',
    'urbanladder': 'Urban Ladder',
    'lenskart': 'Lenskart',
    'lens kart': 'Lenskart',
    'boat': 'boAt',
    'oneplus': 'OnePlus',
    'mi store': 'Xiaomi',
    'realme': 'Realme',

    // ── Transport / Mobility ─────────────────────────────────────────────────────
    'uber': 'Uber',
    'uber india': 'Uber',
    'uber bv': 'Uber',
    'ola': 'Ola',
    'ola cabs': 'Ola',
    'anirban technologies': 'Ola',
    'ani technologies': 'Ola',
    'rapido': 'Rapido',
    'roppen': 'Rapido',
    'namma yatri': 'Namma Yatri',
    'yatri': 'Namma Yatri',
    'bounce': 'Bounce',
    'bounce infra': 'Bounce',
    'yulu': 'Yulu',
    'yulu bikes': 'Yulu',
    'blusmart': 'BluSmart',
    'blue smart': 'BluSmart',
    'ola electric': 'Ola Electric',
    'zoomcar': 'Zoomcar',
    'zoom car': 'Zoomcar',
    'drivezy': 'Drivezy',
    'irctc': 'IRCTC',
    'indian railway': 'IRCTC',
    'railways': 'IRCTC',
    'indian rail': 'IRCTC',
    'indigo': 'IndiGo',
    'interglobe': 'IndiGo',
    'interglobe aviation': 'IndiGo',
    '6e': 'IndiGo',
    'air india': 'Air India',
    'spicejet': 'SpiceJet',
    'spice jet': 'SpiceJet',
    'vistara': 'Vistara',
    'tata sia': 'Vistara',
    'akasa': 'Akasa Air',
    'akasa air': 'Akasa Air',
    'go first': 'Go First',
    'goair': 'Go First',
    'redbus': 'RedBus',
    'red bus': 'RedBus',
    'abhibus': 'AbhiBus',
    'makemytrip': 'MakeMyTrip',
    'mmt': 'MakeMyTrip',
    'goibibo': 'Goibibo',
    'cleartrip': 'Cleartrip',
    'easemytrip': 'EaseMyTrip',
    'ease my trip': 'EaseMyTrip',
    'yatra': 'Yatra',
    'airbnb': 'Airbnb',
    'booking.com': 'Booking.com',
    'booking com': 'Booking.com',
    'oyo': 'OYO',
    'oyo rooms': 'OYO',
    'fabhotels': 'FabHotels',
    'fab hotels': 'FabHotels',
    'treebo': 'Treebo',
    'treebo hotels': 'Treebo',

    // ── Fuel ─────────────────────────────────────────────────────────────────────
    'iocl': 'Indian Oil',
    'indian oil': 'Indian Oil',
    'indane': 'Indian Oil (LPG)',
    'bpcl': 'BPCL',
    'bharat petroleum': 'BPCL',
    'bharatgas': 'BPCL (LPG)',
    'bharat gas': 'BPCL (LPG)',
    'hpcl': 'HPCL',
    'hp petro': 'HPCL',
    'hp gas': 'HPCL (LPG)',
    'hindustan petro': 'HPCL',
    'nayara': 'Nayara Energy',
    'essar oil': 'Nayara Energy',
    'shell': 'Shell',
    'fastag': 'FASTag',
    'nhai': 'FASTag (NHAI)',
    'ihmcl': 'FASTag',

    // ── Utilities / Telecom ──────────────────────────────────────────────────────
    'jio': 'Jio',
    'reliance jio': 'Jio',
    'jio platforms': 'Jio',
    'airtel': 'Airtel',
    'bharti airtel': 'Airtel',
    'bsnl': 'BSNL',
    'vi': 'Vi',
    'vodafone idea': 'Vi',
    'vodafone': 'Vodafone',
    'idea': 'Vi',
    'mtnl': 'MTNL',
    'tata play': 'Tata Play',
    'tata sky': 'Tata Play',
    'dish tv': 'Dish TV',
    'sun direct': 'Sun Direct',
    'd2h': 'd2h',
    'bescom': 'BESCOM',
    'msedcl': 'MSEDCL',
    'mahadiscom': 'MSEDCL',
    'mseb': 'MSEDCL',
    'tata power': 'Tata Power',
    'tatapower': 'Tata Power',
    'adani elec': 'Adani Electricity',
    'adani electric': 'Adani Electricity',
    'torrent power': 'Torrent Power',
    'hp gas cylinder': 'HPCL (LPG)',
    'indane gas': 'Indian Oil (LPG)',
    'mgl': 'Mahanagar Gas',
    'mahanagar gas': 'Mahanagar Gas',
    'igl': 'IGL',
    'piped gas': 'City Gas',

    // ── Streaming / Subscriptions ────────────────────────────────────────────────
    'netflix': 'Netflix',
    'hotstar': 'Hotstar',
    'disney+ hotstar': 'Hotstar',
    'disney hotstar': 'Hotstar',
    'novi digital': 'Hotstar',
    'disneyplus': 'Hotstar',
    'spotify': 'Spotify',
    'youtube': 'YouTube Premium',
    'youtube premium': 'YouTube Premium',
    'amazon prime': 'Amazon Prime',
    'prime video': 'Amazon Prime',
    'zee5': 'ZEE5',
    'zee 5': 'ZEE5',
    'sonyliv': 'SonyLIV',
    'sony liv': 'SonyLIV',
    'mxplayer': 'MX Player',
    'mx player': 'MX Player',
    'jiocinema': 'JioCinema',
    'jio cinema': 'JioCinema',
    'ntwk18 media': 'JioCinema',
    'voot': 'Voot',
    'altbalaji': 'ALTBalaji',
    'alt balaji': 'ALTBalaji',
    'apple music': 'Apple Music',
    'icloud': 'iCloud',
    'apple.com/bill': 'Apple',
    'gaana': 'Gaana',
    'jiosaavn': 'JioSaavn',
    'jio saavn': 'JioSaavn',
    'hungama': 'Hungama',

    // ── Entertainment ────────────────────────────────────────────────────────────
    'bookmyshow': 'BookMyShow',
    'book my show': 'BookMyShow',
    'bms': 'BookMyShow',
    'pvr': 'PVR Cinemas',
    'pvr cinemas': 'PVR Cinemas',
    'inox': 'INOX',
    'inox cinemas': 'INOX',
    'cinepolis': 'Cinepolis',
    'dream11': 'Dream11',
    'dream 11': 'Dream11',
    'dream sport': 'Dream11',
    'mpl': 'MPL',
    'mobile premier': 'MPL',
    'winzo': 'WinZO',
    'rummy circle': 'RummyCircle',
    'steam': 'Steam',
    'google play': 'Google Play',
    'app store': 'App Store',
    'epic games': 'Epic Games',

    // ── Finance / Investment ──────────────────────────────────────────────────────
    'zerodha': 'Zerodha',
    'zerodha broking': 'Zerodha',
    'kite': 'Zerodha',
    'groww': 'Groww',
    'nextbillion': 'Groww',
    'upstox': 'Upstox',
    'rksv': 'Upstox',
    'angel': 'Angel One',
    'angel broking': 'Angel One',
    'angel one': 'Angel One',
    'iifl': 'IIFL',
    'motilal oswal': 'Motilal Oswal',
    'smallcase': 'Smallcase',
    'indmoney': 'INDmoney',
    'ind money': 'INDmoney',
    'fisdom': 'Fisdom',
    'paytm money': 'Paytm Money',
    'etmoney': 'ET Money',
    'et money': 'ET Money',
    'cred': 'CRED',
    'navi': 'Navi',
    'navi finserv': 'Navi',
    'jupiter': 'Jupiter',
    'jupiter money': 'Jupiter',
    'slice': 'Slice',
    'fibe': 'Fibe',
    'early salary': 'EarlySalary',
    'earlysalary': 'EarlySalary',
    'moneytap': 'MoneyTap',
    'money tap': 'MoneyTap',
    'kreditbee': 'KreditBee',
    'paysense': 'PaySense',
    'paytm': 'Paytm',
    'one97': 'Paytm',
    'phonepe': 'PhonePe',
    'phone pe': 'PhonePe',
    'gpay': 'Google Pay',
    'google pay': 'Google Pay',
    'bhim': 'BHIM UPI',
    'bajaj finserv': 'Bajaj Finserv',
    'bajaj fin': 'Bajaj Finserv',
    'bajaj': 'Bajaj Finserv',
    'hdfc': 'HDFC',
    'icici': 'ICICI',
    'sbi': 'SBI',
    'axis': 'Axis Bank',
    'kotak': 'Kotak Bank',
    'yes bank': 'Yes Bank',
    'idfc': 'IDFC First Bank',
    'cleartax': 'ClearTax',
    'clear tax': 'ClearTax',

    // ── Insurance ────────────────────────────────────────────────────────────────
    'lic': 'LIC',
    'life insurance': 'LIC',
    'lic premium': 'LIC',
    'hdfc life': 'HDFC Life',
    'max life': 'Max Life',
    'star health': 'Star Health',
    'starhealthinsurance': 'Star Health',
    'policybazaar': 'PolicyBazaar',
    'policy bazar': 'PolicyBazaar',
    'pb partners': 'PolicyBazaar',
    'acko': 'Acko',
    'digit insurance': 'Digit',
    'go digit': 'Digit',
    'sbi life': 'SBI Life',
    'icici pru': 'ICICI Prudential',
    'tata aia': 'Tata AIA',

    // ── Health / Pharmacy ────────────────────────────────────────────────────────
    'apollo pharmacy': 'Apollo Pharmacy',
    'apollopharmacy': 'Apollo Pharmacy',
    'apollo med': 'Apollo Pharmacy',
    'apollo': 'Apollo',
    'medplus': 'MedPlus',
    'practo': 'Practo',
    '1mg': '1mg',
    'tata 1mg': '1mg',
    'onemg': '1mg',
    'netmeds': 'Netmeds',
    'pharmeasy': 'PharmEasy',
    'pharm easy': 'PharmEasy',
    'medlife': 'Medlife',
    'med life': 'Medlife',
    'mfine': 'MFine',
    'aster dm': 'Aster DM',
    'healthkart': 'HealthKart',
    'health kart': 'HealthKart',
    'cult.fit': 'Cult.fit',
    'cult fit': 'Cult.fit',
    'curefit': 'Cult.fit',
    'cure fit': 'Cult.fit',
    'healthifyme': 'HealthifyMe',
    'fitpass': 'Fitpass',

    // ── Education ────────────────────────────────────────────────────────────────
    'byju': "BYJU'S",
    'byjus': "BYJU'S",
    'think and learn': "BYJU'S",
    'think & learn': "BYJU'S",
    'unacademy': 'Unacademy',
    'vedantu': 'Vedantu',
    'upgrad': 'upGrad',
    'up grad': 'upGrad',
    'coursera': 'Coursera',
    'udemy': 'Udemy',
    'physicswallah': 'Physics Wallah',
    'pw': 'Physics Wallah',
    'toppr': 'Toppr',
    'whitehat jr': 'WhiteHat Jr',
    'whitehatjr': 'WhiteHat Jr',
    'simplilearn': 'Simplilearn',
    'geeksforgeeks': 'GeeksForGeeks',
    'gfg': 'GeeksForGeeks',

    // ── Personal Care ─────────────────────────────────────────────────────────────
    'urban company': 'Urban Company',
    'urbanclap': 'Urban Company',
    'vlcc': 'VLCC',
    'jawed habib': 'Jawed Habib',
    'naturals': 'Naturals',
    'lakme': 'Lakme',
    'loreal': "L'Oréal",
    'mamaearth': 'Mamaearth',
    'wow skin science': 'WOW Skin',
    'beardo': 'Beardo',
    'ustraa': 'Ustraa',
    'bombay shaving': 'Bombay Shaving Company',

    // ── SaaS / Cloud ─────────────────────────────────────────────────────────────
    'google': 'Google',
    'google one': 'Google One',
    'google workspace': 'Google Workspace',
    'microsoft': 'Microsoft',
    'office 365': 'Microsoft 365',
    'msft': 'Microsoft',
    'adobe': 'Adobe',
    'dropbox': 'Dropbox',
    'zoom': 'Zoom',
    'slack': 'Slack',
    'notion': 'Notion',
    'canva': 'Canva',
    'zoho': 'Zoho',
    'freshworks': 'Freshworks',

    // ── Government ───────────────────────────────────────────────────────────────
    'epfo': 'EPFO (PF)',
    'employees pf': 'EPFO (PF)',
    'mnrega': 'MNREGA',
    'mgnregs': 'MNREGA',
    'cbic': 'CBIC (GST)',
    'gstn': 'GSTN',
    'itd': 'Income Tax',
    'income tax': 'Income Tax',
    'direct tax': 'Income Tax',
    'nps': 'NPS (Pension)',
    'national pension': 'NPS (Pension)',
    'pfrda': 'NPS (Pension)',
    'uidai': 'UIDAI',
    'aadhaar': 'UIDAI',
    'pmkisan': 'PM-KISAN',
    'parivahan': 'Parivahan (RTO)',
    'passport seva': 'Passport Seva',
    'bbps': 'BharatBillPay',
    'bharatbill': 'BharatBillPay',
  };

  // Legal entity → brand (for garbled POS strings)
  static const Map<String, String> _legalEntities = {
    'bundl technologies': 'Swiggy',
    'jubilant food': "Domino's",
    'jubilant foodworks': "Domino's",
    'golden arches': "McDonald's",
    'ani technologies': 'Ola',
    'roppen transportation': 'Rapido',
    'interglobe aviation': 'IndiGo',
    'tata sia': 'Vistara',
    'eternal limited': 'Blinkit',
    'avenue supermarts': 'DMart',
    'nextbillion technology': 'Groww',
    'rksv securities': 'Upstox',
    'one97 communications': 'Paytm',
    'ntwk18 media': 'JioCinema',
    'think and learn': "BYJU'S",
    'think & learn': "BYJU'S",
    'urban clap': 'Urban Company',
    'brainvisa technologies': 'Urban Company',
  };

  // Bank-wrapper prefixes to strip before looking up merchant
  static final _bankWrapperRe = RegExp(
    r'^(?:SBI|HDFC|ICICI|AXIS|KOTAK|PNB|BOB|CANARA|YES|INDUS|FEDERAL|IDFCFB|YESBNK|RBL)\s*[*\-\s]+'
    r'(?:POS|MERCHANT|CARD|BANK|DEBIT|TERM|RETAIL)?\s*[*\-\s]*',
    caseSensitive: false,
  );

  // Trailing city / trip / order-id noise
  static final _cityCodeRe = RegExp(r'\s+[A-Z]{2,6}\d*$');
  static final _orderIdRe = RegExp(r'[\s\-#_](?:ORDER|TXN|TRIP|REF|ID|INV)?#?\d{4,}$',
      caseSensitive: false);

  // ── Public API ────────────────────────────────────────────────────────────────

  static String normalize(String raw) {
    if (raw.trim().isEmpty) return raw;

    // Handle VPA input ("zomato.food@hdfcbank")
    if (raw.contains('@')) return _fromVpa(raw);

    // 0. Legal entity alias on the RAW string — before noise stripping, which
    //    can chop real words (e.g. "JUBILANT FOOD" → "JUBILANT" via city-code re).
    final rawLower = raw.toLowerCase().trim();
    for (final entry in _legalEntities.entries) {
      if (rawLower.contains(entry.key)) return entry.value;
    }

    final cleaned = _stripNoise(raw);
    final lower = cleaned.toLowerCase().trim();

    // 1. Exact match
    if (_map.containsKey(lower)) return _map[lower]!;

    // 2. Legal entity alias
    for (final entry in _legalEntities.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    // 3. Starts-with (handles truncation like "AMAZON SELLER SERVIC")
    for (final e in _map.entries) {
      if (lower.startsWith(e.key)) return e.value;
    }

    // 4. Substring match (≥6 chars only, avoids false positives)
    for (final e in _map.entries.where((e) => e.key.length >= 6)) {
      if (lower.contains(e.key)) return e.value;
    }

    // 5. Title-case fallback on original cleaned string
    return _toTitleCase(cleaned.trim());
  }

  /// Extract merchant prefix from VPA and normalise.
  /// "zomato.food@hdfcbank" → "Zomato"
  /// "rahul.sharma@ybl"     → "Rahul Sharma"  (personal VPA)
  static String normalizeVpa(String vpa) => _fromVpa(vpa);

  // ── Internals ────────────────────────────────────────────────────────────────

  static String _fromVpa(String vpa) {
    final lower = vpa.toLowerCase().trim();
    final localPart = lower.split('@').first;

    // Remove dots/dashes/digits from local part to get brand token
    // "zomato.food" → "zomato"   |  "uber12345" → "uber"  |  "rahul.sharma" → "rahul sharma"
    final tokens = localPart
        .replaceAll(RegExp(r'[\d_\-]+'), ' ')
        .replaceAll('.', ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    if (tokens.isEmpty) return _toTitleCase(localPart);

    // Try first token as brand key
    final firstToken = tokens.first;
    if (_map.containsKey(firstToken)) return _map[firstToken]!;

    // Try full local string (e.g. "ccd" without dots)
    final plain = tokens.join('');
    if (_map.containsKey(plain)) return _map[plain]!;

    // Starts-with on first token
    for (final e in _map.entries) {
      if (firstToken.startsWith(e.key)) return e.value;
    }

    // Return as title-case full name (for personal VPAs)
    return _toTitleCase(tokens.join(' '));
  }

  static String _stripNoise(String raw) {
    var s = raw.trim();

    // Strip bank wrapper prefix
    s = s.replaceFirst(_bankWrapperRe, '');

    // If asterisks remain, take first segment (brand is always first)
    if (s.contains('*')) {
      s = s.split('*').first.trim();
    }

    // Strip trailing city code / order ID
    s = s.replaceFirst(_orderIdRe, '');
    s = s.replaceFirst(_cityCodeRe, '');

    return s.trim();
  }

  static String _toTitleCase(String s) => s
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}
