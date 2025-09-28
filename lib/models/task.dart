// lib/models/task.dart
import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String? description;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  String? frequency;

  @HiveField(5)
  double? durationHours;

  @HiveField(6)
  String? seriesId; // Added for repeated tasks

  @HiveField(7)
  int? taskHour; // For sorting morning/evening tasks

  @HiveField(8)
  int? taskMinute; // For sorting morning/evening tasks

  @HiveField(9)
  String? timeCategory; // 'Morning', 'Evening', or 'Anytime'

  // New fields for frequency-based tasks
  @HiveField(10)
  DateTime? endDate;

  @HiveField(11)
  List<int>? daysOfWeek; // For weekly tasks (1=Mon, 2=Tue, etc.)

  @HiveField(12)
  int? monthlyDate; // Day of the month (e.g., 15)

  Task({
    required this.title,
    this.description,
    required this.date,
    this.isCompleted = false,
    this.frequency,
    this.durationHours,
    this.seriesId,
    this.taskHour,
    this.taskMinute,
    this.timeCategory,
    // Include new fields in the constructor
    this.endDate,
    this.daysOfWeek,
    this.monthlyDate,
  });
}
