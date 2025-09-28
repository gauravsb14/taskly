import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/task.dart';
import '../data/task_boxes.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String filter = "All"; // All, Completed, Pending

  List<Task> _applyFilter(List<Task> tasks) {
    if (filter == "Completed") {
      return tasks.where((t) => t.isCompleted).toList();
    } else if (filter == "Pending") {
      return tasks.where((t) => !t.isCompleted).toList();
    }
    return tasks;
  }

  // Prepare weekly task completion data for chart
  List<BarChartGroupData> _weeklyStats(List<Task> tasks) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    Map<int, int> completedCount = {};
    for (int i = 0; i < 7; i++) {
      completedCount[i] = 0;
    }

    for (var task in tasks) {
      if (task.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          task.date.isBefore(startOfWeek.add(const Duration(days: 7)))) {
        int index = task.date.difference(startOfWeek).inDays;
        if (index >= 0 && index < 7 && task.isCompleted) {
          completedCount[index] = (completedCount[index] ?? 0) + 1;
        }
      }
    }

    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (completedCount[i] ?? 0).toDouble(),
            color: Colors.blue,
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task History & Insights"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: "All", child: Text("All Tasks")),
              const PopupMenuItem(value: "Completed", child: Text("Completed")),
              const PopupMenuItem(value: "Pending", child: Text("Pending")),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Task>>(
        valueListenable: TaskBoxes.getTasksBox().listenable(),
        builder: (context, box, _) {
          final allTasks = box.values.toList();
          final tasks = _applyFilter(allTasks);

          return Column(
            children: [
              // Chart Section
              SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BarChart(
                    BarChartData(
                      barGroups: _weeklyStats(allTasks),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final weekDays = [
                                "Sun",
                                "Mon",
                                "Tue",
                                "Wed",
                                "Thu",
                                "Fri",
                                "Sat",
                              ];
                              return Text(weekDays[value.toInt()]);
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ),
              const Divider(),

              // Task List Section
              Expanded(
                child: tasks.isEmpty
                    ? const Center(child: Text("No tasks available"))
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return ListTile(
                            title: Text(task.title),
                            subtitle: Text(
                              DateFormat("EEE, MMM dd yyyy").format(task.date),
                            ),
                            trailing: Icon(
                              task.isCompleted
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: task.isCompleted
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
