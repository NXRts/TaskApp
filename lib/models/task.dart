import 'subtask.dart';

enum TaskPriority { low, medium, high }

enum TaskCategory { academic, personal }

enum TaskType {
  individual,
  group,
  quiz,
  exam,
  practice, // Praktikum
  general,
}

class TaskItem {
  final String id;
  String title;
  String description;
  String? subjectId;
  DateTime dueDate;
  bool isCompleted;
  DateTime? completedAt;
  TaskPriority priority;
  TaskCategory category;
  TaskType taskType;
  List<SubTask> subtasks;
  List<String> attachments; // URLs / links
  String? notes;
  DateTime createdAt;

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.subjectId,
    required this.dueDate,
    this.isCompleted = false,
    this.completedAt,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.academic,
    this.taskType = TaskType.individual,
    List<SubTask>? subtasks,
    List<String>? attachments,
    this.notes,
    DateTime? createdAt,
  })  : subtasks = subtasks ?? [],
        attachments = attachments ?? [],
        createdAt = createdAt ?? DateTime.now();

  double get progress {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    final completedCount = subtasks.where((s) => s.isCompleted).length;
    return completedCount / subtasks.length;
  }

  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;

  bool get isOverdue {
    if (isCompleted) return false;
    return DateTime.now().isAfter(dueDate);
  }

  bool get isDueToday {
    final now = DateTime.now();
    return !isCompleted &&
        dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  Duration get timeLeft => dueDate.difference(DateTime.now());

  String get typeLabel {
    switch (taskType) {
      case TaskType.individual:
        return 'Tugas Individu';
      case TaskType.group:
        return 'Tugas Kelompok';
      case TaskType.quiz:
        return 'Kuis / Ujian Kecil';
      case TaskType.exam:
        return 'UTS / UAS';
      case TaskType.practice:
        return 'Laporan Praktikum';
      case TaskType.general:
        return 'Umum';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority.index,
      'category': category.index,
      'taskType': taskType.index,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'attachments': attachments,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskItem.fromMap(Map<dynamic, dynamic> map) {
    return TaskItem(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Tanpa Judul',
      description: map['description'] as String? ?? '',
      subjectId: map['subjectId'] as String?,
      dueDate: DateTime.tryParse(map['dueDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 1)),
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
      priority: TaskPriority.values[
          (map['priority'] as int? ?? 1).clamp(0, TaskPriority.values.length - 1)],
      category: TaskCategory.values[
          (map['category'] as int? ?? 0).clamp(0, TaskCategory.values.length - 1)],
      taskType: TaskType.values[
          (map['taskType'] as int? ?? 0).clamp(0, TaskType.values.length - 1)],
      subtasks: (map['subtasks'] as List<dynamic>?)
              ?.map((item) => SubTask.fromMap(item as Map<dynamic, dynamic>))
              .toList() ??
          [],
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectId,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? completedAt,
    TaskPriority? priority,
    TaskCategory? category,
    TaskType? taskType,
    List<SubTask>? subtasks,
    List<String>? attachments,
    String? notes,
    DateTime? createdAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      taskType: taskType ?? this.taskType,
      subtasks: subtasks ?? this.subtasks,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

