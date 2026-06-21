import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/utils/category_engine.dart';

void main() {
  // ── categorize() ──────────────────────────────────────────────────────────

  group('CategoryEngine.categorize()', () {
    test('Zomato → Food & Dining', () {
      expect(CategoryEngine.categorize('Zomato', false), 'Food & Dining');
    });

    test('Swiggy → Food & Dining', () {
      expect(CategoryEngine.categorize('Swiggy', false), 'Food & Dining');
    });

    test('Uber → Transport', () {
      expect(CategoryEngine.categorize('Uber', false), 'Transport');
    });

    test('Ola → Transport', () {
      expect(CategoryEngine.categorize('Ola Cabs', false), 'Transport');
    });

    test('Amazon → Shopping', () {
      expect(CategoryEngine.categorize('Amazon', false), 'Shopping');
    });

    test('Flipkart → Shopping', () {
      expect(CategoryEngine.categorize('Flipkart', false), 'Shopping');
    });

    test('credit → Income', () {
      expect(CategoryEngine.categorize('Bank Credit', true), 'Income');
    });

    test('Netflix → Subscriptions', () {
      expect(CategoryEngine.categorize('Netflix', false), 'Subscriptions');
    });

    test('Airtel → Bills & Utilities', () {
      expect(CategoryEngine.categorize('Airtel', false), 'Bills & Utilities');
    });

    test('Apollo Pharmacy → Health', () {
      expect(CategoryEngine.categorize('Apollo Pharmacy', false), 'Health');
    });

    test('Zerodha → Investment', () {
      expect(CategoryEngine.categorize('Zerodha', false), 'Investment');
    });

    test('unknown merchant → Other', () {
      expect(CategoryEngine.categorize('Xyzzy Corp', false), 'Other');
    });
  });

  // ── categorizeFromSms() ───────────────────────────────────────────────────

  group('CategoryEngine.categorizeFromSms()', () {
    test('Zomato UPI → Food & Dining (raw SMS wins)', () {
      const rawSms = 'Rs.350 paid to zomato@okicici via UPI. A/c XXXX1234.';
      expect(
        CategoryEngine.categorizeFromSms(rawSms, 'zomato@okicici', isCredit: false),
        'Food & Dining',
      );
    });

    test('salary credit → Salary', () {
      const rawSms = 'Salary of INR 80000 credited to A/c XXXX5678.';
      expect(
        CategoryEngine.categorizeFromSms(rawSms, 'NEFT/salary', isCredit: true),
        'Salary',
      );
    });

    test('refund credit → Refund', () {
      const rawSms = 'Refund of Rs.300 credited to A/c XXXX4444 from Flipkart.';
      expect(
        CategoryEngine.categorizeFromSms(rawSms, 'Flipkart', isCredit: true),
        'Refund',
      );
    });

    test('UPI P2P (friend) → Send Money', () {
      const rawSms = 'Rs.500 sent to Rahul via UPI. A/c XXXX1111.';
      expect(
        CategoryEngine.categorizeFromSms(rawSms, 'rahul@ybl', isCredit: false),
        'Send Money',
      );
    });

    test('ATM withdrawal → ATM & Cash', () {
      const rawSms = 'Rs.2000 withdrawn from ATM. A/c XXXX6789.';
      expect(
        CategoryEngine.categorizeFromSms(rawSms, 'ATM', isCredit: false),
        'ATM & Cash',
      );
    });

    test('named merchant beats UPI keyword', () {
      const rawSms = 'Rs.200 paid to netflix@hdfcbank via UPI. A/c XXXX9999.';
      expect(
        CategoryEngine.categorizeFromSms(rawSms, 'netflix@hdfcbank', isCredit: false),
        'Subscriptions',
      );
    });
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  group('CategoryEngine helpers', () {
    test('expenseCategories is non-empty', () {
      expect(CategoryEngine.expenseCategories, isNotEmpty);
    });

    test('expenseCategories contains Food & Dining', () {
      expect(CategoryEngine.expenseCategories, contains('Food & Dining'));
    });

    test('getCategoryIcon returns emoji string', () {
      final icon = CategoryEngine.getCategoryIcon('Food & Dining');
      expect(icon, isNotNull);
      expect(icon!.length, greaterThan(0));
    });

    test('getCategoryFlutterColor returns non-null', () {
      final color = CategoryEngine.getCategoryFlutterColor('Transport');
      expect(color, isNotNull);
    });

    test('getCategoryColor returns hex string starting with #', () {
      final hexColor = CategoryEngine.getCategoryColor('Shopping');
      expect(hexColor, isNotNull);
      expect(hexColor!, startsWith('#'));
    });

    test('getCategoryColor for unknown returns non-null', () {
      final hexColor = CategoryEngine.getCategoryColor('NonExistentCategory');
      expect(hexColor, isNotNull);
    });
  });
}
