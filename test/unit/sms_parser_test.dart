import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/utils/sms_parser.dart';

void main() {
  final now = DateTime(2024, 6, 15, 10, 30);

  // ── Rejection filters ──────────────────────────────────────────────────────

  group('SmsParser — rejection', () {
    test('rejects OTP SMS', () {
      const sms = 'Your OTP is 123456. Do not share this with anyone. Valid for 10 minutes.';
      expect(SmsParser.parseSingle(sms, now), isNull);
    });

    test('rejects "your code" SMS', () {
      const sms = 'Your code is 998877. Use it to verify your account.';
      expect(SmsParser.parseSingle(sms, now), isNull);
    });

    test('rejects promotional SMS', () {
      const sms = 'Exclusive offer! Get 50% cashback on your next order. Limited time only!';
      expect(SmsParser.parseSingle(sms, now), isNull);
    });

    test('rejects winner congratulations SMS', () {
      const sms = 'Congratulations you have won a free prize. Claim now!';
      expect(SmsParser.parseSingle(sms, now), isNull);
    });

    test('rejects shipping notification', () {
      const sms = 'Your order has been shipped. Expected delivery in 3 days.';
      expect(SmsParser.parseSingle(sms, now), isNull);
    });

    test('rejects sparse SMS with only 1 bank keyword', () {
      const sms = 'Please check your account.';
      expect(SmsParser.parseSingle(sms, now), isNull);
    });
  });

  // ── Debit detection ────────────────────────────────────────────────────────

  group('SmsParser — debit', () {
    test('HDFC debited keyword', () {
      const sms = 'Rs.1500.00 debited from A/c XXXX1234 on 15-Jun-24 Info: Zomato. Avl Bal: Rs.12345.';
      final r = SmsParser.parseSingle(sms, now);
      expect(r, isNotNull);
      expect(r!.isCredit, false);
      expect(r.amount, 1500.0);
    });

    test('spent at pattern', () {
      const sms = 'INR 500 spent at Amazon on 15-Jun-24. A/c XXXX5678. Avl Bal: 8000.';
      final r = SmsParser.parseSingle(sms, now);
      expect(r, isNotNull);
      expect(r!.isCredit, false);
    });

    test('paid to pattern', () {
      const sms = 'Rs.350 paid to Swiggy via UPI. A/c XXXX9999. Avl Bal: 8000.';
      final r = SmsParser.parseSingle(sms, now);
      expect(r, isNotNull);
      expect(r!.isCredit, false);
    });

    test('sent to pattern (NEFT)', () {
      const sms = 'INR 1000 sent to rahul@ybl via IMPS. A/c XXXX1111. Bal: 9000.';
      final r = SmsParser.parseSingle(sms, now);
      expect(r, isNotNull);
      expect(r!.isCredit, false);
    });

    test('debit beats refund in reference number', () {
      const sms = 'Rs.200 debited from A/c XXXX4321. Ref:refund999. Avl Bal: 5000.';
      final r = SmsParser.parseSingle(sms, now);
      expect(r, isNotNull);
      expect(r!.isCredit, false);
    });

    test('ATM withdrawal is debit', () {
      const sms = 'Rs.2000 withdrawn from ATM at A/c XXXX6789. Avl Bal: 10000.';
      final r = SmsParser.parseSingle(sms, now);
      expect(r, isNotNull);
      expect(r!.isCredit, false);
    });
  });

  // ── Credit detection ───────────────────────────────────────────────────────

  group('SmsParser — credit', () {
    test('credited keyword', () {
      const sms = 'Rs.50000 credited to A/c XXXX5678 on 01-Jun-24. Avl Bal: Rs.52000.';
      final r = SmsParser.parseSingle(sms, now);
      expect(r, isNotNull);
      expect(r!.isCredit, true);
      expect(r.amount, 50000.0);
    });

    test('salary keyword', () {
      const sms = 'Salary of INR 80000 credited to your A/c XXXX2222. Avl Bal: 85000.';
      final r = SmsParser.parseSingle(sms, now);
      expect(r, isNotNull);
      expect(r!.isCredit, true);
    });

    test('money received', () {
      const sms = 'Money received INR 5000 from Rahul. A/c XXXX3333. UPI Ref: 123.';
      final r = SmsParser.parseSingle(sms, now);
      expect(r, isNotNull);
      expect(r!.isCredit, true);
    });

    test('refund without debit signals', () {
      const sms = 'Refund of Rs.300 credited to A/c XXXX4444 from Flipkart. Avl Bal: 6000.';
      final r = SmsParser.parseSingle(sms, now);
      expect(r, isNotNull);
      expect(r!.isCredit, true);
    });
  });

  // ── Amount extraction ──────────────────────────────────────────────────────

  group('SmsParser — amount', () {
    test('INR prefix', () {
      const sms = 'INR 2500.50 debited from A/c XXXX1234. UPI Ref: 999.';
      expect(SmsParser.parseSingle(sms, now)!.amount, 2500.50);
    });

    test('Rs. prefix', () {
      const sms = 'Rs.1200 debited from A/c XXXX5678. Avl Bal: Rs.15000.';
      expect(SmsParser.parseSingle(sms, now)!.amount, 1200.0);
    });

    test('picks transaction amount over balance', () {
      const sms = 'INR 500 debited from A/c XXXX1234. Avl Bal: INR 15000.';
      expect(SmsParser.parseSingle(sms, now)!.amount, 500.0);
    });

    test('comma-formatted lakhs amount', () {
      const sms = 'Rs.1,50,000 credited to A/c XXXX1111. Avl Bal: 2,00,000.';
      expect(SmsParser.parseSingle(sms, now)!.amount, 150000.0);
    });

    test('decimal precision preserved', () {
      const sms = 'INR 499.99 debited from A/c XXXX2222. Avl Bal: 5000.';
      expect(SmsParser.parseSingle(sms, now)!.amount, 499.99);
    });

    test('returns null when no parseable amount exists', () {
      const sms = 'Your account has been debited. Please check your bank balance.';
      expect(SmsParser.parseSingle(sms, now), isNull);
    });
  });

  // ── Account last-4 ────────────────────────────────────────────────────────

  group('SmsParser — account', () {
    test('extracts from A/c XXXX format', () {
      const sms = 'Rs.500 debited from A/c XXXX5432. Avl Bal: 5000.';
      expect(SmsParser.parseSingle(sms, now)!.accountLast4, '5432');
    });

    test('extracts from card XXXX format', () {
      const sms = 'INR 200 spent on card XXXX1234. Avl Bal: 3000. Transaction alert.';
      final r = SmsParser.parseSingle(sms, now);
      expect(r, isNotNull);
      expect(r!.accountLast4, '1234');
    });
  });

  // ── Hash + body storage ────────────────────────────────────────────────────

  group('SmsParser — hash and body', () {
    test('consistent hash for same SMS', () {
      const sms = 'Rs.500 debited from A/c XXXX1234 at Swiggy. Avl Bal: 10000.';
      final r1 = SmsParser.parseSingle(sms, now);
      final r2 = SmsParser.parseSingle(sms, now);
      expect(r1!.rawSmsHash, equals(r2!.rawSmsHash));
    });

    test('different hashes for different SMS', () {
      const sms1 = 'Rs.500 debited from A/c XXXX1234.';
      const sms2 = 'Rs.600 debited from A/c XXXX1234.';
      final r1 = SmsParser.parseSingle(sms1, now);
      final r2 = SmsParser.parseSingle(sms2, now);
      expect(r1!.rawSmsHash, isNot(equals(r2!.rawSmsHash)));
    });

    test('rawSmsBody stored verbatim', () {
      const sms = 'Rs.800 debited from A/c XXXX9999. Avl Bal: 10000.';
      expect(SmsParser.parseSingle(sms, now)!.rawSmsBody, equals(sms));
    });
  });

  // ── toTransaction() ────────────────────────────────────────────────────────

  group('SmsParser.toTransaction()', () {
    test('source is "sms"', () {
      const sms = 'Rs.500 debited from A/c XXXX1234 at Swiggy. Avl Bal: 10000.';
      final tx = SmsParser.toTransaction(SmsParser.parseSingle(sms, now)!);
      expect(tx.source, equals('sms'));
    });

    test('amount propagated correctly', () {
      const sms = 'INR 750 debited from A/c XXXX2222. UPI Ref: 999.';
      final parsed = SmsParser.parseSingle(sms, now)!;
      expect(SmsParser.toTransaction(parsed).amount, equals(parsed.amount));
    });

    test('isCredit propagated correctly', () {
      const sms = 'Rs.5000 credited to A/c XXXX3333. Avl Bal: 15000.';
      expect(SmsParser.toTransaction(SmsParser.parseSingle(sms, now)!).isCredit, isTrue);
    });

    test('Zomato UPI SMS categorized as Food & Dining', () {
      const sms = 'Rs.350 paid to zomato@okicici via UPI. A/c XXXX4444.';
      final tx = SmsParser.toTransaction(SmsParser.parseSingle(sms, now)!);
      expect(tx.category, equals('Food & Dining'));
    });

    test('isSynced defaults to false', () {
      const sms = 'Rs.200 debited from A/c XXXX1234. Avl Bal: 9800.';
      expect(SmsParser.toTransaction(SmsParser.parseSingle(sms, now)!).isSynced, isFalse);
    });

    test('isIgnored defaults to false', () {
      const sms = 'Rs.100 debited from A/c XXXX1234. Avl Bal: 9900.';
      expect(SmsParser.toTransaction(SmsParser.parseSingle(sms, now)!).isIgnored, isFalse);
    });
  });
}
