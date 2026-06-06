import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/utils/sms_parser.dart';

void main() {
  group('SMS Parser Tests', () {
    test('Parse HDFC debit transaction', () {
      const sms = 'HDFC Bank: Debit of Rs. 500 from A/C XXXXXX0123 at RESTAURANT on 01/06/2026. Available Balance: Rs. 25000. Keep your card safe.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result, isNotNull);
      expect(result?.amount, 500);
      expect(result?.isCredit, false);
    });

    test('Parse SBI credit transaction', () {
      const sms = 'Salary Credited: Rs. 50,000 credited to SBI A/C XXXXXX9876 on 01/06/2026. Your available balance is Rs. 75000.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result, isNotNull);
      expect(result?.amount, 50000);
      expect(result?.isCredit, true);
    });

    test('Parse UPI transaction', () {
      const sms = 'You have paid Rs. 250 to MERCHANT@upi using PhonePe on 01/06/2026 at 2:30 PM. Transaction ID: XXXXX. Available balance: Rs. 5000.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result, isNotNull);
      expect(result?.amount, 250);
      expect(result?.merchant, isNotEmpty);
    });

    test('Parse ICICI card transaction', () {
      const sms = 'Dear Customer, Amount Rs. 1200.00 has been debited from your ICICI Bank Credit Card XXXX1234 on 01-Jun-2026 at 15:45 for a purchase at AMAZON.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result, isNotNull);
      expect(result?.amount, 1200);
      expect(result?.isCredit, false);
    });

    test('Parse amount with commas', () {
      const sms = 'HDFC Bank: Debit of Rs. 10,50,000 from A/C XXXXXX0123 on 01/06/2026.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result, isNotNull);
      expect(result?.amount, 1050000);
    });

    test('Reject OTP SMS', () {
      const sms = 'Your OTP for PhonePe login is 123456. Do not share with anyone.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result, isNull);
    });

    test('Reject promotional SMS', () {
      const sms = 'Special offer: Get 50% off on your next purchase at Flipkart. Visit flipkart.com to claim.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result, isNull);
    });

    test('Extract merchant name correctly', () {
      const sms = 'Amount Rs. 500 paid at ZOMATO RESTAURANT via UPI on 01/06/2026.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result?.merchant.toLowerCase(), contains('zomato'));
    });

    test('Detect debit vs credit', () {
      const debit = 'Amount Rs. 100 debited from your account.';
      const credit = 'Amount Rs. 100 credited to your account.';

      final debitResult = SmsParser.parse(debit, DateTime.now());
      final creditResult = SmsParser.parse(credit, DateTime.now());

      expect(debitResult?.isCredit, false);
      expect(creditResult?.isCredit, true);
    });

    test('Extract account last 4 digits', () {
      const sms = 'Amount debited from A/C XXXXXX0987 on 01/06/2026.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result?.accountLast4, '0987');
    });

    test('Duplicate detection via hash', () {
      const sms = 'Amount Rs. 500 debited from your account.';
      final result1 = SmsParser.parse(sms, DateTime.now());
      final result2 = SmsParser.parse(sms, DateTime.now());

      expect(result1?.rawSmsHash, result2?.rawSmsHash);
    });

    test('Handle amount with currency symbol', () {
      const sms = '₹500 debited from your account on 01/06/2026.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result?.amount, 500);
    });

    test('Handle amount without decimal', () {
      const sms = 'Amount Rs 750 has been debited from your account.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result?.amount, 750);
    });

    test('Refund detection', () {
      const sms = 'Refund of Rs. 200 has been credited to your account.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result?.isCredit, true);
    });

    test('Cashback detection', () {
      const sms = 'Cashback of Rs. 50 credited to your account.';
      final result = SmsParser.parse(sms, DateTime.now());
      expect(result?.isCredit, true);
    });
  });
}
