// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BadgeModelAdapter extends TypeAdapter<BadgeModel> {
  @override
  final int typeId = 3;

  @override
  BadgeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BadgeModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      emoji: fields[3] as String,
      isEarned: fields[4] as bool,
      earnedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BadgeModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.emoji)
      ..writeByte(4)
      ..write(obj.isEarned)
      ..writeByte(5)
      ..write(obj.earnedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
