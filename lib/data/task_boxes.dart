import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class TaskBoxes {
  static Box<Task> getTasksBox() => Hive.box<Task>('tasks');
}
