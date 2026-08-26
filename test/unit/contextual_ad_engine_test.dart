import 'package:flutter_test/flutter_test.dart';
import 'package:spendlens/core/engine/contextual_ad_engine.dart';
import 'package:spendlens/domain/models/partner_suggestion.dart';
import 'package:spendlens/domain/models/transaction.dart';

Transaction _txn({
  required String id,
  required String category,
  required double amount,
  bool isCredit = false,
}) {
  final now = DateTime.now();
  return Transaction(
    id: id,
    amount: amount,
    merchant: 'M$id',
    category: category,
    isCredit: isCredit,
    transactionDate: now,
    source: 'sms',
    createdAt: now,
  );
}

PartnerSuggestion? _suggest({
  List<Transaction> txns = const [],
  Set<String> dismissed = const {},
  DateTime? lastShown,
}) {
  return ContextualAdEngine.getSuggestion(
    thisMonthTransactions: txns,
    dismissedPartnerIds: dismissed,
    lastSuggestionShown: lastShown,
  );
}

void main() {
  group('ContextualAdEngine.getSuggestion', () {
    test('no transactions → no suggestion', () {
      expect(_suggest(), isNull);
    });

    test('heavy food spend triggers Swiggy One', () {
      final s = _suggest(txns: [
        _txn(id: '1', category: 'Food & Dining', amount: 900),
        _txn(id: '2', category: 'Food & Dining', amount: 700),
      ]);
      expect(s, isNotNull);
      expect(s!.id, 'swiggy_one');
    });

    test('food spend below threshold → no suggestion', () {
      final s = _suggest(txns: [
        _txn(id: '1', category: 'Food & Dining', amount: 1499),
      ]);
      expect(s, isNull);
    });

    test('income-category debit spend ≥ ₹10k triggers Groww SIP suggestion', () {
      // Engine counts only DEBITS toward category totals.
      final s = _suggest(txns: [
        _txn(id: '1', category: 'Income', amount: 50000),
      ]);
      expect(s, isNotNull);
      expect(s!.id, 'groww_sip');
    });

    test('income credits do NOT count toward spend totals', () {
      // A ₹20k *credit* in Income must not count as spend; Zerodha's
      // trigger needs ₹20k spend in Income which credits alone can't reach.
      final s = _suggest(txns: [
        _txn(id: '1', category: 'Income', amount: 25000, isCredit: true),
      ]);
      if (s != null) expect(s.id, isNot('zerodha_kite'));
    });

    test('dismissed partners are never suggested again', () {
      final s = _suggest(
        txns: [_txn(id: '1', category: 'Food & Dining', amount: 3000)],
        dismissed: {'swiggy_one'},
      );
      if (s != null) expect(s.id, isNot('swiggy_one'));
    });

    test('cooldown: suggestion suppressed within 7 days of last show', () {
      final s = _suggest(
        txns: [_txn(id: '1', category: 'Food & Dining', amount: 3000)],
        lastShown: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(s, isNull);
    });

    test('cooldown expired after 7+ days allows suggestions again', () {
      final s = _suggest(
        txns: [_txn(id: '1', category: 'Food & Dining', amount: 3000)],
        lastShown: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(s, isNotNull);
    });

    test('ignored transactions are excluded from spend totals', () {
      final s = _suggest(txns: [
        _txn(id: '1', category: 'Food & Dining', amount: 5000),
      ].map((t) => Transaction(
            id: t.id,
            amount: t.amount,
            merchant: t.merchant,
            category: t.category,
            isCredit: false,
            transactionDate: t.transactionDate,
            source: 'sms',
            createdAt: t.createdAt,
            isIgnored: true,
          )).toList());
      expect(s, isNull);
    });

    test('highest absolute qualifying spend wins', () {
      // Income debit ₹12k qualifies for Groww; food ₹6k for Swiggy.
      // Engine selects the partner with the larger matching spend.
      final s = _suggest(txns: [
        _txn(id: '1', category: 'Food & Dining', amount: 6000),
        _txn(id: '2', category: 'Income', amount: 12000),
      ]);
      expect(s, isNotNull);
      expect(s!.id, 'groww_sip');
    });
  });
}
