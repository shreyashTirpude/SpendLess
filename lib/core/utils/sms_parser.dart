import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transaction.dart';
import 'category_engine.dart';
import 'merchant_normalizer.dart';

class ParsedSms {
  final double amount;
  final String merchant;
  final bool isCredit;
  final String? accountLast4;
  final DateTime transactionDate;
  final String rawSmsHash;
  final String rawSmsBody;

  const ParsedSms({
    required this.amount,
    required this.merchant,
    required this.isCredit,
    this.accountLast4,
    required this.transactionDate,
    required this.rawSmsHash,
    required this.rawSmsBody,
  });
}

class SmsParser {
  static const _uuid = Uuid();

  // ---------- Bank signal keywords ----------
  static const _bankKeywords = [
    'debited', 'credited', 'debit', 'credit',
    'transaction', 'payment', 'transferred', 'transfer',
    'upi', 'neft', 'imps', 'rtgs',
    'a/c', 'acct', 'account',
    'inr', 'rs.', 'rs ', '₹',
    'bank', 'balance', 'avail bal',
    'money received', 'amount received',
    'spent at', 'withdrawn', 'purchase',
  ];

  // Reject these first — OTP/promo messages that may contain bank keywords
  static const _rejectKeywords = [
    'otp', 'one time password', 'verification code',
    'do not share', 'not share', 'expires in',
    'valid for', 'use this code', 'your code',
    'offer', 'win ', 'winner', 'free ', 'subscribe now',
    'congratulations you', 'limited time', 'exclusive deal',
    'your otp', 'pin is', 'secret code',
  ];

  static ParsedSms? parse(String smsBody, DateTime receivedAt) {
    final body = smsBody.toLowerCase();

    if (_shouldReject(body)) return null;
    if (!_isBankSms(body)) return null;

    final amount = _extractBestAmount(smsBody);
    if (amount == null || amount <= 0) return null;

    final isCredit = _detectCredit(body);
    final merchant = _extractMerchant(smsBody, body, isCredit);
    final accountLast4 = _extractAccountLast4(smsBody);
    final hash = sha256.convert(utf8.encode(smsBody)).toString();

    return ParsedSms(
      amount: amount,
      merchant: merchant,
      isCredit: isCredit,
      accountLast4: accountLast4,
      transactionDate: receivedAt,
      rawSmsHash: hash,
      rawSmsBody: smsBody,
    );
  }

  static bool _shouldReject(String body) =>
      _rejectKeywords.any((k) => body.contains(k));

  static bool _isBankSms(String body) {
    final hits = _bankKeywords.where((k) => body.contains(k)).length;
    return hits >= 2;
  }

  // Extract all candidate amounts, return the most likely transaction amount.
  // Strategy: among candidates >= 1.0, return the one that appears nearest to
  // a debit/credit keyword so we pick the "transaction amount" not the balance.
  static double? _extractBestAmount(String sms) {
    final patterns = [
      RegExp(r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:INR|Rs\.?)', caseSensitive: false),
      RegExp(r'(?:amount|amt)(?:\s+of)?\s*(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(?:debited|credited|paid|sent|received)\s+(?:by\s+|with\s+)?(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(?:of\s+(?:INR|Rs\.?|₹)\s*)([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    ];

    final candidates = <double>[];
    for (final p in patterns) {
      for (final m in p.allMatches(sms)) {
        final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
        if (v != null && v >= 1.0 && v < 10000000) candidates.add(v);
      }
    }
    if (candidates.isEmpty) return null;

    // Prefer the smallest qualifying value that's not a trivially small hint number.
    // In most bank SMSes: "debited ₹500 from A/c XXXX1234 Avl Bal: ₹12,456"
    // we want 500, not 12456. So take the FIRST match (by pattern priority) if > 0.
    // If there's only one, return it directly.
    if (candidates.length == 1) return candidates.first;

    // Remove values that look like "last 4 digits" of account (< 10000 but <= 9999)
    // being the only small value vs a large balance.
    // Heuristic: if we have two+ candidates, take the one > 1 and < the largest,
    // i.e. skip the balance.
    candidates.sort();
    // Return the second-smallest if we have 2+ and the smallest looks like an account stub
    if (candidates.length >= 2 && candidates.first < 100 && candidates.last > 1000) {
      return candidates[1];
    }
    return candidates.first;
  }

  // Debit-first logic: explicit debit keywords override credit detection.
  static bool _detectCredit(String body) {
    const debitSignals = [
      'debited', 'deducted', 'withdrawn', 'spent at', 'sent to',
      'paid to', 'payment made', 'purchase of', 'purchase at',
      'a/c debited', 'acct debited',
    ];
    if (debitSignals.any((k) => body.contains(k))) return false;

    const creditSignals = [
      'credited', 'received', 'salary', 'refund', 'cashback',
      'reversal', 'added to', 'deposited', 'money received',
      'amount received', 'payment received', 'a/c credited',
    ];
    return creditSignals.any((k) => body.contains(k));
  }

  static String _extractMerchant(String sms, String body, bool isCredit) {
    // 1. UPI VPA — highest reliability for UPI transactions
    final vpa = RegExp(
      r'(?:to|from|@)\s*([a-zA-Z0-9._\-]+@[a-zA-Z0-9]+)',
      caseSensitive: false,
    ).firstMatch(sms);
    if (vpa != null) {
      final parts = vpa.group(1)!.split('@');
      return _clean(parts[0]);
    }

    // 2. "at MERCHANT NAME" — card/POS swipe pattern
    final atM = RegExp(
      r'\bat\s+([A-Z][A-Za-z0-9 .&\-]{2,36})(?=\s+on|\s+via|\s+dated|[.,]|\d{2}[\/\-]|\s*$)',
      caseSensitive: false,
    ).firstMatch(sms);
    if (atM != null) return _clean(atM.group(1)!);

    // 3. "paid to NAME" / "sent to NAME" / "transferred to NAME"
    final toM = RegExp(
      r'(?:paid\s+to|sent\s+to|transferred\s+to|to)\s+([A-Z][A-Za-z0-9 .&\-]{2,36})(?=\s+via|\s+on|\s+using|\s+ref|[.,]|\s*$)',
      caseSensitive: false,
    ).firstMatch(sms);
    if (toM != null) return _clean(toM.group(1)!);

    // 4. "received from NAME" — for credit
    if (isCredit) {
      final fromM = RegExp(
        r'(?:from|received\s+from)\s+([A-Z][A-Za-z0-9 .&\-]{2,36})(?=\s+via|\s+on|[.,]|\s*$)',
        caseSensitive: false,
      ).firstMatch(sms);
      if (fromM != null) return _clean(fromM.group(1)!);
    }

    // 5. HDFC style: "Info: MERCHANT*CITY"
    final info = RegExp(r'Info:\s*([A-Za-z0-9 .&\-]{2,36})', caseSensitive: false).firstMatch(sms);
    if (info != null) {
      final raw = info.group(1)!.split('*').first;
      return _clean(raw);
    }

    // 6. "Ref to: NAME" or "Desc: NAME"
    final ref = RegExp(r'(?:Ref\s+to|Desc|Narr(?:ation)?):\s*([A-Za-z0-9 .&\-]{2,36})', caseSensitive: false).firstMatch(sms);
    if (ref != null) return _clean(ref.group(1)!);

    // 7. Normalizer-based brand lookup across the full SMS body
    final normalized = MerchantNormalizer.normalize(body);
    if (normalized != body && normalized.isNotEmpty) return normalized;

    return isCredit ? 'Bank Transfer' : 'Unknown';
  }

  static String _clean(String raw) {
    return raw
        .trim()
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ')
        .trim();
  }

  static String? _extractAccountLast4(String sms) {
    for (final p in [
      RegExp(r'[Aa]/[Cc]\s*[Xx*]{2,}(\d{4})'),
      RegExp(r'[Aa]cct?\s*[Xx*]{2,}(\d{4})'),
      RegExp(r'[Aa]ccount\s*(?:no\.?\s*)?[Xx*]{2,}(\d{4})'),
      RegExp(r'[Cc]ard\s*[Xx*]{2,}(\d{4})'),
      RegExp(r'[Xx*]{4,}(\d{4})'),
    ]) {
      final m = p.firstMatch(sms);
      if (m != null) return m.group(1);
    }
    return null;
  }

  static double? extractBalance(String sms) {
    final patterns = [
      RegExp(r'[Aa]vl?\s*[Bb]al(?:ance)?\s*(?:is|:)?\s*(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'[Bb]alance\s*(?:is|:)?\s*(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)\s*(?:is your balance|available)', caseSensitive: false),
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

  static Transaction toTransaction(ParsedSms parsed, {String? userId}) {
    final normalizedMerchant = MerchantNormalizer.normalize(parsed.merchant);
    final category = CategoryEngine.categorizeFromSms(
      parsed.rawSmsBody,
      normalizedMerchant,
      parsed.isCredit,
    );
    return Transaction(
      id: _uuid.v4(),
      userId: userId,
      amount: parsed.amount,
      merchant: normalizedMerchant,
      category: category,
      isCredit: parsed.isCredit,
      accountLast4: parsed.accountLast4,
      transactionDate: parsed.transactionDate,
      rawSmsHash: parsed.rawSmsHash,
      source: 'sms',
      isSynced: false,
      createdAt: DateTime.now(),
    );
  }
}
