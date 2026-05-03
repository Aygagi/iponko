// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deposit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DepositModelAdapter extends TypeAdapter<DepositModel> {
  @override
  final int typeId = 2;

  @override
  DepositModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DepositModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      goalId: fields[2] as String?,
      amount: fields[3] as double,
      source: fields[4] as String,
      date: fields[5] as DateTime,
      note: fields[6] as String?,
      receiptPhotoPath: fields[7] as String?,
      isApprovedByParent: fields[8] as bool,
      isSynced: fields[9] as bool,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DepositModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.goalId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.receiptPhotoPath)
      ..writeByte(8)
      ..write(obj.isApprovedByParent)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepositModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
