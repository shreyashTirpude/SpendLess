import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/transaction.dart';
import 'category_engine.dart';

class ParsedSms {
  final double amount;
  final String merchant;
  final bool isCredit;
  final String? accountLast4;
  final DateTime transactionDate;
  final String rawSmsHash;

  ParsedSms({
    required this.amount,
    required this.merchant,
    required this.isCredit,
    this.accountLast4,
    required this.transactionDate,
    required this.rawSmsHash,
  });
}

class SmsParser {
  static final _uuid = const Uuid();

  static ParsedSms? parse(String smsBody, DateTime receivedAt) {
    final body = smsBody.toLowerCase();

    if (!_isBankTransactionSms(body)) return null;

    final amount = _extractAmount(smsBody);
    if (amount == null || amount <= 0) return null;

    final isCredit = _isCredit(body);
    final merchant = _extractMerchant(smsBody, isCredit);
    final accountLast4 = _extractAccountLast4(smsBody);
    final hash = sha256.convert(utf8.encode(smsBody)).toString();

    return ParsedSms(
      amount: amount,
      merchant: merchant,
      isCredit: isCredit,
      accountLast4: accountLast4,
      transactionDate: receivedAt,
      rawSmsHash: hash,
    );
  }

  static bool _isBankTransactionSms(String body) {
    final bankKeywords = [
      'debited', 'credited', 'debit', 'credit',
      'transaction', 'payment', 'transferred',
      'upi', 'neft', 'imps', 'a/c', 'acct',
      'inr', 'rs.', '₹', 'bank',
    ];
    final count = bankKeywords.where((k) => body.contains(k)).length;
    return count >= 2;
  }

  static double? _extractAmount(String sms) {
    final patterns = [
      RegExp(r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:INR|Rs\.?|₹)', caseSensitive: false),
      RegExp(r'amount\s*(?:of\s*)?(?:INR|Rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(sms);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final parsed = double.tryParse(amountStr);
        if (parsed != null && parsed > 0 && parsed < 10000000) return parsed;
      }
    }
    return null;
  }

  static bool _isCredit(String body) {
    final creditKeywords = ['credited', 'received', 'salary', 'refund', 'cashback', 'reversal', 'added', 'deposited'];
    return creditKeywords.any((k) => body.contains(k));
  }

  static String _extractMerchant(String sms, bool isCredit) {
    final vpaPattern = RegExp(r'(?:to|from)\s+([a-zA-Z0-9._-]+@[a-zA-Z]+)', caseSensitive: false);
    final vpaMatch = vpaPattern.firstMatch(sms);
    if (vpaMatch != null) {
      return _cleanMerchantName(vpaMatch.group(1)!.split('@')[0]);
    }

    final atPattern = RegExp(r'\bat\s+([A-Z][A-Z0-9\s.&-]{2,30})(?:\s+on|\s+via|\.|,)', caseSensitive: false);
    final atMatch = atPattern.firstMatch(sms);
    if (atMatch != null) return _cleanMerchantName(atMatch.group(1)!);

    final toPattern = RegExp(r'(?:paid\s+to|to)\s+([A-Z][A-Z0-9\s.&-]{2,30})(?:\s+via|\s+on|\.|,)', caseSensitive: false);
    final toMatch = toPattern.firstMatch(sms);
    if (toMatch != null) return _cleanMerchantName(toMatch.group(1)!);

    return isCredit ? 'Bank Transfer' : 'Unknown Merchant';
  }

  static String _cleanMerchantName(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ').split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ').trim();
  }

  static String? _extractAccountLast4(String sms) {
    final patterns = [
      RegExp(r'[Aa]/[Cc]\s*[Xx*]+(\d{4})'),
      RegExp(r'[Aa]cct\s*[Xx*]+(\d{4})'),
      RegExp(r'[Aa]ccount\s*[Xx*]+(\d{4})'),
      RegExp(r'card\s*[Xx*]+(\d{4})', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(sms);
      if (m != null) return m.group(1);
    }
    return null;
  }

  static Transaction toTransaction(ParsedSms parsed, {String? userId}) {
    final category = CategoryEngine.categorize(parsed.merchant, parsed.isCredit);
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
      isSynced: false,
      createdAt: DateTime.now(),
    );
  }
}
