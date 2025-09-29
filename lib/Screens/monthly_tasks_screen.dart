// lib/screens/monthly_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class MonthlyTasksScreen extends StatefulWidget {
  final Box<Task> taskBox;
  const MonthlyTasksScreen({super.key, required this.taskBox});

  @override
  State<MonthlyTasksScreen> createState() => _MonthlyTasksScreenState();
}

class _MonthlyTasksScreenState extends State<MonthlyTasksScreen> {
  DateTime selectedMonth = DateTime.now();

  List<Task> get monthlyTasks {
    return widget.taskBox.values.where((t) {
      return t.date.year == selectedMonth.year &&
          t.date.month == selectedMonth.month;
    }).toList();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: "Select month",
    );
    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  void _addMonthlyTask() {
    showDialog(
      context: context,
      builder: (_) {
        final titleController = TextEditingController();
        DateTime? dueDate;

        return AlertDialog(
          title: const Text("Add Monthly Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Task Title"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedMonth,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      dueDate = picked;
                    });
                  }
                },
                child: Text(
                  dueDate == null
                      ? "Select Due Date"
                      : "Due: ${DateFormat.yMMMd().format(dueDate!)}",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && dueDate != null) {
                  final task = Task(
                    title: titleController.text,
                    date: dueDate!,
                    isCompleted: false,
                    frequency: "monthly",
                  );
                  widget.taskBox.add(task);
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = monthlyTasks;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Monthly Tasks - ${DateFormat.yMMM().format(selectedMonth)}",
        ),
        actions: [
          IconButton(
            onPressed: _pickMonth,
            icon: const Icon(Icons.date_range),
            tooltip: "Pick Month",
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const Center(child: Text("No tasks for this month."))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (_, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(
                    "Due: ${DateFormat.yMMMd().format(task.date)}",
                  ),
                  trailing: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task.isCompleted ? Colors.green : Colors.grey,
                  ),
                  onTap: () {
                    setState(() {
                      task.isCompleted = !task.isCompleted;
                      task.save();
                    });
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMonthlyTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}
