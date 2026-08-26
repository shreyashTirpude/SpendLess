import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/utils/recurring_detector.dart';
import 'package:spendlens/domain/models/transaction.dart';

Transaction _txn({
  required String id,
  required String merchant,
  required double amount,
  required DateTime date,
  bool isCredit = false,
  bool isIgnored = false,
}) {
  return Transaction(
    id: id,
    amount: amount,
    merchant: merchant,
    category: 'Other',
    isCredit: isCredit,
    transactionDate: date,
    source: 'sms',
    createdAt: date,
    isIgnored: isIgnored,
  );
}

void main() {
  group('RecurringDetector.detect', () {
    test('detects a monthly Netflix subscription', () {
      final txns = [
        _txn(id: '1', merchant: 'Netflix', amount: 649, date: DateTime(2024, 4, 5)),
        _txn(id: '2', merchant: 'Netflix', amount: 649, date: DateTime(2024, 5, 5)),
        _txn(id: '3', merchant: 'Netflix', amount: 649, date: DateTime(2024, 6, 5)),
      ];
      final items = RecurringDetector.detect(txns);
      expect(items, hasLength(1));
      final item = items.single;
      expect(item.canonicalMerchant, anyOf('Netflix', contains('Netflix')));
      expect(item.type, RecurringType.subscription);
      expect(item.avgAmount, closeTo(649, 0.01));
      expect(item.typicalDayOfMonth, inInclusiveRange(1, 31));
      expect(item.nextExpected, isNotNull);
      expect(
        item.nextExpected!.isAfter(DateTime(2024, 6, 5)),
        isTrue,
        reason: 'next charge projected after last txn',
      );
    });

    test('classifies EMI by keyword in raw merchant', () {
      final txns = [
        _txn(id: '1', merchant: 'HDFC Home Loan EMI', amount: 24500, date: DateTime(2024, 3, 10)),
        _txn(id: '2', merchant: 'HDFC Home Loan EMI', amount: 24500, date: DateTime(2024, 4, 10)),
        _txn(id: '3', merchant: 'HDFC Home Loan EMI', amount: 24500, date: DateTime(2024, 5, 10)),
      ];
      final items = RecurringDetector.detect(txns);
      expect(items, hasLength(1));
      expect(items.single.type, RecurringType.emi);
    });

    test('classifies telecom as utility', () {
      final txns = [
        _txn(id: '1', merchant: 'Jio Recharge', amount: 349, date: DateTime(2024, 3, 2)),
        _txn(id: '2', merchant: 'Jio Recharge', amount: 349, date: DateTime(2024, 4, 2)),
        _txn(id: '3', merchant: 'Jio Recharge', amount: 349, date: DateTime(2024, 5, 2)),
      ];
      final items = RecurringDetector.detect(txns);
      expect(items, hasLength(1));
      expect(items.single.type, RecurringType.utility);
    });

    test('unknown consistent monthly merchant → generic recurring', () {
      final txns = [
        _txn(id: '1', merchant: 'Local Gym', amount: 1200, date: DateTime(2024, 3, 15)),
        _txn(id: '2', merchant: 'Local Gym', amount: 1200, date: DateTime(2024, 4, 15)),
      ];
      final items = RecurringDetector.detect(txns);
      expect(items, hasLength(1));
      expect(items.single.type, RecurringType.recurring);
    });

    test('two wildly different amounts with only 2 txns → not detected', () {
      final txns = [
        _txn(id: '1', merchant: 'Amazon', amount: 500, date: DateTime(2024, 4, 5)),
        _txn(id: '2', merchant: 'Amazon', amount: 15000, date: DateTime(2024, 5, 5)),
      ];
      expect(RecurringDetector.detect(txns), isEmpty);
    });

    test('credits are excluded from detection', () {
      final txns = [
        _txn(id: '1', merchant: 'Netflix', amount: 649, date: DateTime(2024, 4, 5), isCredit: true),
        _txn(id: '2', merchant: 'Netflix', amount: 649, date: DateTime(2024, 5, 5), isCredit: true),
      ];
      expect(RecurringDetector.detect(txns), isEmpty);
    });

    test('ignored transactions are excluded', () {
      final txns = [
        _txn(id: '1', merchant: 'Netflix', amount: 649, date: DateTime(2024, 4, 5), isIgnored: true),
        _txn(id: '2', merchant: 'Netflix', amount: 649, date: DateTime(2024, 5, 5), isIgnored: true),
      ];
      expect(RecurringDetector.detect(txns), isEmpty);
    });

    test('single transaction per merchant → not detected', () {
      final txns = [
        _txn(id: '1', merchant: 'Netflix', amount: 649, date: DateTime(2024, 4, 5)),
      ];
      expect(RecurringDetector.detect(txns), isEmpty);
    });

    test('results sorted by average amount descending', () {
      final txns = [
        // Cheap subscription
        _txn(id: 'n1', merchant: 'Netflix', amount: 649, date: DateTime(2024, 4, 5)),
        _txn(id: 'n2', merchant: 'Netflix', amount: 649, date: DateTime(2024, 5, 5)),
        // Expensive EMI
        _txn(id: 'e1', merchant: 'Car Loan EMI', amount: 18000, date: DateTime(2024, 4, 1)),
        _txn(id: 'e2', merchant: 'Car Loan EMI', amount: 18000, date: DateTime(2024, 5, 1)),
      ];
      final items = RecurringDetector.detect(txns);
      expect(items, hasLength(2));
      expect(items[0].avgAmount, greaterThan(items[1].avgAmount));
      expect(items[0].type, RecurringType.emi);
    });
  });

  group('RecurringDetector.upcomingIn', () {
    RecurringItem itemOn(DateTime nextExpected) => RecurringItem(
          merchant: 'X',
          canonicalMerchant: 'X',
          avgAmount: 100,
          typicalDayOfMonth: nextExpected.day,
          type: RecurringType.recurring,
          history: const [],
          nextExpected: nextExpected,
        );

    test('returns only items due within the window, sorted by date', () {
      final now = DateTime.now();
      final items = [
        itemOn(now.add(const Duration(days: 30))), // outside
        itemOn(now.add(const Duration(days: 3))),
        itemOn(now.add(const Duration(days: 1))),
        itemOn(now.subtract(const Duration(days: 1))), // already past
      ];
      final upcoming = RecurringDetector.upcomingIn(items, 7);
      expect(upcoming, hasLength(2));
      expect(upcoming[0].nextExpected!.isBefore(upcoming[1].nextExpected!), isTrue);
    });
  });
}
