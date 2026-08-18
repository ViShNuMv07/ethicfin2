import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  int get sortWeight {
    switch (this) {
      case TaskPriority.high:
        return 0;
      case TaskPriority.medium:
        return 1;
      case TaskPriority.low:
        return 2;
    }
  }

  String get asString => name;

  static TaskPriority fromString(String? value) {
    switch (value) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }
}


class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdDate;
  final DateTime updatedDate;

  final bool isSynced;

  final bool isDirty;

  final bool isDeleted;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.dueDate,
    this.isCompleted = false,
    required this.createdDate,
    required this.updatedDate,
    this.isSynced = false,
    this.isDirty = true,
    this.isDeleted = false,
  });

  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isCompleted,
    DateTime? updatedDate,
    bool? isSynced,
    bool? isDirty,
    bool? isDeleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      createdDate: createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      isSynced: isSynced ?? this.isSynced,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.asString,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate.toIso8601String(),
      'isSynced': isSynced,
      'isDirty': isDirty,
      'isDeleted': isDeleted,
    };
  }

  factory Task.fromJson(Map<dynamic, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: TaskPriorityX.fromString(json['priority'] as String?),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdDate:
          DateTime.tryParse(json['createdDate'] as String? ?? '') ??
              DateTime.now(),
      updatedDate:
          DateTime.tryParse(json['updatedDate'] as String? ?? '') ??
              DateTime.now(),
      isSynced: json['isSynced'] as bool? ?? false,
      isDirty: json['isDirty'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'priority': priority.asString,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isCompleted': isCompleted,
      'createdDate': Timestamp.fromDate(createdDate),
      'updatedDate': Timestamp.fromDate(updatedDate),
    };
  }

  factory Task.fromFirestore(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      priority: TaskPriorityX.fromString(data['priority'] as String?),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdDate: (data['createdDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedDate: (data['updatedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSynced: true,
      isDirty: false,
      isDeleted: false,
    );
  }

  @override
  String toString() => 'Task($id, "$title", ${priority.asString}, '
      'completed: $isCompleted, dirty: $isDirty)';
}
