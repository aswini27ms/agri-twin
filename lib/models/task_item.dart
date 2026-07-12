class TaskItem {
  final String id;
  final String field;
  final String taskType;
  final DateTime date;
  final String time;
  final String recurrence;
  final String notes;
  final bool isCompleted;

  TaskItem({
    required this.id,
    required this.field,
    required this.taskType,
    required this.date,
    required this.time,
    required this.recurrence,
    this.notes = '',
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field': field,
      'taskType': taskType,
      'date': date.toIso8601String(),
      'time': time,
      'recurrence': recurrence,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] ?? '',
      field: json['field'] ?? '',
      taskType: json['taskType'] ?? '',
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '',
      recurrence: json['recurrence'] ?? '',
      notes: json['notes'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  TaskItem copyWith({
    String? field,
    String? taskType,
    DateTime? date,
    String? time,
    String? recurrence,
    String? notes,
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id,
      field: field ?? this.field,
      taskType: taskType ?? this.taskType,
      date: date ?? this.date,
      time: time ?? this.time,
      recurrence: recurrence ?? this.recurrence,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
