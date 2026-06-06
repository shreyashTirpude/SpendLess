import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String? userId;
  @HiveField(2) double amount;
  @HiveField(3) String merchant;
  @HiveField(4) String category;
  @HiveField(5) bool isCredit;
  @HiveField(6) String? accountLast4;
  @HiveField(7) DateTime transactionDate;
  @HiveField(8) String? rawSmsHash;
  @HiveField(9) String source;
  @HiveField(10) String? note;
  @HiveField(11) bool isSynced;
  @HiveField(12) DateTime createdAt;
  @HiveField(13) bool isIgnored;

  Transaction({
    required this.id,
    this.userId,
    required this.amount,
    required this.merchant,
    required this.category,
    required this.isCredit,
    this.accountLast4,
    required this.transactionDate,
    this.rawSmsHash,
    required this.source,
    this.note,
    this.isSynced = false,
    required this.createdAt,
    this.isIgnored = false,
  });
}
