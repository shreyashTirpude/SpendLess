import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 2)
class AppCategory extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String icon;
  @HiveField(3) String colorHex;
  @HiveField(4) List<String> keywords;
  @HiveField(5) bool isSystem;

  AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.keywords,
    this.isSystem = true,
  });
}
