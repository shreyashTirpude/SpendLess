import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 1)
class Budget extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String? userId;
  @HiveField(2) String category;
  @HiveField(3) double monthlyLimit;
  @HiveField(4) String monthYear;
  @HiveField(5) bool isSynced;

  Budget({
    required this.id,
    this.userId,
    required this.category,
    required this.monthlyLimit,
    required this.monthYear,
    this.isSynced = false,
  });
}
