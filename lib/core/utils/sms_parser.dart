import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transaction.dart';
import 'category_engine.dart';
import 'merchant_normalizer.dart';

// ── ParsedSms result ──────────────────────────────────────────────────────────

class ParsedSms {
  final double amount;
  final String merchant;
  final bool isCredit;
  final String? accountLast4;
  final DateTime transactionDate;
  final String rawSmsHash;
  final String rawSmsBody;
  final String? vpa;         // UPI VPA if detected
  final String channel;      // UPI | IMPS | NEFT | RTGS | ATM | POS | ECS | NACH | UNKNOWN
  final bool isP2P;          // true when VPA looks like personal transfer

  const ParsedSms({
    required this.amount,
    required this.merchant,
    required this.isCredit,
    this.accountLast4,
    required this.transactionDate,
    required this.rawSmsHash,
    required this.rawSmsBody,
    this.vpa,
    this.channel = 'UNKNOWN',
    this.isP2P = false,
  });
}

// ── Main parser ───────────────────────────────────────────────────────────────

class SmsParser {
  static const _uuid = Uuid();

  // ── Bank sender-ID allowlist (TRAI DLT headers) ───────────────────────────
  static const _trustedSenderPrefixes = [
    'HDFCBK', 'HDFCBN', 'HDFCCC',
    'ICICIB', 'ICICBK', 'ICICCC',
    'SBIBNK', 'SBMSMS', 'SBIPSG', 'SBICRD', 'SBIBK',
    'AXISBK', 'AXISBN', 'AXISCC',
    'KOTAKB', 'KTBANK',
    'YESBNK', 'YESBK',
    'IDFCFB', 'IDFCBK',
    'BOIBNK', 'BOIBAL',
    'PNBSMS', 'PUNBNK',
    'CANBNK', 'CANBK',
    'UNIBNK', 'UNBKOF',
    'INDBNK', 'INDUSB',
    'RBLBNK',
    'FEDBK', 'FEDBNK',
    'HSBCIN',
    'SCBKMS', 'SCBANK',
    'AUSFBN', 'AUBANK',
    'BOBBNK', 'BOBSMS',
    'IDBISB',
    'AMEXIN',
    'CITIBK', 'CITICC',
    'PAYTMB', 'PYTBNK',
    'PHONEPE', 'PPEBNK',
    'GPAYSM',
  ];

  // ── Reject patterns (OTP, promo, failed, alert-only) ─────────────────────
  static const _rejectKeywords = [
    'otp', 'one time password', 'verification code',
    'do not share', 'not share', 'expires in',
    'valid for', 'use this code', 'your code',
    'win ', 'winner', 'subscribe now',
    'congratulations you', 'limited time', 'exclusive deal',
    'your otp', 'pin is', 'secret code', 'cvv',
    // Failed / reversed transactions
    'transaction failed', 'txn failed', 'failed transaction',
    'declined', 'unsuccessful', 'could not be processed',
    'transaction has been reversed', 'amount will be reversed',
    'your upi transaction.*failed',
  ];

  // ── Promotional / loan-offer / marketing signals ──────────────────────────
  // These are advertising messages that contain ₹ amounts and bank words but
  // are NOT transactions (e.g. "You are eligible for a pre-approved loan of
  // Rs 25,00,000. Apply now"). They're only rejected when the message does NOT
  // look like a confirmed transaction (see [_looksConfirmed]) — so a real
  // "NACH PERSONAL LOAN EMI debited" still goes through.
  static const _promotionalKeywords = [
    // loan / credit-card marketing
    'pre-approved', 'pre approved', 'preapproved', 'pre-qualified',
    'you are eligible', 'are eligible', 'eligible for', 'eligibility',
    'loan offer', 'instant loan', 'loan up to', 'loan upto', 'loan of rs',
    'loan of inr', 'loan of ₹', 'get a loan', 'avail a loan', 'avail loan',
    'apply now', 'apply today', 'apply for', 'apply online', 'click to apply',
    'loan approved', 'sanctioned for you', 'credit limit increase',
    'increase your limit', 'upgrade your card', 'lifetime free card',
    // rates / terms (marketing)
    'interest rate', 'lowest interest', 'lowest emi', 'emi starting',
    'starting at just', 'roi of', 'attractive interest', 'flexible tenure',
    // rewards / discounts
    'cashback', 'reward points', 'redeem', 'voucher', 'coupon', 'gift card',
    'flat ', '% off', 'discount', 'mega sale', 'offer ends', 'best deal',
    'special offer', 'festive offer', 'exclusive offer',
    // call-to-action / spam markers
    'click here', 'click the link', 'apply here', 't&c apply', 'tnc apply',
    'call now', 'missed call', 'toll free', 'toll-free', 'give a missed call',
    'download the app', 'install now', 'register now', 'hurry', 'last day',
    'limited period', 'http://', 'https://', 'bit.ly', 'tinyurl', 'www.',
  ];

  // ── Bank signal keywords (need ≥2 hits) ──────────────────────────────────
  static const _bankKeywords = [
    'debited', 'credited', 'debit', 'credit',
    'transaction', 'payment', 'transferred', 'transfer',
    'upi', 'neft', 'imps', 'rtgs', 'nach', 'ecs',
    'a/c', 'acct', 'account', 'a/c no',
    'inr', 'rs.', 'rs ', '₹',
    'bank', 'balance', 'avl bal', 'avail bal',
    'money received', 'amount received',
    'spent at', 'spent on', 'spent', 'card', 'withdrawn', 'purchase',
    'pos', 'atm',
  ];

  // ── Personal UPI VPA suffixes (strong P2P signal) ────────────────────────
  static const _personalVpaSuffixes = {
    'ybl', 'ibl', 'axl',          // PhonePe
    'oksbi', 'okaxis', 'okicici', 'okhdfcbank', // Google Pay (personal)
    'paytm',                        // Paytm personal
    'upi',                          // BHIM
    'apl',                          // Amazon Pay personal
    'sbi', 'icici', 'hdfcbank', 'axisbank', 'kotak',
    'yesbank', 'federal', 'indus', 'rbl',
  };

  // ── Business/merchant-only VPA suffixes ───────────────────────────────────
  static const _merchantVpaSuffixes = {
    'razorpay', 'upirzp',
    'paytmqr',
    'yapl', 'rapl',       // Amazon Pay merchant
    'freecharge',
    'pinelab',
    'zoicici',            // Zomato
    'tapicici',           // Tata Neu
    'fkaxis',             // Flipkart
    'axisgo',             // Ola
    'sliceaxis',          // Slice
    'jupiteraxis',        // Jupiter
    'niyoicici',          // Niyo
    'wahdfcbank', 'waicici', 'wasbi', // WhatsApp Pay
  };

  // ── Main parse entry-point ────────────────────────────────────────────────

  static ParsedSms? parse(String smsBody, DateTime receivedAt,
      {String? senderAddress}) {
    final body = smsBody.toLowerCase();

    // Optional: trust check on sender
    if (senderAddress != null && senderAddress.isNotEmpty) {
      if (!_isTrustedSender(senderAddress)) return null;
    }

    if (_shouldReject(body)) return null;
    if (!_isBankSms(body)) return null;

    // Skip promotional / loan-offer spam (unless it's a confirmed transaction)
    if (_isPromotional(body) && !_looksConfirmed(body)) return null;

    // Skip failed transactions
    if (_isFailed(body)) return null;

    final amount = _extractBestAmount(smsBody);
    if (amount == null || amount <= 0) return null;

    final isCredit = _detectCredit(body);
    final channel = _detectChannel(body);
    final vpaRaw = _extractVpa(smsBody);
    final isP2P = vpaRaw != null && _isPersonalVpa(vpaRaw);

    String merchant;
    if (vpaRaw != null) {
      merchant = MerchantNormalizer.normalizeVpa(vpaRaw);
    } else {
      final raw = _extractMerchant(smsBody, body, isCredit, channel);
      merchant = MerchantNormalizer.normalize(raw);
    }

    final accountLast4 = _extractAccountLast4(smsBody);
    final txDate = _extractDateFromSms(smsBody) ?? receivedAt;
    final hash = sha256.convert(utf8.encode(smsBody)).toString();

    return ParsedSms(
      amount: amount,
      merchant: merchant,
      isCredit: isCredit,
      accountLast4: accountLast4,
      transactionDate: txDate,
      rawSmsHash: hash,
      rawSmsBody: smsBody,
      vpa: vpaRaw,
      channel: channel,
      isP2P: isP2P,
    );
  }

  // ── Trusted sender check ──────────────────────────────────────────────────

  static bool _isTrustedSender(String sender) {
    // Strip TRAI suffix: HDFCBK-S, SBIBNK-T → HDFCBK
    final clean = sender.toUpperCase().replaceAll(RegExp(r'-[STPG]$'), '').trim();
    return _trustedSenderPrefixes.any(
      (prefix) => clean.startsWith(prefix) || clean == prefix,
    );
  }

  static bool _shouldReject(String body) =>
      _rejectKeywords.any((k) => body.contains(k));

  /// Marketing/loan-offer language present.
  static bool _isPromotional(String body) =>
      _promotionalKeywords.any((k) => body.contains(k));

  /// A genuine transaction confirmation: a settlement verb applied to an
  /// account/card with a balance or reference. Loan/credit *offers* never have
  /// this; real loan-EMI debits and disbursal credits do.
  static bool _looksConfirmed(String body) {
    final hasVerb = body.contains('debited') ||
        body.contains('credited') ||
        body.contains('withdrawn') ||
        body.contains('spent') ||
        body.contains('deducted') ||
        (body.contains('paid') && body.contains(' to ')) ||
        body.contains('received');
    final hasAnchor = body.contains('a/c') ||
        body.contains('acct') ||
        body.contains('account') ||
        body.contains('card') ||
        body.contains('avl bal') ||
        body.contains('avbl bal') ||
        body.contains('available bal') ||
        body.contains('bal:') ||
        body.contains('upi ref') ||
        body.contains('txn id') ||
        body.contains('ref no') ||
        body.contains('utr');
    return hasVerb && hasAnchor;
  }

  static bool _isBankSms(String body) {
    final hits = _bankKeywords.where((k) => body.contains(k)).length;
    return hits >= 2;
  }

  static bool _isFailed(String body) {
    const failKeywords = [
      'transaction failed', 'txn failed', 'payment failed',
      'failed.', 'failed!', 'has failed', 'was unsuccessful',
      'could not be processed', 'declined', 'reversed within',
      'will be reversed', 'has been reversed',
    ];
    // A genuine refund often reads "reversed and credited back to your A/c" —
    // that's a real CREDIT, not a failed debit. Don't drop it.
    final isRefundCredit = (body.contains('credited') || body.contains('refund')) &&
        (body.contains('revers') || body.contains('reversed'));
    if (isRefundCredit) return false;
    return failKeywords.any((k) => body.contains(k));
  }

  // ── Channel detection ─────────────────────────────────────────────────────

  static String _detectChannel(String body) {
    if (body.contains('nach') || body.contains('ecs')) return 'NACH';
    if (body.contains('atm') || body.contains('cash withdrawal') || body.contains('atm wd')) return 'ATM';
    if (body.contains('rtgs')) return 'RTGS';
    if (body.contains('neft')) return 'NEFT';
    if (body.contains('imps')) return 'IMPS';
    if (body.contains('upi')) return 'UPI';
    if (body.contains('pos') || body.contains('ecom') || body.contains('spent at')) return 'POS';
    return 'UNKNOWN';
  }

  // ── VPA extraction ────────────────────────────────────────────────────────

  static String? _extractVpa(String sms) {
    // Match VPA patterns: word@word  (e.g. zomato@icici, 9876543210@oksbi)
    final re = RegExp(
      r'(?:to|from|vpa\s*[:=]?)\s*([\w.\-]+@[\w]+)',
      caseSensitive: false,
    );
    final m = re.firstMatch(sms);
    if (m != null) {
      final v = m.group(1)!.toLowerCase();
      if (_isValidPayeeVpa(v)) return v;
    }

    // Bare VPA in SMS body (HDFC Info: field, etc.)
    for (final match in RegExp(r'\b([\w.\-]{3,}@[\w]{2,})\b').allMatches(sms)) {
      final v = match.group(1)!.toLowerCase();
      if (_isValidPayeeVpa(v)) return v;
    }

    return null;
  }

  /// Reject email addresses (support/no-reply lines) and noise handles that
  /// look like a VPA but aren't a payee (e.g. info@hdfcbank.com, care@bank).
  static bool _isValidPayeeVpa(String v) {
    final parts = v.split('@');
    if (parts.length != 2) return false;
    final prefix = parts[0];
    final suffix = parts[1];
    // Real UPI handles have no dot in the suffix; emails do (.com/.in).
    if (suffix.contains('.')) return false;
    const noise = {
      'info', 'noreply', 'no-reply', 'donotreply', 'alerts', 'alert',
      'care', 'support', 'help', 'service', 'notifications', 'notify',
    };
    if (noise.contains(prefix)) return false;
    return true;
  }

  static bool _isPersonalVpa(String vpa) {
    final parts = vpa.split('@');
    if (parts.length < 2) return false;
    final suffix = parts[1].toLowerCase();
    final prefix = parts[0].toLowerCase();

    // Merchant-only suffix → not personal
    if (_merchantVpaSuffixes.contains(suffix)) return false;

    // Pure 10-digit mobile → personal
    if (RegExp(r'^\d{10}$').hasMatch(prefix)) return true;

    // Personal VPA suffix + non-brand prefix → personal
    if (_personalVpaSuffixes.contains(suffix)) {
      // If prefix matches known merchant keywords → not personal
      final merchantPrefixes = [
        'zomato', 'swiggy', 'uber', 'ola', 'amazon', 'flipkart',
        'netflix', 'spotify', 'hotstar', 'jio', 'airtel', 'blinkit',
        'zepto', 'bigbasket', 'irctc', 'dominos', 'kfc', 'mcdonalds',
        'paytm', 'phonepe', 'bookmyshow', 'pvr', 'inox', 'dream11',
        'groww', 'zerodha', 'upstox', 'cred', 'practo', 'nykaa',
        'myntra', 'ajio', 'dmart', 'makemytrip', 'oyo',
      ];
      final alphaPrefix = prefix.replaceAll(RegExp(r'[\d.\-_]'), '');
      if (merchantPrefixes.any((m) => alphaPrefix.startsWith(m))) return false;
      return true;
    }

    return false;
  }

  // ── Amount extraction ─────────────────────────────────────────────────────

  // Balance-exclusion strategy: exclude the balance value
  static double? _extractBestAmount(String sms) {
    final balVal = extractBalance(sms);

    final patterns = [
      // Action keyword + amount (highest precision)
      RegExp(
        r'(?:debited|credited|paid|sent|received|spent|withdrawn)\s+(?:(?:by|with|of)\s+)?(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      // "of INR/Rs/₹ <amount>"
      RegExp(r'of\s+(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      // "amount/amt ₹<amount>"
      RegExp(
        r'(?:amount|amt)(?:\s+of)?:?\s*(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      // General currency prefix
      RegExp(r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      // Amount before currency
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:INR|Rs\.?)', caseSensitive: false),
    ];

    double? firstCandidate;
    for (final p in patterns) {
      for (final m in p.allMatches(sms)) {
        final raw = m.group(1)!.replaceAll(',', '');
        final v = double.tryParse(raw);
        if (v == null || v < 1.0 || v >= 1000000000) continue;
        firstCandidate ??= v;
        if (balVal == null || (v - balVal).abs() > 0.01) return v;
      }
    }
    return firstCandidate;
  }

  // ── Debit / Credit detection ──────────────────────────────────────────────

  static bool _detectCredit(String body) {
    const debitSignals = [
      'debited', 'deducted', 'withdrawn', 'spent at', 'sent to',
      'paid to', 'payment made', 'purchase of', 'purchase at',
      'a/c debited', 'acct debited', 'is debited', 'has been debited',
    ];
    if (debitSignals.any((k) => body.contains(k))) return false;

    const creditSignals = [
      'credited', 'received', 'salary', 'refund', 'cashback',
      'reversal', 'added to', 'deposited', 'money received',
      'amount received', 'payment received', 'a/c credited',
      'is credited', 'has been credited',
    ];
    return creditSignals.any((k) => body.contains(k));
  }

  // ── Merchant extraction (bank-specific patterns) ──────────────────────────

  static String _extractMerchant(
      String sms, String body, bool isCredit, String channel) {

    // 1. HDFC / Kotak / Axis "Info: MERCHANT*CITY" pattern
    final info = RegExp(
      r'Info[:\s]+([A-Za-z0-9][A-Za-z0-9 .\-&*]{2,40}?)(?:\s*\.|$|\s+UPI|\s+Ref|\s+Avl)',
      caseSensitive: false,
    ).firstMatch(sms);
    if (info != null) {
      final raw = info.group(1)!.split('*').first.trim();
      if (raw.toLowerCase() != 'upi' && raw.length > 2) return raw;
    }

    // 2. SBI "UPI-RECIPIENT-vpa-Ref" pattern
    final sbiUpi = RegExp(r'UPI-([^-\s]{3,36})-', caseSensitive: false).firstMatch(sms);
    if (sbiUpi != null) {
      final candidate = sbiUpi.group(1)!;
      if (!candidate.toUpperCase().startsWith('REF') && !RegExp(r'^\d+$').hasMatch(candidate)) {
        return candidate;
      }
    }

    // 3. "at MERCHANT NAME" — card / POS swipe
    final atM = RegExp(
      r'\bat\s+([A-Za-z0-9][A-Za-z0-9 .&\-]{2,36}?)(?=\s+on|\s+via|\s+dated|[.,]|\d{2}[\/\-]|\s*$)',
      caseSensitive: false,
    ).firstMatch(sms);
    if (atM != null) {
      final c = atM.group(1)!.trim();
      if (!_isJunkMerchant(c)) return c;
    }

    // 4. "paid to NAME" / "sent to NAME" / "transferred to NAME"
    final toM = RegExp(
      r'(?:paid\s+to|sent\s+to|transferred\s+to|to)\s+([A-Za-z0-9][A-Za-z0-9 .&\-]{2,36}?)(?=\s+via|\s+on|\s+using|\s+ref|[.,]|\s*$)',
      caseSensitive: false,
    ).firstMatch(sms);
    if (toM != null) {
      final c = toM.group(1)!.trim();
      if (!_isJunkMerchant(c)) return c;
    }

    // 5. "received from NAME" — for credits
    if (isCredit) {
      final fromM = RegExp(
        r'(?:from|received\s+from)\s+([A-Za-z0-9][A-Za-z0-9 .&\-]{2,36}?)(?=\s+via|\s+on|[.,]|\s*$)',
        caseSensitive: false,
      ).firstMatch(sms);
      if (fromM != null) {
        final c = fromM.group(1)!.trim();
        if (!_isJunkMerchant(c)) return c;
      }
    }

    // 6. ICICI "; MERCHANT credited" pattern
    final icicI = RegExp(
      r';\s*([A-Za-z0-9][A-Za-z0-9 .&\-]{2,36}?)\s+credited',
      caseSensitive: false,
    ).firstMatch(sms);
    if (icicI != null) return icicI.group(1)!.trim();

    // 7. Ref to / Desc / Narration
    final ref = RegExp(
      r'(?:Ref\s+to|Desc|Narr(?:ation)?):\s*([A-Za-z0-9][A-Za-z0-9 .&\-]{2,36})',
      caseSensitive: false,
    ).firstMatch(sms);
    if (ref != null) return ref.group(1)!.trim();

    // 8. NACH/ECS → use lender name from SMS if possible
    if (channel == 'NACH') {
      final nach = RegExp(
        r'(?:towards|for|to)\s+([A-Za-z0-9][A-Za-z0-9 .&\-]{2,36})',
        caseSensitive: false,
      ).firstMatch(sms);
      if (nach != null) return nach.group(1)!.trim();
    }

    return isCredit ? 'Bank Transfer' : 'Unknown';
  }

  static bool _isJunkMerchant(String s) {
    final lower = s.toLowerCase().trim();
    const junk = ['atm', 'bank', 'branch', 'neft', 'imps', 'rtgs', 'upi', 'a/c', 'account'];
    return junk.contains(lower) || lower.length < 2;
  }

  // ── Account number ────────────────────────────────────────────────────────

  static String? _extractAccountLast4(String sms) {
    for (final p in [
      RegExp(r'[Aa]/[Cc]\s*[Xx*]{2,}(\d{4})'),
      RegExp(r'[Aa]cct?\s*[Xx*]{2,}(\d{4})'),
      RegExp(r'[Aa]ccount\s*(?:no\.?\s*)?[Xx*]{2,}(\d{4})'),
      RegExp(r'[Cc]ard\s*[Xx*]{2,}(\d{4})'),
      RegExp(r'[Xx*]{4,}(\d{4})'),
      RegExp(r'[Aa]/[Cc]\s*(?:[Nn]o\.?)?\s*[Xx*]{2,4}(\d{4})'),
    ]) {
      final m = p.firstMatch(sms);
      if (m != null) return m.group(1);
    }
    return null;
  }

  // ── Balance extraction ────────────────────────────────────────────────────

  static double? extractBalance(String sms) {
    final patterns = [
      RegExp(
        r'[Aa]vl?\.?\s*[Bb]al(?:ance)?\s*(?:is|:)?\s*(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'[Bb]alance\s*(?:is|:)?\s*(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)\s*(?:is your balance|available)',
        caseSensitive: false,
      ),
      // Credit card: Available limit
      RegExp(
        r'[Aa]vl?\.?\s*(?:[Cc]redit\s+)?[Ll]imit\s*(?:is|:)?\s*(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(sms);
      if (m != null) {
        final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
        if (v != null && v >= 0) return v;
      }
    }
    return null;
  }

  // ── Date extraction from SMS body ─────────────────────────────────────────

  static DateTime? _extractDateFromSms(String sms) {
    // DD-Mon-YY or DD-Mon-YYYY  e.g. "12-Jun-25", "20-Oct-2024"
    final monRe = RegExp(
      r'\b(\d{1,2})[-/]([A-Z][a-z]{2})[-/](\d{2,4})\b',
      caseSensitive: false,
    );
    final m1 = monRe.firstMatch(sms);
    if (m1 != null) {
      final day = int.tryParse(m1.group(1)!);
      final mon = _monthNum(m1.group(2)!);
      var year = int.tryParse(m1.group(3)!);
      if (day != null && mon != null && year != null) {
        if (year < 100) year += 2000;
        return DateTime(year, mon, day);
      }
    }

    // DD/MM/YYYY or DD-MM-YYYY
    final dmyRe = RegExp(r'\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})\b');
    final m2 = dmyRe.firstMatch(sms);
    if (m2 != null) {
      final day = int.tryParse(m2.group(1)!);
      final mon = int.tryParse(m2.group(2)!);
      var year = int.tryParse(m2.group(3)!);
      if (day != null && mon != null && year != null &&
          day >= 1 && day <= 31 && mon >= 1 && mon <= 12) {
        if (year < 100) year += 2000;
        return DateTime(year, mon, day);
      }
    }

    return null;
  }

  static int? _monthNum(String abbr) => const {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  }[abbr.toLowerCase()];

  // ── Transaction builder ───────────────────────────────────────────────────

  static Transaction toTransaction(ParsedSms parsed, {String? userId}) {
    final category = CategoryEngine.categorizeFromSms(
      parsed.rawSmsBody,
      parsed.merchant,
      isCredit: parsed.isCredit,
      vpa: parsed.vpa,
      channel: parsed.channel,
      isP2P: parsed.isP2P,
    );

    // Store VPA in note field for cashflow P2P classification
    final note = parsed.vpa != null ? 'vpa:${parsed.vpa}' : null;

    return Transaction(
      id: _uuid.v4(),
      userId: userId,
      amount: parsed.amount,
      merchant: parsed.merchant,
      category: category,
      isCredit: parsed.isCredit,
      accountLast4: parsed.accountLast4,
      transactionDate: parsed.transactionDate,
      rawSmsHash: parsed.rawSmsHash,
      source: 'sms',
      note: note,
      isSynced: false,
      createdAt: DateTime.now(),
    );
  }
}
