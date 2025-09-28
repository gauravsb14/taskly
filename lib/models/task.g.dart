// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      title: fields[0] as String,
      description: fields[1] as String?,
      date: fields[2] as DateTime,
      isCompleted: fields[3] as bool,
      frequency: fields[4] as String?,
      durationHours: fields[5] as double?,
      seriesId: fields[6] as String?,
      taskHour: fields[7] as int?,
      taskMinute: fields[8] as int?,
      timeCategory: fields[9] as String?,
      endDate: fields[10] as DateTime?,
      daysOfWeek: (fields[11] as List?)?.cast<int>(),
      monthlyDate: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.durationHours)
      ..writeByte(6)
      ..write(obj.seriesId)
      ..writeByte(7)
      ..write(obj.taskHour)
      ..writeByte(8)
      ..write(obj.taskMinute)
      ..writeByte(9)
      ..write(obj.timeCategory)
      ..writeByte(10)
      ..write(obj.endDate)
      ..writeByte(11)
      ..write(obj.daysOfWeek)
      ..writeByte(12)
      ..write(obj.monthlyDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
