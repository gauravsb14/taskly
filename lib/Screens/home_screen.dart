// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';
import '../login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Task> taskBox;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box<Task>('tasks');
  }

  List<DateTime> getWeekDates(DateTime baseDate) {
    final weekday = baseDate.weekday;
    final monday = baseDate.subtract(Duration(days: weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  List<Task> tasksForSelectedDate() {
    return taskBox.values
        .where(
          (t) =>
              t.date.year == selectedDate.year &&
              t.date.month == selectedDate.month &&
              t.date.day == selectedDate.day,
        )
        .toList();
  }

  void _openAddTaskDialog([Task? task]) {
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        task: task,
        selectedDate: selectedDate,
        taskBox: taskBox,
      ),
    ).then((_) => setState(() {}));
  }

  void _toggleComplete(Task task) {
    task.isCompleted = !task.isCompleted;
    task.save();
    setState(() {});
  }

  Future<void> _deleteTask(Task task) async {
    if (task.frequency != null && task.seriesId != null) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete Task"),
          content: const Text(
            "Do you want to delete only this task or the entire series?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, "instance"),
              child: const Text("This Task"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, "series"),
              child: const Text("Entire Series"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
          ],
        ),
      );

      if (result == "instance") {
        await task.delete();
      } else if (result == "series") {
        final tasksToDelete = taskBox.values
            .where((t) => t.seriesId == task.seriesId)
            .toList();
        for (var t in tasksToDelete) {
          await t.delete();
        }
      }
    } else {
      await task.delete();
    }

    setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = getWeekDates(selectedDate);
    final tasks = tasksForSelectedDate();
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Taskly"),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Dates Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: weekDates.map((date) {
                final isSelected =
                    date.day == selectedDate.day &&
                    date.month == selectedDate.month &&
                    date.year == selectedDate.year;

                final isToday =
                    date.day == today.day &&
                    date.month == today.month &&
                    date.year == today.year;

                // Get tasks for this day
                final dayTasks = taskBox.values.where(
                  (t) =>
                      t.date.year == date.year &&
                      t.date.month == date.month &&
                      t.date.day == date.day,
                );

                final hasTasks = dayTasks.isNotEmpty;
                final allCompleted =
                    hasTasks && dayTasks.every((t) => t.isCompleted);

                Color bgColor;
                if (isSelected) {
                  bgColor = Colors.teal;
                } else if (isToday) {
                  bgColor = const Color.fromARGB(255, 173, 187, 211);
                } else {
                  bgColor = Colors.grey[200]!;
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat.E().format(date),
                          style: TextStyle(
                            color: (isSelected || isToday)
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: (isSelected || isToday)
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Task Completion Indicator
                        if (hasTasks)
                          Container(
                            height: 4,
                            width: 20,
                            decoration: BoxDecoration(
                              color: allCompleted ? Colors.green : Colors.amber,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Pick Date Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat.yMMMd().format(selectedDate)),
                ),
              ],
            ),
          ),

          // Task List
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text("No tasks for this day."))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (_, index) {
                      final task = tasks[index];
                      return TaskCard(
                        task: task,
                        onToggleComplete: () => _toggleComplete(task),
                        onEdit: () => _openAddTaskDialog(task),
                        onDelete: () => _deleteTask(task),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
