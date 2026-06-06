// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppCategoryAdapter extends TypeAdapter<AppCategory> {
  @override
  final int typeId = 2;

  @override
  AppCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      icon: fields[2] as String,
      colorHex: fields[3] as String,
      keywords: (fields[4] as List).cast<String>(),
      isSystem: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppCategory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.colorHex)
      ..writeByte(4)
      ..write(obj.keywords)
      ..writeByte(5)
      ..write(obj.isSystem);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
