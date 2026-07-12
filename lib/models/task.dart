class Task {
  final String id;
  final String fieldId;
  final String taskType; // WATER, FERTILIZE, SPRAY, HARVEST, INSPECT, CUSTOM
  final DateTime scheduledDateTime;
  final String recurrence; // ONE_TIME, DAILY, WEEKLY
  final String status; // PENDING, DONE, SKIPPED, MISSED
  final String notes;
  final String sourceType; // MANUAL, AI_GENERATED

  Task({
    required this.id,
    required this.fieldId,
    required this.taskType,
    required this.scheduledDateTime,
    required this.recurrence,
    required this.status,
    required this.notes,
    required this.sourceType,
  });

  Task copyWith({
    String? id,
    String? fieldId,
    String? taskType,
    DateTime? scheduledDateTime,
    String? recurrence,
    String? status,
    String? notes,
    String? sourceType,
  }) {
    return Task(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      taskType: taskType ?? this.taskType,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      recurrence: recurrence ?? this.recurrence,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      sourceType: sourceType ?? this.sourceType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fieldId': fieldId,
        'taskType': taskType,
        'scheduledDateTime': scheduledDateTime.toIso8601String(),
        'recurrence': recurrence,
        'status': status,
        'notes': notes,
        'sourceType': sourceType,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        fieldId: json['fieldId'] as String,
        taskType: json['taskType'] as String,
        scheduledDateTime: DateTime.parse(json['scheduledDateTime'] as String),
        recurrence: json['recurrence'] as String,
        status: json['status'] as String,
        notes: json['notes'] as String? ?? '',
        sourceType: json['sourceType'] as String? ?? 'MANUAL',
      );
}
