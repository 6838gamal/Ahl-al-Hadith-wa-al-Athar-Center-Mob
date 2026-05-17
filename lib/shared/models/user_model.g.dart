// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      username: fields[1] as String,
      displayName: fields[2] as String?,
      academicId: fields[3] as String,
      role: fields[4] as String,
      status: fields[5] as String,
      gender: fields[6] as String,
      avatarUrl: fields[7] as String?,
      email: fields[8] as String?,
      bio: fields[9] as String?,
      isOnline: fields[10] as bool,
      lastSeen: fields[11] as DateTime?,
      createdAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.academicId)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.gender)
      ..writeByte(7)
      ..write(obj.avatarUrl)
      ..writeByte(8)
      ..write(obj.email)
      ..writeByte(9)
      ..write(obj.bio)
      ..writeByte(10)
      ..write(obj.isOnline)
      ..writeByte(11)
      ..write(obj.lastSeen)
      ..writeByte(12)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
