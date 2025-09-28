// lib/widgets/add_task_dialog.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../data/task_boxes.dart';
import 'package:hive/hive.dart';

class AddTaskDialog extends StatefulWidget {
  final Task? task;
  final DateTime? selectedDate;
  final bool isEditingSeries;
  final Box<Task> taskBox; // if you open dialog with series-edit intent

  const AddTaskDialog({
    super.key,
    this.task,
    this.selectedDate,
    this.isEditingSeries = false,
    required this.taskBox,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  String _frequency = 'Once';
  DateTime? _endDate;
  int? _hour;
  int? _minute;
  List<int> _selectedDays = []; // weekday numbers 1..7 (Mon..Sun)
  int? _monthlyDate;
  bool _applyToSeries = false; // checkbox to decide apply to whole series

  final _frequencies = ['Once', 'Daily', 'Weekly', 'Monthly'];
  final _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    // initialize fields from widget.task if editing
    if (widget.task != null) {
      final t = widget.task!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description ?? '';
      _durationCtrl.text = t.durationHours?.toString() ?? '';
      _frequency = t.frequency ?? 'Once';
      _hour = t.taskHour;
      _minute = t.taskMinute;
      _endDate = t.endDate;
      _selectedDays = (t.daysOfWeek ?? []).toList();
      _monthlyDate = t.monthlyDate;
      _applyToSeries = widget.isEditingSeries;
    } else {
      _applyToSeries = false;
      _frequency = 'Once';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final start = widget.selectedDate ?? widget.task?.date ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? start,
      firstDate: start,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _pickTime() async {
    final initial = TimeOfDay(
      hour: _hour ?? TimeOfDay.now().hour,
      minute: _minute ?? TimeOfDay.now().minute,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null)
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
  }

  /// Generate the list of dates the series should include, inclusive.
  /// Generate the list of dates the series should include, inclusive.
  List<DateTime> _generateDatesForSeries({
    required DateTime start,
    required DateTime end,
    required String frequency,
    List<int>? daysOfWeek,
    int? monthlyDate,
  }) {
    final dates = <DateTime>[];
    DateTime cursor = DateTime(start.year, start.month, start.day);

    while (!cursor.isAfter(end)) {
      if (frequency == 'Daily' || frequency == 'Once') {
        dates.add(cursor);
      } else if (frequency == 'Weekly') {
        if (daysOfWeek != null && daysOfWeek.contains(cursor.weekday)) {
          dates.add(cursor);
        }
      } else if (frequency == 'Monthly') {
        final dayToMatch = monthlyDate ?? start.day;
        // Ensure valid date for this month
        final lastDayOfMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
        if (dayToMatch <= lastDayOfMonth && cursor.day == dayToMatch) {
          dates.add(cursor);
        }
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Update an existing series in-place:
  ///  - Keep isCompleted for tasks that remain
  ///  - Update title/description/time/meta for existing tasks
  ///  - Add new Task objects for dates that are newly included
  ///  - Remove tasks that are no longer in desiredDates
  Future<void> _updateExistingSeries({
    required String seriesId,
    required DateTime startDate,
    required DateTime endDate,
    required String frequency,
    required String title,
    String? description,
    double? duration,
    int? taskHour,
    int? taskMinute,
    List<int>? daysOfWeek,
    int? monthlyDate,
    String? timeCategory,
  }) async {
    final box = widget.taskBox;

    // Map existing tasks in the series by date-string for quick lookup
    final existingTasks = box.values
        .where((t) => t.seriesId == seriesId)
        .toList();
    final Map<String, Task> existingByKey = {
      for (var t in existingTasks) _dateKey(t.date): t,
    };

    // Build desired date list (using local midnight)
    final desiredDates = _generateDatesForSeries(
      start: DateTime(startDate.year, startDate.month, startDate.day),
      end: DateTime(endDate.year, endDate.month, endDate.day),
      frequency: frequency,
      daysOfWeek: daysOfWeek,
      monthlyDate: monthlyDate,
    );

    final desiredKeys = desiredDates.map(_dateKey).toSet();

    // 1) Update existing tasks that remain, and collect their keys
    final preservedKeys = <String>{};
    for (final d in desiredDates) {
      final key = _dateKey(d);
      if (existingByKey.containsKey(key)) {
        final task = existingByKey[key]!;
        // Preserve completion state, but update other fields
        final wasCompleted = task.isCompleted;
        task.title = title;
        task.description = description;
        task.frequency = frequency;
        task.durationHours = duration;
        task.taskHour = taskHour;
        task.taskMinute = taskMinute;
        task.timeCategory = timeCategory;
        task.endDate = endDate;
        task.daysOfWeek = daysOfWeek;
        task.monthlyDate = monthlyDate;
        task.seriesId = seriesId;
        // preserve isCompleted
        task.isCompleted = wasCompleted;
        task.save();
        preservedKeys.add(key);
      }
    }

    // 2) Add new tasks for dates that don't exist yet
    for (final d in desiredDates) {
      final key = _dateKey(d);
      if (!existingByKey.containsKey(key)) {
        final newTask = Task(
          title: title,
          description: description,
          date: d,
          frequency: frequency,
          durationHours: duration,
          taskHour: taskHour,
          taskMinute: taskMinute,
          timeCategory: timeCategory,
          endDate: endDate,
          daysOfWeek: daysOfWeek,
          monthlyDate: monthlyDate,
          seriesId: seriesId,
          isCompleted: false,
        );
        box.add(newTask);
      }
    }

    // 3) Remove tasks that are part of the old series but not desired anymore
    for (final t in existingTasks) {
      final key = _dateKey(t.date);
      if (!desiredKeys.contains(key)) {
        // delete the task (series changed to exclude this date)
        t.delete();
      }
    }
  }

  String _dateKey(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String();

  void _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    final description = _descCtrl.text.trim().isEmpty
        ? null
        : _descCtrl.text.trim();
    final duration = double.tryParse(_durationCtrl.text.trim());

    // Determine start date
    final startDate =
        widget.selectedDate ?? widget.task?.date ?? DateTime.now();

    // If recurring, validate end date
    if (_frequency != 'Once' && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an end date for recurring tasks'),
        ),
      );
      return;
    }

    if (_endDate != null && _endDate!.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    // Time category inference (optional)
    String? timeCategory;
    if (_hour != null) {
      timeCategory = (_hour! >= 0 && _hour! < 12) ? 'Morning' : 'Evening';
    } else {
      timeCategory = 'Anytime';
    }

    final box = widget.taskBox;

    // NEW TASK (not editing)
    if (widget.task == null) {
      if (_frequency == 'Once') {
        final newTask = Task(
          title: title,
          description: description,
          date: DateTime(startDate.year, startDate.month, startDate.day),
          frequency: 'Once',
          durationHours: duration,
          taskHour: _hour,
          taskMinute: _minute,
          timeCategory: timeCategory,
          isCompleted: false,
        );
        box.add(newTask);
        Navigator.of(context).pop();
        return;
      } else {
        final seriesId = const Uuid().v4();
        final end = _endDate!;
        final dates = _generateDatesForSeries(
          start: startDate,
          end: end,
          frequency: _frequency,
          daysOfWeek: _selectedDays,
          monthlyDate: _monthlyDate,
        );
        for (final d in dates) {
          final newTask = Task(
            title: title,
            description: description,
            date: d,
            frequency: _frequency,
            durationHours: duration,
            taskHour: _hour,
            taskMinute: _minute,
            timeCategory: timeCategory,
            endDate: _endDate,
            daysOfWeek: _selectedDays.isEmpty ? null : _selectedDays,
            monthlyDate: _monthlyDate,
            seriesId: seriesId,
            isCompleted: false,
          );
          box.add(newTask);
        }
        Navigator.of(context).pop();
        return;
      }
    }

    // EDIT EXISTING TASK (widget.task != null)
    final editingTask = widget.task!;
    if (_applyToSeries && (editingTask.seriesId != null)) {
      // Edit entire series — but preserve existing completion states on remaining tasks
      final seriesId = editingTask.seriesId!;
      final end = _endDate ?? editingTask.endDate ?? startDate;
      await _updateExistingSeries(
        seriesId: seriesId,
        startDate: startDate,
        endDate: end,
        frequency: _frequency,
        title: title,
        description: description,
        duration: duration,
        taskHour: _hour,
        taskMinute: _minute,
        daysOfWeek: _selectedDays.isEmpty ? null : _selectedDays,
        monthlyDate: _monthlyDate,
        timeCategory: timeCategory,
      );
      Navigator.of(context).pop();
      return;
    } else if (_applyToSeries && (editingTask.seriesId == null)) {
      // If editing entire series but the task didn't have a seriesId,
      // create a new series with a new seriesId using current task as start.
      final seriesId = const Uuid().v4();
      final end = _endDate ?? widget.selectedDate ?? editingTask.date;
      final dates = _generateDatesForSeries(
        start: startDate,
        end: end,
        frequency: _frequency,
        daysOfWeek: _selectedDays,
        monthlyDate: _monthlyDate,
      );
      // add the edited task as first (update it)
      editingTask.title = title;
      editingTask.description = description;
      editingTask.frequency = _frequency;
      editingTask.durationHours = duration;
      editingTask.taskHour = _hour;
      editingTask.taskMinute = _minute;
      editingTask.timeCategory = timeCategory;
      editingTask.endDate = _endDate;
      editingTask.daysOfWeek = _selectedDays.isEmpty ? null : _selectedDays;
      editingTask.monthlyDate = _monthlyDate;
      editingTask.seriesId = seriesId;
      editingTask.save();
      // create other dates except the date of this task (which is updated)
      for (final d in dates) {
        if (_dateKey(d) == _dateKey(editingTask.date)) continue;
        final newTask = Task(
          title: title,
          description: description,
          date: d,
          frequency: _frequency,
          durationHours: duration,
          taskHour: _hour,
          taskMinute: _minute,
          timeCategory: timeCategory,
          endDate: _endDate,
          daysOfWeek: _selectedDays.isEmpty ? null : _selectedDays,
          monthlyDate: _monthlyDate,
          seriesId: seriesId,
          isCompleted: false,
        );
        box.add(newTask);
      }
      Navigator.of(context).pop();
      return;
    } else {
      // Edit single occurrence
      editingTask.title = title;
      editingTask.description = description;
      editingTask.frequency = _frequency;
      editingTask.durationHours = duration;
      editingTask.taskHour = _hour;
      editingTask.taskMinute = _minute;
      editingTask.timeCategory = timeCategory;
      editingTask.endDate = _endDate;
      editingTask.daysOfWeek = _selectedDays.isEmpty ? null : _selectedDays;
      editingTask.monthlyDate = _monthlyDate;
      editingTask.save();
      Navigator.of(context).pop();
      return;
    }
  }

  Widget _frequencyWidgets() {
    switch (_frequency) {
      case 'Daily':
        return Column(
          children: [
            Row(
              children: [
                const Text('Ends on: '),
                TextButton(
                  onPressed: _pickEndDate,
                  child: Text(
                    _endDate != null
                        ? _endDate!.toString().split(' ').first
                        : 'Select',
                  ),
                ),
              ],
            ),
          ],
        );
      case 'Weekly':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Ends on: '),
                TextButton(
                  onPressed: _pickEndDate,
                  child: Text(
                    _endDate != null
                        ? _endDate!.toString().split(' ').first
                        : 'Select',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Repeat on:'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: List.generate(7, (i) {
                final weekday = i + 1;
                final selected = _selectedDays.contains(weekday);
                return FilterChip(
                  label: Text(_weekdays[i]),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val)
                        _selectedDays.add(weekday);
                      else
                        _selectedDays.remove(weekday);
                    });
                  },
                );
              }),
            ),
          ],
        );
      case 'Monthly':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Ends on: '),
                TextButton(
                  onPressed: _pickEndDate,
                  child: Text(
                    _endDate != null
                        ? _endDate!.toString().split(' ').first
                        : 'Select',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: _monthlyDate,
              decoration: const InputDecoration(labelText: 'Day of month'),
              items: List.generate(31, (i) => i + 1)
                  .map(
                    (d) =>
                        DropdownMenuItem(value: d, child: Text(d.toString())),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _monthlyDate = v),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = (_hour != null && _minute != null)
        ? '${_hour!.toString().padLeft(2, '0')}:${_minute!.toString().padLeft(2, '0')}'
        : 'Select Time';

    return AlertDialog(
      title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: _frequencies
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setState(() => _frequency = v ?? 'Once'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _frequencyWidgets(),
            const SizedBox(height: 8),
            // TextField(
            //   controller: _durationCtrl,
            //   keyboardType: TextInputType.number,
            //   decoration: const InputDecoration(labelText: 'Duration (hours)'),
            // ),
            TextField(
              controller: _durationCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Duration (hours)',
                hintText: 'e.g. 1.5',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickTime,
                    child: Text(formattedTime),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.task != null)
              CheckboxListTile(
                value: _applyToSeries,
                onChanged: (v) => setState(() => _applyToSeries = v ?? false),
                title: const Text('Apply changes to entire series'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
