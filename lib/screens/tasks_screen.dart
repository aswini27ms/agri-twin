import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../providers/app_providers.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Start with today selected
    _selectedDay = DateTime.now();
  }

  void _showAddTaskSheet() {
    String selectedField = 'North Wheat Plot';
    String selectedTaskType = 'WATER';
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedRecurrence = 'ONE_TIME';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Schedule Task',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Field Dropdown
                    const Text('Field', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    DropdownButtonFormField<String>(
                      value: selectedField,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      items: ['North Wheat Plot', 'South Corn Field', 'East Tomato Plot']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => selectedField = v!),
                    ),
                    const SizedBox(height: 16),

                    // Task Type Dropdown
                    const Text('Task Type', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    DropdownButtonFormField<String>(
                      value: selectedTaskType,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      items: ['WATER', 'FERTILIZE', 'HARVEST', 'PESTICIDE', 'INSPECT']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => selectedTaskType = v!),
                    ),
                    const SizedBox(height: 20),

                    // Date and Time Pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (d != null) setStateDialog(() => selectedDate = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(selectedDate),
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (t != null) setStateDialog(() => selectedTime = t);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  selectedTime.format(context),
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Recurrence Dropdown
                    const Text('Recurrence', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    DropdownButtonFormField<String>(
                      value: selectedRecurrence,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      items: ['ONE_TIME', 'DAILY', 'WEEKLY']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setStateDialog(() => selectedRecurrence = v!),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        hintText: 'Notes (e.g. fertilizer dosage)',
                        hintStyle: TextStyle(color: Colors.grey),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(tasksProvider.notifier).addTask(
                              field: selectedField,
                              taskType: selectedTaskType,
                              date: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
                              time: selectedTime.format(context),
                              recurrence: selectedRecurrence,
                              notes: notesController.text.trim(),
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task scheduled successfully!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<TaskItem> _getEventsForDay(List<TaskItem> allTasks, DateTime day) {
    return allTasks.where((t) {
      return t.date.year == day.year &&
             t.date.month == day.month &&
             t.date.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(tasksProvider);
    final selectedDayTasks = _selectedDay != null ? _getEventsForDay(allTasks, _selectedDay!) : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E523A)),
        title: const Text('Task Calendar', style: TextStyle(color: Color(0xFF1E523A), fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Calendar
            Container(
              color: Colors.white,
              child: TableCalendar<TaskItem>(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) => _getEventsForDay(allTasks, day),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  todayTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFFD1FAE5),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  selectedTextStyle: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold),
                  markerDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E523A)),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: events.take(3).map((_) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                          )).toList(),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Tasks List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedDay != null 
                    ? 'Tasks for ${DateFormat('d MMM').format(_selectedDay!)}'
                    : 'Select a day',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tasks List
            Expanded(
              child: selectedDayTasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks scheduled for this day.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: selectedDayTasks.length,
                      itemBuilder: (context, index) {
                        final task = selectedDayTasks[index];
                        return _buildTaskCard(task);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        backgroundColor: const Color(0xFF16A34A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTaskCard(TaskItem task) {
    Color indicatorColor = Colors.blue;
    if (task.taskType == 'FERTILIZE') indicatorColor = Colors.green;
    if (task.taskType == 'HARVEST') indicatorColor = Colors.orange;
    if (task.taskType == 'PESTICIDE') indicatorColor = Colors.purple;
    if (task.taskType == 'INSPECT') indicatorColor = Colors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left colored indicator
            Container(
              width: 6,
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${task.taskType} - ${task.field}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time: ${task.time} | Source: MANUAL',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.notes,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ]
                  ],
                ),
              ),
            ),

            // Actions
            IconButton(
              icon: Icon(
                task.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: task.isCompleted ? Colors.green : Colors.green[300],
                size: 28,
              ),
              onPressed: () => ref.read(tasksProvider.notifier).toggleTaskComplete(task.id),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 28),
              onPressed: () => ref.read(tasksProvider.notifier).deleteTask(task.id),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
