import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 3)
class UserProfile extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String phone;
  @HiveField(2) String? name;
  @HiveField(3) double monthlyBudget;
  @HiveField(4) bool adsRemoved;
  @HiveField(5) bool biometricEnabled;
  @HiveField(6) DateTime createdAt;

  UserProfile({
    required this.id,
    required this.phone,
    this.name,
    this.monthlyBudget = 0,
    this.adsRemoved = false,
    this.biometricEnabled = false,
    required this.createdAt,
  });
}
