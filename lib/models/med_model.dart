
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'med_model.g.dart';

@HiveType(typeId: 0)
class Medication extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String dose;

  @HiveField(2)
  String strength;

  @HiveField(3)
  int hour;

  @HiveField(4)
  int minute;

  @HiveField(5)
  int colorValue;

  @HiveField(6)
  int frequencyHours;

  Medication({
    required this.name,
    required this.dose,
    required this.strength,
    required this.hour,
    required this.minute,
    required this.colorValue,
    this.frequencyHours = 8,
  });

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
}

@HiveType(typeId: 1)
class HistoryEntry extends HiveObject {
  @HiveField(0)
  DateTime dateTime;

  @HiveField(1)
  String medName;

  @HiveField(2)
  bool taken;

  HistoryEntry({
    required this.dateTime,
    required this.medName,
    required this.taken,
  });
}
