import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:spendlens/data/local/hive_service.dart';
import 'package:spendlens/domain/models/transaction.dart';
import 'package:spendlens/services/sms_scanner_service.dart';

// Value: protects=users from duplicate payments left behind by pre-fix installs
// fails_when=same-hash rows survive the repair or unique/unhashed rows are deleted;
// why_new=legacy uuid v4 ids stored one bank SMS under 3-4 rows; seam=none
void main() {
  // NOTE: removeDuplicateRows() is once-per-process by design (its guard is a
  // private static). One test per file — flutter test runs each file in a fresh
  // isolate, so the guard is pristine here.
  late Directory fixture;

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('spendlens-dedup-test-');
    Hive.init(fixture.path);
    Hive.registerAdapter(TransactionAdapter());
    await Hive.openBox<Transaction>('transactions');
  });

  tearDown(() async {
    await Hive.close();
    await fixture.delete(recursive: true);
  });

  Transaction tx({
    required String id,
    String? hash,
    DateTime? createdAt,
  }) =>
      Transaction(
        id: id,
        amount: 100,
        merchant: 'Zomato',
        category: 'Food & Dining',
        isCredit: false,
        transactionDate: DateTime(2026, 6, 19),
        rawSmsHash: hash,
        source: 'sms',
        createdAt: createdAt ?? DateTime(2026, 6, 19, 10),
      );

  test(
      'repair keeps the earliest same-hash row and never touches unique or '
      'unhashed rows', () async {
    final box = HiveService.transactions;
    await box.putAll({
      // One bank SMS stored four times under random ids (the reported bug).
      'a': tx(id: 'a', hash: 'h1', createdAt: DateTime(2026, 6, 19, 10, 3)),
      'b': tx(id: 'b', hash: 'h1', createdAt: DateTime(2026, 6, 19, 10, 1)),
      'c': tx(id: 'c', hash: 'h1', createdAt: DateTime(2026, 6, 19, 10, 2)),
      'd': tx(id: 'd', hash: 'h1', createdAt: DateTime(2026, 6, 19, 10, 4)),
      // A second, distinct SMS — must survive untouched.
      'e': tx(id: 'e', hash: 'h2'),
      // Manual / demo rows carry no SMS hash — must survive untouched.
      'f': tx(id: 'f', hash: null),
      'g': tx(id: 'g', hash: null),
    });

    await SmsScannerService.removeDuplicateRows();

    final remaining = box.keys.toList()..sort();
    expect(remaining, ['b', 'e', 'f', 'g'],
        reason: 'earliest same-hash row survives; unique and unhashed rows stay');

    // The surviving row is the earliest-created copy of that SMS.
    expect(box.get('b')!.createdAt, DateTime(2026, 6, 19, 10, 1));
  });
}
