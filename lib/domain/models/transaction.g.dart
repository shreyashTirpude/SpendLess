// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      userId: fields[1] as String?,
      amount: fields[2] as double,
      merchant: fields[3] as String,
      category: fields[4] as String,
      isCredit: fields[5] as bool,
      accountLast4: fields[6] as String?,
      transactionDate: fields[7] as DateTime,
      rawSmsHash: fields[8] as String?,
      source: fields[9] as String,
      note: fields[10] as String?,
      isSynced: fields[11] as bool,
      createdAt: fields[12] as DateTime,
      isIgnored: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.merchant)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.isCredit)
      ..writeByte(6)
      ..write(obj.accountLast4)
      ..writeByte(7)
      ..write(obj.transactionDate)
      ..writeByte(8)
      ..write(obj.rawSmsHash)
      ..writeByte(9)
      ..write(obj.source)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.isSynced)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.isIgnored);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
