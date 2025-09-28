// In task_card.dart
import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String subtitleText = '';
    // Use the task's description if available
    if (task.description != null && task.description!.isNotEmpty) {
      subtitleText = task.description!;
    }
    // Append frequency and duration to the subtitle
    if (task.frequency != null || task.durationHours != null) {
      String details = '${task.frequency ?? ''}';
      if (task.durationHours != null) {
        // Explicitly convert the double to a string.
        details +=
            '${task.frequency != null ? ' - ' : ''}${task.durationHours!.toStringAsFixed(1)} hours';
      }
      subtitleText += subtitleText.isNotEmpty ? '\n$details' : details;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        // The leading widget now includes the checkbox and the time indicator
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (bool? value) => onToggleComplete(),
            ),
            if (task.taskHour != null && task.taskMinute != null)
              _TimeIndicator(hour: task.taskHour!, minute: task.taskMinute!),
          ],
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: subtitleText.isNotEmpty
            ? Text(
                subtitleText,
                style: TextStyle(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.teal),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeIndicator extends StatelessWidget {
  final int hour;
  final int minute;

  const _TimeIndicator({required this.hour, required this.minute});

  @override
  Widget build(BuildContext context) {
    // Format the time to display with leading zeros
    String formattedTime =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return Container(
      width: 45, // Adjust width as needed
      margin: const EdgeInsets.only(right: 8),
      child: Text(
        formattedTime,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
